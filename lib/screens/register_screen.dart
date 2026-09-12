import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../utils/network_utils.dart';
import '../theme/app_theme.dart';
import '../config/legal_config.dart';
import 'login_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _nivelPadelController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;

  // Aceptaciones legales
  bool _aceptaCondiciones = false;
  bool _aceptaPrivacidad = false;

  Future<void> _register() async {
    // Validaciones de aceptaciones obligatorias
    if (!_aceptaCondiciones) {
      setState(() {
        _errorMessage = 'Debes leer las Condiciones de Uso hasta el final antes de aceptarlas';

      });
      return;
    }

    if (!_aceptaPrivacidad) {
      setState(() {
        _errorMessage = 'Debes leer la Política de Privacidad hasta el final antes de aceptarla';
      });


      return;
    }

    // Validar el resto del formulario después de las aceptaciones
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
      final email = _emailController.text.trim();

      // Primero verificar si el email ya existe en Firestore
      final emailExistsInFirestore =
          await _checkEmailExistsInFirestore(email);

      if (emailExistsInFirestore) {
        if (mounted) {
          setState(() {
            _errorMessage =
                'Ya existe una cuenta con este email en el sistema.';
            _isLoading = false;
          });
        }
        return;
      }

      // Crear usuario en Firebase Auth
      final userCredential =
          await _authService.createUserWithEmailAndPassword(
        email,
        _passwordController.text.trim(),
      );

      final userId = userCredential.user?.uid;

      if (userId != null) {
        try {
          await _authService.saveUserData(
            userId,
            _nombreController.text.trim(),
            email,
            _telefonoController.text.trim().isEmpty
                ? null
                : _telefonoController.text.trim(),
            _nivelPadelController.text.trim().isEmpty
                ? null
                : double.tryParse(_nivelPadelController.text.trim()),
            aceptaCondiciones: _aceptaCondiciones,
            aceptaPrivacidad: _aceptaPrivacidad,
            versionCondiciones: LegalConfig.versionCondiciones,
            versionPrivacidad: LegalConfig.versionPrivacidad,
          );

          // Enviar email de verificación
          try {
            await _authService.sendEmailVerification();
          } catch (emailError) {
            // Error silenciado para producción
          }

          // Cerrar sesión después del registro
          await _authService.signOut();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Tu cuenta ha sido creada. Revisa tu email para verificarla. Después de verificar, aparecerá pendiente de aprobación.',
                ),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 8),
              ),
            );
          }
        } catch (firestoreError) {
          // Si falla Firestore, eliminar el usuario de Firebase Auth
          // Error silenciado para producción

          await _authService.currentUser?.delete();
          await _authService.signOut();

          if (mounted) {
            setState(() {
              _errorMessage =
                  'Error al guardar datos del usuario. Por favor, intenta de nuevo.';
              _isLoading = false;
            });
          }

          return;
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        final email = _emailController.text.trim();

        final emailExistsInFirestore =
            await _checkEmailExistsInFirestore(email);

        if (!emailExistsInFirestore) {
          if (mounted) {
            setState(() {
              _errorMessage =
                  'Este email estaba registrado pero fue eliminado. Contacta al administrador para que lo elimine completamente del sistema.';
              _isLoading = false;
            });
          }

          return;
        }
      }

      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error al crear cuenta: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkEmailExistsInFirestore(String email) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('usuarios')
          .where('email', isEqualTo: email)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      // Error silenciado para producción
      return false;
    }
  }

  String _getErrorMessage(String code) {
    const errorMessages = {
      'email-already-in-use': 'Ya existe una cuenta con este email',
      'invalid-email': 'Email inválido',
      'weak-password': 'La contraseña es muy débil',
    };

    return errorMessages[code] ?? 'Error de registro: $code';
  }

  Widget _buildCheckboxSection(
    String label,
    bool value,
    Function(bool?)? onChanged, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: _isLoading ? null : onChanged,
        title: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
            if (onTap != null)
              TextButton(
                onPressed: onTap,
                child: const Text(
                  'Ver documento',
                  style: TextStyle(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        activeColor: AppTheme.accentGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_outlined,
              color: Colors.red,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
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
                constraints: const BoxConstraints(
                  maxWidth: 400,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.person_add_outlined,
                        size: 80,
                        color: AppTheme.accentGreen,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Crear Cuenta',
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                              color: Colors.white,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Únete a nuestra comunidad de pádel y reserva tu pista de pádel en Navales',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              color: Colors.white70,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // NOMBRE
                      TextFormField(
                        controller: _nombreController,
                        decoration: const InputDecoration(
                          labelText: 'Nombre Completo',
                          prefixIcon: Icon(
                            Icons.person_outlined,
                          ),
                        ),
                        enableIMEPersonalizedLearning: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es requerido';
                          }

                          if (value.length < 3) {
                            return 'El nombre debe tener al menos 3 caracteres';
                          }

                          return null;
                        },
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // EMAIL
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.email,
                        ],
                        enableSuggestions: true,
                        enableIMEPersonalizedLearning: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El email es requerido';
                          }

                          if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Email inválido';
                          }

                          return null;
                        },
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // CONTRASEÑA
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                          ),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [
                          AutofillHints.newPassword,
                        ],
                        enableSuggestions: true,
                        enableIMEPersonalizedLearning: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'La contraseña es requerida';
                          }

                          if (value.length < 6) {
                            return 'La contraseña debe tener al menos 6 caracteres';
                          }

                          return null;
                        },
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                      // CONFIRMAR CONTRASEÑA
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirmar Contraseña',
                          prefixIcon: Icon(
                            Icons.lock_outlined,
                          ),
                        ),
                        obscureText: true,
                        textInputAction: TextInputAction.next,
                        enableSuggestions: true,
                        enableIMEPersonalizedLearning: false,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Debes confirmar la contraseña';
                          }

                          if (value != _passwordController.text) {
                            return 'Las contraseñas no coinciden';
                          }

                          return null;
                        },
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: 16),

                     // TELÉFONO
