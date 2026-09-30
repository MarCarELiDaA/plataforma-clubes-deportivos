import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/club/actividad.dart';
import '../models/club/instalacion.dart';
import '../services/auth_service.dart';
import '../services/reserva_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import 'confirmation_screen.dart';
import 'my_reservations_screen.dart';

class ReservaScreen extends StatefulWidget {
  final Actividad? actividad;

  const ReservaScreen({super.key, this.actividad});

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final _authService = AuthService();
  final _reservaService = ReservaService();

  DateTime? _selectedDate;
  List<String> _availableTimes = [];
  List<String> _reservedTimes = [];
  List<Instalacion> _instalaciones = [];
  Instalacion? _instalacionActual;

  bool _isLoading = false;

  StreamSubscription<List<String>>? _reservedTimesSubscription;

  Color get _identity => AppTheme.identity;
  Color get _identityLight => AppTheme.identityLight;
  Color get _background => AppTheme.pageBackground;
  Color get _surface => AppTheme.surfaceColor;
  Color get _surfaceSoft => AppTheme.surfaceSoftColor;
  Color get _textPrimary => AppTheme.textPrimaryColor;
  Color get _textSecondary => AppTheme.textSecondaryColor;
  Color get _textTertiary => AppTheme.textTertiaryColor;
  Color get _borderSoft => AppTheme.borderSoftColor;
  Color get _textOnIdentity => AppTheme.textOnIdentity;
  Color get _action => AppTheme.action;

  Color get _activityAccent {
    final value =
        '${widget.actividad?.id ?? ''} ${widget.actividad?.tipo ?? ''} ${widget.actividad?.nombre ?? ''}'
            .toLowerCase();

    if (value.contains('padel') || value.contains('pádel')) {
      return const Color(0xFF19B8C8);
    }

    if (value.contains('tenis') || value.contains('tennis')) {
      return const Color(0xFF65B741);
    }

    if (value.contains('gimnasio') ||
        value.contains('gym') ||
        value.contains('fitness')) {
      return const Color(0xFFFFA726);
    }

    return _identity;
  }

  String _instalacionImage(Instalacion instalacion) {
    final instalacionImage = instalacion.imagen?.trim();

    if (instalacionImage != null && instalacionImage.isNotEmpty) {
      return instalacionImage;
    }

    final actividadImage = widget.actividad?.imagen?.trim();

    if (actividadImage != null && actividadImage.isNotEmpty) {
      return actividadImage;
    }

    return 'assets/images/banner_padel.jpeg';
  }

  String get _selectedImage {
    final instalacion = _instalacionActual;

    if (instalacion != null) {
      return _instalacionImage(instalacion);
    }

    final actividadImage = widget.actividad?.imagen?.trim();

    if (actividadImage != null && actividadImage.isNotEmpty) {
      return actividadImage;
    }

    return 'assets/images/banner_padel.jpeg';
  }

  @override
  void initState() {
    super.initState();
    _loadInstalacionConfig();
  }

