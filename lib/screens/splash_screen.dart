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
  Color get _background => AppTheme.clubBackground;
  Color get _surface => AppTheme.clubSurface;
  Color get _borderSoft => AppTheme.clubBorderSoft;
  Color get _accent => AppTheme.accent;
  Color get _textPrimary => AppTheme.clubTextPrimary;
  Color get _textSecondary => AppTheme.clubTextSecondary;

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
      backgroundColor: _background,
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
                    color: _surface,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: _borderSoft),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Icon(
                    Icons.sports_tennis_rounded,
                    size: 52,
                    color: _accent,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'Clubes Deportivos',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: _textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  'Preparando la aplicación',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: _textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: _accent,
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
