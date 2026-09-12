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
            selection: TextSelection.collapsed(offset: telefono.length),
          );

          _nivelPadelController.value = TextEditingValue(
            text: nivelPadel,
            selection: TextSelection.collapsed(offset: nivelPadel.length),
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfileData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final telefono = _telefonoController.text.trim();
    final nivelPadelStr = _nivelPadelController.text.trim();
    double? nivelPadel;

    // Validar nivel de pádel
    if (nivelPadelStr.isNotEmpty) {
      final nivel = double.tryParse(nivelPadelStr);
      if (nivel == null || nivel < 1.0 || nivel > 7.0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('El nivel debe estar entre 1.0 y 7.0'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      nivelPadel = nivel;
    }

    Map<String, dynamic> data = {};
    
    if (telefono.isNotEmpty) {
      data['telefono'] = telefono;
    }
    
    if (nivelPadelStr.isNotEmpty) {
      data['nivelPadel'] = nivelPadel;
    } else {
      data['nivelPadel'] = null;
    }

    if (data.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay cambios para guardar'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      await _authService.updateUserData(user.uid, data);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos actualizados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar datos: ${e.toString()}'),
            backgroundColor: Colors.red,
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

    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Las contraseñas nuevas no coinciden';
      });
      return;
    }

    final user = _authService.currentUser;
    if (user == null) return;

    try {
      // Reautenticar con la contraseña actual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );
      
      await user.reauthenticateWithCredential(credential);
      
      // Cambiar contraseña
      await user.updatePassword(_newPasswordController.text);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contraseña cambiada exitosamente'),
            backgroundColor: Colors.green,
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
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Cambiar Contraseña', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              decoration: const InputDecoration(
                labelText: 'Contraseña Actual',
                prefixIcon: Icon(Icons.lock),
                labelStyle: TextStyle(color: Colors.white70),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              decoration: const InputDecoration(
                labelText: 'Nueva Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                labelStyle: TextStyle(color: Colors.white70),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirmar Nueva Contraseña',
                prefixIcon: Icon(Icons.lock_outline),
                labelStyle: TextStyle(color: Colors.white70),
              ),
              obscureText: true,
              style: const TextStyle(color: Colors.white),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: _changePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
            ),
            child: const Text('Cambiar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mi Perfil'),
          backgroundColor: AppTheme.primaryBlue,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Icon(
                  Icons.person,
                  size: 80,
                  color: AppTheme.accentGreen,
                ),
                const SizedBox(height: 24),
                Text(
                  'Información del Perfil',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                _buildInfoSection(
                  icon: Icons.person,
                  title: 'Nombre',
                  content: _usuario?.nombre ?? '',
                  isEditable: false,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  icon: Icons.email,
                  title: 'Email',
                  content: _usuario?.email ?? '',
                  isEditable: false,
                ),
                const SizedBox(height: 16),
                _buildInfoSection(
                  icon: Icons.phone,
                  title: 'Teléfono',
                  content: _usuario?.telefono ?? 'No especificado',
                  isEditable: true,
                  controller: _telefonoController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                 DropdownButtonFormField<String>(
                   initialValue: (() {
                     final nivel = double.tryParse(_nivelPadelController.text);
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
                   })(),
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
                   onChanged: (value) {
                     if (value != null) {
                       _nivelPadelController.text = value;
                     }
                   },
                 ),
                 const SizedBox(height: 16),
                _buildInfoSection(
                  icon: Icons.calendar_today,
                  title: 'Fecha de Registro',
                  content: _usuario?.fechaRegistro != null
                      ? '${_usuario!.fechaRegistro!.day}/${_usuario!.fechaRegistro!.month}/${_usuario!.fechaRegistro!.year}'
                      : 'No especificado',
                  isEditable: false,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.lock, color: AppTheme.accentGreen),
                    title: const Text(
                      'Cambiar Contraseña',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white70),
                    onTap: _showChangePasswordDialog,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saveProfileData,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar Cambios'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    bool isEditable = false,
    TextEditingController? controller,
    TextInputType? keyboardType,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentGreen, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEditable && controller != null)
            TextField(
              controller: controller,
               keyboardType: keyboardType ?? TextInputType.text,
               enableIMEPersonalizedLearning: false,
               inputFormatters: keyboardType == TextInputType.phone
                   ? <TextInputFormatter>[
                       FilteringTextInputFormatter.digitsOnly,
                       LengthLimitingTextInputFormatter(9),
                     ]
                   : keyboardType == const TextInputType.numberWithOptions(decimal: true)
                       ? <TextInputFormatter>[
                           FilteringTextInputFormatter.allow(
                             RegExp(r'^\d*\.?\d{0,2}'),
                           ),
                         ]
                       : null,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelStyle: TextStyle(color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
            )
          else
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }
}

