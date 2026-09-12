import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:padel_navales/models/usuario.dart';

void main() {
  group('Usuario Simplificado Tests', () {
    test('fromMap maneja usuarios nuevos con campos de aceptaciones', () {
      final timestamp = Timestamp.fromDate(
        DateTime(2024, 1, 15, 10, 30),
      );

      final map = {
        'nombre': 'Test User',
        'email': 'test@example.com',
        'telefono': '123456789',
        'nivelPadel': 3.5,
        'fechaRegistro': Timestamp.fromDate(
          DateTime(2024, 1, 1),
        ),
        'role': 'user',
        'status': 'approved',
        'aceptaCondiciones': true,
        'aceptaPrivacidad': true,
        'fechaAceptaciones': timestamp,
        'versionCondiciones': '1.0',
        'versionPrivacidad': '1.0',
      };

      final usuario = Usuario.fromMap(map);

      expect(usuario.aceptaCondiciones, isTrue);
      expect(usuario.aceptaPrivacidad, isTrue);
      expect(usuario.fechaAceptaciones, isNotNull);
      expect(usuario.fechaAceptaciones!.year, equals(2024));
      expect(usuario.fechaAceptaciones!.month, equals(1));
      expect(usuario.fechaAceptaciones!.day, equals(15));
    });

    test('fromMap maneja usuarios antiguos sin campos de aceptaciones', () {
      final map = {
        'nombre': 'Old User',
        'email': 'old@example.com',
        'telefono': '987654321',
        'nivelPadel': 2.0,
        'fechaRegistro': Timestamp.fromDate(
          DateTime(2023, 6, 15),
        ),
        'role': 'user',
        'status': 'approved',
      };

      final usuario = Usuario.fromMap(map);

      expect(usuario.aceptaCondiciones, isNull);
      expect(usuario.aceptaPrivacidad, isNull);
      expect(usuario.fechaAceptaciones, isNull);
      expect(usuario.versionCondiciones, isNull);
      expect(usuario.versionPrivacidad, isNull);
    });

    test('toMap guarda correctamente los campos de aceptaciones', () {
      final usuario = Usuario(
        nombre: 'Test User',
        email: 'test@example.com',
        telefono: '123456789',
        nivelPadel: 3.5,
        fechaRegistro: DateTime(2024, 1, 1),
        role: 'user',
        status: 'approved',
        aceptaCondiciones: true,
        aceptaPrivacidad: true,
        fechaAceptaciones: DateTime(
          2024,
          1,
          15,
          10,
          30,
        ),
        versionCondiciones: '1.0',
        versionPrivacidad: '1.0',
      );

      final map = usuario.toMap();

      expect(map['aceptaCondiciones'], isTrue);
      expect(map['aceptaPrivacidad'], isTrue);
      expect(map['fechaAceptaciones'], isA<DateTime>());
      expect(map['versionCondiciones'], equals('1.0'));
      expect(map['versionPrivacidad'], equals('1.0'));
    });
  });
}