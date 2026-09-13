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

  final List<Instalacion> instalaciones;
  final List<String> administradores;

  const ClubConfig({
    required this.nombre,
    required this.deporte,
    required this.logo,
    required this.telefono,
    required this.email,
    required this.direccion,
    required this.horario,
    required this.fondo,
    required this.instalaciones,
    required this.administradores,
  });
}
