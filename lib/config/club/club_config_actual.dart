import '../../models/club/club_config.dart';
import '../../models/club/instalacion.dart';

class ClubConfigActual {
  static const ClubConfig config = ClubConfig(
    // ==========================================================
    // 1. IDENTIDAD DEL CLUB
    // ==========================================================

    nombre: 'Pádel Navales',
    deporte: 'Pádel',

    logo: 'assets/images/logofinal1.png',

    telefono: '923 30 01 83',
    email: 'aytonavales@yahoo.es',

    direccion: 'Camino Martín Vicente, 4\n37882 Navales (Salamanca)',

    horario: 'Lunes a Domingo\n06:30 – 23:00',

    // Se mantiene la ruta actual por compatibilidad.
    fondo: 'assets/images/fondo.png',

    // ==========================================================
    // 2. APARIENCIA GENERAL
    // ==========================================================

    // Azul de identidad del club.
    colorPrimario: '#071A42',

    // Verde para botones, controles y estados activos.
    colorSecundario: '#50C878',

    // Amarillo para acentos visuales.
    colorAcento: '#FFD700',

    // Fondo general claro de la aplicación.
    colorFondo: '#F7F9FC',

    // Fondo de tarjetas, diálogos y superficies.
    colorSuperficie: '#FFFFFF',

    // Superficie alternativa para zonas secundarias.
    colorSuperficieAlternativa: '#F1F5F9',

    // Textos para el tema claro.
    colorTextoPrincipal: '#102033',
    colorTextoSecundario: '#526274',

    // Bordes y separadores.
    colorBorde: '#D7DEE7',

    // Estilo visual inicial.
    estilo: 'claro',

    // ==========================================================
    // 3. IMÁGENES DEL CLUB
    // ==========================================================

    // De momento usamos la imagen actual como hero.
    // Más adelante podremos sustituirla por una imagen propia.
    hero: 'assets/images/pistanavales.png',

    imagenInstalaciones: 'assets/images/pistanavales.png',

    imagenReservas: 'assets/images/pistanavales.png',

    imagenInformacion: 'assets/images/pistanavales.png',

    imagenBienvenida: 'assets/images/pistanavales.png',

    // Imágenes adicionales concretas.
    imagenes: {
      // Ejemplos preparados para futuras imágenes:
      // 'promocion': 'assets/images/promocion.png',
      // 'evento': 'assets/images/evento.png',
      // 'noticias': 'assets/images/noticias.png',
    },

    // ==========================================================
    // 4. FUNCIONALIDAD Y CONTENIDO
    // ==========================================================
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
