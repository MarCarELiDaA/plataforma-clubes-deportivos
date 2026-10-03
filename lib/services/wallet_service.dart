import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../config/app_config.dart';
import '../models/wallet.dart';

/// Lectura privada y ajustes administrativos con registro atómico de movimientos.
class WalletService {
  /// Solo añade escrituras: el llamador debe terminar todas las lecturas antes.
  /// Los IDs estables y el estado privado impiden repetir bloqueos o cobros.
  void registrarMovimientoReserva(Transaction transaction, String usuarioId, {
    required String reservaId, required String tipo, required int importeCentimos,
    required WalletSaldo saldo, required int totalDespues, required int bloqueadoDespues,
  }) {
    final wallet = _wallet(usuarioId);
    final movimientoId = '${tipo.toLowerCase()}-$reservaId';
    transaction.set(wallet, {
      'saldoTotalCentimos': totalDespues, 'saldoBloqueadoCentimos': bloqueadoDespues,
      'moneda': 'EUR', 'esPrueba': saldo.esPrueba,
      'fechaActualizacion': FieldValue.serverTimestamp(), 'ultimoMovimientoId': movimientoId,
    });
    transaction.set(wallet.collection('movimientos').doc(movimientoId), {
      'tipo': tipo, 'importeCentimos': importeCentimos,
      'motivo': tipo == 'BLOQUEO' ? 'Importe retenido para una reserva'
          : tipo == 'LIBERACION' ? 'Reserva cancelada: importe liberado'
          : 'Cobro de una reserva iniciada',
      'fecha': FieldValue.serverTimestamp(),
      'autorUid': FirebaseAuth.instance.currentUser!.uid, 'reservaId': reservaId,
      'saldoAntesCentimos': saldo.totalCentimos, 'saldoDespuesCentimos': totalDespues,
      'bloqueadoAntesCentimos': saldo.bloqueadoCentimos,
      'bloqueadoDespuesCentimos': bloqueadoDespues,
    });
  }

