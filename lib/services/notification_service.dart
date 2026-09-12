import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    // Las notificaciones locales no se utilizan en la versión web.
    if (kIsWeb) return;

    if (_initialized) return;

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Solicitar permisos en Android 13+.
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Inicializar timezone.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Europe/Madrid'));

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // Manejar tap en notificación si es necesario.
  }

  Future<void> showReservationConfirmation() async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reservas_channel',
      'Reservas',
      channelDescription: 'Notificaciones de reservas de pádel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: '🎾 Reserva realizada correctamente',
      body: 'Tu reserva se ha guardado correctamente.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> scheduleReminder(
    String reservaId,
    String fecha,
    String hora,
  ) async {
    if (kIsWeb) return;

    // Parsear fecha y hora.
    final parts = fecha.split('/');
    if (parts.length != 3) return;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return;

    final timeParts = hora.split(':');
    if (timeParts.length != 2) return;

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) return;

    // Crear DateTime de la reserva.
    final now = DateTime.now();
    final reservationTime = DateTime(
      year,
      month,
      day,
      hour,
      minute,
    );

    // Calcular hora del recordatorio (1 hora antes).
    final reminderTime =
        reservationTime.subtract(const Duration(hours: 1));

    // Verificar si el recordatorio es en el futuro.
    if (reminderTime.isBefore(now)) {
      return;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reservas_channel',
      'Reservas',
      channelDescription: 'Notificaciones de reservas de pádel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.zonedSchedule(
      id: reservaId.hashCode,
      title: '⏰ Recordatorio de reserva',
      body: 'Tienes una reserva de la pista de pádel dentro de una hora.',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
  }

  Future<void> showCancellationNotification() async {
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'reservas_channel',
      'Reservas',
      channelDescription: 'Notificaciones de reservas de pádel',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id: 1,
      title: 'Reserva cancelada',
      body: 'Tu reserva ha sido cancelada correctamente.',
      notificationDetails: platformChannelSpecifics,
    );
  }

  Future<void> cancelReminder(String reservaId) async {
    if (kIsWeb) return;

    await _notificationsPlugin.cancel(
      id: reservaId.hashCode,
    );
  }
}
