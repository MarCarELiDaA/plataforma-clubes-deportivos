import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club/instalacion.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<String>> getHorariosReservados(
    String instalacionId,
    String fecha,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('instalacionId', isEqualTo: instalacionId)
          .where('fecha', isEqualTo: fecha)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get()
          .timeout(const Duration(seconds: 5));

      return querySnapshot.docs
          .map((doc) => doc.data()['horaInicio'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }

  Stream<List<String>> getHorariosReservadosStream(
    String instalacionId,
    String fecha,
  ) {
    return _firestore
        .collection('reservas')
        .where('instalacionId', isEqualTo: instalacionId)
        .where('fecha', isEqualTo: fecha)
        .where('estadoReserva', isEqualTo: 'CONFIRMADA')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => doc.data()['horaInicio'] as String)
              .toList(),
        );
  }

  Future<String> crearReserva(Map<String, dynamic> reservaData) async {
    try {
      final docRef = await _firestore
          .collection('reservas')
          .add(reservaData);

      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> crearReservaConVerificacion(
    Map<String, dynamic> reservaData,
    Instalacion instalacion,
  ) async {
    try {
      final instalacionId = reservaData['instalacionId'] as String;
      final fecha = reservaData['fecha'] as String;
      final horaInicio = reservaData['horaInicio'] as String;
      final usuarioId = reservaData['usuarioId'] as String;

      return await _firestore.runTransaction((transaction) async {
        final fechaParts = fecha.split('-');

        final fechaReserva = DateTime(
          int.parse(fechaParts[0]),
          int.parse(fechaParts[1]),
          int.parse(fechaParts[2]),
        );

        if (!validarAntelacion(fechaReserva, instalacion.maxDiasAntelacion)) {
          throw Exception(
            'Solo puedes reservar hasta ${instalacion.maxDiasAntelacion} días de antelación',
          );
        }

        final querySnapshot = await _firestore
            .collection('reservas')
            .where('instalacionId', isEqualTo: instalacionId)
            .where('fecha', isEqualTo: fecha)
            .where('horaInicio', isEqualTo: horaInicio)
            .where('estadoReserva', isEqualTo: 'CONFIRMADA')
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          throw Exception('Este horario ya está reservado');
        }

        final usuarioReservasSnapshot = await _firestore
            .collection('reservas')
            .where('usuarioId', isEqualTo: usuarioId)
            .where('fecha', isEqualTo: fecha)
            .where('estadoReserva', isEqualTo: 'CONFIRMADA')
            .get();

        if (usuarioReservasSnapshot.docs.length >= instalacion.maxReservasPorDia) {
          throw Exception('Has alcanzado el máximo de ${instalacion.maxReservasPorDia} reservas permitidas para este día.');
        }

        for (var doc in usuarioReservasSnapshot.docs) {
          final horaInicioExistente =
              doc.data()['horaInicio'] as String;

          if (sonReservasConsecutivas(
            horaInicioExistente,
            horaInicio,
            instalacion.duracionReservaMinutos,
          )) {
            throw Exception(
              'No puedes reservar horarios consecutivos. '
              'Debe existir un intervalo de ${_formatearDuracion(instalacion.duracionReservaMinutos)} '
              'entre tus reservas.',
            );
          }
        }

        final docRef = _firestore.collection('reservas').doc();

        transaction.set(docRef, reservaData);

        return docRef.id;
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> isHorarioDisponible(
    String instalacionId,
    String fecha,
    String hora,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('instalacionId', isEqualTo: instalacionId)
          .where('fecha', isEqualTo: fecha)
          .where('horaInicio', isEqualTo: hora)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get()
          .timeout(const Duration(seconds: 5));

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getReservasUsuarioConId(
    String usuarioId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> cancelarReserva(String reservaId) async {
    try {
      await _firestore
          .collection('reservas')
          .doc(reservaId)
          .update({
        'estadoReserva': 'CANCELADA_POR_USUARIO',
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<int> calcularHorasReservadasEnDia(
    String usuarioId,
    String fecha,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('fecha', isEqualTo: fecha)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get();

      int totalHoras = 0;

      for (var doc in querySnapshot.docs) {
        final duracion =
            doc.data()['duracionMinutos'] as int? ?? 90;

        totalHoras += duracion;
      }

      return totalHoras;
    } catch (e) {
      return 0;
    }
  }

  Future<int> contarReservasEnDia(
    String usuarioId,
    String fecha,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('fecha', isEqualTo: fecha)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get();

      return querySnapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<Map<String, dynamic>>> getReservasUsuarioEnDia(
    String usuarioId,
    String fecha,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('reservas')
          .where('usuarioId', isEqualTo: usuarioId)
          .where('fecha', isEqualTo: fecha)
          .where('estadoReserva', isEqualTo: 'CONFIRMADA')
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  bool sonReservasConsecutivas(
    String horaInicio1,
    String horaInicio2,
    int duracionReservaMinutos,
  ) {
    try {
      final time1 = horaInicio1.split(':');
      final time2 = horaInicio2.split(':');

      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);

      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);

      final inicio1 = DateTime(
        2024,
        1,
        1,
        hour1,
        minute1,
      );

      final fin1 = inicio1.add(
        Duration(minutes: duracionReservaMinutos),
      );

      final inicio2 = DateTime(
        2024,
        1,
        1,
        hour2,
        minute2,
      );

      return fin1.isAtSameMomentAs(inicio2) ||
          inicio1.isAtSameMomentAs(
            inicio2.add(
              Duration(minutes: duracionReservaMinutos),
            ),
          );
    } catch (e) {
      return false;
    }
  }

  Future<bool> puedeReservarEnDia(
    String usuarioId,
    String fecha,
    int duracionNueva,
    Instalacion instalacion,
  ) async {
    final horasReservadas =
        await calcularHorasReservadasEnDia(usuarioId, fecha);

    final horasTotales = horasReservadas + duracionNueva;

    return horasTotales <= instalacion.maxMinutosPorDia;
  }

  Future<bool> cumpleLimiteReservasPorDia(
    String usuarioId,
    String fecha,
    Instalacion instalacion,
  ) async {
    final reservas =
        await contarReservasEnDia(usuarioId, fecha);

    return reservas < instalacion.maxReservasPorDia;
  }

  Future<bool> noEsConsecutivaConReservasExistentes(
    String usuarioId,
    String fecha,
    String nuevaHoraInicio,
    Instalacion instalacion,
  ) async {
    try {
      final reservas =
          await getReservasUsuarioEnDia(usuarioId, fecha);

      for (var reserva in reservas) {
        final horaInicioExistente =
            reserva['horaInicio'] as String;

        if (sonReservasConsecutivas(
          horaInicioExistente,
          nuevaHoraInicio,
          instalacion.duracionReservaMinutos,
        )) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  bool validarAntelacion(DateTime fechaReserva, int maxDiasAntelacion) {
    final hoy = DateTime.now();

    final fechaLimite = hoy.add(
      Duration(days: maxDiasAntelacion),
    );

    final fechaReservaSinHora = DateTime(
      fechaReserva.year,
      fechaReserva.month,
      fechaReserva.day,
    );

    final fechaLimiteSinHora = DateTime(
      fechaLimite.year,
      fechaLimite.month,
      fechaLimite.day,
    );

    return fechaReservaSinHora.isBefore(fechaLimiteSinHora) ||
        fechaReservaSinHora.isAtSameMomentAs(
          fechaLimiteSinHora,
        );
  }

  String _formatearDuracion(int minutos) {
    if (minutos < 60) {
      return ' minutos';
    }

    final horas = minutos ~/ 60;
    final minutosRestantes = minutos % 60;

    if (minutosRestantes == 0) {
      return horas == 1 ? '1 hora' : ' horas';
    }

    if (horas == 1) {
      return '1 hora y  minutos';
    }

    return ' horas y  minutos';
  }
  bool puedeCancelarReserva(
    String fecha,
    String hora,
  ) {
    try {
      final parts = fecha.split('-');

      if (parts.length != 3) return false;

      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final day = int.parse(parts[2]);

      final timeParts = hora.split(':');

      if (timeParts.length != 2) return false;

      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final now = DateTime.now();

      final reservationTime = DateTime(
        year,
        month,
        day,
        hour,
        minute,
      );

      final horaAntes = reservationTime.subtract(
        const Duration(hours: 1),
      );

      return now.isBefore(horaAntes);
    } catch (e) {
      return false;
    }
  }
}




















