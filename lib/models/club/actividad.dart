import 'instalacion.dart';

class Actividad {
  final String id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final String? imagen;
  final String icono;
  final bool activa;
  final List<Instalacion> instalaciones;

  const Actividad({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.imagen,
    this.icono = 'sports',
    this.activa = true,
    this.instalaciones = const [],
  });

  List<Instalacion> get instalacionesActivas {
    return instalaciones.where((instalacion) => instalacion.activa).toList();
  }

  bool get reservasActivas {
    return instalacionesActivas.any(
      (instalacion) => instalacion.reservasActivas,
    );
  }
}