import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../models/wallet.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _exigirAdministrador() {
    if (!AppConfig.esAdministrador(FirebaseAuth.instance.currentUser?.email)) {
      throw StateError('Acceso reservado al administrador.');
    }
  }

  Stream<({List<Map<String, dynamic>> saldos, List<Map<String, dynamic>> movimientos})>
      getInformeWalletStream() {
    _exigirAdministrador();
    final wallets = _firestore.collection('clubes').doc(AppConfig.club.clubId).collection('wallets');
    // Consultas por Wallet: las reglas actuales permiten estos caminos concretos.
    // No requiere collectionGroup, índices nuevos ni cambios de permisos.
    return wallets.snapshots(includeMetadataChanges: true).asyncMap((snapshot) async {
      _exigirAdministrador();
      if (snapshot.metadata.isFromCache) {
        throw StateError('Esperando confirmación de los saldos del servidor.');
      }
      final saldos = <Map<String, dynamic>>[];
      final movimientos = <Map<String, dynamic>>[];
      for (final wallet in snapshot.docs) {
        WalletSaldo.fromMap(wallet.data());
        final usuario = await _firestore.collection('usuarios').doc(wallet.id)
            .get(const GetOptions(source: Source.server));
        final nombre = usuario.data()?['nombre'] ?? 'Cuenta sin nombre';
        final correo = usuario.data()?['email'] ?? 'Correo no registrado';
        saldos.add({...wallet.data(), 'usuarioId': wallet.id, 'nombre': nombre, 'email': correo});
        // Sin límite de 50: un historial truncado produciría totales incorrectos.
        final historial = await wallet.reference.collection('movimientos')
            .get(const GetOptions(source: Source.server));
        for (final movimiento in historial.docs) {
          WalletMovimiento.fromMap(movimiento.data());
          movimientos.add({...movimiento.data(), 'id': movimiento.id,
            'usuarioId': wallet.id, 'nombre': nombre, 'email': correo});
        }
      }
      return (saldos: saldos, movimientos: movimientos);
    });
  }

  Stream<List<Map<String, dynamic>>> getDisponibilidadClubStream() {
    _exigirAdministrador();
    return _firestore.collection('clubes').doc(AppConfig.club.clubId)
        .collection('disponibilidadPublica').snapshots(includeMetadataChanges: true).map((snapshot) {
      _exigirAdministrador();
      if (snapshot.metadata.isFromCache) {
        throw StateError('Esperando confirmación de la disponibilidad del servidor.');
      }
      return snapshot.docs.map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id}).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getReservasClubStream() {
    if (!AppConfig.esAdministrador(FirebaseAuth.instance.currentUser?.email)) {
      throw StateError('Solo el administrador puede consultar todas las reservas.');
    }
    // Compatibilidad del primer club con reservas previas al campo clubId.
    // El aislamiento de lectura entre clubes sigue pendiente en el esquema raíz.
    return _firestore.collection('reservas').snapshots(includeMetadataChanges: true).map((snapshot) {
      if (snapshot.metadata.isFromCache) {
        throw StateError('Esperando confirmación de las reservas del servidor.');
      }
      return snapshot.docs.where((doc) => doc.data()['clubId'] == AppConfig.club.clubId ||
            (AppConfig.club.clubId == 'club-demo' && doc.data()['clubId'] == null))
            .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id}).toList();
    });
  }

  Stream<QuerySnapshot> getPendingUsersStream() {
    return _firestore
        .collection('usuarios')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> approveUser(String userId) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'status': 'approved',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> denyUser(String userId) async {
    try {
      await _firestore.collection('usuarios').doc(userId).update({
        'status': 'rejected',
      });
    } catch (e) {
      rethrow;
    }
  }
}
