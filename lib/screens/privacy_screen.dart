import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _haLlegadoAlFinal = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de Privacidad'),
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
                    'Política de Privacidad de Padel Navales',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSection(
                    '1. Responsable del tratamiento',
                    'El responsable del tratamiento de los datos personales relacionados con la gestión del servicio municipal de la Pista de Pádel Municipal de Navales será:\n\nExcmo. Ayuntamiento de Navales\n\nCIF: P-3721700-G\n\nDirección: C/ Ayuntamiento nº 19, 37382 - Navales - Salamanca\n\nCorreo electrónico de contacto: aytonavales@yahoo.es\n\nEn caso de que el Ayuntamiento disponga de Delegado de Protección de Datos, sus datos de contacto se incorporarán a esta política una vez sean facilitados por el Ayuntamiento.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '2. ¿Para qué se utilizan los datos?',
                    'Los datos personales recogidos mediante la aplicación Pádel Navales se utilizarán exclusivamente para gestionar el servicio municipal de la pista de pádel.\n\nEn particular, podrán utilizarse para:\n\n• Crear y gestionar la cuenta de usuario.\n• Identificar al usuario.\n• Gestionar reservas.\n• Gestionar cancelaciones.\n• Aplicar las normas de utilización de la instalación.\n• Controlar las condiciones establecidas para las reservas.\n• Gestionar incidencias relacionadas con el servicio.\n• Gestionar las condiciones de acceso de menores.\n• Mantener la seguridad de la aplicación.\n• Prestar el soporte y mantenimiento técnico necesario para el funcionamiento de la aplicación.\n• Conservar las evidencias de aceptación de las Condiciones de Uso y de esta Política de Privacidad.\n• Cumplir las obligaciones legales que resulten aplicables.\n\nLos datos no se utilizarán para publicidad, marketing, venta de información ni elaboración de perfiles comerciales.\n\nLa AEPD recomienda informar de forma clara sobre las finalidades y la base jurídica del tratamiento en el momento de recoger los datos.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '3. Datos que se recogen',
                    'La aplicación puede recoger y tratar los siguientes datos:\n\nDatos de usuario\n\n• Nombre y apellidos.\n• Dirección de correo electrónico.\n• Número de teléfono.\n• Nivel de pádel.\n• Fecha de registro.\n\nDatos necesarios para la gestión de menores\n\n• Fecha de nacimiento.\n• Determinación de si el usuario es menor de 14 años.\n• Autorización de padre, madre o tutor legal cuando corresponda.\n• Fecha de autorización.\n\nDatos relacionados con las aceptaciones legales\n\n• Aceptación de las Condiciones de Uso.\n• Fecha de aceptación.\n• Versión de las Condiciones aceptada.\n• Aceptación de la Política de Privacidad.\n• Fecha de aceptación.\n• Versión de la Política de Privacidad aceptada.\n\nDatos relacionados con las reservas\n\nLa aplicación podrá registrar información necesaria para gestionar las reservas, como fecha, hora, usuario que realiza la reserva y estado de la misma.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '4. Base jurídica',
                    'El tratamiento de los datos personales se realizará, según la finalidad concreta, sobre las bases jurídicas previstas en la normativa de protección de datos.\n\nPara la gestión del servicio municipal de la Pista de Pádel Municipal de Navales, el tratamiento podrá estar basado en el cumplimiento de una misión realizada en interés público o en el ejercicio de poderes públicos conferidos al Ayuntamiento, cuando dicha base jurídica resulte aplicable.\n\nCuando un tratamiento concreto requiera el consentimiento de la persona interesada, este será solicitado de forma específica, libre, informada e inequívoca.\n\nLa aceptación de esta Política de Privacidad tiene como finalidad acreditar que la persona usuaria ha recibido la información exigida por la normativa y no equivale por sí misma a prestar consentimiento para cualquier tratamiento que requiera una base jurídica específica.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '5. Registro y aceptación de documentos',
                    'Para completar el registro será necesario:\n\n☑ Haber leído la Política de Privacidad.\n☑ Aceptar las Condiciones de Uso.\n\nCuando corresponda, deberá existir además la autorización del padre, madre o tutor legal del menor.\n\nLa aplicación conservará la versión de los documentos aceptados y la fecha y hora correspondientes, con el fin de poder acreditar qué versión de los documentos fue presentada y aceptada por la persona usuaria.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '6. Menores de edad',
                    'La aplicación permite el registro de usuarios menores de edad conforme a las condiciones establecidas por el Ayuntamiento y a la normativa aplicable.\n\nUsuarios de 14 años o más\n\nPodrán registrarse utilizando su propia cuenta y realizar las actuaciones que correspondan conforme a las condiciones del servicio y a la normativa aplicable.\n\nCuando un tratamiento concreto tenga como base jurídica el consentimiento, los usuarios de 14 años o más podrán prestarlo por sí mismos en los términos previstos por la normativa.\n\nMenores de 14 años\n\nCuando el tratamiento tenga como base jurídica el consentimiento, este deberá ser prestado o autorizado por quien ejerza la patria potestad o tutela del menor.\n\nLa aplicación solicitará la correspondiente autorización del padre, madre o tutor legal y conservará la evidencia necesaria de dicha autorización.\n\nLa normativa española establece los 14 años como edad a partir de la cual el menor puede prestar por sí mismo consentimiento para el tratamiento de sus datos personales cuando esta sea la base jurídica del tratamiento.\n\nEn los casos en que sea necesario el consentimiento del titular de la patria potestad o tutela, se adoptarán las medidas razonables para comprobar que dicha autorización ha sido efectivamente prestada por la persona que corresponda.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '7. ¿Quién puede acceder a los datos?',
                    'Los datos serán tratados únicamente por las personas o entidades que necesiten acceder a ellos para prestar el servicio, realizar el mantenimiento técnico de la aplicación o cumplir una obligación legal.\n\nLa aplicación utiliza infraestructura tecnológica de Firebase/Google para determinadas funciones técnicas.\n\nLos proveedores tecnológicos que intervengan en el tratamiento de datos por cuenta del responsable deberán ofrecer las garantías exigidas por la normativa de protección de datos y estarán sujetos a las correspondientes condiciones y relaciones de encargo.\n\nNo se realizarán cesiones de datos a terceros para fines comerciales, publicitarios o de marketing.\n\nEl Ayuntamiento de Navales no tendrá acceso técnico directo a la infraestructura interna de Firebase ni a la base de datos técnica de la aplicación. No obstante, esta circunstancia no limita las responsabilidades que correspondan al Ayuntamiento como responsable del tratamiento ni las obligaciones del encargado del tratamiento conforme a la normativa aplicable.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '8. Firebase',
                    'La aplicación utiliza servicios de Firebase/Google como infraestructura tecnológica necesaria para permitir el funcionamiento de determinadas funcionalidades de la aplicación.\n\nEstos servicios podrán intervenir, entre otras funciones, en la autenticación de usuarios, el almacenamiento y gestión técnica de la información y el funcionamiento de determinadas funcionalidades de la aplicación.\n\nLos datos tratados mediante esta infraestructura se utilizarán exclusivamente para las finalidades previstas en esta Política de Privacidad y para el funcionamiento del servicio municipal.\n\nEl titular y desarrollador de la aplicación no utilizará los datos de los usuarios para fines comerciales propios, publicidad, venta de información, elaboración de perfiles comerciales ni para finalidades ajenas al servicio municipal.\n\nCuando corresponda, los proveedores tecnológicos actuarán como subencargados del tratamiento conforme a la normativa aplicable.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '9. Relación con el Ayuntamiento de Navales',
                    'El Excmo. Ayuntamiento de Navales es el responsable del tratamiento de los datos personales relacionados con la gestión del servicio municipal de la Pista de Pádel Municipal de Navales.\n\nEl tratamiento técnico de los datos se realizará por el encargado del tratamiento en los términos establecidos en el correspondiente Acuerdo de Encargo de Tratamiento.\n\nEl Ayuntamiento no dispone de acceso técnico directo a la infraestructura interna de Firebase ni a la base de datos técnica de la aplicación, salvo que las partes acuerden expresamente lo contrario.\n\nEsta circunstancia no modifica la condición del Ayuntamiento como responsable del tratamiento ni las obligaciones que correspondan a cada parte conforme a la normativa aplicable.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '10. Conservación de los datos',
                    'Los datos se conservarán durante el tiempo necesario para gestionar el servicio y mientras exista una base jurídica que legitime su tratamiento.\n\nUna vez finalizado el servicio o la relación con el usuario, los datos serán suprimidos o, cuando resulte necesario, conservados durante los plazos exigidos por las obligaciones legales aplicables o durante el tiempo necesario para atender posibles responsabilidades.\n\nLos plazos concretos de conservación se determinarán de acuerdo con la normativa aplicable y, cuando corresponda, con los criterios establecidos para la gestión del servicio.\n\nLa conservación de los datos no implicará su utilización para finalidades distintas de aquellas que justificaron su conservación.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '11. Seguridad',
                    'Se aplicarán medidas técnicas y organizativas apropiadas para proteger los datos frente a accesos no autorizados, pérdida, destrucción, alteración o divulgación indebida.\n\nEntre otras medidas, la aplicación utiliza mecanismos de autenticación y control de acceso y mantiene protegidos determinados campos relacionados con la información legal y personal.\n\nLas medidas de seguridad deberán adaptarse al riesgo del tratamiento, tal como establece el RGPD y recuerda la AEPD.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '12. Derechos de los usuarios',
                    'Las personas usuarias podrán ejercer, cuando corresponda, los derechos de:\n\n• Acceso.\n• Rectificación.\n• Supresión.\n• Oposición.\n• Limitación del tratamiento.\n• Portabilidad.\n• No ser objeto de determinadas decisiones automatizadas.\n\nPara ejercer sus derechos podrán dirigirse al responsable del tratamiento mediante:\n\nCorreo electrónico:\n\naytonavales@yahoo.es\n\nLa AEPD confirma estos derechos y señala que, con carácter general, las solicitudes deben ser atendidas en el plazo de un mes, con las posibilidades de ampliación previstas legalmente.\n\nEl ejercicio de estos derechos será gratuito, salvo que resulte aplicable alguna de las excepciones previstas legalmente.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '13. Reclamaciones',
                    'Si una persona considera que sus derechos no han sido correctamente atendidos, podrá dirigirse previamente al responsable del tratamiento para solicitar la tutela de sus derechos.\n\nAsimismo, podrá presentar una reclamación ante la Agencia Española de Protección de Datos (AEPD), especialmente cuando considere que el tratamiento de sus datos personales no se ajusta a la normativa aplicable.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '14. Modificaciones de la Política de Privacidad',
                    'Esta Política de Privacidad podrá actualizarse cuando resulte necesario como consecuencia de:\n\n• Cambios legislativos.\n• Cambios en el funcionamiento de la aplicación.\n• Cambios en el servicio municipal.\n• Cambios en los tratamientos realizados.\n• Instrucciones del Ayuntamiento.\n\nCada versión tendrá un número de versión y una fecha de actualización.\n\nLa aplicación podrá conservar la versión concreta aceptada por cada usuario.',
                  ),
                  const SizedBox(height: 16),
                  _buildSection(
                    '15. Versión actual',
                    'Versión: 1.0\n\nÚltima actualización: 22/08/2026.',
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.accentGreen.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      'Versión: 1.0\nÚltima actualización: 22/08/2026.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _haLlegadoAlFinal
                          ? () {
                              Navigator.of(context).pop(true);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _haLlegadoAlFinal
                            ? AppTheme.accentGreen
                            : Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _haLlegadoAlFinal
                            ? 'He leído la Política de Privacidad'
                            : 'Debes llegar al final para aceptar',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
