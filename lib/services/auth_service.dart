import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';
import '../models/usuario.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> saveUserData(
    String userId,
    String nombre,
    String email,
    String? telefono,
    double? nivelPadel, {
    String role = 'user',
    bool? aceptaCondiciones,
    bool? aceptaPrivacidad,
    String? versionCondiciones,
    String? versionPrivacidad,
  }) async {
    // La configuración del club determina los datos iniciales
    // del administrador durante el registro.
    String finalRole = role;
    String finalStatus = 'pending';

    if (AppConfig.esAdministrador(email)) {
      finalRole = 'admin';
      finalStatus = 'approved';
    }

    final usuario = Usuario(
      nombre: nombre,
      email: email,
      telefono: telefono,
      nivelPadel: nivelPadel,
      role: finalRole,
      status: finalStatus,
      fechaRegistro: DateTime.now(),
      aceptaCondiciones: aceptaCondiciones,
      aceptaPrivacidad: aceptaPrivacidad,
      fechaAceptaciones: null,
      versionCondiciones: versionCondiciones,
      versionPrivacidad: versionPrivacidad,
    );

    // Crear mapa de datos con timestamp del servidor.
    final Map<String, dynamic> userData = usuario.toMap();

    // Guardar fecha de aceptaciones mediante timestamp del servidor.
    if (aceptaCondiciones == true || aceptaPrivacidad == true) {
      userData['fechaAceptaciones'] = FieldValue.serverTimestamp();
    }

    // Usar set con merge para asegurar que el documento se guarde correctamente.
    await _firestore
        .collection('usuarios')
        .doc(userId)
        .set(userData, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;

    if (user != null && !user.emailVerified) {
      try {
        await user.sendEmailVerification();
      } catch (e) {
        throw Exception('Error al enviar email de verificación: $e');
      }
    }
  }

  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.reload();
      return user.emailVerified;
    }

    return false;
  }

  Future<void> updateUserData(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore
        .collection('usuarios')
        .doc(userId)
        .update(data);
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;

    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  Future<String?> getUserDisplayName() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['nombre'] ?? user.email;
      }
    }

    return null;
  }

  Future<String?> getUserStatus() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['status'];
      }
    }

    return null;
  }

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data()?['role'];
      }
    }

    return null;
  }

  Future<Map<String, String?>> getUserStatusAndRole() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();

        return {
          'status': data?['status'],
          'role': data?['role'],
        };
      }
    }

    return {
      'status': null,
      'role': null,
    };
  }

  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount googleUser =
        await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth =
        googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await _auth.signInWithCredential(credential);

    // Verificar si el usuario ya existe en Firestore.
    final userDoc = await _firestore
        .collection('usuarios')
        .doc(userCredential.user!.uid)
        .get();

    if (!userDoc.exists) {
      // Crear el usuario en Firestore si no existe.
      await saveUserData(
        userCredential.user!.uid,
        userCredential.user!.displayName ?? 'Usuario',
        userCredential.user!.email ?? '',
        null,
        null,
      );

      // Cerrar sesión después del registro.
      await _auth.signOut();
    }

    return userCredential;
  }
}
