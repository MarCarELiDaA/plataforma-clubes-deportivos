import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/reserva_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> {
  final _authService = AuthService();
  final _reservaService = ReservaService();
  final _notificationService = NotificationService();

  List<Map<String, dynamic>> _reservas = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadReservas();
  }

  Future<void> _loadReservas() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final reservas =
            await _reservaService.getReservasUsuarioConId(user.uid).timeout(
          const Duration(seconds: 5),
          onTimeout: () => [],
        );

        if (mounted) {
          setState(() {
            _reservas = _filterAndSortReservas(reservas);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _filterAndSortReservas(
    List<Map<String, dynamic>> reservas,
  ) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd');
    final timeFormat = DateFormat('HH:mm');

    // Filtrar solo reservas confirmadas y que no estén en el pasado
    final filtered = reservas.where((reserva) {
      try {
        // Solo mostrar reservas confirmadas
        if (reserva['estadoReserva'] != 'CONFIRMADA') {
          return false;
        }

        final fecha = dateFormat.parse(reserva['fecha']);
        final hora = timeFormat.parse(reserva['horaInicio']);
        final fechaHora = DateTime(
          fecha.year,
          fecha.month,
          fecha.day,
          hora.hour,
          hora.minute,
        );

        // No mostrar reservas que ya pasaron
        return fechaHora.isAfter(now);
      } catch (e) {
        return false;
      }
    }).toList();

    // Ordenar por fecha más cercana
    filtered.sort((a, b) {
      try {
        final fechaA = dateFormat.parse(a['fecha']);
        final horaA = timeFormat.parse(a['horaInicio']);
        final fechaHoraA = DateTime(
          fechaA.year,
          fechaA.month,
          fechaA.day,
          horaA.hour,
          horaA.minute,
        );

        final fechaB = dateFormat.parse(b['fecha']);
        final horaB = timeFormat.parse(b['horaInicio']);
        final fechaHoraB = DateTime(
          fechaB.year,
          fechaB.month,
          fechaB.day,
          horaB.hour,
          horaB.minute,
        );

        return fechaHoraA.compareTo(fechaHoraB);
      } catch (e) {
        return 0;
      }
    });

    return filtered;
  }

  Future<void> _cancelReservation(Map<String, dynamic> reserva) async {
    try {
      // Validar política de cancelación (mínimo 1 hora de antelación)
      final puedeCancelar = _reservaService.puedeCancelarReserva(
        reserva['fecha'],
        reserva['horaInicio'],
      );

      if (!puedeCancelar) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: AppTheme.surface,
              title: const Text(
                'No se puede cancelar',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              content: const Text(
                'No puedes cancelar esta reserva porque falta menos de 1 hora para su inicio.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }

      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text(
            'Cancelar reserva',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: const Text(
            '¿Deseas cancelar esta reserva?',
            style: TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'No',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.error,
              ),
              child: const Text(
                'Sí, cancelar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirm == true) {
        setState(() {
          _isLoading = true;
        });

        try {
          await _reservaService.cancelarReserva(reserva['id']);

          // Cancelar el recordatorio asociado
          await _notificationService.cancelReminder(reserva['id']);

          // Mostrar notificación de cancelación
          await _notificationService.showCancellationNotification();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Reserva cancelada exitosamente'),
                backgroundColor: AppTheme.primary,
              ),
            );
            await _loadReservas();
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cancelar reserva: ${e.toString()}'),
                backgroundColor: AppTheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cancelar reserva: ${e.toString()}'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          '¿Estás seguro de que quieres cerrar sesión?',
          style: TextStyle(
            color: AppTheme.textSecondary,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
            ),
            child: const Text(
              'Cerrar sesión',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cerrar sesión: ${e.toString()}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth >= 800;
        final maxContentWidth = isWeb ? 1050.0 : double.infinity;
        final horizontalPadding = isWeb ? 24.0 : 16.0;
        final verticalPadding = isWeb ? 20.0 : 16.0;

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              AppConfig.club.nombre,
              style: TextStyle(
                fontSize: isWeb ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Cerrar sesión',
                icon: const Icon(
                  Icons.logout_outlined,
                  color: AppTheme.textSecondary,
                ),
                onPressed: _logout,
              ),
              SizedBox(width: isWeb ? 12 : 4),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxContentWidth,
                ),
                child: RefreshIndicator(
                  onRefresh: _loadReservas,
                  color: AppTheme.primary,
                  backgroundColor: AppTheme.surface,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: constraints.maxHeight - 120,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            ),
                          )
                        : _reservas.isEmpty
                            ? _buildEmptyState(isWeb)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeaderCard(isWeb),
                                  const SizedBox(height: 18),
                                  ..._reservas.map(
                                    (reserva) =>
                                        _buildReservationCard(reserva),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                              ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderCard(bool isWeb) {
    return Container(
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
            width: isWeb ? 54 : 50,
            height: isWeb ? 54 : 50,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.event_available_rounded,
              color: AppTheme.primary,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis reservas',
                  style: TextStyle(
                    fontSize: isWeb ? 21 : 19,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _reservas.length == 1
                      ? 'Tienes 1 reserva confirmada'
                      : 'Tienes ${_reservas.length} reservas confirmadas',
                  style: TextStyle(
                    fontSize: isWeb ? 14 : 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 15,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  'Activas',
                  style: TextStyle(
                    fontSize: isWeb ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isWeb) {
    return SizedBox(
      height: 560,
      child: Center(
        child: Container(
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
                width: isWeb ? 84 : 76,
                height: isWeb ? 84 : 76,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: isWeb ? 42 : 38,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No tienes reservas',
                style: TextStyle(
                  fontSize: isWeb ? 21 : 19,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Reserva tu primera instalación para verla aquí.',
                style: TextStyle(
                  fontSize: isWeb ? 15 : 14,
                  height: 1.45,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reserva) {
    final dateFormat = DateFormat('yyyy-MM-dd');

    try {
      final fecha = dateFormat.parse(reserva['fecha']);
      final fechaFormateada = DateFormat('dd/MM/yyyy').format(fecha);
      final estado = reserva['estadoReserva'] == 'CONFIRMADA';

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppTheme.borderSoft,
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reserva',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          fechaFormateada,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: estado
                          ? AppTheme.primaryLight
                          : AppTheme.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          estado
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          color: estado
                              ? AppTheme.primary
                              : AppTheme.textTertiary,
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          estado ? 'CONFIRMADA' : 'CANCELADA',
                          style: TextStyle(
                            color: estado
                                ? AppTheme.primary
                                : AppTheme.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.background,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppTheme.borderSoft,
                  ),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.access_time_rounded,
                      'Hora',
                      reserva['horaInicio'],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.sports_tennis_rounded,
                      'Instalación',
                      _getInstalacionNombre(reserva['instalacionId']),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                      Icons.timer_outlined,
                      'Duración',
                      '${reserva['duracionMinutos']} minutos',
                    ),
                  ],
                ),
              ),
              if (estado) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _cancelReservation(reserva),
                    icon: const Icon(
                      Icons.cancel_outlined,
                      size: 19,
                    ),
                    label: const Text(
                      'Cancelar reserva',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(
                        color: AppTheme.error.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  String _getInstalacionNombre(String instalacionId) {
    for (final instalacion in AppConfig.club.instalaciones) {
      if (instalacion.id == instalacionId) {
        return instalacion.nombre;
      }
    }

    return instalacionId;
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppTheme.primary,
          size: 19,
        ),
        const SizedBox(width: 11),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

extension ListExtension<T> on List<T> {
  (List<T>, List<T>) partition(bool Function(T) predicate) {
    final first = <T>[];
    final second = <T>[];

    for (final element in this) {
      if (predicate(element)) {
        first.add(element);
      } else {
        second.add(element);
      }
    }

    return (first, second);
  }
}


