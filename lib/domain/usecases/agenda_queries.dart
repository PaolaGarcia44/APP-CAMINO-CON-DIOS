import '../entities/agenda_task.dart';

/// Una ocurrencia concreta de una tarea (las repetitivas tienen muchas).
class TaskOccurrence {
  final AgendaTask task;
  final DateTime at;

  const TaskOccurrence(this.task, this.at);

  bool get completed => task.isCompletedOn(at);
}

/// Consultas puras sobre la lista de tareas, usadas por la Agenda y el Inicio.
class AgendaQueries {
  AgendaQueries._();

  static int _byTime(TaskOccurrence a, TaskOccurrence b) => a.at.compareTo(b.at);

  /// Tareas del dia [day], ordenadas por hora.
  static List<TaskOccurrence> forDay(List<AgendaTask> tasks, DateTime day) {
    return [
      for (final t in tasks)
        if (t.occurrenceOn(day) case final at?) TaskOccurrence(t, at),
    ]..sort(_byTime);
  }

  /// Proximas ocurrencias sin completar desde [now] hasta [days] dias despues.
  static List<TaskOccurrence> upcoming(
    List<AgendaTask> tasks,
    DateTime now, {
    int days = 30,
    int limit = 50,
  }) {
    final end = now.add(Duration(days: days));
    final result = <TaskOccurrence>[];
    for (final t in tasks) {
      for (final at in t.occurrencesBetween(now, end)) {
        if (at.isBefore(now)) continue;
        final occurrence = TaskOccurrence(t, at);
        if (!occurrence.completed) result.add(occurrence);
      }
    }
    result.sort(_byTime);
    return result.take(limit).toList();
  }

  /// Pendientes: tareas unicas sin completar (incluidas las vencidas) y las
  /// repeticiones de hoy que aun no se completaron.
  static List<TaskOccurrence> pending(List<AgendaTask> tasks, DateTime now) {
    final result = <TaskOccurrence>[];
    for (final t in tasks) {
      if (!t.isRepeating) {
        if (!t.completed) result.add(TaskOccurrence(t, t.start));
      } else if (t.occurrenceOn(now) case final at? when !t.isCompletedOn(now)) {
        result.add(TaskOccurrence(t, at));
      }
    }
    return result..sort(_byTime);
  }

  /// Completadas: tareas unicas hechas y cada dia completado de las
  /// repetitivas, de la mas reciente a la mas antigua.
  static List<TaskOccurrence> completed(List<AgendaTask> tasks) {
    final result = <TaskOccurrence>[];
    for (final t in tasks) {
      if (!t.isRepeating) {
        if (t.completed) result.add(TaskOccurrence(t, t.start));
      } else {
        for (final key in t.completedDates) {
          final day = DateTime.tryParse(key);
          if (day != null) {
            result
                .add(TaskOccurrence(t, DateTime(day.year, day.month, day.day, t.start.hour, t.start.minute)));
          }
        }
      }
    }
    return result..sort((a, b) => b.at.compareTo(a.at));
  }

  /// Si hay al menos una tarea en [day] (para los puntos del calendario).
  static bool hasTasksOn(List<AgendaTask> tasks, DateTime day) => tasks.any((t) => t.occursOn(day));
}
