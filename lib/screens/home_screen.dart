
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../services/auth_service.dart';
import 'admin_screen.dart';
import 'info_screen.dart';
import 'login_screen.dart';
import 'my_reservations_screen.dart';
import 'profile_screen.dart';
import 'reserva_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();

  String _userRole = 'user';

  Color get _accent => const Color(0xFF16A36A);
  Color get _accentSoft => const Color(0xFFE8F7F0);
  Color get _background => const Color(0xFFF7F8FA);
  Color get _textPrimary => const Color(0xFF18221D);
  Color get _textSecondary => const Color(0xFF69746E);

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

    if (user != null && mounted) {
      try {
        final userStatus = await _authService.getUserStatus();

        if (userStatus == null && mounted) {
          await _authService.signOut();

          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              ),
            );
          }
        }
      } catch (_) {
        // Error silenciado para producción.
      }
    }
  }

  Future<void> _checkUserRole() async {
    final user = _authService.currentUser;

    if (user != null && mounted) {
      setState(() {
        _userRole =
            AppConfig.esAdministrador(user.email) ? 'admin' : 'user';
      });
    }
  }

  void _openReserva() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ReservaScreen(),
      ),
    );
  }

  void _openMisReservas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MyReservationsScreen(),
      ),
    );
  }

  void _openProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  void _openInfo() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => InfoScreen(),
      ),
    );
  }

  void _openAdmin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AdminScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            'Cerrar sesión',
            style: TextStyle(
              color: _textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            '¿Estás seguro de que quieres cerrar sesión?',
            style: TextStyle(
              color: _textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFD94B4B),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Cerrar sesión'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await _authService.signOut();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LoginScreen(),
          ),
        );
      }
    }
  }

  Widget _buildDrawer(BuildContext context) {
    final user = _authService.currentUser;

    final userName =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : user?.email ?? 'Usuario';

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FBF9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _accent.withValues(alpha: 0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.06),
                          ),
                        ),
                        child: AppConfig.club.logo.isNotEmpty
                            ? Image.asset(
                                AppConfig.club.logo,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                Icons.sports_tennis_rounded,
                                color: _accent,
                                size: 27,
                              ),
                      ),
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
                  const SizedBox(height: 17),
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
                    style: TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
                children: [
                  _drawerSection('CUENTA'),
                  _drawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Mi perfil',
                    onTap: _openProfile,
                  ),
                  const SizedBox(height: 16),
                  _drawerSection('RESERVAS'),
                  _drawerItem(
                    icon: Icons.calendar_month_rounded,
                    title: 'Reservar pista',
                    highlighted: true,
                    onTap: _openReserva,
                  ),
                  _drawerItem(
                    icon: Icons.event_available_rounded,
                    title: 'Mis reservas',
                    onTap: _openMisReservas,
                  ),
                  const SizedBox(height: 16),
                  _drawerSection('CLUB'),
                  _drawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Información del club',
                    onTap: _openInfo,
                  ),
                  if (_userRole == 'admin') ...[
                    const SizedBox(height: 16),
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
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFD94B4B),
                ),
                title: const Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: Color(0xFFD94B4B),
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
    bool highlighted = false,
  }) {
    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      tileColor: highlighted ? _accentSoft : Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 2,
      ),
      leading: Icon(
        icon,
        color: highlighted ? _accent : _textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: highlighted ? _textPrimary : _textSecondary,
          fontSize: 14,
          fontWeight: highlighted ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: highlighted
          ? Icon(
              Icons.chevron_right_rounded,
              color: _accent,
              size: 20,
            )
          : null,
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }

  Widget _buildHero({
    required double height,
    required double padding,
    required bool compact,
  }) {
    final hasImage = AppConfig.club.fondo.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          compact ? 26 : 30,
        ),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (hasImage)
            Image.asset(
              AppConfig.club.fondo,
              fit: BoxFit.cover,
            )
          else
            Container(
              color: const Color(0xFFF1F5F3),
            ),
          if (hasImage)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.96),
                    Colors.white.withValues(alpha: 0.84),
                    Colors.white.withValues(alpha: 0.18),
                  ],
                ),
              ),
            ),
          if (hasImage)
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.40),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(padding),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 620,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _accentSoft,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppConfig.club.deporte,
                            style: TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Bienvenido a',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: compact ? 16 : 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConfig.club.nombre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: compact ? 29 : 42,
                        height: 1.08,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Reserva tu pista de forma rápida y disfruta de tu club.',
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: compact ? 13 : 15,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _openReserva,
                        icon: const Icon(
                          Icons.calendar_month_rounded,
                          size: 20,
                        ),
                        label: const Text(
                          'Reservar pista',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(17),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool primary,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: primary
                  ? _accent.withValues(alpha: 0.14)
                  : Colors.black.withValues(alpha: 0.06),
            ),
            boxShadow: [
              BoxShadow(
                color: primary
                    ? _accent.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.045),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primary
                      ? _accentSoft
                      : const Color(0xFFF4F6F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: _accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _accent.withValues(alpha: 0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      drawer: _buildDrawer(context),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        leading: Builder(
          builder: (context) {
            return IconButton(
              tooltip: 'Menú',
              icon: Icon(
                Icons.menu_rounded,
                size: 27,
                color: _textPrimary,
              ),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            if (AppConfig.club.logo.isNotEmpty)
              Container(
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Image.asset(
                  AppConfig.club.logo,
                  fit: BoxFit.contain,
                ),
              ),
            if (AppConfig.club.logo.isNotEmpty)
              const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppConfig.club.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: Icon(
              Icons.logout_rounded,
              color: _textPrimary,
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;

            final contentWidth =
                constraints.maxWidth > 1280 ? 1280.0 : constraints.maxWidth;

            final horizontalPadding = isDesktop ? 24.0 : 16.0;

            final heroHeight = isDesktop ? 420.0 : 350.0;

            final heroPadding = isDesktop ? 42.0 : 24.0;

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    18,
                    horizontalPadding,
                    32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHero(
                        height: heroHeight,
                        padding: heroPadding,
                        compact: !isDesktop,
                      ),
                      const SizedBox(height: 28),
                      Text(
                        'Accesos rápidos',
                        style: TextStyle(
                          color: _textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 13),
                      LayoutBuilder(
                        builder: (context, quickConstraints) {
                          final twoColumns =
                              quickConstraints.maxWidth >= 700;

                          final cardWidth = twoColumns
                              ? (quickConstraints.maxWidth - 14) / 2
                              : quickConstraints.maxWidth;

                          return Wrap(
                            spacing: 14,
                            runSpacing: 14,
                            children: [
                              SizedBox(
                                width: cardWidth,
                                child: _buildQuickCard(
                                  icon: Icons.calendar_month_rounded,
                                  title: 'Reservar pista',
                                  subtitle:
                                      'Consulta horarios y disponibilidad.',
                                  primary: true,
                                  onTap: _openReserva,
                                ),
                              ),
                              SizedBox(
                                width: cardWidth,
                                child: _buildQuickCard(
                                  icon: Icons.event_available_rounded,
                                  title: 'Mis reservas',
                                  subtitle:
                                      'Consulta y gestiona tus reservas.',
                                  primary: false,
                                  onTap: _openMisReservas,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _buildQuickCard(
                        icon: Icons.info_outline_rounded,
                        title: 'Información del club',
                        subtitle:
                            'Dirección, instalaciones, horarios y normas.',
                        primary: false,
                        onTap: _openInfo,
                      ),
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
