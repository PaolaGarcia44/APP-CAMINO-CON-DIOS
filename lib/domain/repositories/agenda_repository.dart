import '../entities/agenda_task.dart';

abstract class AgendaRepository {
  List<AgendaTask> getAll();
  AgendaTask? getById(String id);
  Future<void> save(AgendaTask task);
  Future<void> delete(String id);

  /// Reserva un id unico para la notificacion de una tarea nueva.
  Future<int> nextNotificationId();
}
