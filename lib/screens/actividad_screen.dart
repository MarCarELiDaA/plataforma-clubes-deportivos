import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ActividadScreen extends StatelessWidget {
  final String nombre;
  final IconData icono;

  const ActividadScreen({
    super.key,
    required this.nombre,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.clubBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.clubSurface,
        foregroundColor: AppTheme.clubTextPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          nombre,
          style: TextStyle(
            color: AppTheme.clubTextPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.clubSurface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.clubBorder,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    icono,
                    size: 34,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.clubTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Consulta los horarios y actividades disponibles.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: AppTheme.clubTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Horarios',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.clubTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildHorario('06:30', 'Disponible'),
            _buildHorario('08:00', 'Disponible'),
            _buildHorario('09:30', 'Disponible'),
            _buildHorario('11:00', 'Disponible'),
            _buildHorario('12:30', 'Disponible'),
            _buildHorario('17:00', 'Disponible'),
            _buildHorario('18:30', 'Disponible'),
            _buildHorario('20:00', 'Disponible'),
            const SizedBox(height: 24),
            Text(
              'Normas',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppTheme.clubTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.clubSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.clubBorder,
                ),
              ),
              child: Text(
                'Las normas, horarios y condiciones de esta actividad serán configurables por cada club.',
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: AppTheme.clubTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorario(String hora, String estado) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppTheme.clubSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.clubBorder,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              hora,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.clubTextPrimary,
              ),
            ),
          ),
          Text(
            estado,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.clubTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}