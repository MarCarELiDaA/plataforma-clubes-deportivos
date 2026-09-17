import '../../models/club/instalacion.dart';

class ClubConfig {
  final String nombre;
  final String deporte;
  final String logo;
  final String telefono;
  final String email;
  final String direccion;
  final String horario;
  final String fondo;

  /// Identidad visual del club.
  ///
  /// Se almacenan como colores hexadecimales para mantener
  /// ClubConfig independiente de Flutter/UI.
  final String colorPrimario;
  final String colorSecundario;
  final String colorAcento;

  final List<Instalacion> instalaciones;
  final List<String> administradores;

  /// Módulos funcionales activos para este cliente.
  final Map<String, bool> modulos;

  const ClubConfig({
    required this.nombre,
    required this.deporte,
    required this.logo,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.horario,
    required this.fondo,
    this.colorPrimario = '#FF6B57',
    this.colorSecundario = '#7C3AED',
    this.colorAcento = '#22C55E',
    required this.instalaciones,
    required this.administradores,
    this.modulos = const {},
  });

  /// Indica si un módulo está activo.
  bool moduloActivo(String modulo) {
    return modulos[modulo] ?? false;
  }
}
