import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/usuario.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _nivelPadelController = TextEditingController();

  Usuario? _usuario;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _authService.currentUser;

    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _usuario = Usuario.fromMap(doc.data()!);

          final telefono = _usuario?.telefono ?? '';
          final nivelPadel = _usuario?.nivelPadel?.toString() ?? '';

          _telefonoController.value = TextEditingValue(
            text: telefono,
            selection: TextSelection.collapsed(
              offset: telefono.length,
            ),
          );

          _nivelPadelController.value = TextEditingValue(
            text: nivelPadel,
            selection: TextSelection.collapsed(
              offset: nivelPadel.length,
            ),
          );

          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfileData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final telefono = _telefonoController.text.trim();
    final nivelPadelStr = _nivelPadelController.text.trim();

    double? nivelPadel;

    if (nivelPadelStr.isNotEmpty) {
      final nivel = double.tryParse(nivelPadelStr);

      if (nivel == null || nivel < 1.0 || nivel > 7.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'El nivel debe estar entre 1.0 y 7.0',
              ),
              backgroundColor: AppTheme.destructiveRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      nivelPadel = nivel;
    }

    final Map<String, dynamic> data = {};

    if (telefono.isNotEmpty) {
      data['telefono'] = telefono;
    } else {
      data['telefono'] = null;
    }

    if (nivelPadelStr.isNotEmpty) {
      data['nivelPadel'] = nivelPadel;
    } else {
      data['nivelPadel'] = null;
    }

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No hay cambios para guardar',
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      await _authService.updateUserData(
        user.uid,
        data,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Datos actualizados correctamente',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al guardar datos: ${e.toString()}',
            ),
            backgroundColor: AppTheme.destructiveRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Todos los campos son requeridos';
      });
      return;
    }

    if (_newPasswordController.text !=
        _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas nuevas no coinciden';
      });
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(
        credential,
      );

      await user.updatePassword(
        _newPasswordController.text,
      );

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Contraseña cambiada exitosamente',
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error al cambiar contraseña';

      if (e.code == 'wrong-password') {
        message = 'La contraseña actual es incorrecta';
      } else if (e.code == 'weak-password') {
        message = 'La nueva contraseña es muy débil';
      }

      if (mounted) {
        setState(() {
          _errorMessage = message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error: ${e.toString()}';
        });
      }
    }
  }

  void _showChangePasswordDialog() {
    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();

    setState(() {
      _errorMessage = null;
    });

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          surfaceTintColor: Colors.transparent,
          title: const Text(
            'Cambiar contraseña',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.borderSoft,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.success,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_reset_rounded,
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.borderSoft,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.success,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.borderSoft,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.success,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.destructiveRed
                          .withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.destructiveRed
                            .withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: AppTheme.destructiveRed,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            20,
            0,
            20,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: _changePassword,
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.success,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cambiar'),
            ),
          ],
        );
      },
    );
  }

  String? _getNivelValue() {
    final nivel = double.tryParse(
      _nivelPadelController.text,
    );

    if (nivel == null) return null;

    if (nivel == 1.0) return '1.0';
    if (nivel == 3.25) return '3.25';
    if (nivel == 3.50) return '3.50';
    if (nivel == 3.75) return '3.75';
    if (nivel == 4.00) return '4.00';
    if (nivel == 4.25) return '4.25';
    if (nivel == 4.50) return '4.50';
    if (nivel == 4.75) return '4.75';
    if (nivel == 5.00) return '5.00';
    if (nivel > 5.00) return '5.01';

    return null;
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _telefonoController.dispose();
    _nivelPadelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text('Mi perfil'),
          backgroundColor: AppTheme.surface,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: AppTheme.success,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Mi perfil'),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1050,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      _buildProfileHeader(),
                      const SizedBox(height: 20),
                      _buildInfoCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Nombre',
                        content: _usuario?.nombre ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.email_outlined,
                        title: 'Email',
                        content: _usuario?.email ?? '',
                      ),
                      const SizedBox(height: 12),
                      _buildEditableInfoCard(
                        icon: Icons.phone_outlined,
                        title: 'Teléfono',
                        controller: _telefonoController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(9),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildLevelCard(),
                      const SizedBox(height: 12),
                      _buildInfoCard(
                        icon: Icons.calendar_today_outlined,
                        title: 'Fecha de registro',
                        content: _usuario?.fechaRegistro != null
                            ? '${_usuario!.fechaRegistro!.day}/'
                                '${_usuario!.fechaRegistro!.month}/'
                                '${_usuario!.fechaRegistro!.year}'
                            : 'No especificado',
                      ),
                      const SizedBox(height: 20),
                      _buildPasswordCard(),
                      const SizedBox(height: 24),
                      Align(
                        alignment: isWide
                            ? Alignment.centerRight
                            : Alignment.center,
                        child: FilledButton.icon(
                          onPressed: _saveProfileData,
                          icon: const Icon(
                            Icons.save_outlined,
                            size: 19,
                          ),
                          label: const Text(
                            'Guardar cambios',
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppTheme.success,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 13,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.success.withValues(alpha: 0.25),
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 40,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _usuario?.nombre ?? 'Mi perfil',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _usuario?.email ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIconContainer(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  content.isEmpty
                      ? 'No especificado'
                      : content,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableInfoCard({
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required TextInputType keyboardType,
    required List<TextInputFormatter> inputFormatters,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconContainer(icon),
              const SizedBox(width: 14),
              const Text(
                'Teléfono',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              hintText: 'Introduce tu teléfono',
              filled: true,
              fillColor: AppTheme.background,
              prefixIcon: const Icon(
                Icons.phone_outlined,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.borderSoft,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.success,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildIconContainer(
                Icons.sports_tennis_rounded,
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nivel de pádel',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Indica tu nivel actual',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _getNivelValue(),
            decoration: InputDecoration(
              labelText: 'Nivel',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.borderSoft,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppTheme.success,
                  width: 1.5,
                ),
              ),
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
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _nivelPadelController.text = value;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: _buildIconContainer(
          Icons.lock_outline_rounded,
        ),
        title: const Text(
          'Cambiar contraseña',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: const Text(
          'Actualiza tu contraseña de acceso',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppTheme.textSecondary,
        ),
        onTap: _showChangePasswordDialog,
      ),
    );
  }

  Widget _buildIconContainer(IconData icon) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.successLight,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(
        icon,
        color: AppTheme.success,
        size: 21,
      ),
    );
  }
}