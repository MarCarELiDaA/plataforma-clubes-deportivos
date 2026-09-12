import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _rememberEmail = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
    _checkCurrentUser();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('saved_email');
    if (savedEmail != null && mounted) {
      setState(() {
        _emailController.text = savedEmail;
        _rememberEmail = true;
      });
    }
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberEmail) {
      await prefs.setString('saved_email', email);
    } else {
      await prefs.remove('saved_email');
    }
  }

  Future<void> _checkCurrentUser() async {
    final user = _authService.currentUser;
    if (user != null && mounted) {
      // Verificar si el email está verificado
      final isVerified = await _authService.isEmailVerified();
      final userEmail = user.email ?? '';
      
      // El administrador no necesita verificación de email
      if (userEmail != 'martin.bautista.sanchez@gmail.com' && !isVerified) {
        await _authService.signOut();
        setState(() {
          _errorMessage = 'Debes verificar tu email antes de acceder. Revisa tu bandeja de entrada.';
        });
        return;
      }

      // Verificar si el usuario existe en Firestore y su estado
      final userStatus = await _authService.getUserStatus();
      
      // Si el usuario no existe en Firestore (se borró), cerrar sesión
      if (userStatus == null) {
        await _authService.signOut();
        setState(() {
          _errorMessage = 'Usuario no encontrado. Por favor, regístrate nuevamente.';
        });
        return;
      }
      
      if (userEmail != 'martin.bautista.sanchez@gmail.com') {
        if (userStatus == 'pending') {
          await _authService.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta está pendiente de aprobación por el administrador.';
          });
          return;
        }
        
        if (userStatus == 'denied') {
          await _authService.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta ha sido denegada por el administrador.';
          });
          return;
        }
      }

      // Si todas las validaciones pasan, navegar a Home
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (!await NetworkUtils.isNetworkAvailable()) {
      setState(() {
        _errorMessage = NetworkUtils.errorNoInternet;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Verificar si el email está verificado
      final isVerified = await _authService.isEmailVerified();
      final userEmail = _authService.currentUser?.email ?? '';
      
      // El administrador no necesita verificación de email
      if (userEmail != 'martin.bautista.sanchez@gmail.com' && !isVerified) {
        await _authService.signOut();
        setState(() {
          _errorMessage = 'Debes verificar tu email antes de acceder. Revisa tu bandeja de entrada.';
          _isLoading = false;
        });
        
        // Mostrar opciones para reenviar o verificar
        if (mounted) {
          _showEmailVerificationDialog();
        }
        return;
      }

      // Verificar si el usuario existe en Firestore y su estado
      final userStatus = await _authService.getUserStatus();
      
      // Si el usuario no existe en Firestore (se borró), cerrar sesión
      if (userStatus == null) {
        await _authService.signOut();
        setState(() {
          _errorMessage = 'Usuario no encontrado. Por favor, regístrate nuevamente.';
          _isLoading = false;
        });
        return;
      }
      
      if (userEmail != 'martin.bautista.sanchez@gmail.com') {
        if (userStatus == 'pending') {
          await _authService.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta está pendiente de aprobación por el administrador.';
            _isLoading = false;
          });
          return;
        }
        
        if (userStatus == 'denied') {
          await _authService.signOut();
          setState(() {
            _errorMessage = 'Tu cuenta ha sido denegada por el administrador.';
            _isLoading = false;
          });
          return;
        }
      }

      // Guardar email si el usuario lo quiere recordar
      await _saveEmail(_emailController.text.trim());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de login: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        _errorMessage = 'Introduce tu email para recuperar la contraseña';
      });
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      setState(() {
        _errorMessage = 'Introduce un email válido';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Hemos enviado un correo para restablecer tu contraseña. Revisa tu bandeja de entrada.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = switch (e.code) {
            'invalid-email' => 'El email no es válido',
            'user-not-found' => 'No existe una cuenta con ese email',
            'too-many-requests' =>
              'Demasiadas solicitudes. Inténtalo de nuevo más tarde.',
            _ => 'No se pudo enviar el correo de recuperación',
          };
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No se pudo enviar el correo de recuperación';
        });
      }
    }
  }
  String _getErrorMessage(String code) {
    const errorMessages = {
      'user-not-found': 'No existe usuario con este email',
      'wrong-password': 'Contraseña incorrecta',
      'invalid-email': 'Email inválido',
      'user-disabled': 'Usuario deshabilitado',
    };
    return errorMessages[code] ?? 'Error de autenticación: $code';
  }

  void _showEmailVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Email no verificado'),
        content: const Text('Debes verificar tu email para acceder a la aplicación.'),
        actions: [
          TextButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              
                            // Intentar reenviar email de verificación
              try {
                await _authService.signInWithEmailAndPassword(email, password);
                await _authService.sendEmailVerification();
                await _authService.signOut();

                if (!context.mounted) return;

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email de verificación reenviado. Revisa tu bandeja de entrada.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al reenviar email: '),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Reenviar email'),
          ),
          TextButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();

              // Intentar verificar email
              try {
                await _authService.signInWithEmailAndPassword(email, password);
                final isVerified = await _authService.isEmailVerified();

                if (isVerified) {
                  await _authService.signOut();

                  if (!context.mounted) return;

                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email verificado. Tu cuenta está pendiente de aprobación por el administrador.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  await _authService.signOut();

                  if (!context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email aún no verificado. Por favor, revisa tu bandeja de entrada.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (!context.mounted) return;

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error al verificar email: '),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Verificar de nuevo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue,
              AppTheme.backgroundDark,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentGreen.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/images/fondo.png',
                            height: 200,
                            width: 250,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'PADEL NAVALES',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppTheme.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Inicia sesión para reservar tu pista',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                         selectAllOnFocus: false,
                        autofillHints: const [AutofillHints.email],
                        enableSuggestions: true,
                        autocorrect: false,
                        enableIMEPersonalizedLearning: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es requerido';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Email inválido';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        enableSuggestions: true,
                        autocorrect: false,
                        enableIMEPersonalizedLearning: false,
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es requerida';
                          }
                          return null;
                        },
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _isLoading ? null : _forgotPassword,
                          child: const Text(
                            '¿Has olvidado tu contraseña?',
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberEmail,
                            onChanged: _isLoading ? null : (value) {
                              setState(() {
                                _rememberEmail = value ?? false;
                              });
                            },
                            activeColor: AppTheme.accentGreen,
                          ),
                          const Text(
                            'Recordar email',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.errorRed),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.errorRed),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Iniciar Sesión'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                        child: const Text('¿No tienes cuenta? Regístrate'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}


