import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../domain/entities/agenda_task.dart';
import '../../domain/repositories/agenda_repository.dart';

class AgendaRepositoryImpl implements AgendaRepository {
  final Box box;
  final Box settingsBox;

  AgendaRepositoryImpl({Box? box, Box? settingsBox})
      : box = box ?? Hive.box(HiveBoxes.agenda),
        settingsBox = settingsBox ?? Hive.box(HiveBoxes.settings);

  /// Los ids de notificacion de la Agenda empiezan aqui para no chocar con
  /// los recordatorios diarios fijos (ver NotificationIds).
  static const firstNotificationId = 10000;

  @override
  List<AgendaTask> getAll() {
    final result = <AgendaTask>[];
    for (final raw in box.values) {
      if (raw is Map) {
        try {
          result.add(AgendaTask.fromMap(raw));
        } catch (_) {
          // Un registro dañado no debe impedir cargar el resto.
        }
      }
    }
    result.sort((a, b) => a.start.compareTo(b.start));
    return result;
  }

  @override
  AgendaTask? getById(String id) {
    final raw = box.get(id);
    return raw is Map ? AgendaTask.fromMap(raw) : null;
  }

  @override
  Future<void> save(AgendaTask task) => box.put(task.id, task.toMap());

  @override
  Future<void> delete(String id) => box.delete(id);

  @override
  Future<int> nextNotificationId() async {
    final current = settingsBox.get(SettingsKeys.agendaNotificationCounter) as int? ?? firstNotificationId;
    // Despues de ~2 mil millones de tareas vuelve a empezar; en la practica nunca.
    final next = current >= 0x7FFFFFF0 ? firstNotificationId : current + 1;
    await settingsBox.put(SettingsKeys.agendaNotificationCounter, next);
    return current;
  }
}
