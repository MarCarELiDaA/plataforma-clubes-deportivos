import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/reserva_service.dart';
import '../services/notification_service.dart';
import '../utils/network_utils.dart';
import '../theme/app_theme.dart';

class ConfirmationScreen extends StatefulWidget {
  final DateTime selectedDate;
  final String selectedTime;
  final String pistaName;
  final int duration;

  const ConfirmationScreen({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.pistaName,
    required this.duration,
  });

  @override
  State<ConfirmationScreen> createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final _authService = AuthService();
  final _reservaService = ReservaService();
  final _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _isConfirmed = false;
  bool _isNavigating = false;

  String _calculateEndTime(String startTime, int durationMinutes) {
    final parts = startTime.split(':');
    final dateTime = DateTime(2024, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    final endTime = dateTime.add(Duration(minutes: durationMinutes));
    return '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmReservation() async {
    // Prevenir múltiples pulsaciones
    if (_isLoading || _isNavigating) {
      return;
    }

    if (!await NetworkUtils.isNetworkAvailable()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(NetworkUtils.errorNoInternet),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final userDoc = await _firestore.collection('usuarios').doc(user.uid).get();
      final userName = userDoc.data()?['nombre'] ?? user.email ?? 'Usuario';

      final dateFormat = '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

      final reservaData = {
        'usuarioId': user.uid,
        'nombreUsuario': userName,
        'pistaId': 'Pista Navales',
        'fecha': dateFormat,
        'horaInicio': widget.selectedTime,
        'duracionMinutos': widget.duration,
        'estadoReserva': 'CONFIRMADA',
        'fechaCreacionReserva': FieldValue.serverTimestamp(),
      };

      final reservaId = await _reservaService.crearReservaConVerificacion(reservaData);

      // Mostrar notificación de confirmación
      await _notificationService.showReservationConfirmation();

      // Programar recordatorio para 1 hora antes
      await _notificationService.scheduleReminder(
        reservaId,
        DateFormat('dd/MM/yyyy').format(widget.selectedDate),
        widget.selectedTime,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConfirmed = true;
          _isNavigating = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Reserva confirmada exitosamente!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navegar inmediatamente después de confirmar
        Navigator.of(context).pop();
        _isNavigating = false;
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al confirmar reserva: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _returnWithRefresh() {
    if (!_isNavigating) {
      Navigator.of(context).pop(true); // Return true to trigger refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    final endTime = _calculateEndTime(widget.selectedTime, widget.duration);
    final dateFormat = '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PADEL NAVALES'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
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
                    height: 100,
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isConfirmed ? '¡Reserva Confirmada!' : 'Confirmar Reserva',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isConfirmed 
                    ? 'Tu pista ha sido reservada exitosamente'
                    : 'Revisa los detalles de tu reserva',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 4,
                color: AppTheme.accentGreen,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow(Icons.sports_tennis, 'Pista:', widget.pistaName),
                      const Divider(color: Colors.white),
                      _buildDetailRow(Icons.calendar_today, 'Fecha:', dateFormat),
                      const Divider(color: Colors.white),
                      _buildDetailRow(Icons.access_time, 'Hora:', '${widget.selectedTime} - $endTime'),
                      const Divider(color: Colors.white),
                      _buildDetailRow(Icons.timer, 'Duración:', '${widget.duration} minutos'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_isConfirmed)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 24),
                      SizedBox(width: 12),
                      Text(
                        'Reserva Confirmada',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmReservation,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Confirmar Reserva'),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _isLoading ? null : _returnWithRefresh,
                child: const Text('Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.accentGreen, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.accentWhite,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: AppTheme.accentWhite,
            ),
          ),
        ],
      ),
    );
  }
}
