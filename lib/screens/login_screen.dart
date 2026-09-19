import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../utils/network_utils.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _rememberEmail = true;
  bool _obscurePassword = true;
  String? _errorMessage;

  Color get _primary => AppTheme.primary;
  Color get _primarySoft => AppTheme.primaryLight;
  Color get _background => AppTheme.clubBackground;
  Color get _surface => AppTheme.clubSurface;
  Color get _surfaceSoft => AppTheme.clubSurfaceSoft;
  Color get _textPrimary => AppTheme.clubTextPrimary;
  Color get _textSecondary => AppTheme.clubTextSecondary;
  Color get _border => AppTheme.clubBorder;
  Color get _textOnPrimary => AppTheme.textOnPrimary;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _checkCurrentUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');

    if (!mounted) return;

    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberEmail = true;
      });
    }
  }

  Future<void> _saveEmail() async {
    final prefs = await SharedPreferences.getInstance();

    if (_rememberEmail) {
      await prefs.setString('saved_email', _emailController.text.trim());
    } else {
      await prefs.remove('saved_email');
    }
  }

  Future<void> _checkCurrentUser() async {
    final user = _authService.currentUser;

    if (user == null) return;

    try {
      await user.reload();

      if (!mounted) return;

      final refreshedUser = _authService.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        final status = await _authService.getUserStatus();

        if (!mounted) return;

        if (status == 'approved') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        } else {
          await _authService.signOut();

          if (!mounted) return;

          await _showAccountStatusDialog(status);
        }
      }
    } catch (_) {
      // Si no se puede comprobar el usuario actual,
      // permanecemos en la pantalla de login.
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasInternet = await NetworkUtils.isNetworkAvailable();

      if (!hasInternet) {
        if (!mounted) return;

        setState(() {
          _errorMessage = NetworkUtils.errorNoInternet;
          _isLoading = false;
        });

        return;
      }

      await _saveEmail();

      final userCredential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      await user.reload();

      final refreshedUser = _authService.currentUser;

      if (refreshedUser == null) {
        throw FirebaseAuthException(code: 'user-not-found');
      }

      if (!refreshedUser.emailVerified) {
        await _authService.signOut();

        if (!mounted) return;

        await _showEmailVerificationDialog();

        setState(() {
          _isLoading = false;
        });

        return;
      }

      final status = await _authService.getUserStatus();

      if (!mounted) return;

      if (status != 'approved') {
        await _authService.signOut();

        if (!mounted) return;

        await _showAccountStatusDialog(status);

        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = NetworkUtils.errorFirebase;
        _isLoading = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Introduce tu correo electrónico para continuar.';
      });
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Introduce un correo electrónico válido.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final hasInternet = await NetworkUtils.isNetworkAvailable();

      if (!hasInternet) {
        if (!mounted) return;

        setState(() {
          _errorMessage = NetworkUtils.errorNoInternet;
          _isLoading = false;
        });

        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Si el correo existe, recibirás instrucciones para restablecer la contraseña.',
          ),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage = NetworkUtils.errorFirebase;
        _isLoading = false;
      });
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'El correo electrónico no es válido.';

      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';

      case 'user-not-found':
        return 'No existe ninguna cuenta con este correo electrónico.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'El correo o la contraseña no son correctos.';

      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos e inténtalo de nuevo.';

      case 'network-request-failed':
        return NetworkUtils.errorNoInternet;

      case 'operation-not-allowed':
        return 'El inicio de sesión con correo electrónico no está disponible.';

      default:
        return 'No se ha podido iniciar sesión. Inténtalo de nuevo.';
    }
  }

  Future<void> _showAccountStatusDialog(String? status) async {
    String title;
    String message;
    IconData icon;

    switch (status) {
      case 'pending':
        title = 'Cuenta pendiente';
        message =
            'Tu cuenta ha sido registrada correctamente, pero todavía está pendiente de aprobación por parte del administrador del club.';
        icon = Icons.hourglass_empty_rounded;
        break;

      case 'rejected':
        title = 'Cuenta no aprobada';
        message =
            'Tu solicitud de acceso no ha sido aprobada por el administrador del club.';
        icon = Icons.block_rounded;
        break;

      default:
        title = 'Cuenta no disponible';
        message =
            'No se ha podido comprobar el estado de tu cuenta. Contacta con el administrador del club.';
        icon = Icons.info_outline_rounded;
        break;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(color: _textSecondary, fontSize: 15, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: _textOnPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Entendido',
                  style: TextStyle(
                    color: _textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEmailVerificationDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _primarySoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.mark_email_unread_outlined, color: _primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Verifica tu correo',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Debes verificar tu correo electrónico antes de iniciar sesión. '
            'Revisa tu bandeja de entrada y la carpeta de spam.',
            style: TextStyle(color: _textSecondary, fontSize: 15, height: 1.5),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: _textOnPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Entendido',
                  style: TextStyle(
                    color: _textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _textSecondary),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _surface,
      labelStyle: TextStyle(color: _textSecondary, fontWeight: FontWeight.w400),
      hintStyle: TextStyle(color: _textSecondary),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.error, width: 1.5),
      ),
    );
  }

  Widget _loginLogoFallback(String logo) {
    if (logo.isNotEmpty) {
      return Image.asset(
        logo,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(Icons.sports_tennis_rounded, size: 52, color: _primary);
        },
      );
    }

    return Icon(Icons.sports_tennis_rounded, size: 52, color: _primary);
  }

  @override
  Widget build(BuildContext context) {
    final club = AppConfig.club;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: _border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.055),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 280,
                          height: 116,
                          padding: EdgeInsets.zero,
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withValues(alpha: 0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: club.imagenLogin.isNotEmpty
                                ? Image.asset(
                                    club.imagenLogin,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _loginLogoFallback(club.logo);
                                    },
                                  )
                                : _loginLogoFallback(club.logo),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          club.nombre,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Accede a tu cuenta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 30),
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                decoration: _inputDecoration(
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';

                                  if (email.isEmpty) {
                                    return 'Introduce tu correo electrónico';
                                  }

                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!emailRegex.hasMatch(email)) {
                                    return 'Introduce un correo válido';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (!_isLoading) {
                                    _login();
                                  }
                                },
                                decoration: _inputDecoration(
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Introduce tu contraseña';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _forgotPassword,
                                  style: TextButton.styleFrom(
                                    foregroundColor: _primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                  ),
                                  child: Text(
                                    '¿Has olvidado tu contraseña?',
                                    style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: _rememberEmail,
                                      activeColor: _primary,
                                      checkColor: _textOnPrimary,
                                      onChanged: _isLoading
                                          ? null
                                          : (value) {
                                              setState(() {
                                                _rememberEmail = value ?? false;
                                              });
                                            },
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Recordar mi correo electrónico',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: AppTheme.error.withValues(
                                        alpha: 0.22,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.error_outline_rounded,
                                        color: AppTheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: AppTheme.error,
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: _textOnPrimary,
                                    disabledBackgroundColor: _primary
                                        .withValues(alpha: 0.45),
                                    disabledForegroundColor: _textOnPrimary
                                        .withValues(alpha: 0.7),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: _textOnPrimary,
                                          ),
                                        )
                                      : Text(
                                          'Iniciar sesión',
                                          style: TextStyle(
                                            color: _textOnPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 17,
                    ),
                    decoration: BoxDecoration(
                      color: _surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿No tienes una cuenta?',
                          style: TextStyle(color: _textSecondary, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            foregroundColor: _primary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            'Crear cuenta',
                            style: TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
