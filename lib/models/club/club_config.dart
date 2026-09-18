import '../../models/club/instalacion.dart';

class ClubConfig {
  // ============================================================
  // 1. IDENTIDAD DEL CLUB
  // ============================================================

  final String nombre;
  final String deporte;
  final String telefono;
  final String email;
  final String direccion;
  final String horario;

  // Se mantienen estas propiedades por compatibilidad
  // con las pantallas actuales.
  final String logo;
  final String fondo;

  // ============================================================
  // 2. APARIENCIA GENERAL
  // ============================================================

  /// Color principal de identidad del club.
  ///
  /// Ejemplo: azul corporativo.
  final String colorPrimario;

  /// Color secundario para botones y controles principales.
  ///
  /// Ejemplo: verde.
  final String colorSecundario;

  /// Color de acento para detalles visuales.
  ///
  /// Ejemplo: amarillo.
  final String colorAcento;

  /// Color de fondo general de la aplicación.
  final String colorFondo;

  /// Color principal de tarjetas, diálogos y superficies.
  final String colorSuperficie;

  /// Color alternativo para superficies secundarias.
  final String colorSuperficieAlternativa;

  /// Color principal de los textos.
  final String colorTextoPrincipal;

  /// Color secundario de los textos.
  final String colorTextoSecundario;

  /// Color de bordes y separadores.
  final String colorBorde;

  /// Estilo visual general de la aplicación.
  ///
  /// Valores previstos:
  /// - claro
  /// - oscuro
  /// - automatico
  final String estilo;

  // ============================================================
  // 3. IMÁGENES DEL CLUB
  // ============================================================

  /// Imagen principal o hero de la pantalla de inicio.
  final String hero;

  /// Imagen para la sección de instalaciones.
  final String imagenInstalaciones;

  /// Imagen para la sección de reservas.
  final String imagenReservas;

  /// Imagen para la sección de información.
  final String imagenInformacion;

  /// Imagen de bienvenida.
  final String imagenBienvenida;

  /// Imágenes adicionales configurables.
  ///
  /// Ejemplo:
  /// {
  ///   'promocion': 'assets/clubs/club_x/promocion.jpg',
  ///   'evento': 'assets/clubs/club_x/evento.jpg',
  /// }
  final Map<String, String> imagenes;

  // ============================================================
  // 4. FUNCIONALIDAD Y CONTENIDO
  // ============================================================

  final List<Instalacion> instalaciones;
  final List<String> administradores;

  /// Módulos funcionales activos para este cliente.
  ///
  /// Ejemplo:
  /// {
  ///   'reservations': true,
  ///   'payments': false,
  ///   'notifications': true,
  /// }
  final Map<String, bool> modulos;

  const ClubConfig({
    // ------------------------------------------------------------
    // Identidad
    // ------------------------------------------------------------
    required this.nombre,
    required this.deporte,
    required this.logo,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.horario,
    required this.fondo,

    // ------------------------------------------------------------
    // Apariencia
    // ------------------------------------------------------------
    this.colorPrimario = '#071A42',
    this.colorSecundario = '#50C878',
    this.colorAcento = '#FFD700',
    this.colorFondo = '#F7F9FC',
    this.colorSuperficie = '#FFFFFF',
    this.colorSuperficieAlternativa = '#F1F5F9',
    this.colorTextoPrincipal = '#102033',
    this.colorTextoSecundario = '#526274',
    this.colorBorde = '#D7DEE7',
    this.estilo = 'claro',

    // ------------------------------------------------------------
    // Imágenes
    // ------------------------------------------------------------
    this.hero = '',
    this.imagenInstalaciones = '',
    this.imagenReservas = '',
    this.imagenInformacion = '',
    this.imagenBienvenida = '',
    this.imagenes = const {},

    // ------------------------------------------------------------
    // Funcionalidad y contenido
    // ------------------------------------------------------------
    required this.instalaciones,
    required this.administradores,
    this.modulos = const {},
  });

  /// Indica si un módulo está activo.
  bool moduloActivo(String modulo) {
    return modulos[modulo] ?? false;
  }

  /// Devuelve una imagen adicional configurada.
  ///
  /// Si no existe, devuelve una cadena vacía.
  String imagen(String clave) {
    return imagenes[clave] ?? '';
  }
}
