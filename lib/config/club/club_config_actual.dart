import '../../models/club/actividad.dart';
import '../../models/club/club_config.dart';
import '../../models/club/instalacion.dart';

class ClubConfigActual {
  static const ClubConfig config = ClubConfig(
    nombre: 'Club Deportivo Ejemplo',
    deporte: 'Deporte y bienestar',

    logo: 'assets/images/logofinal1.jpeg',

    telefono: '900 000 000',
    email: 'info@clubdeportivoejemplo.es',

    direccion: 'Avenida del Deporte, 1\n00000 Ciudad',

    horario: 'Lunes a Domingo\n08:00 – 22:00',

    fondo: 'assets/images/fondo.png',

    colorPrimario: '#071A42',
    colorSecundario: '#50C878',
    colorAcento: '#FFD700',

    colorFondo: '#F7F9FC',
    colorSuperficie: '#FFFFFF',
    colorSuperficieAlternativa: '#F1F5F9',

    colorTextoPrincipal: '#102033',
    colorTextoSecundario: '#526274',

    colorBorde: '#D7DEE7',

    estilo: 'claro',

    hero: 'assets/images/home_hero.jpeg',
    imagenLogin: 'assets/images/login_banner.jpeg',
    menuIcon: 'menuRounded',

    imagenInstalaciones: 'assets/images/pistanavales.png',
    imagenReservas: 'assets/images/pistanavales.png',
    imagenInformacion: 'assets/images/pistanavales.png',
    imagenBienvenida: 'assets/images/pistanavales.png',

    imagenes: {},

    administradores: ['martin.bautista.sanchez@gmail.com'],

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
        id: 'instalacion_deportiva_1',
        nombre: 'Pista deportiva de ejemplo',
        tipo: 'Instalación deportiva',
        descripcion: 'Instalación deportiva configurable por el cliente.',
        imagen: 'assets/images/pistanavales.png',
        horarios: [
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

    actividades: [
      Actividad(
        id: 'padel',
        nombre: 'Pádel',
        tipo: 'Pádel',
        descripcion: 'Reserva de pistas de pádel.',
        imagen: 'assets/images/banner_padel.jpeg',
        icono: 'sports_tennis',
        instalaciones: [
          Instalacion(
            id: 'pista_padel_1',
            nombre: 'Pista de Pádel',
            tipo: 'Pista de pádel',
            descripcion: 'Pista de pádel configurable.',
            imagen: 'assets/images/banner_padel.jpeg',
            horarios: [
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
            ],
            duracionReservaMinutos: 90,
            maxReservasPorDia: 2,
            maxMinutosPorDia: 180,
            maxDiasAntelacion: 10,
            minutosAntelacionCancelacion: 60,
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
      ),
      Actividad(
        id: 'tenis',
        nombre: 'Tenis',
        tipo: 'Tenis',
        descripcion: 'Reserva de pistas de tenis.',
        imagen: 'assets/images/banner_tenis.jpeg',
        icono: 'sports_tennis',
        instalaciones: [
          Instalacion(
            id: 'pista_tenis_1',
            nombre: 'Pista de Tenis',
            tipo: 'Pista de tenis',
            descripcion: 'Pista de tenis configurable.',
            imagen: 'assets/images/banner_tenis.jpeg',
            horarios: [
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
            ],
            duracionReservaMinutos: 90,
            maxReservasPorDia: 2,
            maxMinutosPorDia: 180,
            maxDiasAntelacion: 10,
            minutosAntelacionCancelacion: 60,
            normas: [
              'Las condiciones de reserva serán configurables por el cliente.',
            ],
            reservasActivas: true,
            pagosActivos: false,
            accesoDigitalActivo: false,
          ),
        ],
      ),
      Actividad(
        id: 'gimnasio',
        nombre: 'Gimnasio',
        tipo: 'Gimnasio',
        descripcion: 'Acceso y actividades del gimnasio.',
        imagen: 'assets/images/banner_gym.jpeg',
        icono: 'fitness_center',
        instalaciones: [
          Instalacion(
            id: 'gimnasio_1',
            nombre: 'Gimnasio',
            tipo: 'Gimnasio',
            descripcion: 'Espacio de gimnasio configurable.',
            imagen: 'assets/images/banner_gym.jpeg',
            horarios: [
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
            ],
            duracionReservaMinutos: 60,
            maxReservasPorDia: 1,
            maxMinutosPorDia: 60,
            maxDiasAntelacion: 10,
            minutosAntelacionCancelacion: 60,
            normas: [
              'Las condiciones de reserva serán configurables por el cliente.',
            ],
            reservasActivas: true,
            pagosActivos: false,
            accesoDigitalActivo: false,
          ),
        ],
      ),
    ],
  );
}