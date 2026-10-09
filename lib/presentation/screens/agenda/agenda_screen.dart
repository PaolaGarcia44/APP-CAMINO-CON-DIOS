import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/month_calendar.dart';
import '../../../domain/entities/agenda_task.dart';
import '../../../domain/usecases/agenda_queries.dart';
import '../../../routes/route_paths.dart';
import '../../providers/agenda_providers.dart';
import 'task_tile.dart';

enum _AgendaView { day, upcoming, pending, completed }

extension on _AgendaView {
  String get label => switch (this) {
        _AgendaView.day => 'Dia',
        _AgendaView.upcoming => 'Proximas',
        _AgendaView.pending => 'Pendientes',
        _AgendaView.completed => 'Completadas',
      };
}

class AgendaScreen extends ConsumerStatefulWidget {
  const AgendaScreen({super.key});

  @override
  ConsumerState<AgendaScreen> createState() => _AgendaScreenState();
}

class _AgendaScreenState extends ConsumerState<AgendaScreen> {
  _AgendaView _view = _AgendaView.day;
  DateTime _selectedDay = AgendaTask.dateOnly(DateTime.now());
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  // null = automatico: en pantallas bajas se muestra solo la semana.
  bool? _compact;

  void _goToday() {
    final today = AgendaTask.dateOnly(DateTime.now());
    setState(() {
      _view = _AgendaView.day;
      _selectedDay = today;
      _focusedMonth = DateTime(today.year, today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(agendaProvider);
    final now = DateTime.now();
    final theme = Theme.of(context);
    final compact = _compact ?? MediaQuery.sizeOf(context).height < 760;

    final List<TaskOccurrence> items = switch (_view) {
      _AgendaView.day => AgendaQueries.forDay(tasks, _selectedDay),
      _AgendaView.upcoming => AgendaQueries.upcoming(tasks, now),
      _AgendaView.pending => AgendaQueries.pending(tasks, now),
      _AgendaView.completed => AgendaQueries.completed(tasks),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agenda'),
        actions: [
          IconButton(tooltip: 'Hoy', icon: const Icon(Icons.today_outlined), onPressed: _goToday),
          if (_view == _AgendaView.day)
            IconButton(
              tooltip: compact ? 'Ver mes completo' : 'Ver solo la semana',
              icon: Icon(compact ? Icons.calendar_month_outlined : Icons.view_week_outlined),
              onPressed: () => setState(() => _compact = !compact),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nueva tarea'),
        onPressed: () => context.push(
          RoutePaths.agendaNew(_view == _AgendaView.day ? _selectedDay : null),
        ),
      ),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            child: _view == _AgendaView.day
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: MonthCalendar(
                      focusedMonth: _focusedMonth,
                      selectedDay: _selectedDay,
                      compact: compact,
                      onDaySelected: (d) => setState(() => _selectedDay = AgendaTask.dateOnly(d)),
                      onMonthChanged: (m) => setState(() => _focusedMonth = m),
                      markersFor: (day) {
                        final dayTasks = AgendaQueries.forDay(tasks, day);
                        if (dayTasks.isEmpty) return const [];
                        final allDone = dayTasks.every((o) => o.completed);
                        return [allDone ? theme.colorScheme.outline : theme.colorScheme.secondary];
                      },
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                for (final v in _AgendaView.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(v.label),
                      selected: _view == v,
                      onSelected: (_) => setState(() => _view = v),
                    ),
                  ),
              ],
            ),
          ),
          if (_view == _AgendaView.day)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _dayTitle(_selectedDay),
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
          Expanded(
            child: items.isEmpty
                ? _EmptyAgenda(view: _view)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final occurrence = items[i];
                      final showDate = _view != _AgendaView.day &&
                          (i == 0 || !MonthCalendar.isSameDay(items[i - 1].at, occurrence.at));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showDate)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                              child: Text(_dayTitle(occurrence.at), style: theme.textTheme.titleSmall),
                            ),
                          TaskTile(
                            key: ValueKey('${occurrence.task.id}-${occurrence.at}'),
                            occurrence: occurrence,
                            showOverdue: _view == _AgendaView.pending,
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static String _dayTitle(DateTime day) {
    final today = AgendaTask.dateOnly(DateTime.now());
    final d = AgendaTask.dateOnly(day);
    final diff = d.difference(today).inDays;
    final formatted = DateFormat("EEEE d 'de' MMMM", 'es').format(d);
    final label = formatted[0].toUpperCase() + formatted.substring(1);
    if (diff == 0) return 'Hoy · $label';
    if (diff == 1) return 'Mañana · $label';
    if (diff == -1) return 'Ayer · $label';
    return label;
  }
}

class _EmptyAgenda extends StatelessWidget {
  final _AgendaView view;
  const _EmptyAgenda({required this.view});

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (view) {
      _AgendaView.day => (Icons.event_available_outlined, 'No hay tareas para este dia.'),
      _AgendaView.upcoming => (Icons.upcoming_outlined, 'No tienes tareas en los proximos 30 dias.'),
      _AgendaView.pending => (Icons.task_alt, '¡Todo al dia! No tienes tareas pendientes.'),
      _AgendaView.completed => (Icons.checklist_rtl, 'Aun no has completado tareas.'),
    };
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
