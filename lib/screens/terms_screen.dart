import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final legal = AppConfig.legal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Términos y condiciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Responsable del servicio',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(legal.responsable),
            Text('NIF/CIF: ${legal.identificacionFiscal}'),
            Text(legal.direccion),
            Text(legal.email),
            Text(legal.telefono),

            const SizedBox(height: 24),

            const Text(
              '1. Objeto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La aplicación permite a los usuarios registrados consultar la disponibilidad '
              'y realizar reservas de las instalaciones ofrecidas por el responsable del servicio.',
            ),

            const SizedBox(height: 24),

            const Text(
              '2. Registro de usuarios',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El usuario deberá proporcionar información veraz y mantener actualizados '
              'sus datos de registro. El usuario es responsable de mantener la confidencialidad '
              'de sus credenciales.',
            ),

            const SizedBox(height: 24),

            const Text(
              '3. Reservas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las reservas estarán sujetas a las condiciones, horarios, límites y normas '
              'establecidos para cada instalación.',
            ),

            const SizedBox(height: 24),

            const Text(
              '4. Cancelaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Las condiciones y plazos de cancelación dependerán de la configuración de '
              'cada instalación y de las normas establecidas por el responsable del servicio.',
            ),

            const SizedBox(height: 24),

            const Text(
              '5. Uso de las instalaciones',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El usuario se compromete a utilizar las instalaciones de acuerdo con las '
              'normas aplicables y a respetar las condiciones de uso establecidas.',
            ),

            const SizedBox(height: 24),

            const Text(
              '6. Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para cualquier cuestión relacionada con estos términos, puede contactar '
              'con ${legal.responsable} a través de ${legal.email}.',
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.center,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 20,
                ),
                label: const Text(
                  'Acepto',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
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