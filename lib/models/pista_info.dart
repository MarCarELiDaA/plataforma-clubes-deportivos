enum PistaEstado {
  disponible,
  mantenimiento,
  cerradaTemporalmente,
}

class PistaInfo {
  final String nombrePista;
  final String descripcion;
  final PistaEstado estadoActual;
  final String horarioAperturaClub;
  final String horarioCierreClub;
  final List<String> franjasDisponiblesPorDefecto;
  final int duracionPartidoMinutos;
  final String? reglasUso;
  final DateTime? fechaActualizacion;

  PistaInfo({
    required this.nombrePista,
    required this.descripcion,
    required this.estadoActual,
    required this.horarioAperturaClub,
    required this.horarioCierreClub,
    required this.franjasDisponiblesPorDefecto,
    required this.duracionPartidoMinutos,
    this.reglasUso,
    this.fechaActualizacion,
  });

  factory PistaInfo.fromMap(Map<String, dynamic> map) {
    return PistaInfo(
      nombrePista: map['nombrePista'] ?? 'Pista de Pádel',
      descripcion: map['descripcion'] ?? 'Pista de pádel profesional',
      estadoActual: _parsePistaEstado(map['estadoActual']),
      horarioAperturaClub: map['horarioAperturaClub'] ?? '09:00',
      horarioCierreClub: map['horarioCierreClub'] ?? '23:00',
      franjasDisponiblesPorDefecto: 
          List<String>.from(map['franjasDisponiblesPorDefecto'] ?? []),
      duracionPartidoMinutos: map['duracionPartidoMinutos'] ?? 90,
      reglasUso: map['reglasUso'],
      fechaActualizacion: map['fechaActualizacion']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombrePista': nombrePista,
      'descripcion': descripcion,
      'estadoActual': estadoActual.name.toUpperCase(),
      'horarioAperturaClub': horarioAperturaClub,
      'horarioCierreClub': horarioCierreClub,
      'franjasDisponiblesPorDefecto': franjasDisponiblesPorDefecto,
      'duracionPartidoMinutos': duracionPartidoMinutos,
      'reglasUso': reglasUso,
      'fechaActualizacion': fechaActualizacion,
    };
  }

  static PistaEstado _parsePistaEstado(String? estado) {
    switch (estado) {
      case 'DISPONIBLE':
        return PistaEstado.disponible;
      case 'MANTENIMIENTO':
        return PistaEstado.mantenimiento;
      case 'CERRADA_TEMPORALMENTE':
        return PistaEstado.cerradaTemporalmente;
      default:
        return PistaEstado.disponible;
    }
  }

  String get estadoActualString {
    switch (estadoActual) {
      case PistaEstado.disponible:
        return 'DISPONIBLE';
      case PistaEstado.mantenimiento:
        return 'MANTENIMIENTO';
      case PistaEstado.cerradaTemporalmente:
        return 'CERRADA_TEMPORALMENTE';
    }
  }
}