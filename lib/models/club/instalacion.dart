class Instalacion {
  final String id;
  final String nombre;
  final String tipo;
  final String? descripcion;
  final String? imagen;
  final bool activa;

  final List<String> horarios;
  /// Precio por reserva completa, en céntimos, según la hora de inicio.
  final Map<String, int> preciosPorHorarioCentimos;
  final int duracionReservaMinutos;
  /// Plazas disponibles por fecha y horario; 1 para una pista exclusiva.
  final int aforoPorHorario;

  final int maxReservasPorDia;
  final int maxMinutosPorDia;
  final int maxDiasAntelacion;

  /// Minutos mínimos de antelación necesarios para cancelar una reserva.
  final int minutosAntelacionCancelacion;

  final List<String> normas;

  final bool reservasActivas;
  final bool pagosActivos;
  final bool accesoDigitalActivo;

  const Instalacion({
    required this.id,
    required this.nombre,
    required this.tipo,
    this.descripcion,
    this.imagen,
    this.activa = true,
    this.horarios = const [],
    this.preciosPorHorarioCentimos = const {},
    this.duracionReservaMinutos = 60,
    this.aforoPorHorario = 1,
    this.maxReservasPorDia = 2,
    this.maxMinutosPorDia = 180,
    this.maxDiasAntelacion = 10,
    this.minutosAntelacionCancelacion = 60,
    this.normas = const [],
    this.reservasActivas = true,
    this.pagosActivos = false,
    this.accesoDigitalActivo = false,
  }) : assert(aforoPorHorario > 0);
}
