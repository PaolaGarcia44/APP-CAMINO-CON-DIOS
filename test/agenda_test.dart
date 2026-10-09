import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:luz_para_hoy/data/repositories/agenda_repository_impl.dart';
import 'package:luz_para_hoy/domain/entities/agenda_task.dart';
import 'package:luz_para_hoy/domain/usecases/agenda_queries.dart';

AgendaTask task({
  String id = 't1',
  String title = 'Estudiar Python',
  required DateTime start,
  TaskRepeat repeat = TaskRepeat.none,
  int? reminder,
}) =>
    AgendaTask(
      id: id,
      title: title,
      start: start,
      repeat: repeat,
      reminderMinutes: reminder,
      notificationId: 10000,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('Repeticion de tareas', () {
    test('sin repeticion ocurre solo su dia', () {
      final t = task(start: DateTime(2026, 10, 10, 18));
      expect(t.occursOn(DateTime(2026, 10, 10)), true);
      expect(t.occursOn(DateTime(2026, 10, 11)), false);
      expect(t.occurrenceOn(DateTime(2026, 10, 10)), DateTime(2026, 10, 10, 18));
    });

    test('diaria ocurre todos los dias desde su inicio', () {
      final t = task(start: DateTime(2026, 10, 7, 7), repeat: TaskRepeat.daily);
      expect(t.occursOn(DateTime(2026, 10, 6)), false);
      expect(t.occursOn(DateTime(2026, 10, 7)), true);
      expect(t.occursOn(DateTime(2027, 2, 14)), true);
    });

    test('semanal respeta el dia de la semana', () {
      final t = task(start: DateTime(2026, 10, 7, 9), repeat: TaskRepeat.weekly); // miercoles
      expect(t.occursOn(DateTime(2026, 10, 14)), true);
      expect(t.occursOn(DateTime(2026, 10, 15)), false);
    });

    test('mensual omite los meses sin ese dia', () {
      final t = task(start: DateTime(2026, 1, 31, 8), repeat: TaskRepeat.monthly);
      expect(t.occursOn(DateTime(2026, 2, 28)), false);
      expect(t.occursOn(DateTime(2026, 3, 31)), true);
      expect(t.nextOccurrence(DateTime(2026, 2, 1)), DateTime(2026, 3, 31, 8));
    });

    test('completar una repeticion no completa las demas', () {
      var t = task(start: DateTime(2026, 10, 7, 7), repeat: TaskRepeat.daily);
      t = t.toggleCompletedOn(DateTime(2026, 10, 7));
      expect(t.isCompletedOn(DateTime(2026, 10, 7)), true);
      expect(t.isCompletedOn(DateTime(2026, 10, 8)), false);
      t = t.toggleCompletedOn(DateTime(2026, 10, 7));
      expect(t.isCompletedOn(DateTime(2026, 10, 7)), false);
    });

    test('nextOccurrence salta la de hoy si la hora ya paso', () {
      final t = task(start: DateTime(2026, 10, 1, 7), repeat: TaskRepeat.daily);
      expect(t.nextOccurrence(DateTime(2026, 10, 7, 8)), DateTime(2026, 10, 8, 7));
      expect(t.nextOccurrence(DateTime(2026, 10, 7, 6)), DateTime(2026, 10, 7, 7));
    });
  });

  group('Consultas de la Agenda', () {
    final now = DateTime(2026, 10, 7, 12);
    final tasks = [
      task(id: 'a', title: 'Vencida', start: DateTime(2026, 10, 5, 9)),
      task(id: 'b', title: 'Leer la Biblia', start: DateTime(2026, 10, 1, 7), repeat: TaskRepeat.daily),
      task(id: 'c', title: 'Estudiar', start: DateTime(2026, 10, 10, 18)),
    ];

    test('tareas del dia ordenadas por hora', () {
      final day = AgendaQueries.forDay(tasks, DateTime(2026, 10, 10));
      expect(day.map((o) => o.task.id).toList(), ['b', 'c']);
    });

    test('proximas excluye lo pasado y respeta el limite', () {
      final upcoming = AgendaQueries.upcoming(tasks, now, days: 3);
      expect(upcoming.first.at, DateTime(2026, 10, 8, 7));
      expect(upcoming.any((o) => o.task.id == 'a'), false);
      expect(upcoming.any((o) => o.task.id == 'c'), true);
    });

    test('pendientes incluye vencidas y la repeticion de hoy', () {
      final pending = AgendaQueries.pending(tasks, now);
      expect(pending.map((o) => o.task.id).toSet(), {'a', 'b', 'c'});
    });

    test('completadas lista cada dia completado de las repetitivas', () {
      final done = [
        tasks[1].toggleCompletedOn(DateTime(2026, 10, 6)).toggleCompletedOn(DateTime(2026, 10, 7)),
        tasks[0].toggleCompletedOn(DateTime(2026, 10, 5)),
      ];
      final completed = AgendaQueries.completed(done);
      expect(completed.length, 3);
      expect(completed.first.at, DateTime(2026, 10, 7, 7));
    });
  });

  group('Persistencia', () {
    test('las tareas sobreviven a cerrar y reabrir la caja', () async {
      final dir = await Directory.systemTemp.createTemp('agenda_test');
      Hive.init(dir.path);
      var repo = AgendaRepositoryImpl(
        box: await Hive.openBox('agenda'),
        settingsBox: await Hive.openBox('settings'),
      );
      final id1 = await repo.nextNotificationId();
      final id2 = await repo.nextNotificationId();
      expect(id2, id1 + 1);

      final original = task(
        start: DateTime(2026, 10, 10, 18),
        repeat: TaskRepeat.weekly,
        reminder: 10,
      ).copyWith(description: 'Estudiar funciones y listas');
      await repo.save(original);
      await Hive.close();

      Hive.init(dir.path);
      repo = AgendaRepositoryImpl(
        box: await Hive.openBox('agenda'),
        settingsBox: await Hive.openBox('settings'),
      );
      final loaded = repo.getById('t1')!;
      expect(loaded.title, 'Estudiar Python');
      expect(loaded.description, 'Estudiar funciones y listas');
      expect(loaded.start, DateTime(2026, 10, 10, 18));
      expect(loaded.repeat, TaskRepeat.weekly);
      expect(loaded.reminderMinutes, 10);
      expect(await repo.nextNotificationId(), id2 + 1);
    });
  });
}
