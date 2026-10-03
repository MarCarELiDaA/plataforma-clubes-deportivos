import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import '../config/app_config.dart';
import '../models/club/instalacion.dart';

class ReservaService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static bool _publicTimeZonesInitialized = false;

  DateTime getInicioHorarioPublico(DateTime date, String time) {
    if (!_publicTimeZonesInitialized) {
      if (!tz.timeZoneDatabase.isInitialized) {
        tzdata.initializeTimeZones();
      }
      _publicTimeZonesInitialized = true;
    }
    final parts = time.split(':');
    return tz.TZDateTime(
      tz.getLocation(AppConfig.club.zonaHoraria),
      date.year, date.month, date.day,
      int.parse(parts[0]), int.parse(parts[1]),
    ).toUtc();
  }

  Stream<List<({DateTime inicio, DateTime fin})>>
      getDisponibilidadPublicaStream(String instalacionId, String fecha) {
      final day = DateTime.parse(fecha);
      String formatDate(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      return _firestore.collection('clubes').doc(AppConfig.club.clubId)
          .collection('disponibilidadPublica')
          .where('instalacionId', isEqualTo: instalacionId)
          .where('fecha', whereIn: [
            formatDate(DateTime(day.year, day.month, day.day - 1)),
            fecha,
            formatDate(DateTime(day.year, day.month, day.day + 1)),
          ])
          .snapshots(includeMetadataChanges: true)
          .map((snapshot) {
      if (snapshot.metadata.isFromCache) {
        throw StateError('Disponibilidad pendiente de confirmar con el servidor');
      }
      return snapshot.docs.map((doc) {
        final data = doc.data();
        if (data.length != 4 || data['instalacionId'] != instalacionId ||
            data['fecha'] is! String || data['horaInicio'] is! String ||
            data['duracionMinutos'] is! int) {
          throw const FormatException('Intervalo inválido');
        }
        final duration = data['duracionMinutos'] as int;
        final time = data['horaInicio'] as String;
        if (duration <= 0 ||
            !RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(time)) {
          throw const FormatException('Intervalo inválido');
        }
        final inicio = getInicioHorarioPublico(
          DateTime.parse(data['fecha'] as String), time,
        );
        final fin = inicio.add(Duration(minutes: duration));
        return (inicio: inicio, fin: fin);
      }).toList();
    });
  }

  Future<String> crearReserva(Map<String, dynamic> reservaData) async {
    try {
      final docRef = _firestore.collection('reservas').doc();
      final publicRef = _firestore.collection('clubes')
          .doc(AppConfig.club.clubId)
          .collection('disponibilidadPublica').doc(docRef.id);
      final batch = _firestore.batch();
      batch.set(docRef, reservaData);
      batch.set(publicRef, {
        'instalacionId': reservaData['instalacionId'],
        'fecha': reservaData['fecha'],
        'horaInicio': reservaData['horaInicio'],
        'duracionMinutos': reservaData['duracionMinutos'],
      });
      await batch.commit();

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
      final duration = reservaData['duracionMinutos'] as int;
      if (duration <= 0) throw Exception('Duración de reserva inválida');
      final start = DateTime.parse('${fecha}T$horaInicio:00');
      final end = start.add(Duration(minutes: duration));
      String formatDate(DateTime value) =>
          '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
      final previousDay = DateTime(start.year, start.month, start.day - 1);
      final nextDay = DateTime(start.year, start.month, start.day + 1);

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
            .where('fecha', whereIn: [formatDate(previousDay), fecha, formatDate(nextDay)])
            .where('estadoReserva', isEqualTo: 'CONFIRMADA')
            .get();

        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final existingStart = DateTime.parse(
            '${data['fecha']}T${data['horaInicio']}:00',
          );
          final existingDuration = data['duracionMinutos'] as int;
          if (existingDuration <= 0) {
            throw Exception('No se pudo verificar la ocupación');
          }
          final existingEnd = existingStart.add(Duration(minutes: existingDuration));
          if (start.isBefore(existingEnd) && end.isAfter(existingStart)) {
            throw Exception('Este horario se solapa con una reserva existente');
          }
        }

        final docRef = _firestore.collection('reservas').doc();

        transaction.set(docRef, reservaData);
        final publicRef = _firestore.collection('clubes')
            .doc(AppConfig.club.clubId)
            .collection('disponibilidadPublica').doc(docRef.id);
        transaction.set(publicRef, {
          'instalacionId': instalacionId,
          'fecha': fecha,
          'horaInicio': horaInicio,
          'duracionMinutos': duration,
        });

        return docRef.id;
      });
    } catch (e) {
      rethrow;
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
      final batch = _firestore.batch();
      batch.update(_firestore.collection('reservas').doc(reservaId), {
        'estadoReserva': 'CANCELADA_POR_USUARIO',
      });
      batch.delete(_firestore.collection('clubes')
          .doc(AppConfig.club.clubId)
          .collection('disponibilidadPublica').doc(reservaId));
      await batch.commit();
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
        final duracion = doc.data()['duracionMinutos'] as int? ?? 90;

        totalHoras += duracion;
      }

      return totalHoras;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> puedeReservarEnDia(
    String usuarioId,
    String fecha,
    int duracionNueva,
    Instalacion instalacion,
  ) async {
    final horasReservadas = await calcularHorasReservadasEnDia(
      usuarioId,
      fecha,
    );

    final horasTotales = horasReservadas + duracionNueva;

    return horasTotales <= instalacion.maxMinutosPorDia;
  }

  bool validarAntelacion(DateTime fechaReserva, int maxDiasAntelacion) {
    final hoy = DateTime.now();

    final fechaLimite = hoy.add(Duration(days: maxDiasAntelacion));

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
        fechaReservaSinHora.isAtSameMomentAs(fechaLimiteSinHora);
  }

  bool puedeCancelarReserva(String fecha, String hora) {
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

      final reservationTime = DateTime(year, month, day, hour, minute);

      final horaAntes = reservationTime.subtract(const Duration(hours: 1));

      return now.isBefore(horaAntes);
    } catch (e) {
      return false;
    }
  }
}
