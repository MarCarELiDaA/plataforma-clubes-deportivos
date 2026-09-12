import 'package:flutter/material.dart';
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
        final reservas = await _reservaService.getReservasUsuarioConId(user.uid).timeout(
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

  List<Map<String, dynamic>> _filterAndSortReservas(List<Map<String, dynamic>> reservas) {
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
              backgroundColor: AppTheme.primaryBlue,
              title: const Text('No se puede cancelar', style: TextStyle(color: Colors.white)),
              content: const Text(
                'No puedes cancelar esta reserva porque falta menos de 1 hora para su inicio.',
                style: TextStyle(color: Colors.white),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK', style: TextStyle(color: Colors.white)),
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
          backgroundColor: AppTheme.primaryBlue,
          title: const Text('Cancelar Reserva', style: TextStyle(color: Colors.white)),
          content: const Text(
            '¿Deseas cancelar esta reserva?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.destructiveRed,
              ),
              child: const Text('Sí, cancelar'),
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
              const SnackBar(
                content: Text('Reserva cancelada exitosamente'),
                backgroundColor: Colors.green,
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
                backgroundColor: Colors.red,
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
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.white)),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?', style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.destructiveRed,
            ),
            child: const Text('Cerrar Sesión'),
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
            SnackBar(content: Text('Error al cerrar sesión: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('PADEL NAVALES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined, color: Colors.grey),
            onPressed: _logout,
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
        child: Column(
          children: [
            // Logo
            Image.asset(
              'assets/images/fondo.png',
              height: screenHeight * 0.12,
              fit: BoxFit.contain,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _reservas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryBlue,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.accentGreen.withValues(alpha: 0.3),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.asset(
                                    'assets/images/fondo.png',
                                    height: screenHeight * 0.2,
                                    width: screenWidth * 0.5,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.03),
                              Text(
                                'No tienes reservas',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.05,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: screenHeight * 0.01),
                              Text(
                                'Reserva tu primera pista en Navales Padel Club',
                                style: TextStyle(
                                  fontSize: screenWidth * 0.035,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadReservas,
                          child: ListView.builder(
                            padding: EdgeInsets.all(screenWidth * 0.04),
                            itemCount: _reservas.length,
                            itemBuilder: (context, index) {
                              final reserva = _reservas[index];
                              return _buildReservationCard(reserva);
                            },
                          ),
                        ),
            ),
          ],
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
      
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 4,
        color: AppTheme.cardBackground,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        color: AppTheme.accentGreen,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        fechaFormateada,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.accentWhite,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: estado
                          ? AppTheme.accentGreen
                          : AppTheme.accentYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          estado ? Icons.check_circle : Icons.cancel,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          estado
                              ? 'CONFIRMADA'
                              : 'CANCELADA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.access_time, 'Hora:', reserva['horaInicio']),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.sports_tennis, 'Pista:', reserva['pistaId']),
              const SizedBox(height: 8),
              _buildDetailRow(Icons.timer, 'Duración:', '${reserva['duracionMinutos']} minutos'),
              const SizedBox(height: 16),
              if (estado)
                OutlinedButton.icon(
                  onPressed: () => _cancelReservation(reserva),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancelar Reserva'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.accentYellow,
                    side: const BorderSide(color: AppTheme.accentYellow),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      return const SizedBox.shrink();
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentGreen, size: 20),
        const SizedBox(width: 12),
        Text(
          '$label ',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.accentWhite,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: AppTheme.accentWhite,
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