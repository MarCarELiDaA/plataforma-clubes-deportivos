import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Firebase ya se inicializa en main.dart.
      // Aquí solo preparamos las notificaciones.
      // En Web no hace nada.
      // En Android/iOS prepara las notificaciones.
      await NotificationService().initialize();
    } catch (_) {
      // Si la preparación de notificaciones falla, continuamos
      // igualmente hacia el login.
    }

    if (!mounted) return;

    // Sustituimos directamente el splash por el login,
    // sin animación ni pantalla intermedia.
    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        pageBuilder: (context, animation, secondaryAnimation) {
          return const LoginScreen();
        },
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: AppTheme.borderSoft,
                    ),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Icon(
                    Icons.sports_tennis_rounded,
                    size: 52,
                    color: AppTheme.success,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'Clubes Deportivos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Preparando la aplicación',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppTheme.success,
                    strokeWidth: 2.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