  @override
  void dispose() {
    _reservedTimesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInstalacionConfig() async {
    final instalaciones =
        (widget.actividad != null
                ? widget.actividad!.instalacionesActivas
                : AppConfig.club.instalaciones.where(
                    (instalacion) => instalacion.activa,
                  ))
            .toList();

    if (!mounted) return;

    setState(() {
      _instalaciones = instalaciones;

      if (instalaciones.isEmpty) {
        _instalacionActual = null;
        _availableTimes = [];
      } else {
        _instalacionActual = instalaciones.first;
        _availableTimes = instalaciones.first.horarios;
      }

      _reservedTimes = [];
      _selectedDate = null;
    });
  }

  Future<void> _selectInstalacion(Instalacion instalacion) async {
    if (_instalacionActual?.id == instalacion.id) return;

    _reservedTimesSubscription?.cancel();

    if (!mounted) return;

    setState(() {
      _instalacionActual = instalacion;
      _availableTimes = instalacion.horarios;
      _reservedTimes = [];
      _selectedDate = null;
      _isLoading = false;
    });
  }

  Future<void> _selectDate() async {
    final instalacion = _instalacionActual;

    if (instalacion == null) return;

    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(Duration(days: instalacion.maxDiasAntelacion)),
      builder: (context, child) {
        final baseTheme = Theme.of(context);

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: _identity,
              onPrimary: _textOnIdentity,
              secondary: _identity,
              onSecondary: _textOnIdentity,
              surface: _surface,
              onSurface: _textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: _identity,
                textStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: _surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: _identity,
              headerForegroundColor: _textOnIdentity,
              todayForegroundColor: WidgetStatePropertyAll(_identity),
              todayBackgroundColor: WidgetStatePropertyAll(_identityLight),
              dayForegroundColor: WidgetStatePropertyAll(_textPrimary),
              dayOverlayColor: WidgetStatePropertyAll(
                _identity.withValues(alpha: 0.08),
              ),
              yearForegroundColor: WidgetStatePropertyAll(_textPrimary),
              yearOverlayColor: WidgetStatePropertyAll(
                _identity.withValues(alpha: 0.08),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedDate = picked;
        _reservedTimes = [];
      });

      _loadReservedTimes(picked);
    }
  }

  void _loadReservedTimes(DateTime date) {
    final instalacion = _instalacionActual;

    if (instalacion == null) return;

    _reservedTimesSubscription?.cancel();

    final dateFormat =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    setState(() {
      _isLoading = true;
    });

    _reservedTimesSubscription = _reservaService
        .getHorariosReservadosStream(instalacion.id, dateFormat)
        .listen(
          (reservedTimes) {
            if (!mounted) return;

            setState(() {
              _reservedTimes = reservedTimes;
              _isLoading = false;
            });
          },
          onError: (_) {
            if (!mounted) return;

            setState(() {
              _isLoading = false;
            });
          },
        );
  }

  bool _isTimePast(String time) {
    if (_selectedDate == null) return false;

    final now = DateTime.now();

    final selectedDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );

    final timeParts = time.split(':');

