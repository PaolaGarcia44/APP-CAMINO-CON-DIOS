import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/agenda_task.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/usecases/notification_planner.dart';
import 'agenda_providers.dart';
import 'calendar_providers.dart';
import 'datasource_providers.dart';
import 'repository_providers.dart';

/// Programa (y reprograma) todas las notificaciones locales a partir de las
/// preferencias, los mensajes del dia, el calendario y la Agenda.
class ReminderScheduler {
  final Ref ref;
  ReminderScheduler(this.ref);

  // Las reprogramaciones se encadenan para que nunca corran dos a la vez.
  Future<void> _queue = Future.value();

  Future<void> _enqueue(Future<void> Function() job) {
    final next = _queue.then((_) => job()).catchError((Object e) {
      debugPrint('Error al programar notificaciones: $e');
    });
    _queue = next;
    return next;
  }

  /// Cancela todo y vuelve a programar segun la configuracion actual. Se
  /// llama al abrir la app, al cambiar de dia y al cambiar los ajustes.
  Future<void> rescheduleAll() => _enqueue(() async {
        if (!NotificationService.isAvailable) return;
        final prefs = ref.read(notificationPreferencesProvider);
        final now = DateTime.now();
        final messages = prefs.enabled && prefs.dailyMessage
            ? await ref.read(quotesLocalDataSourceProvider).getAll()
            : const <Never>[];
        final plan = NotificationPlanner.build(
          prefs: prefs,
          now: now,
          messages: messages,
          specialDates: prefs.enabled && prefs.specialDates ? await _specialDates(now) : const [],
          tasks: ref.read(agendaProvider),
        );
        await NotificationService.cancelAll();
        for (final n in plan) {
          await NotificationService.schedule(n);
        }
      });

  /// Actualiza solo el recordatorio de una tarea.
  Future<void> syncTask(AgendaTask task) => _enqueue(() async {
        await NotificationService.cancel(task.notificationId);
        final prefs = ref.read(notificationPreferencesProvider);
        if (!prefs.enabled || !prefs.agenda) return;
        final planned = NotificationPlanner.agendaTask(task, DateTime.now());
        if (planned != null) await NotificationService.schedule(planned);
      });

  Future<void> cancelTask(AgendaTask task) => _enqueue(() => NotificationService.cancel(task.notificationId));

  /// Solemnidades, fiestas y celebraciones principales de este año y el
  /// siguiente (el planificador se queda con las de los proximos dias).
  Future<List<SpecialDate>> _specialDates(DateTime now) async {
    final calendar = await ref.read(catholicCalendarProvider.future);
    return [
      for (final year in [now.year, now.year + 1])
        for (final c in calendar.celebrationsForYear(year))
          if (c.rank.isSpecial) SpecialDate(c.date, c.name),
    ];
  }
}

final reminderSchedulerProvider = Provider<ReminderScheduler>((ref) => ReminderScheduler(ref));

class NotificationPreferencesNotifier extends StateNotifier<NotificationPreferences> {
  final Ref ref;
  NotificationPreferencesNotifier(this.ref)
      : super(ref.read(settingsRepositoryProvider).getNotificationPreferences());

  /// Guarda los cambios y reprograma. Al activar las notificaciones pide el
  /// permiso del sistema; devuelve false si el usuario lo nego.
  Future<bool> update(NotificationPreferences prefs) async {
    final turningOn = prefs.enabled && !state.enabled;
    state = prefs;
    await ref.read(settingsRepositoryProvider).setNotificationPreferences(prefs);
    var granted = true;
    if (turningOn) granted = await NotificationService.requestPermission();
    await ref.read(reminderSchedulerProvider).rescheduleAll();
    return granted;
  }
}

final notificationPreferencesProvider =
    StateNotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
  (ref) => NotificationPreferencesNotifier(ref),
);

/// Si el usuario crea una tarea con recordatorio pero las notificaciones
/// estan apagadas, ofrece activarlas en ese momento.
Future<void> ensureAgendaRemindersEnabled(BuildContext context, WidgetRef ref) async {
  final prefs = ref.read(notificationPreferencesProvider);
  if (prefs.enabled && prefs.agenda) return;
  final accept = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.notifications_active_outlined),
      title: const Text('¿Activar recordatorios?'),
      content: const Text(
        'Tus recordatorios de Agenda estan desactivados. ¿Quieres activarlos para recibir '
        'un aviso a la hora de tus tareas?',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Ahora no')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Activar')),
      ],
    ),
  );
  if (accept != true) return;
  final granted = await ref
      .read(notificationPreferencesProvider.notifier)
      .update(prefs.copyWith(enabled: true, agenda: true));
  if (!granted && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Permiso de notificaciones denegado. Puedes activarlo en los ajustes del telefono.'),
    ));
  }
}