TextFormField(
  controller: _telefonoController,
  decoration: const InputDecoration(
    labelText: 'Teléfono (opcional)',
    prefixIcon: Icon(
      Icons.phone_outlined,
    ),
  ),
  keyboardType: TextInputType.phone,
  maxLength: 9,
  enableIMEPersonalizedLearning: false,
  validator: (value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^[0-9]{9}$').hasMatch(value)) {
        return 'El teléfono debe tener 9 dígitos';
      }
    }

    return null;
  },
  enabled: !_isLoading,
),
                      const SizedBox(height: 16),

                      // NIVEL DE PÁDEL
                      // NIVEL DE PÁDEL
                      DropdownButtonFormField<String>(
                        initialValue: _nivelPadelController.text.isEmpty
                            ? null
                            : _nivelPadelController.text,
                        decoration: const InputDecoration(
                          labelText: 'Nivel de Pádel',
                          prefixIcon: Icon(Icons.star_outline),
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '1.0',
                            child: Text('Iniciación'),
                          ),
                          DropdownMenuItem(
                            value: '3.25',
                            child: Text('3.25'),
                          ),
                          DropdownMenuItem(
                            value: '3.50',
                            child: Text('3.50'),
                          ),
                          DropdownMenuItem(
                            value: '3.75',
                            child: Text('3.75'),
                          ),
                          DropdownMenuItem(
                            value: '4.00',
                            child: Text('4.00'),
                          ),
                          DropdownMenuItem(
                            value: '4.25',
                            child: Text('4.25'),
                          ),
                          DropdownMenuItem(
                            value: '4.50',
                            child: Text('4.50'),
                          ),
                          DropdownMenuItem(
                            value: '4.75',
                            child: Text('4.75'),
                          ),
                          DropdownMenuItem(
                            value: '5.00',
                            child: Text('5.00'),
                          ),
                          DropdownMenuItem(
                            value: '5.01',
                            child: Text('Más de 5'),
                          ),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                _nivelPadelController.text = value ?? '';
                              },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // CONDICIONES DE USO
                      _buildCheckboxSection(
                        'He leído y acepto las Condiciones de Uso',
                        _aceptaCondiciones,
                        null, // Checkbox no interactivo - solo se marca desde TermsScreen
                        onTap: () async {
                          final aceptado = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => const TermsScreen(),
                            ),
                          );
                          if (aceptado == true && mounted) {
                            setState(() {
                              _aceptaCondiciones = true;
                              _errorMessage = null; // Limpiar error al aceptar
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 12),

                      // POLÍTICA DE PRIVACIDAD
                      _buildCheckboxSection(
                        'He leído y acepto la Política de Privacidad',
                        _aceptaPrivacidad,
                        null, // Checkbox no interactivo - solo se marca desde PrivacyScreen
                        onTap: () async {
                          final aceptado = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (context) => const PrivacyScreen(),
                            ),
                          );
                          if (aceptado == true && mounted) {
                            setState(() {
                              _aceptaPrivacidad = true;
                              _errorMessage = null; // Limpiar error al aceptar
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 24),

                      // ERROR
                      if (_errorMessage != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppTheme.errorRed,
                            ),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.errorRed,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // BOTÓN CREAR CUENTA
        ElevatedButton(
  onPressed: _isLoading ? null : _register,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.of(context).pop();
                              },
                        child: const Text(
                          '¿Ya tienes cuenta? Inicia sesión',
                        ),
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
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _nivelPadelController.dispose();
    super.dispose();
  }
}





