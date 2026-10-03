import '../../models/club/actividad.dart';
import '../../models/club/instalacion.dart';
import 'paleta_club.dart';

class ClubConfig {
  // ============================================================
  // 1. IDENTIDAD DEL CLUB
  // ============================================================

  final String clubId;
  final String zonaHoraria;
  final String nombre;
  final String deporte;
  final String telefono;
  final String email;
  final String direccion;
  final String horario;

  final String logo;
  final String fondo;

  // ============================================================
  // 2. APARIENCIA GENERAL
  // ============================================================

  final String colorPrimario;
  final PaletaClub? paleta;
  final String colorSecundario;
  final String colorAcento;
  final String colorFondo;
  final String colorSuperficie;
  final String colorSuperficieAlternativa;
  final String colorTextoPrincipal;
  final String colorTextoSecundario;
  final String colorBorde;
  final String estilo;

  // ============================================================
  // 3. IMÁGENES DEL CLUB
  // ============================================================

  final String hero;
  final String imagenLogin;
  final String menuIcon;
  final String imagenInstalaciones;
  final String imagenReservas;
  final String imagenInformacion;
  final String imagenBienvenida;
  final Map<String, String> imagenes;

  // ============================================================
  // 4. FUNCIONALIDAD Y CONTENIDO
  // ============================================================

  final List<Instalacion> instalaciones;

  final List<Actividad> actividades;

  final List<String> administradores;

  final Map<String, bool> modulos;

  const ClubConfig({
    // Identidad
    required this.clubId,
    required this.zonaHoraria,
    required this.nombre,
    required this.deporte,
    required this.logo,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.horario,
    required this.fondo,

    // Apariencia
    this.paleta,
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

    // Imágenes
    this.hero = '',
    this.imagenLogin = '',
    this.menuIcon = 'menuRounded',
    this.imagenInstalaciones = '',
    this.imagenReservas = '',
    this.imagenInformacion = '',
    this.imagenBienvenida = '',
    this.imagenes = const {},

    // Funcionalidad
    required this.instalaciones,
    this.actividades = const [],
    required this.administradores,
    this.modulos = const {},
  });

  bool moduloActivo(String modulo) {
    return modulos[modulo] ?? false;
  }

  String imagen(String clave) {
    return imagenes[clave] ?? '';
  }

  Actividad? actividad(String id) {
    try {
      return actividades.firstWhere((actividad) => actividad.id == id);
    } catch (_) {
      return null;
    }
  }
}
