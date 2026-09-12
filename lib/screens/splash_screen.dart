import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _isInitialized = false;
  String _statusText = 'Cargando';

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Inicializar Firebase
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyCgzQj-l2smjxWVy4fuhx8Ju6c5K8_2BYY",
          authDomain: "furtivosxml.firebaseapp.com",
          projectId: "furtivosxml",
          storageBucket: "furtivosxml.firebasestorage.app",
          messagingSenderId: "313903258233",
          appId: "1:313903258233:android:8895d4f57c37b3b66192a8",
        ),
      );

      // Cerrar cualquier sesión de Firebase que haya quedado persistida.
      // La aplicación solicitará las credenciales cada vez que se abra.
      await FirebaseAuth.instance.signOut();

      setState(() {
        _statusText = 'Cargando';
      });

      // Inicializar notificaciones
      await NotificationService().initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Navegar a Login después de inicializar
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Error de inicialización';
        });

        // En caso de error, navegar igualmente a Login para manejarlo allí
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071A42),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            if (!_isInitialized)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppTheme.accentGreen,
                ),
                strokeWidth: 4,
              )
            else
              const Icon(
                Icons.check_circle,
                color: AppTheme.accentGreen,
                size: 48,
              ),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppTheme.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}