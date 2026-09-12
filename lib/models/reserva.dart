enum EstadoReserva {
  confirmada,
  canceladaPorUsuario,
  canceladaPorAdmin,
}

class Reserva {
  final String usuarioId;
  final String nombreUsuario;
  final String pistaId;
  final String fecha;
  final String horaInicio;
  final int duracionMinutos;
  final EstadoReserva estadoReserva;
  final DateTime? fechaCreacionReserva;

  Reserva({
    required this.usuarioId,
    required this.nombreUsuario,
    required this.pistaId,
    required this.fecha,
    required this.horaInicio,
    required this.duracionMinutos,
    required this.estadoReserva,
    this.fechaCreacionReserva,
  });

  factory Reserva.fromMap(Map<String, dynamic> map) {
    return Reserva(
      usuarioId: map['usuarioId'] ?? '',
      nombreUsuario: map['nombreUsuario'] ?? '',
      pistaId: map['pistaId'] ?? '',
      fecha: map['fecha'] ?? '',
      horaInicio: map['horaInicio'] ?? '',
      duracionMinutos: map['duracionMinutos'] ?? 0,
      estadoReserva: _parseEstadoReserva(map['estadoReserva']),
      fechaCreacionReserva: map['fechaCreacionReserva']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuarioId': usuarioId,
      'nombreUsuario': nombreUsuario,
      'pistaId': pistaId,
      'fecha': fecha,
      'horaInicio': horaInicio,
      'duracionMinutos': duracionMinutos,
      'estadoReserva': estadoReserva.name,
      'fechaCreacionReserva': fechaCreacionReserva,
    };
  }

  static EstadoReserva _parseEstadoReserva(String? estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return EstadoReserva.confirmada;
      case 'CANCELADA_POR_USUARIO':
        return EstadoReserva.canceladaPorUsuario;
      case 'CANCELADA_POR_ADMIN':
        return EstadoReserva.canceladaPorAdmin;
      default:
        return EstadoReserva.confirmada;
    }
  }

  String get estadoReservaString {
    switch (estadoReserva) {
      case EstadoReserva.confirmada:
        return 'CONFIRMADA';
      case EstadoReserva.canceladaPorUsuario:
        return 'CANCELADA_POR_USUARIO';
      case EstadoReserva.canceladaPorAdmin:
        return 'CANCELADA_POR_ADMIN';
    }
  }
}