    final selectedTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    return now.isAfter(selectedTime);
  }

  Future<void> _selectTime(String time) async {
    final instalacion = _instalacionActual;

    if (_selectedDate == null || instalacion == null) return;

    final user = _authService.currentUser;

    if (user != null) {
      final dateFormat =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      try {
        final puedeReservar = await _reservaService.cumpleLimiteReservasPorDia(
          user.uid,
          dateFormat,
          instalacion,
        );

        if (!puedeReservar) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ya tienes dos reservas para este día'),
                backgroundColor: AppTheme.error,
              ),
            );
          }

          return;
        }

        final noEsConsecutiva = await _reservaService
            .noEsConsecutivaConReservasExistentes(
              user.uid,
              dateFormat,
              time,
              instalacion,
            );

        if (!noEsConsecutiva) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No puedes reservar horarios consecutivos. '
                  'Debe existir un bloque de 1 hora y 30 minutos '
                  'entre tus reservas.',
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }

          return;
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Error al verificar disponibilidad. '
                'Inténtalo de nuevo.',
              ),
              backgroundColor: AppTheme.error,
            ),
          );
        }

        return;
      }
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ConfirmationScreen(
          selectedDate: _selectedDate!,
          selectedTime: time,
          actividadId: widget.actividad?.id,
          instalacionId: instalacion.id,
          instalacionName: instalacion.nombre,
          duration: instalacion.duracionReservaMinutos,
        ),
      ),
    );
  }

  IconData get _actividadIcon {
    switch (widget.actividad?.icono) {
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'sports_tennis':
      default:
        return Icons.sports_tennis_rounded;
    }
  }

  Widget _buildInstalacionCard({
    required Instalacion instalacion,
    required double width,
    required bool isWeb,
  }) {
    final selected = _instalacionActual?.id == instalacion.id;
    final accent = _activityAccent;

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectInstalacion(instalacion),
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: isWeb ? 210 : 190,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: selected ? accent : _borderSoft,
                width: selected ? 3 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.24),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : AppTheme.softShadow,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _instalacionImage(instalacion),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: _surfaceSoft,
                      alignment: Alignment.center,
                      child: Icon(
                        _actividadIcon,
                        size: 52,
                        color: _textTertiary,
                      ),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.24),
                        Colors.black.withValues(alpha: 0.84),
                      ],
                      stops: const [0.0, 0.42, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: 13,
                  right: 13,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? accent
                          : Colors.black.withValues(alpha: 0.46),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.28),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.touch_app_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          selected ? 'SELECCIONADA' : 'ELEGIR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 15,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        instalacion.nombre,
                        softWrap: true,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          height: 1.1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 7,
                        runSpacing: 6,
                        children: [
                          _buildImageBadge(
                            icon: Icons.schedule_rounded,
                            text: '${instalacion.duracionReservaMinutos} min',
                          ),
                          _buildImageBadge(
                            icon: Icons.calendar_month_rounded,
                            text: '${instalacion.maxDiasAntelacion} días',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 13),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstalacionSelector(bool isWeb) {
    if (_instalaciones.isEmpty) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        const spacing = 14.0;

        int columns;
        if (availableWidth >= 900 && _instalaciones.length >= 3) {
          columns = 3;
        } else if (availableWidth >= 620 && _instalaciones.length >= 2) {
          columns = 2;
        } else {
          columns = 1;
        }

        final cardWidth = columns == 1
            ? availableWidth
            : (availableWidth - spacing * (columns - 1)) / columns;

        if (columns == 1 && _instalaciones.length > 1) {
          final mobileCardWidth = (availableWidth * 0.84).clamp(250.0, 340.0);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elige instalación o actividad',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Desliza para ver todas las opciones disponibles.',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 190,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 4),
                  itemCount: _instalaciones.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: spacing),
                  itemBuilder: (context, index) {
                    return _buildInstalacionCard(
                      instalacion: _instalaciones[index],
                      width: mobileCardWidth,
                      isWeb: false,
                    );
                  },
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_instalaciones.length > 1) ...[
              Text(
                'Elige instalación o actividad',
                style: TextStyle(
                  color: _textPrimary,
                  fontSize: isWeb ? 20 : 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecciona dónde quieres realizar tu reserva.',
                style: TextStyle(color: _textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final instalacion in _instalaciones)
                  _buildInstalacionCard(
                    instalacion: instalacion,
                    width: cardWidth,
                    isWeb: isWeb,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeGrid(bool isWeb) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        int columns;
        if (width >= 850) {
          columns = 4;
        } else if (width >= 560) {
          columns = 3;
        } else if (width >= 340) {
          columns = 2;
        } else {
          columns = 1;
        }

        const spacing = 10.0;
        final cardWidth = (width - spacing * (columns - 1)) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final time in _availableTimes)
              _buildTimeCard(time: time, width: cardWidth, isWeb: isWeb),
          ],
        );
      },
    );
  }

  Widget _buildTimeCard({
    required String time,
    required double width,
    required bool isWeb,
  }) {
    final isReserved = _reservedTimes.contains(time);
    final isPast = _isTimePast(time);
    final isAvailable = !isReserved && !isPast;

    final statusColor = isAvailable
        ? const Color(0xFF27AE60)
        : isReserved
        ? const Color(0xFFE74C3C)
        : const Color(0xFF7F8C8D);

    final statusText = isAvailable
        ? 'LIBRE'
        : isReserved
        ? 'RESERVADO'
        : 'PASADA';

    final statusIcon = isAvailable
        ? Icons.check_circle_rounded
        : isReserved
        ? Icons.lock_rounded
        : Icons.history_rounded;

    return SizedBox(
      width: width,
      height: isWeb ? 116 : 108,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAvailable ? () => _selectTime(time) : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: statusColor.withValues(alpha: isAvailable ? 0.70 : 0.58),
                width: isAvailable ? 1.7 : 1.2,
              ),
              boxShadow: isAvailable ? AppTheme.softShadow : const [],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _selectedImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: _surfaceSoft);
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: isPast
                        ? const Color(0xFF455A64).withValues(alpha: 0.66)
                        : Colors.black.withValues(alpha: 0.52),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 28, 8, 8),
                    child: Text(
                      time,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: isPast ? 0.76 : 1,
                        ),
                        fontSize: isWeb ? 23 : 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        shadows: const [
                          Shadow(blurRadius: 8, color: Colors.black54),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    final hasInstallations = _instalaciones.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 40 : 24,
        vertical: isWeb ? 42 : 34,
      ),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _borderSoft),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isWeb ? 76 : 68,
            height: isWeb ? 76 : 68,
            decoration: BoxDecoration(
              color: _surfaceSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _actividadIcon,
              size: isWeb ? 38 : 34,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            hasInstallations
                ? 'Selecciona una fecha'
                : 'No hay instalaciones disponibles',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            hasInstallations
                ? 'Elige un día para consultar los horarios disponibles.'
                : 'Actualmente no hay instalaciones activas para reservar.',
            style: TextStyle(
              fontSize: isWeb ? 15 : 14,
              height: 1.45,
              color: _textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final isWeb = width >= 800;
        final isSmall = width < 400;

        final maxContentWidth = isWeb ? 1050.0 : 700.0;

        final horizontalPadding = isWeb
            ? 24.0
            : isSmall
            ? 12.0
            : 16.0;

        final verticalPadding = isWeb ? 20.0 : 16.0;

        return Scaffold(
          backgroundColor: _background,
          drawer: const AppDrawer(),
          appBar: AppBar(
            automaticallyImplyLeading: false,
            leading: Builder(
              builder: (context) => IconButton(
                tooltip: 'Menú',
                icon: Icon(Icons.menu_rounded, color: _textPrimary, size: 27),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              widget.actividad == null
                  ? 'Reservar pista'
                  : 'Reservar ${widget.actividad!.nombre}',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            backgroundColor: _surface,
            foregroundColor: _textPrimary,
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    verticalPadding,
                    horizontalPadding,
                    24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInstalacionSelector(isWeb),
                      const SizedBox(height: 14),
                      Container(
                        padding: EdgeInsets.all(isWeb ? 18 : 16),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _borderSoft),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _activityAccent.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.calendar_month_rounded,
                                    color: _activityAccent,
                                    size: 19,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Elige la fecha',
                                    style: TextStyle(
                                      fontSize: isWeb ? 17 : 16,
                                      fontWeight: FontWeight.w800,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: isSmall ? 48 : 50,
                              child: ElevatedButton.icon(
                                onPressed: _instalacionActual == null
                                    ? null
                                    : _selectDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _surfaceSoft,
                                  foregroundColor: _textPrimary,
                                  disabledBackgroundColor: _surfaceSoft,
                                  disabledForegroundColor: _textTertiary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: Icon(
                                  Icons.calendar_today_outlined,
                                  size: 19,
                                  color: _activityAccent,
                                ),
                                label: Text(
                                  _selectedDate == null
                                      ? 'Seleccionar fecha'
                                      : 'Cambiar fecha',
                                ),
                              ),
                            ),
                            if (_selectedDate != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: _surfaceSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.event_available_rounded,
                                      size: 18,
                                      color: _textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedDate!.day}/'
                                      '${_selectedDate!.month}/'
                                      '${_selectedDate!.year}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedDate != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                'Horarios disponibles',
                                style: TextStyle(
                                  fontSize: isWeb ? 18 : 17,
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: _action.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.circle, size: 7, color: _action),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Disponible',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _action,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 50),
                            child: Center(
                              child: CircularProgressIndicator(color: _action),
                            ),
                          )
                        else ...[
                          _buildTimeGrid(isWeb),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MyReservationsScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.event_note_rounded,
                                size: 20,
                              ),
                              label: const Text('Mis reservas'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _action,
                                side: BorderSide(
                                  color: _action.withValues(alpha: 0.45),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ] else
                        _buildEmptyState(isWeb),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
