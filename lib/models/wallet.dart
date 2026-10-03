import 'package:cloud_firestore/cloud_firestore.dart';

class WalletSaldo {
  final int totalCentimos;
  final int bloqueadoCentimos;
  final bool esPrueba;

  int get disponibleCentimos => totalCentimos - bloqueadoCentimos;

  const WalletSaldo({
    required this.totalCentimos,
    required this.bloqueadoCentimos,
    required this.esPrueba,
  });

  factory WalletSaldo.fromMap(Map<String, dynamic> data) {
    final total = data['saldoTotalCentimos'];
    final blocked = data['saldoBloqueadoCentimos'];
    if (total is! int || blocked is! int || total < 0 || blocked < 0 ||
        blocked > total || data['moneda'] != 'EUR' || data['esPrueba'] is! bool) {
      throw const FormatException('Los datos del saldo no son válidos.');
    }
    return WalletSaldo(
      totalCentimos: total,
      bloqueadoCentimos: blocked,
      esPrueba: data['esPrueba'] as bool,
    );
  }
}

class WalletMovimiento {
  final String tipo;
  final int importeCentimos;
  final String motivo;
  final DateTime fecha;
  final String? reservaId;

  const WalletMovimiento({
    required this.tipo,
    required this.importeCentimos,
    required this.motivo,
    required this.fecha,
    this.reservaId,
  });

  factory WalletMovimiento.fromMap(Map<String, dynamic> data) {
    final tipo = data['tipo'];
    final importe = data['importeCentimos'];
    final motivo = data['motivo'];
    final fecha = data['fecha'];
    final reservaId = data['reservaId'];
    if (tipo is! String || !const {
      'INGRESO', 'INGRESO_PRUEBA', 'RECARGA_SIMULADA', 'RETIRADA', 'BLOQUEO',
      'LIBERACION', 'COBRO', 'DEVOLUCION',
    }.contains(tipo) || importe is! int || importe <= 0 ||
        motivo is! String || motivo.trim().isEmpty || fecha is! Timestamp ||
        (reservaId != null && (reservaId is! String || reservaId.isEmpty))) {
      throw const FormatException('Los datos del movimiento no son válidos.');
    }
    return WalletMovimiento(
      tipo: tipo,
      importeCentimos: importe,
      motivo: motivo,
      fecha: fecha.toDate(),
      reservaId: reservaId as String?,
    );
  }
}
