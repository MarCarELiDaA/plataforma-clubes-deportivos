import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/usuario.dart';

class AuthService {
  static bool _enviandoVerificacion = false;
  static Future<FirebaseAuth>? _authDeVerificacion;
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
    String password, {
    required String telefono,
  }) async {
    if (!RegExp(r'^\d{9}$').hasMatch(telefono.trim())) {
      throw FirebaseAuthException(
        code: 'invalid-phone-number',
        message: 'Introduce un teléfono de 9 dígitos.',
      );
    }
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
    String finalStatus = AppConfig.club.requiereAprobacionUsuarios
        ? 'pending' : 'approved';

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
    await _enviarVerificacion(_auth);
  }

  Future<void> _enviarVerificacion(FirebaseAuth auth) async {
    final user = auth.currentUser;

    if (user != null && !user.emailVerified) {
      if (_enviandoVerificacion) {
        throw FirebaseAuthException(
          code: 'verification-in-progress',
          message: 'Ya se está enviando un correo. Espera a que termine.',
        );
      }
      _enviandoVerificacion = true;
      try {
        final email = user.email ?? '';
        final proximoEnvio = await proximoEnvioVerificacion(email);
        if (proximoEnvio != null && proximoEnvio.isAfter(DateTime.now())) {
          throw FirebaseAuthException(
            code: 'verification-cooldown',
            message: 'Espera antes de solicitar otro correo de verificación.',
          );
        }
        await auth.setLanguageCode('es');
        final prefs = await SharedPreferences.getInstance();
        await prefs.reload();
        final ahora = DateTime.now().millisecondsSinceEpoch;
        final peticiones = _peticionesVerificacion(prefs, email, ahora);
        peticiones.add(ahora);
        final guardado = await prefs.setStringList(
          _claveVerificacion(email),
          peticiones.map((peticion) => peticion.toString()).toList(),
        );
        if (!guardado) {
          throw StateError('No se pudo guardar el límite de reenvíos.');
        }
        await user.sendEmailVerification();
      } on FirebaseAuthException {
        rethrow;
      } catch (e) {
        throw Exception('Error al enviar email de verificación: $e');
      } finally {
        _enviandoVerificacion = false;
      }
    }
  }

  String _claveVerificacion(String email) =>
      'email_verification_${AppConfig.club.clubId}_${email.trim().toLowerCase()}';

  List<int> _peticionesVerificacion(
    SharedPreferences prefs, String email, int ahora,
  ) {
    final peticiones = (prefs.getStringList(_claveVerificacion(email)) ?? [])
        .map(int.tryParse)
        .whereType<int>()
        .where((peticion) => peticion > ahora - const Duration(hours: 1).inMilliseconds)
        .toList()..sort();
    return peticiones;
  }

  Future<DateTime?> proximoEnvioVerificacion(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final ahora = DateTime.now().millisecondsSinceEpoch;
    final peticiones = _peticionesVerificacion(prefs, email, ahora);
    if (peticiones.isEmpty) return null;
    final trasUltimo = peticiones.last + const Duration(seconds: 60).inMilliseconds;
    final trasLimite = peticiones.length >= 5
        ? peticiones[peticiones.length - 5] + const Duration(hours: 1).inMilliseconds
        : trasUltimo;
    return DateTime.fromMillisecondsSinceEpoch(
      trasLimite > trasUltimo ? trasLimite : trasUltimo,
    );
  }

  Future<void> reenviarCorreoVerificacion(String email, String password) async {
    final proximoEnvio = await proximoEnvioVerificacion(email);
    if (proximoEnvio != null && proximoEnvio.isAfter(DateTime.now())) {
      throw FirebaseAuthException(
        code: 'verification-cooldown',
        message: 'Espera antes de solicitar otro correo de verificación.',
      );
    }
    // Una instancia separada evita activar las pantallas privadas al reenviar.
    final authCorreo = await (_authDeVerificacion ??= () async {
      try {
        final existentes = Firebase.apps.where((app) => app.name == 'verificacionCorreo');
        final app = existentes.isNotEmpty ? existentes.first : await Firebase.initializeApp(
          name: 'verificacionCorreo', options: Firebase.app().options,
        );
        final auth = FirebaseAuth.instanceFor(app: app);
        if (kIsWeb) await auth.setPersistence(Persistence.NONE);
        return auth;
      } catch (_) {
        _authDeVerificacion = null;
        rethrow;
      }
    }());
    try {
      await authCorreo.signInWithEmailAndPassword(email: email.trim(), password: password);
      await authCorreo.currentUser?.reload();
      if (authCorreo.currentUser?.emailVerified == true) {
        throw FirebaseAuthException(
          code: 'email-already-verified',
          message: 'Tu correo ya está verificado. Cierra este aviso e inicia sesión.',
        );
      }
      await _enviarVerificacion(authCorreo);
    } finally {
      // Reenviar el correo no concede acceso a la aplicación.
      await authCorreo.signOut();
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

  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('usuarios').doc(userId).update(data);
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
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        return doc.data()?['nombre'] ?? user.email;
      }
    }

    return null;
  }

  Future<String?> getUserStatus() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        return doc.data()?['status'];
      }
    }

    return null;
  }

  Future<String?> getUserRole() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        return doc.data()?['role'];
      }
    }

    return null;
  }

  Future<Map<String, String?>> getUserStatusAndRole() async {
    final user = _auth.currentUser;

    if (user != null) {
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data();

        return {'status': data?['status'], 'role': data?['role']};
      }
    }

    return {'status': null, 'role': null};
  }

  Future<UserCredential> signInWithGoogle() async {
    await _googleSignIn.initialize();

    final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);

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
