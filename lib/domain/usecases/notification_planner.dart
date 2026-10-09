import '../../core/utils/daily_selector.dart';
import '../../data/models/quote_model.dart';
import '../entities/agenda_task.dart';
import '../entities/notification_preferences.dart';
import '../entities/planned_notification.dart';

/// Ids fijos de las notificaciones. Las tareas de la Agenda usan ids desde
/// 10000 (ver AgendaRepositoryImpl.firstNotificationId).
class NotificationIds {
  NotificationIds._();

  static const reading = 2;
  static const reflection = 3;
  static const dailyMessageBase = 100; // 100..(100 + dailyMessageDays)
  static const specialDateBase = 300; // 300..(300 + maxSpecialDates)
}

/// Fecha especial a notificar (solemnidad, fiesta...).
class SpecialDate {
  final DateTime date;
  final String name;
  const SpecialDate(this.date, this.name);
}

/// Decide que notificaciones programar. Es logica pura (sin plugins), para
/// poder probarla; NotificationService solo traduce el plan al sistema.
class NotificationPlanner {
  NotificationPlanner._();

  /// El mensaje del dia cambia cada dia, asi que se programan avisos
  /// individuales para los proximos dias. Se reprograman cada vez que se
  /// abre la app, de modo que la ventana siempre avanza.
  static const dailyMessageDays = 30;
  static const specialDateDays = 90;
  static const maxSpecialDates = 60;

  static String greetingTitle(DayTime time) {
    if (time.hour >= 5 && time.hour < 12) return 'Buenos días 🌅';
    if (time.hour >= 12 && time.hour < 19) return 'Buenas tardes ☀️';
    return 'Buenas noches 🌙';
  }

  static List<PlannedNotification> dailyMessages({
    required DateTime now,
    required DayTime time,
    required List<QuoteModel> messages,
    int days = dailyMessageDays,
  }) {
    if (messages.isEmpty) return const [];
    final result = <PlannedNotification>[];
    for (var i = 0; i < days; i++) {
      final day = DateTime(now.year, now.month, now.day + i);
      final when = time.on(day);
      if (!when.isAfter(now)) continue;
      final message = messages[DailySelector.indexFor(day, messages.length)];
      result.add(PlannedNotification(
        id: NotificationIds.dailyMessageBase + i,
        title: greetingTitle(time),
        body: message.fullText,
        when: when,
        kind: NotificationKind.dailyMessage,
        payload: '/home',
      ));
    }
    return result;
  }

  static PlannedNotification reading(DayTime time, DateTime now) => PlannedNotification(
        id: NotificationIds.reading,
        title: 'Lectura bíblica',
        body: 'Es momento de continuar tu lectura de la Palabra 📖',
        when: _nextDaily(time, now),
        kind: NotificationKind.reading,
        repeat: NotificationRepeat.daily,
        payload: '/bible',
      );

  static PlannedNotification reflection(DayTime time, DateTime now) => PlannedNotification(
        id: NotificationIds.reflection,
        title: 'Reflexión del día',
        body: 'Hoy te espera una nueva reflexión ✨',
        when: _nextDaily(time, now),
        kind: NotificationKind.reflection,
        repeat: NotificationRepeat.daily,
        payload: '/more/reflections',
      );

  static List<PlannedNotification> specialDates({
    required DateTime now,
    required DayTime time,
    required List<SpecialDate> dates,
  }) {
    final end = now.add(const Duration(days: specialDateDays));
    final upcoming = dates
        .map((d) => SpecialDate(time.on(d.date), d.name))
        .where((d) => d.date.isAfter(now) && d.date.isBefore(end))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    // Si coinciden dos celebraciones el mismo dia, se avisa una sola vez.
    final byDay = <String, List<String>>{};
    for (final d in upcoming) {
      byDay.putIfAbsent(AgendaTask.dayKey(d.date), () => []).add(d.name);
    }
    final result = <PlannedNotification>[];
    var i = 0;
    for (final entry in byDay.entries) {
      if (i >= maxSpecialDates) break;
      final day = DateTime.parse(entry.key);
      final names = entry.value;
      result.add(PlannedNotification(
        id: NotificationIds.specialDateBase + i,
        title: 'Hoy celebramos una fecha especial de nuestra fe ✨',
        body: names.length == 1
            ? 'Hoy es la celebración de ${names.first}.'
            : 'Hoy celebramos: ${names.join(' y ')}.',
        when: time.on(day),
        kind: NotificationKind.specialDates,
        payload: '/more/calendar',
      ));
      i++;
    }
    return result;
  }

  /// Recordatorio de una tarea, o null si no tiene, ya esta completada o
  /// su hora ya paso. Las repetitivas se programan una sola vez con
  /// repeticion del sistema (diaria, semanal o mensual).
  static PlannedNotification? agendaTask(AgendaTask task, DateTime now) {
    final offset = task.reminderMinutes;
    if (offset == null) return null;
    if (!task.isRepeating && task.completed) return null;

    // Primera ocurrencia cuyo aviso (hora - anticipacion) aun no ha pasado.
    final occurrence = task.nextOccurrence(now.add(Duration(minutes: offset)));
    if (occurrence == null) return null;
    final when = occurrence.subtract(Duration(minutes: offset));
    if (!when.isAfter(now)) return null;

    final hh = occurrence.hour.toString().padLeft(2, '0');
    final mm = occurrence.minute.toString().padLeft(2, '0');
    final timeText = offset == 0 ? 'Ahora · $hh:$mm' : '${_offsetText(offset)} · $hh:$mm';
    final description = task.description?.trim() ?? '';

    return PlannedNotification(
      id: task.notificationId,
      title: task.title,
      body: description.isEmpty ? timeText : '$timeText\n$description',
      when: when,
      kind: NotificationKind.agenda,
      repeat: switch (task.repeat) {
        TaskRepeat.none => null,
        TaskRepeat.daily => NotificationRepeat.daily,
        TaskRepeat.weekly => NotificationRepeat.weekly,
        TaskRepeat.monthly => NotificationRepeat.monthly,
      },
      payload: '/agenda',
    );
  }

  static String _offsetText(int minutes) {
    if (minutes < 60) return 'En $minutes minutos';
    if (minutes == 60) return 'En 1 hora';
    if (minutes == 1440) return 'Mañana';
    return 'En ${minutes ~/ 60} horas';
  }

  static DateTime _nextDaily(DayTime time, DateTime now) {
    final today = time.on(now);
    return today.isAfter(now) ? today : time.on(DateTime(now.year, now.month, now.day + 1));
  }

  /// Plan completo segun las preferencias del usuario.
  static List<PlannedNotification> build({
    required NotificationPreferences prefs,
    required DateTime now,
    required List<QuoteModel> messages,
    required List<SpecialDate> specialDates,
    required List<AgendaTask> tasks,
  }) {
    if (!prefs.enabled) return const [];
    return [
      if (prefs.dailyMessage) ...dailyMessages(now: now, time: prefs.dailyMessageTime, messages: messages),
      if (prefs.reading) reading(prefs.readingTime, now),
      if (prefs.reflection) reflection(prefs.reflectionTime, now),
      if (prefs.specialDates)
        ...NotificationPlanner.specialDates(
          now: now,
          time: prefs.specialDatesTime,
          dates: specialDates,
        ),
      if (prefs.agenda)
        for (final t in tasks)
          if (agendaTask(t, now) case final planned?) planned,
    ];
  }
}
