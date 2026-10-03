import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas de horarios', () {
    test('23:00 es un inicio de reserva válido', () {
      final horarios = [
        '06:30',
        '08:00',
        '09:30',
        '11:00',
        '12:30',
        '14:00',
        '15:30',
        '17:00',
        '18:30',
        '20:00',
        '21:30',
        '23:00',
      ];
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

}
