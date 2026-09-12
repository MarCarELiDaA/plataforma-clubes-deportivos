import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _haLlegadoAlFinal = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Condiciones de Uso'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
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
        child: SafeArea(
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 20) {
                if (!_haLlegadoAlFinal) {
                  setState(() {
                    _haLlegadoAlFinal = true;
                  });
                }
              }
              return false;
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Condiciones de Uso de Padel Navales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    '1. Objeto',
                    'Las presentes Condiciones de Uso regulan el acceso y utilización de la Pista de Pádel Municipal de Navales mediante la aplicación Pádel Navales.\n\nLa instalación es de titularidad del Excmo. Ayuntamiento de Navales, que gestiona directamente el servicio.\n\nEl uso de la pista estará sujeto a estas condiciones y a las instrucciones y normas que establezca el Ayuntamiento.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '2. Acceso al servicio',
                    'Podrán registrarse en la aplicación las personas que cumplan las condiciones de acceso establecidas por el Ayuntamiento.\n\nEl registro no implica necesariamente que el Ayuntamiento deba aceptar cualquier solicitud si existen condiciones, restricciones o causas justificadas que impidan el acceso al servicio.\n\nLas condiciones de acceso al servicio serán las establecidas por el Ayuntamiento y podrán modificarse cuando resulte necesario por razones legales, organizativas o de funcionamiento del servicio. Cualquier modificación que afecte a las condiciones de uso será comunicada a los usuarios cuando resulte necesario.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '3. Usuarios menores de edad',
                    'Usuarios de 14 años o más\n\nPodrán disponer de una cuenta propia y utilizar el servicio conforme a estas condiciones y a la normativa aplicable.\n\nMenores de 14 años\n\nPodrán acceder al servicio cuando exista la autorización correspondiente de su padre, madre o tutor legal, conforme al procedimiento establecido en la aplicación.\n\nEl padre, madre o tutor legal será responsable de la autorización otorgada y de que el menor cumpla las condiciones aplicables al uso del servicio.\n\nEl Ayuntamiento podrá establecer condiciones adicionales de acompañamiento o supervisión de los menores cuando así lo considere necesario.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '4. Registro',
                    'Para registrarse será necesario proporcionar información verdadera, completa y actualizada.\n\nLos datos necesarios podrán incluir:\n\n• Nombre y apellidos.\n• Email.\n• Teléfono.\n• Fecha de nacimiento.\n• Nivel de pádel.\n• Contraseña y datos necesarios para la autenticación.\n\nEl usuario será responsable de mantener la confidencialidad de sus credenciales.\n\nNo podrá utilizar las credenciales de otra persona ni permitir que otra persona utilice su cuenta.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '5. Aceptación de las condiciones',
                    'Antes de completar el registro será necesario:\n\n☑ Leer y aceptar las Condiciones de Uso.\n☑ Leer la Política de Privacidad.\n\nCuando corresponda:\n\n☑ Contar con la autorización del padre, madre o tutor legal.\n\nLa aplicación conservará la versión de los documentos aceptados y la fecha y hora correspondientes, con el fin de poder acreditar qué versión de los documentos fue presentada y aceptada por el usuario.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '6. Reservas',
                    'Las reservas se realizarán exclusivamente mediante los mecanismos habilitados en la aplicación.\n\nCada usuario podrá realizar un máximo de:\n\n2 reservas por usuario y día.\n\nLas dos reservas realizadas por un mismo usuario en el mismo día:\n\nNO podrán ser consecutivas.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '7. Duración de las reservas',
                    'Cada reserva tendrá una duración de:\n\n1 hora y 30 minutos.\n\nEl usuario deberá respetar el horario asignado y abandonar la instalación cuando finalice el periodo reservado.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '8. Horarios disponibles',
                    'Los horarios actualmente previstos son:\n\n• 06:30\n• 08:00\n• 09:30\n• 11:00\n• 12:30\n• 14:00\n• 15:30\n• 17:00\n• 18:30\n• 20:00\n• 21:30\n• 23:00\n\nEl Ayuntamiento podrá modificar los horarios cuando las necesidades de la instalación así lo requieran.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '9. Cancelaciones',
                    'El usuario podrá cancelar una reserva hasta:\n\n1 hora antes del comienzo de la reserva.\n\nUna vez superado dicho plazo, la aplicación podrá impedir la cancelación.\n\nEl Ayuntamiento podrá establecer medidas adicionales ante un uso reiterado e injustificado de reservas que no sean utilizadas.\n\nEn caso de que una reserva no pueda ser utilizada y haya transcurrido el plazo establecido para su cancelación, el usuario deberá asumir las consecuencias que, en su caso, establezca el Ayuntamiento conforme a las normas de utilización del servicio.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '10. Prohibición de ceder reservas',
                    'Las reservas son personales.\n\nNo está permitido vender, ceder, prestar o transferir una reserva a otra persona.\n\nLa persona que haya realizado la reserva será responsable de su utilización.\n\nEl Ayuntamiento podrá establecer las medidas que correspondan ante el incumplimiento de esta norma.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '11. Gratuidad del servicio',
                    'Actualmente el servicio de reserva de la pista se presta:\n\nDe forma gratuita.\n\nNo se establece actualmente ningún precio por reserva.\n\nEl Ayuntamiento podrá establecer tasas, precios públicos u otras condiciones económicas en el futuro cuando proceda legalmente y sean aprobadas por los órganos competentes.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '12. Normas de utilización de la pista',
                    'Las personas usuarias deberán:\n\n• Mantener una conducta adecuada y respetuosa.\n• Utilizar la pista únicamente para la práctica del pádel.\n• Utilizar calzado y equipamiento deportivo adecuado.\n• Cuidar las instalaciones, mobiliario y material deportivo.\n• Responder de los daños ocasionados por un uso inadecuado.\n• Respetar los horarios de reserva.\n• Abandonar la pista al finalizar el periodo reservado.\n• Depositar los residuos en los lugares habilitados.\n• Dejar la pista en las mismas condiciones en las que se encontró.\n• Comunicar cualquier desperfecto o incidencia.\n• Cumplir las indicaciones del Ayuntamiento.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '13. Tabaco y alcohol',
                    'Queda prohibido fumar y consumir bebidas alcohólicas en aquellos espacios de la instalación en los que dicha conducta esté prohibida por la normativa aplicable o por las normas establecidas por el Ayuntamiento.\n\nLos usuarios deberán cumplir en todo momento la normativa aplicable y las instrucciones municipales.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '14. Animales',
                    'El acceso de animales a la pista y a las diferentes zonas de la instalación se regirá por la normativa aplicable y por las normas establecidas por el Ayuntamiento, respetándose en todo caso las excepciones legalmente previstas.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '15. Conductas prohibidas',
                    'No estará permitido:\n\n• Dañar deliberadamente las instalaciones.\n• Utilizar la pista para actividades distintas del pádel.\n• Introducir elementos que puedan deteriorar la instalación.\n• Utilizar la pista fuera del horario reservado.\n• Ceder reservas a terceros.\n• Utilizar cuentas pertenecientes a otras personas.\n• Facilitar datos falsos durante el registro.\n• Realizar un uso fraudulento de la aplicación.\n• Alterar o intentar manipular el funcionamiento de la aplicación.\n• Incumplir las instrucciones del Ayuntamiento.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '16. Incidencias',
                    'Para comunicar incidencias relacionadas con la pista o con las reservas podrá utilizarse:\n\nCorreo electrónico:\n\naytonavales@yahoo.es\n\nTeléfono de contacto:\n\n923 30 01 83',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '17. Responsabilidad del usuario',
                    'El usuario será responsable de utilizar correctamente:\n\n• Su cuenta.\n• Sus credenciales.\n• Las reservas realizadas.\n• La instalación municipal.\n• El material utilizado durante la práctica deportiva.\n\nEl usuario responderá de los daños que cause por un uso indebido cuando así corresponda legalmente.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '18. Suspensión o cancelación de cuentas',
                    'El Ayuntamiento podrá adoptar las medidas que correspondan cuando un usuario incumpla estas Condiciones de Uso o las normas municipales aplicables.\n\nDependiendo de la gravedad del incumplimiento, podrán adoptarse medidas como:\n\n• Advertencia.\n• Cancelación de reservas.\n• Suspensión temporal de la cuenta.\n• Bloqueo de la cuenta.\n• Otras medidas previstas por la normativa o por las reglas municipales.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '19. Funcionamiento de la aplicación',
                    'La aplicación se proporciona como herramienta tecnológica para facilitar la gestión del servicio.\n\nPodrán producirse interrupciones temporales por:\n\n• Mantenimiento.\n• Actualizaciones.\n• Problemas técnicos.\n• Fallos de conexión.\n• Incidencias de proveedores tecnológicos.\n• Circunstancias ajenas al control del desarrollador.\n\nSe realizarán las actuaciones técnicas necesarias para restablecer el funcionamiento normal del servicio en el menor tiempo posible, dentro de las posibilidades técnicas existentes.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '20. Modificación de las condiciones',
                    'El Ayuntamiento podrá modificar las presentes Condiciones de Uso cuando resulte necesario por:\n\n• Cambios en la normativa.\n• Cambios en la instalación.\n• Cambios en los horarios.\n• Cambios en el sistema de reservas.\n• Cambios en las condiciones de utilización.\n• Necesidades de funcionamiento del servicio.\n\nLas nuevas versiones deberán quedar identificadas mediante número de versión y fecha.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '21. Aceptación',
                    'Antes de completar el registro, el usuario deberá tener acceso a las presentes Condiciones de Uso y a la Política de Privacidad.\n\nLa aceptación de las Condiciones de Uso y la confirmación de haber leído la Política de Privacidad se realizarán mediante acciones expresas e independientes dentro de la aplicación.\n\nCuando corresponda, el registro de un menor de 14 años requerirá además la autorización de su padre, madre o tutor legal conforme al procedimiento establecido en la aplicación.',
                  ),
                  const SizedBox(height: 16),

                  _buildSection(
                    '22. Versión actual',
                    'Versión: 1.0\n\nÚltima actualización: 22/08/2026.',
                  ),

                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.accentGreen.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'Versión: 1.0\nÚltima actualización: 22/08/2026.',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _haLlegadoAlFinal
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      child: Text(
                        _haLlegadoAlFinal
                            ? 'He leído las Condiciones de Uso'
                            : 'Lee las condiciones hasta el final',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.accentGreen,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}