  /// Modo de pruebas sin backend: se ejecuta tras validar el inicio de sesión.
  /// No cobra reservas antiguas que carezcan de un bloqueo de Wallet.
  Future<void> cobrarReservasIniciadas() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || !AppConfig.club.moduloActivo('wallet')) return;
    final firestore = FirebaseFirestore.instance;
    final reservas = await firestore.collection('reservas')
        .where('usuarioId', isEqualTo: user.uid).get(const GetOptions(source: Source.server));
    for (final candidata in reservas.docs) {
      final data = candidata.data();
      if (data['clubId'] != AppConfig.club.clubId ||
          data['estadoReserva'] != 'CONFIRMADA' || data['estadoWallet'] != 'BLOQUEADO' ||
          (data['inicioReserva'] as Timestamp).toDate().isAfter(DateTime.now())) continue;
      await firestore.runTransaction((transaction) async {
        final documento = await transaction.get(candidata.reference);
        final actual = documento.data();
        if (actual == null || actual['estadoReserva'] != 'CONFIRMADA' ||
            actual['estadoWallet'] != 'BLOQUEADO' ||
            (actual['inicioReserva'] as Timestamp).toDate().isAfter(DateTime.now())) return;
        final walletDoc = await transaction.get(_wallet(user.uid));
        if (!walletDoc.exists) throw StateError('No se pudo consultar el Wallet para cobrar.');
        final saldo = WalletSaldo.fromMap(walletDoc.data()!);
        final importe = actual['importeWalletCentimos'] as int;
        if (importe <= 0 || saldo.bloqueadoCentimos < importe) {
          throw StateError('El saldo bloqueado no coincide con la reserva.');
        }
        registrarMovimientoReserva(transaction, user.uid,
          reservaId: candidata.id, tipo: 'COBRO', importeCentimos: importe,
          saldo: saldo, totalDespues: saldo.totalCentimos - importe,
          bloqueadoDespues: saldo.bloqueadoCentimos - importe);
        transaction.update(candidata.reference, {'estadoWallet': 'COBRADO'});
      });
    }
  }

  String crearReferenciaSimulacion(String usuarioId) =>
      'sim-${_wallet(usuarioId).collection('movimientos').doc().id}';

  /// La referencia permite reintentar sin duplicar un ingreso simulado.
  /// Un pago real deberá confirmarlo un servidor que verifique la pasarela;
  /// nunca se aceptará como prueba de pago un importe enviado por el navegador.
  Future<void> simularRecarga(String usuarioId, {
    required int importeCentimos, required String referencia,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final config = AppConfig.club.wallet;
    if (user == null || user.uid != usuarioId ||
        !AppConfig.club.moduloActivo('wallet') || !config.simulacionRecargas ||
        importeCentimos <= 0 || importeCentimos > 9007199254740991 ||
        !RegExp(r'^sim-[A-Za-z0-9]{20}$').hasMatch(referencia)) {
      throw StateError('No se puede realizar esta recarga simulada.');
    }
    final firestore = FirebaseFirestore.instance;
    final wallet = _wallet(usuarioId);
    final movimiento = wallet.collection('movimientos').doc(referencia);
    await firestore.runTransaction((transaction) async {
      final usuario = await transaction.get(firestore.collection('usuarios').doc(usuarioId));
      final documento = await transaction.get(wallet);
      final anterior = await transaction.get(movimiento);
      if (!usuario.exists) throw StateError('La cuenta ya no existe.');
      if (anterior.exists) {
        final data = anterior.data()!;
        if (data['tipo'] != 'RECARGA_SIMULADA' ||
            data['importeCentimos'] != importeCentimos || data['autorUid'] != user.uid) {
          throw StateError('La referencia ya corresponde a otra operación.');
        }
        return;
      }
      final saldo = documento.exists ? WalletSaldo.fromMap(documento.data()!)
          : const WalletSaldo(totalCentimos: 0, bloqueadoCentimos: 0, esPrueba: true);
      if (!saldo.esPrueba) throw StateError('Solo se pueden simular recargas en un Wallet de prueba.');
      final total = saldo.totalCentimos + importeCentimos;
      if (total > 9007199254740991) throw StateError('El saldo supera la precisión admitida.');
      transaction.set(wallet, {
        'saldoTotalCentimos': total, 'saldoBloqueadoCentimos': saldo.bloqueadoCentimos,
        'moneda': 'EUR', 'esPrueba': true,
        'fechaActualizacion': FieldValue.serverTimestamp(), 'ultimoMovimientoId': referencia,
      });
      transaction.set(movimiento, {
        'tipo': 'RECARGA_SIMULADA', 'importeCentimos': importeCentimos,
        'motivo': 'Recarga simulada sin pago real', 'fecha': FieldValue.serverTimestamp(),
        'autorUid': user.uid, 'saldoAntesCentimos': saldo.totalCentimos,
        'saldoDespuesCentimos': total, 'origen': 'SIMULACION', 'referenciaOperacion': referencia,
      });
    });
  }

  Future<List<({String id, String email, String nombre})>> buscarUsuarios(
    String identificador,
  ) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null || !AppConfig.esAdministrador(admin.email)) {
      throw StateError('Solo el administrador puede buscar otras cuentas.');
    }
    final input = identificador.trim();
    final esCorreo = input.contains('@');
    final value = esCorreo ? input : input.replaceAll(RegExp(r'[\s().-]'), '');
    if (value.isEmpty) throw StateError('Introduce un correo o teléfono.');
    final coleccion = FirebaseFirestore.instance.collection('usuarios');
    // Las cuentas antiguas pueden tener el teléfono guardado como número.
    // Consultamos ambos tipos sin modificar perfiles ni descargar la colección.
    final telefonoNumerico = !esCorreo && RegExp(r'^\d{9}$').hasMatch(value)
        ? int.tryParse(value) : null;
    final consulta = esCorreo
        ? coleccion.where('email', isEqualTo: value)
        : coleccion.where('telefono', whereIn: [
            value,
            if (telefonoNumerico != null) telefonoNumerico,
          ]);
    final usuarios = await consulta.get(const GetOptions(source: Source.server));
    if (usuarios.docs.isEmpty) {
      throw StateError('No se encontraron cuentas con ese correo o teléfono.');
    }
    final resultados = usuarios.docs.map((usuario) {
      final data = usuario.data();
      final email = data['email'] as String;
      final nombre = (data['nombre'] as String?)?.trim();
      return (id: usuario.id, email: email,
          nombre: nombre == null || nombre.isEmpty ? email : nombre);
    }).toList();
    resultados.sort((a, b) => a.email.compareTo(b.email));
    return resultados;
  }

  Future<void> ajustarSaldo(String usuarioId, {
    required int importeCentimos, required bool ingreso, required String motivo,
  }) async {
    final admin = FirebaseAuth.instance.currentUser;
    if (admin == null || !AppConfig.esAdministrador(admin.email) ||
        !AppConfig.club.moduloActivo('wallet')) {
      throw StateError('Solo el administrador puede ajustar saldo.');
    }
    if (importeCentimos <= 0 || motivo.trim().isEmpty) {
      throw StateError('Introduce un importe positivo y un motivo.');
    }
    final firestore = FirebaseFirestore.instance;
    final wallet = _wallet(usuarioId);
    // El ID se conserva durante los reintentos de la transacción.
    final movimiento = wallet.collection('movimientos').doc();
    await firestore.runTransaction((transaction) async {
      final usuario = await transaction.get(firestore.collection('usuarios').doc(usuarioId));
      final documento = await transaction.get(wallet);
      if (!usuario.exists) throw StateError('La cuenta ya no existe.');
      final saldo = documento.exists ? WalletSaldo.fromMap(documento.data()!)
          : WalletSaldo(totalCentimos: 0, bloqueadoCentimos: 0,
              esPrueba: AppConfig.club.wallet.simulacionRecargas);
      if (!ingreso && importeCentimos > saldo.disponibleCentimos) {
        throw StateError('La retirada supera el saldo disponible. El saldo bloqueado no se puede retirar.');
      }
      final total = saldo.totalCentimos + (ingreso ? importeCentimos : -importeCentimos);
      if (total > 9007199254740991) {
        throw StateError('El saldo supera la precisión admitida por la aplicación.');
      }
      transaction.set(wallet, {
        'saldoTotalCentimos': total,
        'saldoBloqueadoCentimos': saldo.bloqueadoCentimos,
        'moneda': 'EUR', 'esPrueba': saldo.esPrueba,
        'fechaActualizacion': FieldValue.serverTimestamp(),
        'ultimoMovimientoId': movimiento.id,
      });
      transaction.set(movimiento, {
        'tipo': ingreso ? 'INGRESO' : 'RETIRADA',
        'importeCentimos': importeCentimos, 'motivo': motivo.trim(),
        'fecha': FieldValue.serverTimestamp(), 'autorUid': admin.uid,
        'saldoAntesCentimos': saldo.totalCentimos, 'saldoDespuesCentimos': total,
      });
    });
  }

  DocumentReference<Map<String, dynamic>> _wallet(String usuarioId) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || (user.uid != usuarioId && !AppConfig.esAdministrador(user.email)) ||
        !AppConfig.club.moduloActivo('wallet')) {
      throw StateError('No se puede acceder a este Wallet.');
    }
    return FirebaseFirestore.instance.collection('clubes')
        .doc(AppConfig.club.clubId).collection('wallets').doc(usuarioId);
  }

  Stream<WalletSaldo?> getSaldoStream(String usuarioId) {
    return _wallet(usuarioId).snapshots(includeMetadataChanges: true).map((doc) {
      if (doc.metadata.isFromCache) {
        throw StateError('Esperando confirmación del saldo del servidor.');
      }
      if (!doc.exists) return null;
      return WalletSaldo.fromMap(doc.data()!);
    });
  }

  Stream<List<WalletMovimiento>> getMovimientosStream(String usuarioId) {
    return _wallet(usuarioId).collection('movimientos')
        .orderBy('fecha', descending: true).limit(50)
        .snapshots(includeMetadataChanges: true).map((snapshot) {
      if (snapshot.metadata.isFromCache) {
        throw StateError('Esperando confirmación de movimientos del servidor.');
      }
      return snapshot.docs
          .map((doc) => WalletMovimiento.fromMap(doc.data())).toList();
    });
  }
}
