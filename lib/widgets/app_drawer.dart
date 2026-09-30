import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../screens/admin_screen.dart';
import '../screens/info_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_reservations_screen.dart';
import '../screens/profile_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();

  String _userRole = 'user';
  bool _loadingRole = true;

  Color get _accent => AppTheme.primary;
  Color get _surface => AppTheme.clubSurface;
  Color get _surfaceSoft => AppTheme.clubSurfaceSoft;
  Color get _textPrimary => AppTheme.clubTextPrimary;
  Color get _textSecondary => AppTheme.clubTextSecondary;

  bool get _reservasActivas => AppConfig.club.moduloActivo('reservations');

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final role = await _authService.getUserRole();

      if (!mounted) return;

      setState(() {
        _userRole = role ?? 'user';
        _loadingRole = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _userRole = 'user';
        _loadingRole = false;
      });
    }
  }

  void _closeDrawer() {
    Navigator.of(context).pop();
  }

  void _openScreen(Widget screen) {
    _closeDrawer();

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  void _openProfile() {
    _openScreen(const ProfileScreen());
  }

  void _openMisReservas() {
    if (!_reservasActivas) return;

    _openScreen(const MyReservationsScreen());
  }

  void _openInfo() {
    _openScreen(InfoScreen());
  }

  void _openAdmin() {
    _openScreen(const AdminScreen());
  }

  Future<void> _logout() async {
    _closeDrawer();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Cerrar sesión',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text('Cancelar', style: TextStyle(color: _textSecondary)),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    await _authService.signOut();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _clubLogo({double size = 54}) {
    if (AppConfig.club.logo.isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(Icons.sports_rounded, color: _accent, size: size * 0.55),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        AppConfig.club.logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(size * 0.28),
            ),
            child: Icon(
              Icons.sports_rounded,
              color: _accent,
              size: size * 0.55,
            ),
          );
        },
      ),
    );
  }

  Widget _drawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 7),
      child: Text(
        title,
        style: TextStyle(
          color: _accent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, color: _textSecondary),
      title: Text(
        title,
        style: TextStyle(
          color: _textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    final userName = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!
        : user?.email ?? 'Usuario';

    return Drawer(
      backgroundColor: _surface,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: _surfaceSoft,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _accent.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _clubLogo(),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Text(
                          AppConfig.club.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            height: 1.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppConfig.club.deporte,
                    style: TextStyle(color: _textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                children: [
                  _drawerSection('CUENTA'),
                  _drawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Mi perfil',
                    onTap: _openProfile,
                  ),
                  if (_reservasActivas) ...[
                    const SizedBox(height: 14),
                    _drawerSection('RESERVAS'),
                    _drawerItem(
                      icon: Icons.event_available_rounded,
                      title: 'Mis reservas',
                      onTap: _openMisReservas,
                    ),
                  ],
                  const SizedBox(height: 14),
                  _drawerSection('CLUB'),
                  _drawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Información del club',
                    onTap: _openInfo,
                  ),
                  if (!_loadingRole && _userRole == 'admin') ...[
                    const SizedBox(height: 14),
                    _drawerSection('ADMINISTRACIÓN'),
                    _drawerItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Panel de administración',
                      onTap: _openAdmin,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: Icon(Icons.logout_rounded, color: AppTheme.error),
                title: Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: AppTheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: _logout,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
