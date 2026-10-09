import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/agenda_task.dart';
import '../../providers/agenda_providers.dart';
import '../../providers/notification_providers.dart';

/// Crear o editar una tarea de la Agenda.
class TaskEditorScreen extends ConsumerStatefulWidget {
  final String? taskId;
  final DateTime? initialDate;

  const TaskEditorScreen({super.key, this.taskId, this.initialDate});

  @override
  ConsumerState<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends ConsumerState<TaskEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _description;
  late DateTime _date;
  late TimeOfDay _time;
  TaskRepeat _repeat = TaskRepeat.none;
  int? _reminder = 10;
  AgendaTask? _existing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _existing = widget.taskId == null
        ? null
        : ref.read(agendaProvider).where((t) => t.id == widget.taskId).firstOrNull;
    final existing = _existing;
    _title = TextEditingController(text: existing?.title ?? '');
    _description = TextEditingController(text: existing?.description ?? '');
    if (existing != null) {
      _date = AgendaTask.dateOnly(existing.start);
      _time = TimeOfDay.fromDateTime(existing.start);
      _repeat = existing.repeat;
      _reminder = existing.reminderMinutes;
    } else {
      final now = DateTime.now();
      _date = AgendaTask.dateOnly(widget.initialDate ?? now);
      // Por defecto, la proxima hora en punto.
      _time = TimeOfDay(hour: (now.hour + 1) % 24, minute: 0);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  DateTime get _start => DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Fecha de la tarea',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Hora de la tarea',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final notifier = ref.read(agendaProvider.notifier);
    final description = _description.text.trim();
    final existing = _existing;

    if (existing == null) {
      await notifier.create(
        title: _title.text.trim(),
        description: description.isEmpty ? null : description,
        start: _start,
        repeat: _repeat,
        reminderMinutes: _reminder,
      );
    } else {
      await notifier.save(existing.copyWith(
        title: _title.text.trim(),
        description: description.isEmpty ? null : description,
        clearDescription: description.isEmpty,
        start: _start,
        repeat: _repeat,
        reminderMinutes: _reminder,
        clearReminder: _reminder == null,
        // Al cambiar el tipo de repeticion, el registro de dias completados
        // anterior deja de tener sentido.
        completedDates: _repeat == existing.repeat ? existing.completedDates : <String>{},
      ));
    }
    if (!mounted) return;
    if (_reminder != null) await ensureAgendaRemindersEnabled(context, ref);
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final existing = _existing;
    if (existing == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Eliminar tarea'),
        content: Text(existing.isRepeating
            ? 'Se eliminaran todas las repeticiones de "${existing.title}".'
            : '¿Eliminar "${existing.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(agendaProvider.notifier).delete(existing);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = DateFormat("EEEE d 'de' MMMM 'de' y", 'es').format(_date);
    final reminderInPast = _reminder != null &&
        _repeat == TaskRepeat.none &&
        _start.subtract(Duration(minutes: _reminder!)).isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Text(_existing == null ? 'Nueva tarea' : 'Editar tarea'),
        actions: [
          if (_existing != null)
            IconButton(tooltip: 'Eliminar', icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            TextFormField(
              controller: _title,
              autofocus: _existing == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Titulo',
                hintText: 'Ej. Estudiar Python',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Escribe un titulo' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descripcion (opcional)',
                hintText: 'Ej. Estudiar funciones y listas',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Fecha'),
                    subtitle: Text(dateLabel[0].toUpperCase() + dateLabel.substring(1)),
                    onTap: _pickDate,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Hora'),
                    subtitle: Text(_time.format(context)),
                    onTap: _pickTime,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Text('Repetir', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in TaskRepeat.values)
                  ChoiceChip(
                    label: Text(r.label),
                    selected: _repeat == r,
                    onSelected: (_) => setState(() => _repeat = r),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            Text('Recordatorio', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              initialValue: _reminder,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications_outlined),
              ),
              items: [
                DropdownMenuItem<int?>(value: null, child: Text(ReminderOptions.label(null))),
                for (final m in ReminderOptions.values)
                  DropdownMenuItem<int?>(value: m, child: Text(ReminderOptions.label(m))),
              ],
              onChanged: (v) => setState(() => _reminder = v),
            ),
            if (reminderInPast)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'La hora del recordatorio ya paso, por lo que no se enviara aviso.',
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                ),
              ),
            if (_repeat == TaskRepeat.monthly && _date.day > 28)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Los meses que no tienen el dia ${_date.day} se omitiran.',
                  style: theme.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton.icon(
            icon: const Icon(Icons.check),
            label: Text(_existing == null ? 'Guardar tarea' : 'Guardar cambios'),
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          ),
        ),
      ),
    );
  }
}
