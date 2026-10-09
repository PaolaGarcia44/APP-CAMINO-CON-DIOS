/// Hora del dia en minutos desde la medianoche (independiente de Flutter
/// para poder usarse en la capa de dominio y en pruebas).
class DayTime {
  final int hour;
  final int minute;
  const DayTime(this.hour, this.minute);

  int get minutes => hour * 60 + minute;
  factory DayTime.fromMinutes(int m) => DayTime((m ~/ 60) % 24, m % 60);

  DateTime on(DateTime day) => DateTime(day.year, day.month, day.day, hour, minute);

  @override
  bool operator ==(Object other) => other is DayTime && other.minutes == minutes;
  @override
  int get hashCode => minutes;
}

/// Configuracion de notificaciones guardada localmente.
class NotificationPreferences {
  /// Interruptor general. Si esta apagado no se programa nada.
  final bool enabled;
  final bool dailyMessage;
  final DayTime dailyMessageTime;
  final bool reading;
  final DayTime readingTime;
  final bool reflection;
  final DayTime reflectionTime;
  final bool specialDates;
  final DayTime specialDatesTime;
  final bool agenda;

  const NotificationPreferences({
    this.enabled = false,
    this.dailyMessage = true,
    this.dailyMessageTime = const DayTime(7, 0),
    this.reading = true,
    this.readingTime = const DayTime(20, 0),
    this.reflection = false,
    this.reflectionTime = const DayTime(17, 0),
    this.specialDates = true,
    this.specialDatesTime = const DayTime(8, 0),
    this.agenda = true,
  });

  NotificationPreferences copyWith({
    bool? enabled,
    bool? dailyMessage,
    DayTime? dailyMessageTime,
    bool? reading,
    DayTime? readingTime,
    bool? reflection,
    DayTime? reflectionTime,
    bool? specialDates,
    DayTime? specialDatesTime,
    bool? agenda,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      dailyMessage: dailyMessage ?? this.dailyMessage,
      dailyMessageTime: dailyMessageTime ?? this.dailyMessageTime,
      reading: reading ?? this.reading,
      readingTime: readingTime ?? this.readingTime,
      reflection: reflection ?? this.reflection,
      reflectionTime: reflectionTime ?? this.reflectionTime,
      specialDates: specialDates ?? this.specialDates,
      specialDatesTime: specialDatesTime ?? this.specialDatesTime,
      agenda: agenda ?? this.agenda,
    );
  }

  Map<String, dynamic> toMap() => {
        'dailyMessage': dailyMessage,
        'dailyMessageTime': dailyMessageTime.minutes,
        'reading': reading,
        'readingTime': readingTime.minutes,
        'reflection': reflection,
        'reflectionTime': reflectionTime.minutes,
        'specialDates': specialDates,
        'specialDatesTime': specialDatesTime.minutes,
        'agenda': agenda,
      };

  /// [enabled] se guarda aparte (clave historica `notifications_enabled`).
  factory NotificationPreferences.fromMap(Map<dynamic, dynamic>? map, {required bool enabled}) {
    const d = NotificationPreferences();
    if (map == null) return d.copyWith(enabled: enabled);
    DayTime time(String key, DayTime fallback) {
      final v = map[key];
      return v is int ? DayTime.fromMinutes(v) : fallback;
    }

    return NotificationPreferences(
      enabled: enabled,
      dailyMessage: map['dailyMessage'] as bool? ?? d.dailyMessage,
      dailyMessageTime: time('dailyMessageTime', d.dailyMessageTime),
      reading: map['reading'] as bool? ?? d.reading,
      readingTime: time('readingTime', d.readingTime),
      reflection: map['reflection'] as bool? ?? d.reflection,
      reflectionTime: time('reflectionTime', d.reflectionTime),
      specialDates: map['specialDates'] as bool? ?? d.specialDates,
      specialDatesTime: time('specialDatesTime', d.specialDatesTime),
      agenda: map['agenda'] as bool? ?? d.agenda,
    );
  }
}
