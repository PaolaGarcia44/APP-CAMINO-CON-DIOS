import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/agenda_task.dart';
import '../../domain/usecases/agenda_queries.dart';
import 'notification_providers.dart';
import 'repository_providers.dart';

/// Estado de la Agenda: todas las tareas, persistidas en Hive.
class AgendaNotifier extends StateNotifier<List<AgendaTask>> {
  final Ref ref;
  AgendaNotifier(this.ref) : super(ref.read(agendaRepositoryProvider).getAll());

  void _reload() => state = ref.read(agendaRepositoryProvider).getAll();

  /// Crea una tarea nueva con id y notificacion propios.
  Future<AgendaTask> create({
    required String title,
    String? description,
    required DateTime start,
    TaskRepeat repeat = TaskRepeat.none,
    int? reminderMinutes,
  }) async {
    final repo = ref.read(agendaRepositoryProvider);
    final task = AgendaTask(
      id: 't${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      description: description,
      start: start,
      repeat: repeat,
      reminderMinutes: reminderMinutes,
      notificationId: await repo.nextNotificationId(),
      createdAt: DateTime.now(),
    );
    await save(task);
    return task;
  }

  /// Guarda la tarea y actualiza su recordatorio.
  Future<void> save(AgendaTask task) async {
    await ref.read(agendaRepositoryProvider).save(task);
    _reload();
    await ref.read(reminderSchedulerProvider).syncTask(task);
  }

  Future<void> delete(AgendaTask task) async {
    await ref.read(agendaRepositoryProvider).delete(task.id);
    _reload();
    await ref.read(reminderSchedulerProvider).cancelTask(task);
  }

  Future<void> toggleCompleted(AgendaTask task, DateTime day) => save(task.toggleCompletedOn(day));
}

final agendaProvider = StateNotifierProvider<AgendaNotifier, List<AgendaTask>>(
  (ref) => AgendaNotifier(ref),
);

/// Proximas tareas pendientes (para Inicio).
final upcomingTasksProvider = Provider<List<TaskOccurrence>>((ref) {
  final tasks = ref.watch(agendaProvider);
  return AgendaQueries.upcoming(tasks, DateTime.now(), days: 14, limit: 3);
});
