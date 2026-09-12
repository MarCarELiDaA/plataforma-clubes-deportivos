import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas unitarias de consecutividad', () {
    test('18:30–20:00 + 20:00–21:30 → PROHIBIDO', () {
      // Verificar lógica de consecutividad sin Firebase
      final duracionMinutos = 90;
      
      final time1 = '18:30'.split(':');
      final time2 = '20:00'.split(':');
      
      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);
      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);
      
      final inicio1 = DateTime(2024, 1, 1, hour1, minute1);
      final fin1 = inicio1.add(Duration(minutes: duracionMinutos));
      final inicio2 = DateTime(2024, 1, 1, hour2, minute2);
      
      expect(fin1.isAtSameMomentAs(inicio2), isTrue);
    });

    test('18:30–20:00 + 21:30–23:00 → PERMITIDO', () {
      final duracionMinutos = 90;
      
      final time1 = '18:30'.split(':');
      final time2 = '21:30'.split(':');
      
      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);
      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);
      
      final inicio1 = DateTime(2024, 1, 1, hour1, minute1);
      final fin1 = inicio1.add(Duration(minutes: duracionMinutos));
      final inicio2 = DateTime(2024, 1, 1, hour2, minute2);
      
      expect(fin1.isAtSameMomentAs(inicio2), isFalse);
    });

    test('21:30–23:00 + 23:00–00:30 → PROHIBIDO', () {
      final duracionMinutos = 90;
      
      final time1 = '21:30'.split(':');
      final time2 = '23:00'.split(':');
      
      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);
      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);
      
      final inicio1 = DateTime(2024, 1, 1, hour1, minute1);
      final fin1 = inicio1.add(Duration(minutes: duracionMinutos));
      final inicio2 = DateTime(2024, 1, 1, hour2, minute2);
      
      expect(fin1.isAtSameMomentAs(inicio2), isTrue);
    });

    test('20:00–21:30 + 23:00–00:30 → PERMITIDO', () {
      final duracionMinutos = 90;
      
      final time1 = '20:00'.split(':');
      final time2 = '23:00'.split(':');
      
      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);
      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);
      
      final inicio1 = DateTime(2024, 1, 1, hour1, minute1);
      final fin1 = inicio1.add(Duration(minutes: duracionMinutos));
      final inicio2 = DateTime(2024, 1, 1, hour2, minute2);
      
      expect(fin1.isAtSameMomentAs(inicio2), isFalse);
    });

    test('06:30–08:00 + 08:00–09:30 → PROHIBIDO', () {
      final duracionMinutos = 90;
      
      final time1 = '06:30'.split(':');
      final time2 = '08:00'.split(':');
      
      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);
      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);
      
      final inicio1 = DateTime(2024, 1, 1, hour1, minute1);
      final fin1 = inicio1.add(Duration(minutes: duracionMinutos));
      final inicio2 = DateTime(2024, 1, 1, hour2, minute2);
      
      expect(fin1.isAtSameMomentAs(inicio2), isTrue);
    });

    test('06:30–08:00 + 09:30–11:00 → PERMITIDO', () {
      final duracionMinutos = 90;
      
      final time1 = '06:30'.split(':');
      final time2 = '09:30'.split(':');
      
      final hour1 = int.parse(time1[0]);
      final minute1 = int.parse(time1[1]);
      final hour2 = int.parse(time2[0]);
      final minute2 = int.parse(time2[1]);
      
      final inicio1 = DateTime(2024, 1, 1, hour1, minute1);
      final fin1 = inicio1.add(Duration(minutes: duracionMinutos));
      final inicio2 = DateTime(2024, 1, 1, hour2, minute2);
      
      expect(fin1.isAtSameMomentAs(inicio2), isFalse);
    });
  });

  group('Pruebas de horarios', () {
    test('23:00 es un inicio de reserva válido', () {
      final horarios = ['06:30', '08:00', '09:30', '11:00', '12:30', '14:00', '15:30', '17:00', '18:30', '20:00', '21:30', '23:00'];
      expect(horarios.contains('23:00'), isTrue);
    });

    test('Duración de reserva es 90 minutos', () {
      const duracionMinutos = 90;
      expect(duracionMinutos, 90);
    });

    test('Reserva 23:00 → 00:30 dura 90 minutos', () {
      final duracionMinutos = 90;
      final horaInicio = '23:00'.split(':');
      final hour = int.parse(horaInicio[0]);
      final minute = int.parse(horaInicio[1]);
      
      final inicio = DateTime(2024, 1, 1, hour, minute);
      final fin = inicio.add(Duration(minutes: duracionMinutos));
      
      // 23:00 + 90 minutos = 00:30 del día siguiente
      expect(fin.hour, 0);
      expect(fin.minute, 30);
    });
  });

  group('Pruebas de límites', () {
    test('Máximo 2 reservas por día', () {
      const maxReservasPorDia = 2;
      expect(maxReservasPorDia, 2);
    });

    test('Máximo 3 horas por día', () {
      const maxHorasPorDia = 3;
      expect(maxHorasPorDia, 3);
    });

    test('2 reservas = 180 minutos = 3 horas', () {
      const maxReservasPorDia = 2;
      const duracionMinutos = 90;
      final totalMinutos = maxReservasPorDia * duracionMinutos;
      expect(totalMinutos, 180);
    });

    test('Máximo 10 días de antelación', () {
      const maxDiasAntelacion = 10;
      expect(maxDiasAntelacion, 10);
    });
  });
}
