import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/club/actividad.dart';
import '../screens/admin_screen.dart';
import '../screens/home_screen.dart';
import '../screens/info_screen.dart';
import '../screens/login_screen.dart';
import '../screens/my_reservations_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/reserva_screen.dart';
import '../screens/wallet_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatefulWidget {
  final String? actividadActualId;

  const AppDrawer({super.key, this.actividadActualId});

  static void volverAtras(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  static Widget botonAtras(BuildContext context, {bool habilitado = true}) {
    return IconButton(
      tooltip: 'Atrás',
      icon: Icon(Icons.arrow_back_rounded, color: AppTheme.clubTextPrimary),
      onPressed: habilitado ? () => volverAtras(context) : null,
    );
  }

  static Widget menuConAtras(BuildContext context) {
    return Row(
      children: [
        botonAtras(context),
        Builder(
          builder: (drawerContext) => IconButton(
            tooltip: 'Menú',
            icon: Icon(Icons.menu_rounded,
                color: AppTheme.clubTextPrimary, size: 27),
            onPressed: () => Scaffold.of(drawerContext).openDrawer(),
          ),
        ),
      ],
    );
  }

  static Widget botonCerrarSesion(BuildContext context) {
    if (AuthService().currentUser == null) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: Icon(Icons.logout_rounded, color: AppTheme.clubTextPrimary),
      onPressed: () => cerrarSesion(context),
    );
  }

  static Future<void> cerrarSesion(
    BuildContext context, {
    bool cerrarDrawer = false,
  }) async {
    final authService = AuthService();
    if (authService.currentUser == null) return;
    final surface = AppTheme.clubSurface;
    final textPrimary = AppTheme.clubTextPrimary;
    final textSecondary = AppTheme.clubTextSecondary;
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    if (cerrarDrawer) Navigator.of(context).pop();

    final confirm = await showDialog<bool>(
      context: navigator.context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: surface,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Cerrar sesión',
            style: TextStyle(color: textPrimary, fontWeight: FontWeight.w700),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text('Cancelar', style: TextStyle(color: textSecondary)),
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

    if (confirm != true || !navigator.mounted) return;

    try {
      await authService.signOut();
    } catch (_) {
      if (messenger.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('No se pudo cerrar sesión. Inténtalo de nuevo.'),
          ),
        );
      }
      return;
    }

    if (!navigator.mounted) return;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const HomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();

  String _userRole = 'user';
  bool _loadingRole = true;

  bool get _esVisitante => _authService.currentUser == null;

  Color get _accent => AppTheme.primary;
  Color get _surface => AppTheme.clubSurface;
  Color get _surfaceSoft => AppTheme.clubSurfaceSoft;
  Color get _textPrimary => AppTheme.clubTextPrimary;
  Color get _textSecondary => AppTheme.clubTextSecondary;

  bool get _reservasActivas => AppConfig.club.moduloActivo('reservations');

  List<Actividad> get _actividades => AppConfig.club.actividades
      .where((actividad) => actividad.activa &&
          actividad.id != widget.actividadActualId)
      .toList();

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

  void _openHome() {
    final navigator = Navigator.of(context, rootNavigator: true);
    _closeDrawer();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  void _openScreen(Widget screen) {
    _closeDrawer();

    Navigator.of(context).push(MaterialPageRoute(builder: (context) => screen));
  }

  void _openProfile() {
    if (_esVisitante) {
      _openLogin();
      return;
    }
    _openScreen(const ProfileScreen());
  }

  void _openMisReservas() {
    if (_esVisitante) {
      _openLogin();
      return;
    }
    if (!_reservasActivas) return;

    _openScreen(const MyReservationsScreen());
  }

  void _openInfo() {
    _openScreen(InfoScreen());
  }

  void _openWallet() {
    if (!AppConfig.club.moduloActivo('wallet')) return;
    if (_esVisitante) {
      _openLogin();
      return;
    }
    final navigator = Navigator.of(context);
    _closeDrawer();
    navigator.push(MaterialPageRoute(builder: (context) => const WalletScreen()));
  }

  void _openActividad(Actividad actividad) {
    if (!_reservasActivas || !actividad.activa ||
        actividad.id == widget.actividadActualId) return;
    _openScreen(ReservaScreen(actividad: actividad));
  }

  void _openAdmin() {
    if (_esVisitante) {
      _openLogin();
      return;
    }
    _openScreen(const AdminScreen());
  }

  void _openLogin() {
    _openScreen(const LoginScreen());
  }

  Future<void> _logout() =>
      AppDrawer.cerrarSesion(context, cerrarDrawer: true);

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
    required IconData? icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: icon == null ? null : Icon(icon, color: _textSecondary),
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

    final userName = _esVisitante
        ? 'Visitante'
        : user?.displayName?.trim().isNotEmpty == true
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
                  _drawerItem(
                    icon: Icons.home_outlined,
                    title: 'Inicio',
                    onTap: _openHome,
                  ),
                  const SizedBox(height: 14),
                  if (_actividades.isNotEmpty) ...[
                    _drawerSection('DEPORTES'),
                    for (final actividad in _actividades)
                      _drawerItem(
                        icon: null,
                        title: actividad.nombre,
                        onTap: () => _openActividad(actividad),
                      ),
                    const SizedBox(height: 14),
                  ],
                  _drawerSection('CUENTA'),
                  if (_esVisitante)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: FilledButton.icon(
                        onPressed: _openLogin,
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: AppTheme.textOnPrimary,
                        ),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Iniciar sesión'),
                      ),
                    )
                  else
                    _drawerItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Mi perfil',
                      onTap: _openProfile,
                    ),
                  if (!_esVisitante && AppConfig.club.moduloActivo('wallet'))
                    _drawerItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Wallet',
                      onTap: _openWallet,
                    ),
                  if (!_esVisitante && _reservasActivas) ...[
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
                  if (!_esVisitante && !_loadingRole && _userRole == 'admin') ...[
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
            if (!_esVisitante)
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
