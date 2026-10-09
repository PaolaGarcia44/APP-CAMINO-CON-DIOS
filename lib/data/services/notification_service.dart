import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/entities/planned_notification.dart';

/// Canales de notificacion de Android. Cada uno aparece por separado en los
/// ajustes del sistema, para que el usuario pueda silenciarlos uno a uno.
enum NotificationChannel {
  dailyMessage('luz_daily_message', 'Mensaje del dia', 'Mensaje de fe y esperanza cada mañana'),
  reading('luz_bible_reading', 'Lectura biblica', 'Recordatorio para continuar la lectura de la Palabra'),
  reflection('luz_reflection', 'Reflexion diaria', 'Aviso de la reflexion del dia'),
  specialDates('luz_special_dates', 'Fechas especiales', 'Solemnidades y fiestas de la Iglesia'),
  agenda('luz_agenda', 'Recordatorios de Agenda', 'Avisos de las tareas de tu Agenda');

  final String id;
  final String title;
  final String description;
  const NotificationChannel(this.id, this.title, this.description);

  Importance get importance =>
      this == NotificationChannel.agenda ? Importance.high : Importance.defaultImportance;

  static NotificationChannel forKind(NotificationKind kind) => switch (kind) {
        NotificationKind.dailyMessage => dailyMessage,
        NotificationKind.reading => reading,
        NotificationKind.reflection => reflection,
        NotificationKind.specialDates => specialDates,
        NotificationKind.agenda => agenda,
      };
}

/// Envoltorio de flutter_local_notifications (notificaciones locales, sin
/// Firebase ni servicios externos).
class NotificationService {
  NotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;
  static String? _launchPayload;
  static final _taps = StreamController<String>.broadcast();

  /// Rutas a abrir cuando el usuario toca una notificacion con la app abierta.
  static Stream<String> get taps => _taps.stream;

  static bool get isAvailable => _initialized;

  static AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final locationName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(locationName));
    } catch (_) {
      // Si no se puede determinar la zona horaria del dispositivo, se usa UTC.
    }

    try {
      const androidInit = AndroidInitializationSettings('ic_stat_notification');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) _taps.add(payload);
        },
      );
      _initialized = true;

      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp ?? false) {
        _launchPayload = launch!.notificationResponse?.payload;
      }

      final android = _android;
      if (android != null) {
        for (final channel in NotificationChannel.values) {
          await android.createNotificationChannel(AndroidNotificationChannel(
            channel.id,
            channel.title,
            description: channel.description,
            importance: channel.importance,
          ));
        }
      }
    } catch (e) {
      // En plataformas sin soporte de notificaciones locales (web, pruebas y
      // algunos escritorios) el plugin no se puede inicializar; la app sigue
      // funcionando normalmente, solo sin recordatorios.
      debugPrint('Notificaciones no disponibles: $e');
    }
  }

  /// Ruta de la notificacion que abrio la app (solo se entrega una vez).
  static String? takeLaunchPayload() {
    final payload = _launchPayload;
    _launchPayload = null;
    return payload;
  }

  /// Pide permiso para mostrar notificaciones (Android 13+ e iOS).
  /// Devuelve false si el usuario lo nego.
  static Future<bool> requestPermission() async {
    if (!_initialized) return false;
    try {
      final android = _android;
      if (android != null) {
        return await android.requestNotificationsPermission() ?? true;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> areNotificationsAllowed() async {
    if (!_initialized) return false;
    try {
      return await _android?.areNotificationsEnabled() ?? true;
    } catch (_) {
      return true;
    }
  }

  /// En Android 12+ las alarmas exactas requieren un permiso especial. Sin
  /// el, los avisos llegan igual pero pueden retrasarse algunos minutos.
  static Future<bool> canScheduleExact() async {
    if (!_initialized) return false;
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return false;
    }
  }

  /// Abre la pantalla del sistema para permitir alarmas exactas.
  static Future<void> requestExactAlarms() async {
    if (!_initialized) return;
    try {
      await _android?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  /// Programa [n]. Los recordatorios de Agenda usan alarma exacta cuando el
  /// sistema lo permite; el resto puede llegar con unos minutos de margen.
  static Future<void> schedule(PlannedNotification n) async {
    if (!_initialized) return;
    final channel = NotificationChannel.forKind(n.kind);
    final exact = n.kind == NotificationKind.agenda;
    final when = tz.TZDateTime(
      tz.local,
      n.when.year,
      n.when.month,
      n.when.day,
      n.when.hour,
      n.when.minute,
    );
    // Una notificacion unica en el pasado no se puede programar.
    if (n.repeat == null && !when.isAfter(tz.TZDateTime.now(tz.local))) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.title,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: exact ? Priority.high : Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(n.body),
        category: exact ? AndroidNotificationCategory.reminder : null,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    var mode = AndroidScheduleMode.inexactAllowWhileIdle;
    if (exact && await canScheduleExact()) mode = AndroidScheduleMode.exactAllowWhileIdle;

    try {
      await _plugin.zonedSchedule(
        n.id,
        n.title,
        n.body,
        when,
        details,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: mode,
        matchDateTimeComponents: switch (n.repeat) {
          null => null,
          NotificationRepeat.daily => DateTimeComponents.time,
          NotificationRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
          NotificationRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
        },
        payload: n.payload,
      );
    } catch (e) {
      debugPrint('No se pudo programar la notificacion ${n.id}: $e');
    }
  }

  static Future<void> cancel(int id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id);
    } catch (_) {}
  }

  static Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
