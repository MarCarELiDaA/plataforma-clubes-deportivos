import 'package:flutter/material.dart';
import '../config/app_config.dart';
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
  final String instalacionId;
  final String instalacionName;
  final int duration;

  const ConfirmationScreen({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.instalacionId,
    required this.instalacionName,
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
    final dateTime = DateTime(
      2024,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
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

      final userDoc =
          await _firestore.collection('usuarios').doc(user.uid).get();
      final userName = userDoc.data()?['nombre'] ?? user.email ?? 'Usuario';

      final dateFormat =
          '${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}';

      final reservaData = {
        'usuarioId': user.uid,
        'nombreUsuario': userName,
        'instalacionId': widget.instalacionId,
        'fecha': dateFormat,
        'horaInicio': widget.selectedTime,
        'duracionMinutos': widget.duration,
        'estadoReserva': 'CONFIRMADA',
        'fechaCreacionReserva': FieldValue.serverTimestamp(),
      };

      final reservaId = await _reservaService.crearReservaConVerificacion(
        reservaData,
        AppConfig.club.instalaciones.first,
      );

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
    final endTime = _calculateEndTime(
      widget.selectedTime,
      widget.duration,
    );

    final dateFormat =
        '${widget.selectedDate.day}/${widget.selectedDate.month}/${widget.selectedDate.year}';

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(AppConfig.club.nombre),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 20,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 900,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context, isWide),
                      const SizedBox(height: 28),
                      _buildReservationCard(
                        context,
                        dateFormat,
                        endTime,
                        isWide,
                      ),
                      const SizedBox(height: 24),
                      _buildActionSection(context, isWide),
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

  Widget _buildHeader(BuildContext context, bool isWide) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        );

    return Column(
      children: [
        Container(
          width: isWide ? 100 : 84,
          height: isWide ? 100 : 84,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppTheme.borderSoft,
            ),
            boxShadow: AppTheme.softShadow,
          ),
          padding: const EdgeInsets.all(14),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              AppConfig.club.fondo,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _isConfirmed ? '¡Reserva confirmada!' : 'Confirmar reserva',
          style: titleStyle,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
          ),
          child: Text(
            _isConfirmed
                ? 'Tu reserva se ha realizado correctamente.'
                : 'Revisa los detalles antes de confirmar tu reserva.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildReservationCard(
    BuildContext context,
    String dateFormat,
    String endTime,
    bool isWide,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      padding: EdgeInsets.all(isWide ? 28 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.successLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.sports_tennis,
                  color: AppTheme.success,
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Detalles de la reserva',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.sports_tennis,
                    label: 'Instalación',
                    value: widget.instalacionName,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.calendar_today_outlined,
                    label: 'Fecha',
                    value: dateFormat,
                  ),
              ),
            ],
          )
          else ...[
            _buildDetailItem(
              icon: Icons.sports_tennis,
              label: 'Instalación',
              value: widget.instalacionName,
            ),
            const SizedBox(height: 14),
            _buildDetailItem(
              icon: Icons.calendar_today_outlined,
              label: 'Fecha',
              value: dateFormat,
            ),
          ],
          const SizedBox(height: 14),
          if (isWide)
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.access_time,
                    label: 'Horario',
                    value: '${widget.selectedTime} - $endTime',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDetailItem(
                    icon: Icons.timer_outlined,
                    label: 'Duración',
                    value: '${widget.duration} minutos',
                  ),
                ),
              ],
            )
          else ...[
            _buildDetailItem(
              icon: Icons.access_time,
              label: 'Horario',
              value: '${widget.selectedTime} - $endTime',
            ),
            const SizedBox(height: 14),
            _buildDetailItem(
              icon: Icons.timer_outlined,
              label: 'Duración',
              value: '${widget.duration} minutos',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppTheme.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSection(BuildContext context, bool isWide) {
    if (_isConfirmed) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        decoration: BoxDecoration(
          color: AppTheme.successLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.success.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle,
              color: AppTheme.success,
              size: 24,
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'Reserva confirmada',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.success,
                      fontWeight: FontWeight.w700,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    final confirmButton = SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _confirmReservation,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.success,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.success.withValues(alpha: 0.55),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 21,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Confirmar reserva',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );

    final backButton = SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: _isLoading ? null : _returnWithRefresh,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.textPrimary,
          disabledForegroundColor:
              AppTheme.textSecondary.withValues(alpha: 0.5),
          side: const BorderSide(
            color: AppTheme.borderSoft,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: const Text(
          'Volver',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );

    return isWide
        ? Row(
            children: [
              Expanded(child: confirmButton),
              const SizedBox(width: 14),
              SizedBox(
                width: 180,
                child: backButton,
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              confirmButton,
              const SizedBox(height: 12),
              backButton,
            ],
          );
  }
}