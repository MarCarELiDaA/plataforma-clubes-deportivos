class Usuario {
  final String nombre;
  final String email;
  final String? telefono;
  final double? nivelPadel;
  final DateTime? fechaRegistro;
  final String role;
  final String status;

  // Campos de aceptaciones legales simplificados
  final bool? aceptaCondiciones;
  final bool? aceptaPrivacidad;
  final DateTime? fechaAceptaciones;
  final String? versionCondiciones;
  final String? versionPrivacidad;

  Usuario({
    required this.nombre,
    required this.email,
    this.telefono,
    this.nivelPadel,
    this.fechaRegistro,
    this.role = 'user',
    this.status = 'pending',
    this.aceptaCondiciones,
    this.aceptaPrivacidad,
    this.fechaAceptaciones,
    this.versionCondiciones,
    this.versionPrivacidad,
  });

  factory Usuario.fromMap(Map<String, dynamic> map) {
    return Usuario(
      nombre: map['nombre'] ?? '',
      email: map['email'] ?? '',
      telefono: map['telefono'],
      nivelPadel: map['nivelPadel']?.toDouble(),
      fechaRegistro: map['fechaRegistro']?.toDate(),
      role: map['role'] ?? 'user',
      status: map['status'] ?? 'pending',
      aceptaCondiciones: map['aceptaCondiciones'],
      aceptaPrivacidad: map['aceptaPrivacidad'],
      fechaAceptaciones: map['fechaAceptaciones']?.toDate(),
      versionCondiciones: map['versionCondiciones'],
      versionPrivacidad: map['versionPrivacidad'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'nivelPadel': nivelPadel,
      'fechaRegistro': fechaRegistro,
      'role': role,
      'status': status,
      'aceptaCondiciones': aceptaCondiciones,
      'aceptaPrivacidad': aceptaPrivacidad,
      'fechaAceptaciones': fechaAceptaciones,
      'versionCondiciones': versionCondiciones,
      'versionPrivacidad': versionPrivacidad,
    };
  }
}