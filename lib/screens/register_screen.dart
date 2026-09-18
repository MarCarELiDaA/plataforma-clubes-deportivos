import 'package:flutter/material.dart';
import '../config/app_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/network_utils.dart';
import '../theme/app_theme.dart';
import '../config/legal_config.dart';
import 'login_screen.dart';
import 'privacy_screen.dart';
import 'terms_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // Aceptaciones legales
  bool _aceptaCondiciones = false;
  bool _aceptaPrivacidad = false;

  // Indica si el usuario ha abierto y aceptado cada documento.
  bool _haAceptadoCondiciones = false;
  bool _haAceptadoPrivacidad = false;

  String? _nivelPadel;

  final List<String> _nivelesPadel = [
    'Iniciación',
    'Medio',
    'Avanzado',
    'Competición',
  ];

  Color get _primary => AppTheme.primary;
  Color get _background => AppTheme.clubBackground;
  Color get _surface => AppTheme.clubSurface;
  Color get _textPrimary => AppTheme.clubTextPrimary;
  Color get _textSecondary => AppTheme.clubTextSecondary;
  Color get _textTertiary => AppTheme.clubTextTertiary;
  Color get _border => AppTheme.clubBorder;
  Color get _textOnPrimary => AppTheme.textOnPrimary;

  Future<void> _openTerms() async {
    if (_isLoading) return;

    final accepted = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (context) => const TermsScreen()));

    if (!mounted) return;

    if (accepted == true) {
      setState(() {
        _haAceptadoCondiciones = true;
        _aceptaCondiciones = true;
        _errorMessage = null;
      });
    }
  }

  Future<void> _openPrivacy() async {
    if (_isLoading) return;

    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const PrivacyScreen()),
    );

    if (!mounted) return;

    if (accepted == true) {
      setState(() {
        _haAceptadoPrivacidad = true;
        _aceptaPrivacidad = true;
        _errorMessage = null;
      });
    }
  }

  Future<bool> _checkEmailExistsInFirestore(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _register() async {
    // Validaciones de aceptaciones obligatorias
    if (!_aceptaCondiciones || !_aceptaPrivacidad) {
      setState(() {
        _errorMessage =
            'Debes leer y aceptar las Condiciones de Uso y la Política de Privacidad.';
      });
      return;
    }

    // Validar el resto del formulario después de las aceptaciones
    if (!_formKey.currentState!.validate()) return;

    final hasConnection = await NetworkUtils.isNetworkAvailable();

    if (!hasConnection) {
      setState(() {
        _errorMessage =
            'No hay conexión a Internet. Comprueba tu conexión e inténtalo de nuevo.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    User? createdUser;

    try {
      final emailExists = await _checkEmailExistsInFirestore(email);

      if (emailExists) {
        setState(() {
          _errorMessage = 'Ya existe una cuenta con este correo electrónico.';
          _isLoading = false;
        });
        return;
      }

      final credential = await _authService.createUserWithEmailAndPassword(
        email,
        _passwordController.text,
      );

      createdUser = credential.user;

      if (createdUser == null) {
        throw Exception('No se pudo crear el usuario.');
      }

      await _authService.saveUserData(
        createdUser.uid,
        _nameController.text.trim(),
        email,
        _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        _nivelPadel == null ? null : double.tryParse(_nivelPadel!),
        aceptaCondiciones: _aceptaCondiciones,
        aceptaPrivacidad: _aceptaPrivacidad,
        versionCondiciones: LegalConfig.versionCondiciones,
        versionPrivacidad: LegalConfig.versionPrivacidad,
      );

      await createdUser.sendEmailVerification();

      await FirebaseAuth.instance.signOut();

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada correctamente. Revisa tu correo para verificarla.',
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message = 'Ya existe una cuenta con este correo electrónico.';
          break;
        case 'invalid-email':
          message = 'El correo electrónico no es válido.';
          break;
        case 'weak-password':
          message = 'La contraseña es demasiado débil.';
          break;
        case 'network-request-failed':
          message =
              'No hay conexión a Internet. Comprueba tu conexión e inténtalo de nuevo.';
          break;
        default:
          message = 'No se pudo crear la cuenta. Inténtalo de nuevo.';
      }

      if (!mounted) return;

      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
    } catch (_) {
      if (createdUser != null) {
        try {
          await createdUser.delete();
        } catch (_) {}
      }

      if (!mounted) return;

      setState(() {
        _errorMessage = 'No se pudo crear la cuenta. Inténtalo de nuevo.';
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: _surface,
      labelStyle: TextStyle(color: _textSecondary, fontSize: 14),
      hintStyle: TextStyle(color: _textTertiary, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildCheckboxSection(
    String label,
    bool value,
    Function(bool?)? onChanged, {
    VoidCallback? onTap,
    bool enabled = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: _isLoading || !enabled ? null : onChanged,
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              TextButton(
                onPressed: _isLoading ? null : onTap,
                style: TextButton.styleFrom(
                  foregroundColor: _primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Leer',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        activeColor: _primary,
        checkColor: _textOnPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Crear cuenta',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth >= 700 ? 32.0 : 20.0;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                24,
                horizontalPadding,
                32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.035),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Crea tu cuenta',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Completa tus datos para comenzar.',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 28),

                              // NOMBRE Y APELLIDOS
                              TextFormField(
                                controller: _nameController,
                                enabled: !_isLoading,
                                textCapitalization: TextCapitalization.words,
                                decoration: _inputDecoration(
                                  label: 'Nombre y apellidos',
                                  icon: Icons.person_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Introduce tu nombre y apellidos';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // EMAIL
                              TextFormField(
                                controller: _emailController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.emailAddress,
                                decoration: _inputDecoration(
                                  label: 'Correo electrónico',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Introduce tu correo electrónico';
                                  }

                                  final emailRegex = RegExp(
                                    r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                  );

                                  if (!emailRegex.hasMatch(value.trim())) {
                                    return 'Introduce un correo válido';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // CONTRASEÑA
                              TextFormField(
                                controller: _passwordController,
                                enabled: !_isLoading,
                                obscureText: true,
                                decoration: _inputDecoration(
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Introduce una contraseña';
                                  }

                                  if (value.length < 6) {
                                    return 'La contraseña debe tener al menos 6 caracteres';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // CONFIRMAR CONTRASEÑA
                              TextFormField(
                                controller: _confirmPasswordController,
                                enabled: !_isLoading,
                                obscureText: true,
                                decoration: _inputDecoration(
                                  label: 'Confirmar contraseña',
                                  icon: Icons.lock_outline,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Confirma tu contraseña';
                                  }

                                  if (value != _passwordController.text) {
                                    return 'Las contraseñas no coinciden';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // TELÉFONO
                              TextFormField(
                                controller: _phoneController,
                                enabled: !_isLoading,
                                keyboardType: TextInputType.phone,
                                decoration: _inputDecoration(
                                  label: 'Teléfono (opcional)',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return null;
                                  }

                                  final phone = value.trim();

                                  if (!RegExp(r'^\d{9}$').hasMatch(phone)) {
                                    return 'El teléfono debe tener 9 dígitos';
                                  }

                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              if (AppConfig.club.moduloActivo(
                                'padelLevel',
                              )) ...[
                                // NIVEL DE PÁDEL
                                DropdownButtonFormField<String>(
                                  initialValue: _nivelPadel,
                                  decoration: _inputDecoration(
                                    label: 'Nivel de pádel',
                                    icon: Icons.sports_tennis,
                                  ),
                                  items: _nivelesPadel.map((nivel) {
                                    return DropdownMenuItem<String>(
                                      value: nivel,
                                      child: Text(
                                        nivel,
                                        style: TextStyle(color: _textPrimary),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _isLoading
                                      ? null
                                      : (value) {
                                          setState(() {
                                            _nivelPadel = value;
                                            _errorMessage = null;
                                          });
                                        },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Selecciona tu nivel de pádel';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 24),
                              ],

                              // ACEPTACIÓN LEGAL
                              Text(
                                'Información legal',
                                style: TextStyle(
                                  color: _textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              const SizedBox(height: 10),

                              _buildCheckboxSection(
                                'He leído y acepto las Condiciones de Uso',
                                _aceptaCondiciones,
                                _haAceptadoCondiciones
                                    ? (value) {
                                        setState(() {
                                          _aceptaCondiciones = value ?? false;
                                          _errorMessage = null;
                                        });
                                      }
                                    : null,
                                onTap: _openTerms,
                                enabled: _haAceptadoCondiciones,
                              ),

                              const SizedBox(height: 10),

                              _buildCheckboxSection(
                                'He leído y acepto la Política de Privacidad',
                                _aceptaPrivacidad,
                                _haAceptadoPrivacidad
                                    ? (value) {
                                        setState(() {
                                          _aceptaPrivacidad = value ?? false;
                                          _errorMessage = null;
                                        });
                                      }
                                    : null,
                                onTap: _openPrivacy,
                                enabled: _haAceptadoPrivacidad,
                              ),

                              const SizedBox(height: 10),

                              Text(
                                'Para continuar, abre cada documento, léelo y pulsa «Acepto» al final.',
                                style: TextStyle(
                                  color: _textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),

                              if (_errorMessage != null) ...[
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.error.withValues(
                                      alpha: 0.06,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppTheme.error.withValues(
                                        alpha: 0.20,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        color: AppTheme.error,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: const TextStyle(
                                            color: Color(0xFFB42318),
                                            fontSize: 13,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              SizedBox(
                                height: 54,
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: _textOnPrimary,
                                    disabledBackgroundColor: _primary
                                        .withValues(alpha: 0.5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: _textOnPrimary,
                                          ),
                                        )
                                      : Text(
                                          'Crear cuenta',
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

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '¿Ya tienes cuenta?',
                              style: TextStyle(
                                color: _textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            TextButton(
                              onPressed: _isLoading
                                  ? null
                                  : () {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const LoginScreen(),
                                        ),
                                      );
                                    },
                              child: Text(
                                'Inicia sesión',
                                style: TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        Center(
                          child: Text(
                            AppConfig.club.nombre,
                            style: TextStyle(
                              color: _textTertiary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
