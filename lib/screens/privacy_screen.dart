import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final legal = AppConfig.legal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de privacidad'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth =
              constraints.maxWidth > 1050 ? 1050.0 : constraints.maxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.borderSoft,
                        ),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.success.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.lock_outline_rounded,
                              color: AppTheme.success,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Política de privacidad',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Información sobre el tratamiento y protección de los datos personales de los usuarios.',
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _SectionCard(
                      title: '1. Responsable del tratamiento',
                      icon: Icons.business_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(legal.responsable),
                          const SizedBox(height: 4),
                          Text(
                            'NIF/CIF: ${legal.identificacionFiscal}',
                          ),
                          const SizedBox(height: 4),
                          Text(legal.direccion),
                          const SizedBox(height: 4),
                          Text(legal.email),
                          const SizedBox(height: 4),
                          Text(legal.telefono),
                        ],
                      ),
                    ),

                    _SectionCard(
                      title: '2. Finalidad del tratamiento',
                      icon: Icons.track_changes_outlined,
                      child: const Text(
                        'Los datos personales proporcionados por los usuarios serán tratados '
                        'con la finalidad de gestionar el registro y acceso a la aplicación, '
                        'permitir la utilización de sus funcionalidades, gestionar las reservas '
                        'de las instalaciones y mantener la comunicación necesaria relacionada '
                        'con el servicio solicitado por el usuario.',
                      ),
                    ),

                    _SectionCard(
                      title: '3. Datos personales tratados',
                      icon: Icons.person_outline_rounded,
                      child: const Text(
                        'En función de las funcionalidades utilizadas, podrán tratarse datos '
                        'identificativos y de contacto proporcionados por el usuario durante '
                        'el registro o durante el uso de la aplicación. El responsable tratará '
                        'únicamente aquellos datos que resulten necesarios para las finalidades '
                        'correspondientes.',
                      ),
                    ),

                    _SectionCard(
                      title: '4. Base jurídica',
                      icon: Icons.gavel_outlined,
                      child: const Text(
                        'La base jurídica del tratamiento dependerá de la finalidad concreta '
                        'para la que se utilicen los datos. Podrá estar basada, entre otros '
                        'supuestos previstos por la normativa aplicable, en la ejecución de '
                        'la relación solicitada por el usuario, en el cumplimiento de '
                        'obligaciones legales o en el consentimiento del interesado cuando '
                        'este resulte necesario.',
                      ),
                    ),

                    _SectionCard(
                      title: '5. Carácter necesario de los datos',
                      icon: Icons.info_outline_rounded,
                      child: const Text(
                        'Los datos solicitados como obligatorios son necesarios para poder '
                        'prestar determinadas funcionalidades del servicio. La falta de '
                        'aportación de dichos datos podrá impedir el registro, el acceso '
                        'o la utilización de determinadas funciones de la aplicación.',
                      ),
                    ),

                    _SectionCard(
                      title: '6. Conservación de los datos',
                      icon: Icons.schedule_outlined,
                      child: const Text(
                        'Los datos personales se conservarán durante el tiempo necesario '
                        'para cumplir las finalidades para las que fueron recogidos y, '
                        'cuando corresponda, durante los plazos exigidos por las obligaciones '
                        'legales aplicables. Una vez finalizados dichos plazos, los datos '
                        'serán eliminados o, cuando proceda, debidamente bloqueados.',
                      ),
                    ),

                    _SectionCard(
                      title: '7. Destinatarios',
                      icon: Icons.groups_outlined,
                      child: const Text(
                        'Los datos podrán ser comunicados a terceros cuando exista una base '
                        'jurídica que lo permita o cuando dicha comunicación resulte necesaria '
                        'para la prestación del servicio solicitado, el cumplimiento de una '
                        'obligación legal o la gestión de las funcionalidades de la aplicación.',
                      ),
                    ),

                    _SectionCard(
                      title: '8. Transferencias internacionales',
                      icon: Icons.public_outlined,
                      child: const Text(
                        'Cuando alguno de los servicios utilizados para prestar las '
                        'funcionalidades de la aplicación implique una transferencia '
                        'internacional de datos personales, esta se realizará únicamente '
                        'cuando exista una base jurídica válida y se cumplan las garantías '
                        'exigidas por la normativa de protección de datos aplicable.',
                      ),
                    ),

                    _SectionCard(
                      title: '9. Seguridad',
                      icon: Icons.security_outlined,
                      child: const Text(
                        'El responsable adoptará las medidas técnicas y organizativas '
                        'apropiadas para proteger los datos personales frente a accesos '
                        'no autorizados, pérdida, alteración, divulgación o cualquier '
                        'otra forma de tratamiento indebido, teniendo en cuenta la naturaleza '
                        'de los datos y los riesgos asociados al tratamiento.',
                      ),
                    ),

                    _SectionCard(
                      title: '10. Derechos de los usuarios',
                      icon: Icons.verified_user_outlined,
                      child: const Text(
                        'El usuario puede ejercer, cuando proceda, los derechos de acceso, '
                        'rectificación, supresión, oposición, limitación del tratamiento '
                        'y portabilidad de sus datos personales, así como cualquier otro '
                        'derecho reconocido por la normativa aplicable.',
                      ),
                    ),

                    _SectionCard(
                      title: '11. Cómo ejercer los derechos',
                      icon: Icons.mail_outline_rounded,
                      child: Text(
                        'Para ejercer sus derechos, el usuario puede dirigirse al responsable '
                        'del tratamiento a través de ${legal.email}, indicando el derecho '
                        'que desea ejercer y aportando la información necesaria para poder '
                        'atender correctamente su solicitud.',
                      ),
                    ),

                    _SectionCard(
                      title: '12. Derecho a reclamar',
                      icon: Icons.report_problem_outlined,
                      child: const Text(
                        'El usuario tiene derecho a presentar una reclamación ante la '
                        'autoridad de control competente en materia de protección de datos '
                        'si considera que el tratamiento de sus datos personales no se '
                        'ajusta a la normativa aplicable.',
                      ),
                    ),

                    _SectionCard(
                      title: '13. Actualizaciones de la política',
                      icon: Icons.update_outlined,
                      child: const Text(
                        'Esta política de privacidad podrá actualizarse cuando resulte '
                        'necesario para adaptarla a cambios normativos, técnicos, '
                        'organizativos o a nuevas funcionalidades del servicio. Cuando '
                        'los cambios sean relevantes, se facilitará al usuario la información '
                        'correspondiente de acuerdo con la normativa aplicable.',
                      ),
                    ),

                    _SectionCard(
                      title: '14. Información adicional',
                      icon: Icons.description_outlined,
                      child: const Text(
                        'La presente política constituye una información general sobre '
                        'el tratamiento de datos personales asociado a la aplicación. '
                        'El responsable deberá revisar y adaptar su contenido a los '
                        'tratamientos concretos que realice, a los servicios utilizados, '
                        'a los destinatarios de los datos, a los plazos de conservación '
                        'y a las restantes circunstancias aplicables a cada instalación '
                        'o entidad.',
                      ),
                    ),

                    const SizedBox(height: 8),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.success.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppTheme.success,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Antes de publicar esta política, el responsable del servicio '
                              'debe revisar y completar la información de acuerdo con los '
                              'tratamientos reales de datos que se realicen.',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.45,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
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
            ),
          );
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppTheme.borderSoft,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.success.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.success,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DefaultTextStyle(
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: Colors.grey.shade800,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}