import '../../models/club/club_config.dart';
import '../../models/club/instalacion.dart';

class ClubConfigActual {
  static const ClubConfig config = ClubConfig(
    nombre: 'Pádel Navales',
    deporte: 'Pádel',
    logo: 'assets/images/logofinal1.png',
    telefono: '923 30 01 83',
    email: 'aytonavales@yahoo.es',
    direccion: 'Camino Martín Vicente, 4\n37882 Navales (Salamanca)',
    horario: 'Lunes a Domingo\n06:30 – 23:00',
    fondo: 'assets/images/fondo.png',

    administradores: [
      'martin.bautista.sanchez@gmail.com',
    ],

    // Módulos funcionales activos para este cliente.
    modulos: {
      'reservations': true,
      'payments': false,
      'accessControl': false,
      'notifications': true,
      'matches': false,
      'ranking': false,
        'padelLevel': true,
    },

    instalaciones: [
      Instalacion(
        id: 'pista_padel_1',
        nombre: 'Pista de Pádel Municipal de Navales',
        tipo: 'Pista de pádel',
        descripcion: 'Pista de pádel municipal',
        imagen: 'assets/images/pistanavales.png',
        horarios: [
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
        ],
        duracionReservaMinutos: 90,
        normas: [
          'Máximo 2 reservas por usuario y día.',
          'Las reservas del mismo día no pueden ser consecutivas.',
          'Las reservas tienen una duración de 1 hora y 30 minutos.',
          'Las reservas pueden cancelarse hasta 1 hora antes.',
          'Las reservas no son transferibles.',
        ],
        reservasActivas: true,
        pagosActivos: false,
        accesoDigitalActivo: false,
      ),
    ],
  );
}

