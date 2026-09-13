import 'package:flutter/material.dart';
import '../config/app_config.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final legal = AppConfig.legal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de privacidad'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Política de privacidad',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Responsable del tratamiento',
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
              'Finalidad del tratamiento',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los datos personales se tratarán para gestionar el registro de usuarios, '
              'la gestión de reservas de las instalaciones, las comunicaciones relacionadas '
              'con el servicio y el cumplimiento de las obligaciones legales aplicables.',
            ),

            const SizedBox(height: 24),

            const Text(
              'Datos tratados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'La aplicación podrá tratar datos identificativos y de contacto necesarios '
              'para la gestión de la cuenta y de las reservas.',
            ),

            const SizedBox(height: 24),

            const Text(
              'Conservación de los datos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los datos se conservarán durante el tiempo necesario para prestar el servicio '
              'y mientras existan obligaciones legales que requieran su conservación.',
            ),

            const SizedBox(height: 24),

            const Text(
              'Derechos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El usuario puede ejercer sus derechos de acceso, rectificación, supresión, '
              'oposición, limitación y portabilidad cuando resulten aplicables.',
            ),

            const SizedBox(height: 24),

            const Text(
              'Contacto',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Para cualquier cuestión relacionada con la privacidad, puede contactar con '
              '${legal.responsable} a través de ${legal.email}.',
            ),
          ],
        ),
      ),
    );
  }
}
