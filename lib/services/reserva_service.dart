import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../models/club/instalacion.dart';
import '../models/wallet.dart';
import 'wallet_service.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _publicTimeZonesInitialized = false;

  DateTime getInicioHorarioPublico(DateTime date, String time) {
    if (!_publicTimeZonesInitialized) {
      if (!tz.timeZoneDatabase.isInitialized) {
        tzdata.initializeTimeZones();
      }
      _publicTimeZonesInitialized = true;
    }
    final parts = time.split(':');
    return tz.TZDateTime(
      tz.getLocation(AppConfig.club.zonaHoraria),
      date.year, date.month, date.day,
      int.parse(parts[0]), int.parse(parts[1]),
    ).toUtc();
  }

  Stream<List<({DateTime inicio, DateTime fin})>>
      getDisponibilidadPublicaStream(String instalacionId, String fecha) {
      final day = DateTime.parse(fecha);
      String formatDate(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      return _firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('disponibilidadPublica')
          .where('instalacionId', isEqualTo: instalacionId)
          .where('fecha', whereIn: [
            formatDate(DateTime(day.year, day.month, day.day - 1)),
            fecha,
            formatDate(DateTime(day.year, day.month, day.day + 1)),
          ])
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
      if (snapshot.metadata.isFromCache) {
        throw StateError('Disponibilidad pendiente de confirmar con el servidor');
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data.length != 4 || data['instalacionId'] != instalacionId ||
            data['fecha'] is! String || data['horaInicio'] is! String ||
            data['duracionMinutos'] is! int) {
          throw const FormatException('Intervalo inválido');
        }
        final duration = data['duracionMinutos'] as int;
        final time = data['horaInicio'] as String;
        if (duration <= 0 ||
            !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
          throw const FormatException('Intervalo inválido');
        }
        final inicio = getInicioHorarioPublico(
          DateTime.parse(data['fecha'] as String), time,
        );
        final fin = inicio.add(Duration(minutes: duration));
        return (inicio: inicio, fin: fin);
      }).toList();
    });
  }

  Future<String> crearReserva(Map<String, dynamic> reservaData) async {
    try {
      for (final instalacion in [
        ...AppConfig.club.instalaciones,
        ...AppConfig.club.actividades.expand((actividad) => actividad.instalaciones),
      ]) {
        if (instalacion.id == reservaData['instalacionId']) {
          return crearReservaConVerificacion(reservaData, instalacion);
        }
      }
      throw StateError('La instalación ya no está disponible.');
    } catch (e) {
      rethrow;
    }
  }

  Future<String> crearReservaConVerificacion(
    Map<String, dynamic> reservaData,
    Instalacion instalacion,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final usuarioId = reservaData['usuarioId'] as String;
      final esAdmin = AppConfig.esAdministrador(user?.email);
      if (user == null || (usuarioId != user.uid && !esAdmin)) {
        throw StateError('Inicia sesión para crear tu reserva.');
      }
      final instalacionId = reservaData['instalacionId'] as String;
      final fecha = reservaData['fecha'] as String;
      final horaInicio = reservaData['horaInicio'] as String;
      final duration = reservaData['duracionMinutos'] as int;
      if (duration <= 0) throw Exception('Duración de reserva inválida');
      final start = getInicioHorarioPublico(DateTime.parse(fecha), horaInicio);
      final end = start.add(Duration(minutes: duration));
      String formatDate(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      final diaLocal = DateTime.parse(fecha);
      final previousDay = DateTime(diaLocal.year, diaLocal.month, diaLocal.day - 1);
      final nextDay = DateTime(diaLocal.year, diaLocal.month, diaLocal.day + 1);
      final esClase = instalacion.aforoPorHorario > 1;
      if (instalacion.id != instalacionId ||
          !instalacion.horarios.contains(horaInicio) ||
          duration != instalacion.duracionReservaMinutos) {
        throw StateError('La clase o su horario no coinciden con la configuración.');
      }
      final docRef = _firestore.collection('reservas').doc();
      final controlReserva = _firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('controlReservas').doc(instalacionId);
      final controlClase = _firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('controlClases').doc('${instalacionId}_${fecha}_$horaInicio');
      final inicio = getInicioHorarioPublico(DateTime.parse(fecha), horaInicio);
      if (!inicio.isAfter(DateTime.now())) {
        throw StateError('Este horario ya ha comenzado.');
      }
      final importe = AppConfig.club.moduloActivo('wallet')
          ? instalacion.preciosPorHorarioCentimos[horaInicio] ?? 0 : 0;
      final wallet = _firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('wallets').doc(usuarioId);
      final datos = <String, dynamic>{
        ...reservaData,
        'clubId': AppConfig.club.clubId,
        'creadaPorUid': user.uid,
        'inicioReserva': Timestamp.fromDate(inicio),
        'minutosAntelacionCancelacion': instalacion.minutosAntelacionCancelacion,
        'limiteCancelacion': Timestamp.fromDate(inicio.subtract(
          Duration(minutes: instalacion.minutosAntelacionCancelacion))),
        'importeWalletCentimos': importe,
        'estadoWallet': importe > 0 ? 'BLOQUEADO' : 'SIN_CARGO',
      };

      Future<String> prepararReserva(Transaction transaction) async {
        // Un único documento por instalación coordina todos sus días y horarios:
        // también se comparte entre reservas que cruzan medianoche y cancelaciones.
        // No representa ocupación ni reemplaza la consulta de reservas existentes.
        await transaction.get(controlReserva);
        if (esAdmin) {
          final destinatario = await transaction.get(
              _firestore.collection('usuarios').doc(usuarioId));
          if (!destinatario.exists) throw StateError('La cuenta seleccionada ya no existe.');
          datos['nombreUsuario'] = destinatario.data()!['nombre'] ??
              destinatario.data()!['email'] ?? 'Usuario';
        }
        // Serializa las altas de la misma clase. Al cambiar este documento,
        // Firestore reintenta y vuelve a consultar plazas y reservas del usuario.
        if (esClase) await transaction.get(controlClase);
        WalletSaldo? saldo;
        if (importe > 0) {
          final documento = await transaction.get(wallet);
          if (!documento.exists) throw StateError(esAdmin && usuarioId != user.uid
              ? 'El usuario seleccionado no tiene Wallet. Ingresa saldo antes de reservar.'
              : 'Recarga tu Wallet antes de reservar.');
          saldo = WalletSaldo.fromMap(documento.data()!);
          if (saldo.disponibleCentimos < importe) {
            throw StateError(esAdmin && usuarioId != user.uid
                ? 'Saldo disponible insuficiente en el Wallet del usuario seleccionado.'
                : 'Saldo disponible insuficiente. Recarga tu Wallet.');
          }
        }
        final fechaParts = fecha.split('-');

        final fechaReserva = DateTime(
          int.parse(fechaParts[0]),
          int.parse(fechaParts[1]),
          int.parse(fechaParts[2]),
        );

        if (!esAdmin && !validarAntelacion(fechaReserva, instalacion.maxDiasAntelacion)) {
          throw Exception(
            'Solo puedes reservar hasta ${instalacion.maxDiasAntelacion} días de antelación',
          );
        }

        final querySnapshot = await _firestore
            .collection('reservas')
            .where('instalacionId', isEqualTo: instalacionId)
            .where('fecha', whereIn: [formatDate(previousDay), fecha, formatDate(nextDay)])
            .where('estadoReserva', isEqualTo: 'CONFIRMADA')
            .get(const GetOptions(source: Source.server));

        int plazasOcupadas = 0;
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          if (data['clubId'] != AppConfig.club.clubId &&
              !(AppConfig.club.clubId == 'club-demo' && data['clubId'] == null)) continue;
          final existingStart = getInicioHorarioPublico(
              DateTime.parse(data['fecha'] as String), data['horaInicio'] as String);
          final existingDuration = data['duracionMinutos'] as int;
          if (existingDuration <= 0) {
            throw Exception('No se pudo verificar la ocupación');
          }
          final existingEnd = existingStart.add(Duration(minutes: existingDuration));
          if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
            if (esClase && existingStart == start && existingDuration == duration) {
              if (data['usuarioId'] == usuarioId) {
                throw StateError('Ya tienes una reserva en esta clase y horario.');
              }
              plazasOcupadas++;
              continue;
            }
            throw Exception('Este horario se solapa con una reserva existente');
          }
        }

        if (esClase && plazasOcupadas >= instalacion.aforoPorHorario) {
          throw StateError('La clase está completa.');
        }

        transaction.set(docRef, datos);
        if (saldo != null) {
          WalletService().registrarMovimientoReserva(transaction, usuarioId,
            reservaId: docRef.id, tipo: 'BLOQUEO', importeCentimos: importe,
            saldo: saldo, totalDespues: saldo.totalCentimos,
            bloqueadoDespues: saldo.bloqueadoCentimos + importe);
        }
        final publicRef = _firestore.collection('clubes')
            .doc(AppConfig.club.clubId)
            .collection('disponibilidadPublica').doc(docRef.id);
        transaction.set(publicRef, {
          'instalacionId': instalacionId,
          'fecha': fecha,
          'horaInicio': horaInicio,
          'duracionMinutos': duration,
        });
        if (esClase) transaction.set(controlClase, {
          'instalacionId': instalacionId, 'fecha': fecha, 'horaInicio': horaInicio,
          'ultimaReservaId': docRef.id,
        });
        transaction.set(controlReserva, {
          'reservaId': docRef.id,
          'operacion': 'CREAR',
          'actualizadoEn': FieldValue.serverTimestamp(),
        });

        return docRef.id;
      }

      // La conversión Dart/JavaScript puede ocultar las excepciones del callback.
      // Conservamos la causa sin convertir un fallo en una transacción válida.
      Object? errorOriginal;
      StackTrace? stackOriginal;
      try {
        return await _firestore.runTransaction((transaction) async {
          errorOriginal = null;
          stackOriginal = null;
          try {
            return await prepararReserva(transaction);
          } catch (error, stack) {
            errorOriginal = error;
            stackOriginal = stack;
            rethrow;
          }
        });
      } catch (error) {
        if (errorOriginal != null && stackOriginal != null) {
          Error.throwWithStackTrace(errorOriginal!, stackOriginal!);
        }
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getReservasUsuarioConId(
    String usuarioId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (AppConfig.esAdministrador(FirebaseAuth.instance.currentUser?.email)) rethrow;
      return [];
    }
  }

  Future<void> cancelarReserva(String reservaId, {bool comoAdministrador = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Inicia sesión para cancelar.');
    if (comoAdministrador && !AppConfig.esAdministrador(user.email)) {
      throw StateError('Solo el administrador puede cancelar reservas de otros usuarios.');
    }
    final reserva = _firestore.collection('reservas').doc(reservaId);
    await _firestore.runTransaction((transaction) async {
      final documento = await transaction.get(reserva);
      final data = documento.data();
      if (data == null || (!comoAdministrador && data['usuarioId'] != user.uid)) {
        throw StateError('La reserva no pertenece a tu cuenta.');
      }
      if (data['estadoReserva'] == 'CANCELADA_POR_USUARIO' ||
          data['estadoReserva'] == 'CANCELADA_POR_ADMIN') return;
      if (data['estadoReserva'] != 'CONFIRMADA') {
        throw StateError('La reserva ya no se puede cancelar.');
      }
      if (!comoAdministrador && !puedeCancelarReserva(data['fecha'] as String, data['horaInicio'] as String,
          limiteCancelacion: data['limiteCancelacion'] as Timestamp?)) {
        throw StateError('El plazo de cancelación de esta reserva ha terminado.');
      }
      if (data['clubId'] != AppConfig.club.clubId &&
          !(AppConfig.club.clubId == 'club-demo' && data['clubId'] == null)) {
        throw StateError('La reserva no pertenece al club actual.');
      }
      final controlReserva = _firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('controlReservas').doc(data['instalacionId'] as String);
      await transaction.get(controlReserva);
      final usuarioId = data['usuarioId'] as String;
      final cambios = <String, dynamic>{
        'estadoReserva': comoAdministrador ? 'CANCELADA_POR_ADMIN' : 'CANCELADA_POR_USUARIO',
        if (comoAdministrador) 'canceladaPorUid': user.uid,
        if (comoAdministrador) 'fechaCancelacion': FieldValue.serverTimestamp(),
      };
      if (data['estadoWallet'] == 'BLOQUEADO') {
        final wallet = _firestore.collection('clubes').doc(AppConfig.club.clubId)
            .collection('wallets').doc(usuarioId);
        final walletDoc = await transaction.get(wallet);
        if (!walletDoc.exists) throw StateError('No se pudo consultar el Wallet.');
        final saldo = WalletSaldo.fromMap(walletDoc.data()!);
        final importe = data['importeWalletCentimos'] as int;
        if (saldo.bloqueadoCentimos < importe) {
          throw StateError('El saldo bloqueado no coincide con la reserva.');
        }
        WalletService().registrarMovimientoReserva(transaction, usuarioId,
          reservaId: reservaId, tipo: 'LIBERACION', importeCentimos: importe,
          saldo: saldo, totalDespues: saldo.totalCentimos,
          bloqueadoDespues: saldo.bloqueadoCentimos - importe);
        cambios['estadoWallet'] = 'LIBERADO';
      }
      transaction.update(reserva, cambios);
      transaction.delete(_firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('disponibilidadPublica').doc(reservaId));
      transaction.set(controlReserva, {
        'reservaId': reservaId,
        'operacion': 'CANCELAR',
        'actualizadoEn': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<int> calcularHorasReservadasEnDia(
    String usuarioId,
    String fecha,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('fecha', isEqualTo: fecha)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get();

      int totalHoras = 0;

      for (var doc in querySnapshot.docs) {
        final duracion = doc.data()['duracionMinutos'] as int? ?? 90;

        totalHoras += duracion;
      }

      return totalHoras;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> puedeReservarEnDia(
    String usuarioId,
    String fecha,
    int duracionNueva,
    Instalacion instalacion,
  ) async {
    final horasReservadas = await calcularHorasReservadasEnDia(
      usuarioId,
      fecha,
    );

    final horasTotales = horasReservadas + duracionNueva;

    return horasTotales <= instalacion.maxMinutosPorDia;
  }

  bool validarAntelacion(DateTime fechaReserva, int maxDiasAntelacion) {
    final hoy = DateTime.now();

    final fechaLimite = hoy.add(Duration(days: maxDiasAntelacion));

    final fechaReservaSinHora = DateTime(
      fechaReserva.year,
      fechaReserva.month,
      fechaReserva.day,
    );

    final fechaLimiteSinHora = DateTime(
      fechaLimite.year,
      fechaLimite.month,
      fechaLimite.day,
    );

    return fechaReservaSinHora.isBefore(fechaLimiteSinHora) ||
        fechaReservaSinHora.isAtSameMomentAs(fechaLimiteSinHora);
  }

  bool puedeCancelarReserva(String fecha, String hora, {Timestamp? limiteCancelacion}) {
    try {
      if (limiteCancelacion != null) {
        return DateTime.now().isBefore(limiteCancelacion.toDate());
      }
      final parts = fecha.split('-');

      if (parts.length != 3) return false;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final timeParts = hora.split(':');

      if (timeParts.length != 2) return false;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = DateTime.now();

      final reservationTime = DateTime(year, month, day, hour, minute);

      final horaAntes = reservationTime.subtract(const Duration(hours: 1));

      return now.isBefore(horaAntes);
    } catch (e) {
      return false;
    }
  }
}
