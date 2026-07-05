import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Notificaciones locales (sin Firebase ni servicios externos). Los ids
/// de las notificaciones diarias estan fijos para poder actualizarlas o
/// cancelarlas de forma individual.
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static const idMorning = 1;
  static const idReading = 2;
  static const idReflection = 3;
  static const idRosary = 4;

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Si no se puede determinar la zona horaria del dispositivo, se usa UTC.
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _plugin.initialize(settings);
    _initialized = true;
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static tz.TZDateTime _nextInstanceOfTime(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  static Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfTime(time),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'luz_para_hoy_daily',
          'Recordatorios diarios',
          channelDescription: 'Recordatorios de lectura, oracion y reflexion diaria',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> scheduleDefaultReminders() async {
    await requestPermissions();
    await _scheduleDaily(
      id: idMorning,
      title: 'Buenos dias',
      body: 'Comienza el dia con un momento de oracion.',
      time: const TimeOfDay(hour: 7, minute: 0),
    );
    await _scheduleDaily(
      id: idReading,
      title: 'Es momento de leer la Palabra',
      body: 'Tu lectura biblica de hoy te espera.',
      time: const TimeOfDay(hour: 12, minute: 0),
    );
    await _scheduleDaily(
      id: idReflection,
      title: 'Hoy te espera una reflexion',
      body: 'Tomate un momento para la reflexion del dia.',
      time: const TimeOfDay(hour: 17, minute: 0),
    );
    await _scheduleDaily(
      id: idRosary,
      title: 'No olvides tu Rosario',
      body: 'Un espacio para orar el Rosario de hoy.',
      time: const TimeOfDay(hour: 20, minute: 0),
    );
  }

  static Future<void> cancelAll() => _plugin.cancelAll();
}
