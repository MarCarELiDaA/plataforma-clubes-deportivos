import 'dart:async';

import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../models/club/instalacion.dart';
import '../services/auth_service.dart';
import '../services/reserva_service.dart';
import '../theme/app_theme.dart';
import 'confirmation_screen.dart';

class ReservaScreen extends StatefulWidget {
  const ReservaScreen({super.key});

  @override
  State<ReservaScreen> createState() => _ReservaScreenState();
}

class _ReservaScreenState extends State<ReservaScreen> {
  final _authService = AuthService();
  final _reservaService = ReservaService();

  DateTime? _selectedDate;
  List<String> _availableTimes = [];
  List<String> _reservedTimes = [];
  bool _isLoading = false;

  Instalacion get _instalacionActual => AppConfig.club.instalaciones.first;

  StreamSubscription<List<String>>? _reservedTimesSubscription;

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
    final instalaciones = AppConfig.club.instalaciones;

    if (instalaciones.isEmpty) {
      if (!mounted) return;

      setState(() {
        _availableTimes = [];
      });

      return;
    }

    final instalacion = _instalacionActual;

    if (!mounted) return;

    setState(() {
      _availableTimes = instalacion.horarios;
    });
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 10),
      ),
      builder: (context, child) {
        final baseTheme = Theme.of(context);

        return Theme(
          data: baseTheme.copyWith(
            colorScheme: baseTheme.colorScheme.copyWith(
              primary: AppTheme.success,
              onPrimary: Colors.white,
              secondary: AppTheme.success,
              onSecondary: Colors.white,
              surface: AppTheme.surface,
              onSurface: AppTheme.textPrimary,
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: AppTheme.surface,
              surfaceTintColor: Colors.transparent,
              headerBackgroundColor: AppTheme.success,
              headerForegroundColor: Colors.white,
              todayForegroundColor:
                  WidgetStatePropertyAll(AppTheme.success),
              todayBackgroundColor:
                  WidgetStatePropertyAll(AppTheme.successLight),
              dayForegroundColor:
                  WidgetStatePropertyAll(AppTheme.textPrimary),
              dayOverlayColor:
                  WidgetStatePropertyAll(AppTheme.successLight),
              yearForegroundColor:
                  WidgetStatePropertyAll(AppTheme.textPrimary),
              yearOverlayColor:
                  WidgetStatePropertyAll(AppTheme.successLight),
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
    _reservedTimesSubscription?.cancel();

    final dateFormat =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    setState(() {
      _isLoading = true;
    });

    _reservedTimesSubscription = _reservaService
        .getHorariosReservadosStream(
          _instalacionActual.id,
          dateFormat,
        )
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
    if (_selectedDate == null) return;

    final user = _authService.currentUser;

    if (user != null) {
      final dateFormat =
          '${_selectedDate!.year}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}';

      try {
        final puedeReservar =
            await _reservaService.cumpleLimiteReservasPorDia(
          user.uid,
          dateFormat,
          _instalacionActual,
        );

        if (!puedeReservar) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Ya tienes dos reservas para este día',
                ),
                backgroundColor: AppTheme.error,
              ),
            );
          }

          return;
        }

        final noEsConsecutiva =
            await _reservaService.noEsConsecutivaConReservasExistentes(
          user.uid,
          dateFormat,
          time,
          _instalacionActual,
        );

        if (!noEsConsecutiva) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No puedes reservar horarios consecutivos. Debe existir un bloque de 1 hora y 30 minutos entre tus reservas.',
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
                'Error al verificar disponibilidad. Inténtalo de nuevo.',
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
          instalacionId: _instalacionActual.id,
          instalacionName: _instalacionActual.nombre,
          duration: _instalacionActual.duracionReservaMinutos,
        ),
      ),
    );
  }

  Widget _buildTimeGrid(bool isWeb) {
    final columns = isWeb ? 4 : 3;

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 4),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: isWeb ? 2.8 : 2.2,
        crossAxisSpacing: isWeb ? 12 : 8,
        mainAxisSpacing: isWeb ? 12 : 8,
      ),
      itemCount: _availableTimes.length,
      itemBuilder: (context, index) {
        final time = _availableTimes[index];
        final isReserved = _reservedTimes.contains(time);
        final isPast = _isTimePast(time);
        final isAvailable = !isReserved && !isPast;

        final backgroundColor = isAvailable
            ? AppTheme.surface
            : isReserved
                ? AppTheme.warning.withValues(alpha: 0.08)
                : AppTheme.surfaceMuted;

        final foregroundColor = isAvailable
            ? AppTheme.textPrimary
            : isReserved
                ? AppTheme.textPrimary
                : AppTheme.textTertiary;

        return Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isAvailable
                  ? AppTheme.borderSoft
                  : isReserved
                      ? AppTheme.warning.withValues(alpha: 0.35)
                      : AppTheme.border,
            ),
            boxShadow: isAvailable
                ? AppTheme.softShadow
                : [
                    const BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isAvailable
                  ? () => _selectTime(time)
                  : null,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isReserved
                          ? Icons.block_rounded
                          : isPast
                              ? Icons.history_rounded
                              : Icons.access_time_rounded,
                      color: isAvailable
                          ? AppTheme.success
                          : foregroundColor,
                      size: isWeb ? 19 : 20,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        isReserved
                            ? 'RESERVADO'
                            : isPast
                                ? 'PASADA'
                                : time,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: foregroundColor,
                          fontWeight: isAvailable
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: isWeb ? 13 : 14,
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
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? 40 : 24,
        vertical: isWeb ? 42 : 34,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: isWeb ? 76 : 68,
            height: isWeb ? 76 : 68,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sports_tennis_rounded,
              size: isWeb ? 38 : 34,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Selecciona una fecha',
            style: TextStyle(
              fontSize: isWeb ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Elige un día para consultar los horarios disponibles.',
            style: TextStyle(
              fontSize: isWeb ? 15 : 14,
              height: 1.45,
              color: AppTheme.textSecondary,
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
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              'Reservar pista',
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                ),
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
                      Container(
                        padding: EdgeInsets.all(
                          isWeb ? 22 : 18,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderSoft,
                          ),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: isWeb ? 52 : 48,
                              height: isWeb ? 52 : 48,
                              decoration: BoxDecoration(
                                color: AppTheme.successLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Icon(
                                Icons.sports_tennis_rounded,
                                color: AppTheme.success,
                                size: isWeb ? 27 : 25,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Instalación',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppTheme.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _instalacionActual.nombre,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: isWeb ? 20 : 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: EdgeInsets.all(
                          isWeb ? 18 : 16,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.borderSoft,
                          ),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Fecha',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: isSmall ? 48 : 50,
                              child: ElevatedButton.icon(
                                onPressed: _selectDate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.success,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 19,
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
                                  color: AppTheme.successLight,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.event_available_rounded,
                                      size: 18,
                                      color: AppTheme.success,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedDate!.day}/'
                                      '${_selectedDate!.month}/'
                                      '${_selectedDate!.year}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
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
                                  color: AppTheme.textPrimary,
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
                                color: AppTheme.successLight,
                                borderRadius:
                                    BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 7,
                                    color: AppTheme.success,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Disponible',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 50,
                            ),
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.success,
                              ),
                            ),
                          )
                        else
                          _buildTimeGrid(isWeb),
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