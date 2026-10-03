import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/club/actividad.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'admin_screen.dart';
import 'info_screen.dart';
import 'login_screen.dart';
import 'my_reservations_screen.dart';
import 'profile_screen.dart';
import 'reserva_screen.dart';
import 'wallet_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final AuthService _authService = AuthService();

  String _userRole = 'user';

  bool get _esVisitante => _authService.currentUser == null;

  void _openLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  bool _redirectVisitanteToLogin() {
    if (!_esVisitante) return false;
    _openLogin();
    return true;
  }

  Color get _accent => AppTheme.primary;
  Color get _background => AppTheme.clubBackground;
  Color get _surface => AppTheme.clubSurface;
  Color get _surfaceSoft => AppTheme.clubSurfaceSoft;
  Color get _textPrimary => AppTheme.clubTextPrimary;
  Color get _textSecondary => AppTheme.clubTextSecondary;
  Color get _border => AppTheme.clubBorder;
  Color get _textOnAccent => AppTheme.textOnPrimary;

  bool get _reservasActivas => AppConfig.club.moduloActivo('reservations');

  List<Actividad> get _actividades {
    return AppConfig.club.actividades
        .where((actividad) => actividad.activa && actividad.reservasActivas)
        .toList();
  }

  IconData get _menuIcon {
    switch (AppConfig.club.menuIcon) {
      case 'menu':
        return Icons.menu;
      case 'menuOpen':
        return Icons.menu_open;
      case 'menuBook':
        return Icons.menu_book_outlined;
      case 'menuRounded':
      default:
        return Icons.menu_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkUserRole();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkUserExists();
    }
  }

  Future<void> _checkUserExists() async {
    final user = _authService.currentUser;

    if (user == null || !mounted) {
      return;
    }

    try {
      final userStatus = await _authService.getUserStatus();

      if (userStatus == null && mounted) {
        await _authService.signOut();

        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } catch (_) {}
  }

  Future<void> _checkUserRole() async {
    final role = await _authService.getUserRole();

    if (!mounted) return;

    setState(() {
      _userRole = role ?? 'user';
    });
  }

  void _openReserva(Actividad actividad) {
    if (!_reservasActivas) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReservaScreen(actividad: actividad),
      ),
    );
  }

  void _openMisReservas() {
    if (_redirectVisitanteToLogin()) return;
    if (!_reservasActivas) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const MyReservationsScreen()),
    );
  }

  void _openProfile() {
    if (_redirectVisitanteToLogin()) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  void _openWallet() {
    if (!AppConfig.club.moduloActivo('wallet')) return;
    if (_redirectVisitanteToLogin()) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const WalletScreen()),
    );
  }

  void _openInfo() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => InfoScreen()));
  }

  void _openAdmin() {
    if (_redirectVisitanteToLogin()) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AdminScreen()));
  }

  Future<void> _logout({bool fromDrawer = false}) async {
    if (_esVisitante) return;
    final navigator = Navigator.of(context, rootNavigator: true);
    final messenger = ScaffoldMessenger.of(context);
    if (fromDrawer) Navigator.of(context).pop();

    final confirm = await showDialog<bool>(
      context: navigator.context,
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

    if (confirm != true || !navigator.mounted) return;

    try {
      await _authService.signOut();
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
      MaterialPageRoute(builder: (context) => const HomeScreen()),
      (route) => false,
    );
  }

  IconData _activityIcon(String icono) {
    switch (icono) {
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'sports_tennis':
        return Icons.sports_tennis_rounded;
      case 'sports_soccer':
        return Icons.sports_soccer_rounded;
      case 'sports_basketball':
        return Icons.sports_basketball_rounded;
      case 'sports_volleyball':
        return Icons.sports_volleyball_rounded;
      case 'pool':
        return Icons.pool_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      default:
        return Icons.sports_rounded;
    }
  }

  Widget _clubLogo({double size = 42, bool clickable = false}) {
    Widget logo;

    if (AppConfig.club.logo.isEmpty) {
      logo = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Icon(Icons.sports_rounded, color: _accent, size: size * 0.55),
      );
    } else {
      logo = Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: _border.withValues(alpha: 0.7)),
        ),
        child: Image.asset(
          AppConfig.club.logo,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.sports_rounded, color: _accent);
          },
        ),
      );
    }

    if (!clickable) {
      return logo;
    }

    return Tooltip(
      message: 'Información del club',
      child: InkWell(
        onTap: _openInfo,
        borderRadius: BorderRadius.circular(size * 0.28),
        child: logo,
      ),
    );
  }

  Widget _buildPlatformBrand({required bool compact}) {
    if (compact) {
      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          style: TextStyle(color: _textSecondary, fontSize: 9, height: 1),
          children: [
            const TextSpan(text: 'powered by '),
            TextSpan(
              text: 'Yo Reservo',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'powered by',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 10,
              height: 1,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Yo Reservo',
            style: TextStyle(
              color: _accent,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
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
                      _clubLogo(size: 54),
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
                  Builder(
                    builder: (drawerContext) => _drawerItem(
                      icon: Icons.home_outlined,
                      title: 'Inicio',
                      onTap: () => Scaffold.of(drawerContext).closeDrawer(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (AppConfig.club.actividades.any((actividad) => actividad.activa)) ...[
                    _drawerSection('DEPORTES'),
                    for (final actividad in AppConfig.club.actividades.where(
                      (actividad) => actividad.activa,
                    ))
                      _drawerItem(
                        icon: null,
                        title: actividad.nombre,
                        onTap: () => _openReserva(actividad),
                      ),
                    const SizedBox(height: 14),
                  ],
                  if (_esVisitante) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _openLogin();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: _textOnAccent,
                        ),
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Iniciar sesión'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _drawerSection('CLUB'),
                    _drawerItem(
                      icon: Icons.info_outline_rounded,
                      title: 'Información del club',
                      onTap: _openInfo,
                    ),
                  ],
                  if (!_esVisitante) ...[
                    _drawerSection('CUENTA'),
                    _drawerItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Mi perfil',
                      onTap: _openProfile,
                    ),
                    if (AppConfig.club.moduloActivo('wallet'))
                      _drawerItem(
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Wallet',
                        onTap: () {
                          final navigator = Navigator.of(context);
                          navigator.pop();
                          _openWallet();
                        },
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
                    if (_userRole == 'admin') ...[
                      const SizedBox(height: 14),
                      _drawerSection('ADMINISTRACIÓN'),
                      _drawerItem(
                        icon: Icons.admin_panel_settings_outlined,
                        title: 'Panel de administración',
                        onTap: _openAdmin,
                      ),
                    ],
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
                  onTap: () => _logout(fromDrawer: true),
                ),
              ),
          ],
        ),
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
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  Widget _buildHeroImage() {
    final hero = AppConfig.club.hero.trim();

    if (hero.isEmpty) {
      return Container(
        color: AppTheme.primaryDark,
        alignment: Alignment.center,
        child: Icon(
          Icons.sports_rounded,
          color: Colors.white.withValues(alpha: 0.35),
          size: 70,
        ),
      );
    }

    return Image.asset(
      hero,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppTheme.primaryDark,
          alignment: Alignment.center,
          child: Icon(
            Icons.sports_rounded,
            color: Colors.white.withValues(alpha: 0.35),
            size: 70,
          ),
        );
      },
    );
  }

  Color _activityColor(Actividad actividad) {
    switch (actividad.id.toLowerCase()) {
      case 'padel':
        return AppTheme.action;
      case 'tenis':
        return AppTheme.accentColor;
      case 'gimnasio':
        return AppTheme.identity;
      default:
        return _accent;
    }
  }

  Widget _buildActivityMenuItem({
    required Actividad actividad,
    required double height,
    bool compact = false,
  }) {
    final iconSize = height < 55
        ? 34.0
        : compact
        ? 42.0
        : 44.0;

    final activityColor = _activityColor(actividad);
    final buttonColor = Color.alphaBlend(
      AppTheme.identity.withValues(alpha: 0.08),
      AppTheme.clubSurface,
    );
    final foregroundColor = AppTheme.textoSobreColor(buttonColor);

    return Material(
      color: buttonColor.withValues(alpha: 0.86),
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.30),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: activityColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _openReserva(actividad),
        borderRadius: BorderRadius.circular(16),
        hoverColor: foregroundColor.withValues(alpha: 0.10),
        focusColor: foregroundColor.withValues(alpha: 0.12),
        splashColor: foregroundColor.withValues(alpha: 0.18),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: height < 55 ? 10 : 13),
          child: Row(
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: activityColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _activityIcon(actividad.icono),
                  color: AppTheme.textoSobreColor(activityColor),
                  size: iconSize * 0.50,
                ),
              ),
              SizedBox(width: height < 55 ? 8 : 10),
              Expanded(
                child: Text(
                  actividad.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foregroundColor,
                    shadows: const [],
                    fontSize: height < 55 ? 13 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: foregroundColor,
                size: height < 55 ? 19 : 21,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopActivities() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = _actividades.length;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        const spacing = 8.0;
        final availableHeight = constraints.maxHeight - (spacing * (count - 1));

        final calculatedHeight = availableHeight / count;

        if (calculatedHeight >= 46) {
          final itemHeight = calculatedHeight.clamp(46.0, 66.0);

          return Column(
            children: [
              for (int index = 0; index < count; index++) ...[
                Expanded(
                  child: _buildActivityMenuItem(
                    actividad: _actividades[index],
                    height: itemHeight,
                  ),
                ),
                if (index < count - 1) const SizedBox(height: spacing),
              ],
            ],
          );
        }

        return Scrollbar(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            itemCount: count,
            separatorBuilder: (context, index) =>
                const SizedBox(height: spacing),
            itemBuilder: (context, index) {
              return _buildActivityMenuItem(
                actividad: _actividades[index],
                height: 50,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDesktopHero() {
    return Container(
      height: 370,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.identity, width: 2),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(shadows: [
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(-1, -1)),
        ]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            Row(
              children: [
                SizedBox(
                  width: 290,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Actividades',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Elige qué quieres reservar',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Expanded(child: _buildDesktopActivities()),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(34, 28, 34, 28),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 570),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.20),
                                ),
                              ),
                              child: const Text(
                                'TU CLUB, TUS RESERVAS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 11),
                            Text(
                              AppConfig.club.nombre,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Selecciona una actividad y gestiona tu reserva de forma rápida y sencilla.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 14,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileHero() {
    return Container(
      height: 335,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.identity, width: 2),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(shadows: [
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(-1, -1)),
        ]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildHeroImage(),
            Positioned(
              left: 18,
              right: 18,
              top: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.club.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      height: 1,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Elige una actividad para reservar',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              right: 0,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Actividades',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    height: 66,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 16),
                      itemCount: _actividades.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: 205,
                          child: _buildActivityMenuItem(
                            actividad: _actividades[index],
                            height: 66,
                            compact: true,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHero({required bool desktop}) {
    if (_actividades.isEmpty) {
      return Container(
        height: desktop ? 260 : 220,
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _border),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sports_rounded, color: _accent, size: 42),
            const SizedBox(height: 12),
            Text(
              'No hay actividades disponibles',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return desktop ? _buildDesktopHero() : _buildMobileHero();
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      softWrap: true,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      softWrap: true,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 11,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: _textSecondary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess({required bool desktop}) {
    final cards = <Widget>[
      if (_esVisitante)
        OutlinedButton.icon(
          onPressed: _openLogin,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.action,
            backgroundColor: _surface,
            padding: const EdgeInsets.all(15),
            side: BorderSide(
              color: AppTheme.action.withValues(alpha: 0.22),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          icon: const Icon(Icons.login_rounded),
          label: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Iniciar sesión'),
              Text(
                'Accede a tu cuenta para reservar.',
                style: TextStyle(color: _textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
      if (!_esVisitante) ...[
        if (_reservasActivas)
          _buildQuickCard(
            icon: Icons.calendar_month_rounded,
            title: 'Mis reservas',
            subtitle: 'Consulta y gestiona tus reservas.',
            color: AppTheme.action,
            onTap: _openMisReservas,
          ),
        _buildQuickCard(
          icon: Icons.info_outline_rounded,
          title: 'Información del club',
          subtitle: 'Horarios, normas y contacto.',
          color: AppTheme.accentColor,
          onTap: _openInfo,
        ),
        _buildQuickCard(
          icon: Icons.person_outline_rounded,
          title: 'Mi perfil',
          subtitle: 'Consulta y actualiza tus datos.',
          color: AppTheme.identity,
          onTap: _openProfile,
        ),
        if (_userRole == 'admin')
          _buildQuickCard(
            icon: Icons.settings_outlined,
            title: 'Administración',
            subtitle: 'Gestiona usuarios, reservas y club.',
            color: AppTheme.action,
            onTap: _openAdmin,
          ),
      ],
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;

        int columns;
        if (constraints.maxWidth >= 1120 && cards.length >= 4) {
          columns = 4;
        } else if (constraints.maxWidth >= 620 && cards.length >= 2) {
          columns = 2;
        } else {
          columns = 1;
        }

        columns = columns.clamp(1, cards.length);

        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: cardWidth, child: card),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menú',
              icon: Icon(_menuIcon, color: _textPrimary, size: 27),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        titleSpacing: 0,
        title: LayoutBuilder(
          builder: (context, constraints) {
            final compact = MediaQuery.sizeOf(context).width < 650;

            return Row(
              children: [
                _clubLogo(size: compact ? 36 : 40, clickable: true),
                const SizedBox(width: 10),
                Expanded(
                  child: compact
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConfig.club.nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: _textPrimary,
                                fontSize: 14,
                                height: 1.05,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 3),
                            _buildPlatformBrand(compact: true),
                          ],
                        )
                      : Text(
                          AppConfig.club.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                if (!compact) _buildPlatformBrand(compact: false),
              ],
            );
          },
        ),
        actions: [
          if (_esVisitante)
            TextButton(
              onPressed: _openLogin,
              child: Text(
                'Iniciar sesión',
                style: TextStyle(color: _textPrimary),
              ),
            ),
          if (!_esVisitante) ...[
            IconButton(
              tooltip: 'Mi perfil',
              icon: Icon(Icons.person_outline_rounded, color: _textPrimary),
              onPressed: _openProfile,
            ),
            IconButton(
              tooltip: 'Cerrar sesión',
              icon: Icon(Icons.logout_rounded, color: _textPrimary),
              onPressed: _logout,
            ),
          ],
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= 850;
            final horizontalPadding = desktop ? 24.0 : 14.0;

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1280),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    14,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(desktop: desktop),
                      const SizedBox(height: 18),
                      Text(
                        'Accesos rápidos',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: desktop ? 22 : 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildQuickAccess(desktop: desktop),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
