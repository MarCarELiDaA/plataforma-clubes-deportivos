import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final legal = AppConfig.legal;

    final background = AppTheme.clubBackground;
    final surface = AppTheme.clubSurface;
    final primary = AppTheme.primary;
    final textPrimary = AppTheme.clubTextPrimary;
    final textSecondary = AppTheme.clubTextSecondary;
    final textOnPrimary = AppTheme.textOnPrimary;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
        backgroundColor: surface,
        foregroundColor: textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Términos y condiciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Responsable del servicio',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 8),
            DefaultTextStyle(
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(legal.responsable),
                  Text('NIF/CIF: ${legal.identificacionFiscal}'),
                  Text(legal.direccion),
                  Text(legal.email),
                  Text(legal.telefono),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Text(
              '1. Objeto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'La aplicación permite a los usuarios registrados consultar la disponibilidad '
              'y realizar reservas de las instalaciones ofrecidas por el responsable del servicio.',
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              '2. Registro de usuarios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El usuario deberá proporcionar información veraz y mantener actualizados '
              'sus datos de registro. El usuario es responsable de mantener la confidencialidad '
              'de sus credenciales.',
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              '3. Reservas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las reservas estarán sujetas a las condiciones, horarios, límites y normas '
              'establecidos para cada instalación.',
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              '4. Cancelaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Las condiciones y plazos de cancelación dependerán de la configuración de '
              'cada instalación y de las normas establecidas por el responsable del servicio.',
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              '5. Uso de las instalaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El usuario se compromete a utilizar las instalaciones de acuerdo con las '
              'normas aplicables y a respetar las condiciones de uso establecidas.',
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 24),

            Text(
              '6. Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para cualquier cuestión relacionada con estos términos, puede contactar '
              'con ${legal.responsable} a través de ${legal.email}.',
              style: TextStyle(color: textSecondary, fontSize: 15, height: 1.5),
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: const Text(
                  'Acepto',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
