enum TaskRepeat { none, daily, weekly, monthly }

extension TaskRepeatX on TaskRepeat {
  String get label {
    switch (this) {
      case TaskRepeat.none:
        return 'No repetir';
      case TaskRepeat.daily:
        return 'Todos los dias';
      case TaskRepeat.weekly:
        return 'Cada semana';
      case TaskRepeat.monthly:
        return 'Cada mes';
    }
  }

  static TaskRepeat fromName(String? name) =>
      TaskRepeat.values.firstWhere((r) => r.name == name, orElse: () => TaskRepeat.none);
}

/// Opciones de recordatorio, en minutos antes de la tarea.
class ReminderOptions {
  ReminderOptions._();

  static const List<int> values = [0, 5, 10, 15, 30, 60, 1440];

  static String label(int? minutes) {
    if (minutes == null) return 'Sin recordatorio';
    if (minutes == 0) return 'A la hora de la tarea';
    if (minutes < 60) return '$minutes minutos antes';
    if (minutes == 60) return '1 hora antes';
    if (minutes == 1440) return '1 dia antes';
    return '${minutes ~/ 60} horas antes';
  }
}

/// Tarea de la Agenda. Se guarda en Hive como Map (sin adaptadores).
///
/// - [start] guarda la fecha y hora de la tarea (o de su primera
///   repeticion).
/// - Las tareas sin repeticion usan [completed]; las repetitivas guardan en
///   [completedDates] los dias (yyyy-MM-dd) en que se completaron, para que
///   completar "Leer la Biblia" hoy no la marque como hecha mañana.
/// - Las mensuales se repiten el mismo dia del mes; los meses que no tienen
///   ese dia (p. ej. 31 de febrero) se omiten.
class AgendaTask {
  final String id;
  final String title;
  final String? description;
  final DateTime start;
  final TaskRepeat repeat;
  final int? reminderMinutes;
  final bool completed;
  final Set<String> completedDates;
  final int notificationId;
  final DateTime createdAt;

  const AgendaTask({
    required this.id,
    required this.title,
    this.description,
    required this.start,
    this.repeat = TaskRepeat.none,
    this.reminderMinutes,
    this.completed = false,
    this.completedDates = const {},
    required this.notificationId,
    required this.createdAt,
  });

  bool get isRepeating => repeat != TaskRepeat.none;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Si la tarea ocurre en el dia [day] (ignora la hora).
  bool occursOn(DateTime day) {
    final target = dateOnly(day);
    final first = dateOnly(start);
    if (target.isBefore(first)) return false;
    switch (repeat) {
      case TaskRepeat.none:
        return target == first;
      case TaskRepeat.daily:
        return true;
      case TaskRepeat.weekly:
        return target.weekday == first.weekday;
      case TaskRepeat.monthly:
        return target.day == first.day;
    }
  }

  /// Fecha y hora de la ocurrencia en [day], o null si ese dia no ocurre.
  DateTime? occurrenceOn(DateTime day) {
    if (!occursOn(day)) return null;
    return DateTime(day.year, day.month, day.day, start.hour, start.minute);
  }

  bool isCompletedOn(DateTime day) => isRepeating ? completedDates.contains(dayKey(day)) : completed;

  /// Primera ocurrencia cuya hora es igual o posterior a [from].
  DateTime? nextOccurrence(DateTime from) {
    if (!isRepeating) return start.isBefore(from) ? null : start;
    var day = dateOnly(from.isBefore(start) ? start : from);
    // Basta con revisar un poco mas de un año para cualquier repeticion.
    for (var i = 0; i < 400; i++) {
      final occurrence = occurrenceOn(day);
      if (occurrence != null && !occurrence.isBefore(from)) return occurrence;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return null;
  }

  /// Todas las ocurrencias entre [from] y [to] (ambos dias incluidos).
  List<DateTime> occurrencesBetween(DateTime from, DateTime to) {
    final result = <DateTime>[];
    var day = dateOnly(from);
    final end = dateOnly(to);
    while (!day.isAfter(end)) {
      final occurrence = occurrenceOn(day);
      if (occurrence != null) result.add(occurrence);
      if (!isRepeating && occurrence != null) break;
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return result;
  }

  AgendaTask copyWith({
    String? title,
    String? description,
    bool clearDescription = false,
    DateTime? start,
    TaskRepeat? repeat,
    int? reminderMinutes,
    bool clearReminder = false,
    bool? completed,
    Set<String>? completedDates,
    int? notificationId,
  }) {
    return AgendaTask(
      id: id,
      title: title ?? this.title,
      description: clearDescription ? null : (description ?? this.description),
      start: start ?? this.start,
      repeat: repeat ?? this.repeat,
      reminderMinutes: clearReminder ? null : (reminderMinutes ?? this.reminderMinutes),
      completed: completed ?? this.completed,
      completedDates: completedDates ?? this.completedDates,
      notificationId: notificationId ?? this.notificationId,
      createdAt: createdAt,
    );
  }

  /// Marca o desmarca como completada la ocurrencia del dia [day].
  AgendaTask toggleCompletedOn(DateTime day) {
    if (!isRepeating) return copyWith(completed: !completed);
    final key = dayKey(day);
    final dates = {...completedDates};
    if (!dates.remove(key)) dates.add(key);
    return copyWith(completedDates: dates);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'start': start.toIso8601String(),
        'repeat': repeat.name,
        'reminderMinutes': reminderMinutes,
        'completed': completed,
        'completedDates': completedDates.toList(),
        'notificationId': notificationId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory AgendaTask.fromMap(Map<dynamic, dynamic> map) {
    return AgendaTask(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      start: DateTime.parse(map['start'] as String),
      repeat: TaskRepeatX.fromName(map['repeat'] as String?),
      reminderMinutes: map['reminderMinutes'] as int?,
      completed: map['completed'] as bool? ?? false,
      completedDates: ((map['completedDates'] as List?) ?? const []).cast<String>().toSet(),
      notificationId: map['notificationId'] as int,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
