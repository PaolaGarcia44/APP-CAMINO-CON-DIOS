import 'package:flutter_test/flutter_test.dart';
import 'package:luz_para_hoy/core/utils/daily_selector.dart';
import 'package:luz_para_hoy/data/datasources/quotes_local_datasource.dart';
import 'package:luz_para_hoy/data/models/quote_model.dart';
import 'package:luz_para_hoy/domain/entities/agenda_task.dart';
import 'package:luz_para_hoy/domain/entities/notification_preferences.dart';
import 'package:luz_para_hoy/domain/entities/planned_notification.dart';
import 'package:luz_para_hoy/domain/usecases/notification_planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Mensaje del dia', () {
    test('nunca repite el mismo mensaje dos dias seguidos (3 años)', () {
      for (final count in [2, 7, 128]) {
        var previous = -1;
        var day = DateTime(2025, 1, 1);
        for (var i = 0; i < 365 * 3; i++) {
          final index = DailySelector.indexFor(day, count);
          expect(index, isNot(previous), reason: 'count=$count, dia=$day');
          expect(index, inInclusiveRange(0, count - 1));
          previous = index;
          day = DateTime(day.year, day.month, day.day + 1);
        }
      }
    });

    test('recorre todos los mensajes antes de repetir', () {
      const count = 50;
      final start = DailySelector.dayNumber(DateTime(2026, 1, 1));
      final cycleStart = start - start % count;
      final seen = <int>{};
      for (var i = 0; i < count; i++) {
        final day = DateTime.utc(2024, 1, 1).add(Duration(days: cycleStart + i));
        seen.add(DailySelector.indexFor(day, count));
      }
      expect(seen.length, count);
    });

    test('es estable durante todo el dia', () {
      expect(
        DailySelector.indexFor(DateTime(2026, 10, 7, 0, 1), 128),
        DailySelector.indexFor(DateTime(2026, 10, 7, 23, 59), 128),
      );
    });

    test('los mensajes locales cargan, con citas y sin Rosario', () async {
      final quotes = await QuotesLocalDataSource().getAll();
      expect(quotes.length, greaterThan(100));
      expect(quotes.where((q) => q.reference != null), isNotEmpty);
      expect(quotes.any((q) => q.text.toLowerCase().contains('rosario')), false);
    });
  });

  group('Planificador de notificaciones', () {
    final now = DateTime(2026, 10, 7, 9, 30);
    const messages = [
      QuoteModel(id: 'a', text: 'Mensaje A'),
      QuoteModel(id: 'b', text: 'Mensaje B', reference: 'Juan 1:1'),
      QuoteModel(id: 'c', text: 'Mensaje C'),
    ];

    test('mensajes diarios: omite la hora ya pasada de hoy y usa ids unicos', () {
      final plan = NotificationPlanner.dailyMessages(
        now: now,
        time: const DayTime(7, 0),
        messages: messages,
        days: 5,
      );
      expect(plan.length, 4); // hoy a las 7:00 ya paso
      expect(plan.first.when, DateTime(2026, 10, 8, 7));
      expect(plan.map((p) => p.id).toSet().length, plan.length);
      expect(plan.first.title, 'Buenos días 🌅');
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].body, isNot(plan[i - 1].body));
      }
    });

    test('lectura y reflexion se repiten a diario a la hora elegida', () {
      final reading = NotificationPlanner.reading(const DayTime(20, 0), now);
      expect(reading.when, DateTime(2026, 10, 7, 20));
      expect(reading.repeat, NotificationRepeat.daily);
      final reflection = NotificationPlanner.reflection(const DayTime(8, 0), now);
      expect(reflection.when, DateTime(2026, 10, 8, 8));
    });

    test('recordatorio de tarea 10 minutos antes', () {
      final task = AgendaTask(
        id: 't',
        title: 'Estudiar Python',
        description: 'Estudiar funciones y listas.',
        start: DateTime(2026, 10, 10, 18),
        reminderMinutes: 10,
        notificationId: 10001,
        createdAt: now,
      );
      final planned = NotificationPlanner.agendaTask(task, now)!;
      expect(planned.when, DateTime(2026, 10, 10, 17, 50));
      expect(planned.id, 10001);
      expect(planned.repeat, isNull);
      expect(planned.body, contains('Estudiar funciones y listas.'));
    });

    test('tareas sin recordatorio, completadas o pasadas no se programan', () {
      final base = AgendaTask(
        id: 't',
        title: 'X',
        start: DateTime(2026, 10, 10, 18),
        notificationId: 10002,
        createdAt: now,
      );
      expect(NotificationPlanner.agendaTask(base, now), isNull);
      expect(
        NotificationPlanner.agendaTask(base.copyWith(reminderMinutes: 0, completed: true), now),
        isNull,
      );
      expect(
        NotificationPlanner.agendaTask(
          base.copyWith(reminderMinutes: 0, start: DateTime(2026, 10, 7, 9)),
          now,
        ),
        isNull,
      );
    });

    test('tarea diaria: si hoy ya paso, el primer aviso es mañana y se repite', () {
      final task = AgendaTask(
        id: 't',
        title: 'Leer la Biblia',
        start: DateTime(2026, 9, 1, 7),
        repeat: TaskRepeat.daily,
        reminderMinutes: 0,
        notificationId: 10003,
        createdAt: now,
      );
      final planned = NotificationPlanner.agendaTask(task, now)!;
      expect(planned.when, DateTime(2026, 10, 8, 7));
      expect(planned.repeat, NotificationRepeat.daily);
    });

    test('fechas especiales: agrupa por dia y respeta la ventana', () {
      final plan = NotificationPlanner.specialDates(
        now: now,
        time: const DayTime(8, 0),
        dates: [
          SpecialDate(DateTime(2026, 10, 7), 'Hoy ya pasada la hora'),
          SpecialDate(DateTime(2026, 11, 1), 'Todos los Santos'),
          SpecialDate(DateTime(2026, 12, 8), 'Inmaculada Concepcion'),
          SpecialDate(DateTime(2026, 12, 8), 'Otra'),
          SpecialDate(DateTime(2027, 6, 1), 'Fuera de la ventana'),
        ],
      );
      expect(plan.length, 2);
      expect(plan.first.when, DateTime(2026, 11, 1, 8));
      expect(plan.first.body, 'Hoy es la celebración de Todos los Santos.');
      expect(plan.last.body, contains('Inmaculada Concepcion y Otra'));
    });

    test('con el interruptor general apagado no se programa nada', () {
      final plan = NotificationPlanner.build(
        prefs: const NotificationPreferences(enabled: false),
        now: now,
        messages: messages,
        specialDates: const [],
        tasks: const [],
      );
      expect(plan, isEmpty);
    });

    test('ningun id se repite en el plan completo', () {
      final plan = NotificationPlanner.build(
        prefs: const NotificationPreferences(enabled: true, reflection: true),
        now: now,
        messages: messages,
        specialDates: [SpecialDate(DateTime(2026, 11, 1), 'Todos los Santos')],
        tasks: [
          AgendaTask(
            id: 't',
            title: 'X',
            start: DateTime(2026, 10, 9, 10),
            reminderMinutes: 15,
            notificationId: 10000,
            createdAt: now,
          ),
        ],
      );
      expect(plan.map((p) => p.id).toSet().length, plan.length);
      expect(plan.any((p) => p.kind == NotificationKind.agenda), true);
      expect(plan.any((p) => p.kind == NotificationKind.specialDates), true);
    });
  });
}
