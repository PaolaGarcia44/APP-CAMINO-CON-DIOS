import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/entities/agenda_task.dart';
import '../../../domain/usecases/agenda_queries.dart';
import '../../../routes/route_paths.dart';
import '../../providers/agenda_providers.dart';

/// Fila de una tarea: completar con un toque, editar al tocarla y eliminar
/// deslizando (con opcion de deshacer).
class TaskTile extends ConsumerWidget {
  final TaskOccurrence occurrence;
  final bool showOverdue;
  final bool dense;

  const TaskTile({
    super.key,
    required this.occurrence,
    this.showOverdue = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = occurrence.task;
    final done = occurrence.completed;
    final theme = Theme.of(context);
    final overdue = showOverdue && !done && occurrence.at.isBefore(DateTime.now());
    final time = TimeOfDay.fromDateTime(occurrence.at).format(context);

    final details = <InlineSpan>[
      TextSpan(text: time),
      if (task.isRepeating) ...[
        const TextSpan(text: '  '),
        const WidgetSpan(child: Icon(Icons.repeat, size: 14), alignment: PlaceholderAlignment.middle),
        TextSpan(text: ' ${task.repeat.label}'),
      ],
      if (task.reminderMinutes != null) ...[
        const TextSpan(text: '  '),
        const WidgetSpan(
          child: Icon(Icons.notifications_active_outlined, size: 14),
          alignment: PlaceholderAlignment.middle,
        ),
      ],
      if (overdue) const TextSpan(text: '  · Vencida'),
    ];

    final tile = Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
        dense: dense,
        leading: IconButton(
          tooltip: done ? 'Marcar como pendiente' : 'Marcar como completada',
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              done ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(done),
              color: done ? AppColors.success : theme.colorScheme.outline,
            ),
          ),
          onPressed: () => ref.read(agendaProvider.notifier).toggleCompleted(task, occurrence.at),
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            decoration: done ? TextDecoration.lineThrough : null,
            color: done ? theme.colorScheme.onSurface.withValues(alpha: 0.5) : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(children: details),
              style: theme.textTheme.bodySmall?.copyWith(
                color: overdue ? theme.colorScheme.error : null,
              ),
            ),
            if (!dense && (task.description?.isNotEmpty ?? false))
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(task.description!, maxLines: 2, overflow: TextOverflow.ellipsis),
              ),
          ],
        ),
        onTap: () => context.push(RoutePaths.agendaEdit(task.id)),
      ),
    );

    if (dense) return tile;

    return Dismissible(
      key: ValueKey('dismiss-${task.id}-${occurrence.at}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline),
      ),
      confirmDismiss: (_) async {
        if (!task.isRepeating) return true;
        return await showDialog<bool>(
              context: context,
              builder: (c) => AlertDialog(
                title: const Text('Eliminar tarea repetitiva'),
                content: Text('Se eliminaran todas las repeticiones de "${task.title}".'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
                  FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) async {
        final notifier = ref.read(agendaProvider.notifier);
        final messenger = ScaffoldMessenger.of(context);
        await notifier.delete(task);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text('"${task.title}" eliminada'),
            action: SnackBarAction(label: 'Deshacer', onPressed: () => notifier.save(task)),
          ),
        );
      },
      child: tile,
    );
  }
}
