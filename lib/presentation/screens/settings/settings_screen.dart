import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/app_config.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/services/notification_service.dart';
import '../../../domain/entities/notification_preferences.dart';
import '../../providers/bible_providers.dart';
import '../../providers/journal_providers.dart';
import '../../providers/notification_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> with WidgetsBindingObserver {
  bool _exactAllowed = true;
  bool _systemAllowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver de los ajustes del sistema, comprobar de nuevo los permisos.
    if (state == AppLifecycleState.resumed) _refreshPermissions();
  }

  Future<void> _refreshPermissions() async {
    final exact = await NotificationService.canScheduleExact();
    final system = await NotificationService.areNotificationsAllowed();
    if (!mounted) return;
    setState(() {
      _exactAllowed = !NotificationService.isAvailable || exact;
      _systemAllowed = !NotificationService.isAvailable || system;
    });
  }

  Future<void> _updateNotifications(NotificationPreferences prefs) async {
    final granted = await ref.read(notificationPreferencesProvider.notifier).update(prefs);
    await _refreshPermissions();
    if (!granted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Permiso denegado. Puedes activarlo en los ajustes del telefono.'),
      ));
    }
  }

  Future<void> _pickTime(DayTime current, void Function(DayTime) onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
    );
    if (picked != null) onPicked(DayTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final readerScale = ref.watch(readerFontScaleProvider);
    final readingMode = ref.watch(readingModeProvider);
    final notif = ref.watch(notificationPreferencesProvider);
    final theme = Theme.of(context);

    String timeLabel(DayTime t) =>
        'Todos los dias a las ${TimeOfDay(hour: t.hour, minute: t.minute).format(context)}';

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          // ------------------------------------------------------------- Apariencia
          const _SectionLabel('Apariencia'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto_outlined),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Oscuro'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) => ref.read(themeModeProvider.notifier).setMode(s.first),
            ),
          ),
          ListTile(
            title: const Text('Tamaño de letra de la app'),
            subtitle: Slider(
              value: fontScale,
              min: 0.8,
              max: 1.6,
              divisions: 8,
              label: '${(fontScale * 100).round()}%',
              onChanged: (v) => ref.read(fontScaleProvider.notifier).setScale(v),
            ),
          ),
          const Divider(),

          // ---------------------------------------------------------------- Lectura
          const _SectionLabel('Lectura'),
          ListTile(
            title: const Text('Tamaño de letra de la Biblia'),
            subtitle: Slider(
              value: readerScale,
              min: 0.8,
              max: 1.8,
              divisions: 10,
              label: '${(readerScale * 100).round()}%',
              onChanged: (v) => ref.read(readerFontScaleProvider.notifier).setScale(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'En el principio era el Verbo...',
              textScaler: TextScaler.noScaling,
              style: AppTextTheme.scripture.copyWith(
                fontSize: AppTextTheme.scripture.fontSize! * readerScale,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SegmentedButton<ReadingMode>(
              segments: const [
                ButtonSegment(
                  value: ReadingMode.standard,
                  icon: Icon(Icons.article_outlined),
                  label: Text('Estandar'),
                ),
                ButtonSegment(
                  value: ReadingMode.sepia,
                  icon: Icon(Icons.local_cafe_outlined),
                  label: Text('Sepia (comodo)'),
                ),
              ],
              selected: {readingMode},
              onSelectionChanged: (s) => ref.read(readingModeProvider.notifier).setMode(s.first),
            ),
          ),
          const Divider(),

          // ---------------------------------------------------------- Notificaciones
          const _SectionLabel('Notificaciones'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Activar notificaciones'),
            subtitle: const Text('Funcionan sin internet, programadas en tu telefono'),
            value: notif.enabled,
            onChanged: (v) => _updateNotifications(notif.copyWith(enabled: v)),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: !notif.enabled
                ? const SizedBox(width: double.infinity)
                : Column(
                    children: [
                      if (!_systemAllowed)
                        _WarningTile(
                          text: 'Las notificaciones estan bloqueadas en los ajustes del telefono.',
                          action: 'Permitir',
                          onTap: () async {
                            await NotificationService.requestPermission();
                            await _refreshPermissions();
                          },
                        ),
                      _NotificationRow(
                        icon: Icons.wb_twilight_outlined,
                        title: 'Mensaje del dia',
                        subtitle: timeLabel(notif.dailyMessageTime),
                        value: notif.dailyMessage,
                        onChanged: (v) => _updateNotifications(notif.copyWith(dailyMessage: v)),
                        onTapTime: () => _pickTime(
                          notif.dailyMessageTime,
                          (t) => _updateNotifications(notif.copyWith(dailyMessageTime: t)),
                        ),
                      ),
                      _NotificationRow(
                        icon: Icons.menu_book_outlined,
                        title: 'Recordatorio de lectura',
                        subtitle: timeLabel(notif.readingTime),
                        value: notif.reading,
                        onChanged: (v) => _updateNotifications(notif.copyWith(reading: v)),
                        onTapTime: () => _pickTime(
                          notif.readingTime,
                          (t) => _updateNotifications(notif.copyWith(readingTime: t)),
                        ),
                      ),
                      _NotificationRow(
                        icon: Icons.wb_sunny_outlined,
                        title: 'Reflexion diaria',
                        subtitle: timeLabel(notif.reflectionTime),
                        value: notif.reflection,
                        onChanged: (v) => _updateNotifications(notif.copyWith(reflection: v)),
                        onTapTime: () => _pickTime(
                          notif.reflectionTime,
                          (t) => _updateNotifications(notif.copyWith(reflectionTime: t)),
                        ),
                      ),
                      _NotificationRow(
                        icon: Icons.celebration_outlined,
                        title: 'Fechas especiales',
                        subtitle:
                            'Solemnidades y fiestas · ${TimeOfDay(hour: notif.specialDatesTime.hour, minute: notif.specialDatesTime.minute).format(context)}',
                        value: notif.specialDates,
                        onChanged: (v) => _updateNotifications(notif.copyWith(specialDates: v)),
                        onTapTime: () => _pickTime(
                          notif.specialDatesTime,
                          (t) => _updateNotifications(notif.copyWith(specialDatesTime: t)),
                        ),
                      ),
                      _NotificationRow(
                        icon: Icons.event_note_outlined,
                        title: 'Recordatorios de Agenda',
                        subtitle: 'Segun el recordatorio de cada tarea',
                        value: notif.agenda,
                        onChanged: (v) => _updateNotifications(notif.copyWith(agenda: v)),
                      ),
                      if (notif.agenda && !_exactAllowed)
                        _WarningTile(
                          text: 'Para que los recordatorios de Agenda lleguen a la hora exacta, '
                              'permite "Alarmas y recordatorios".',
                          action: 'Permitir',
                          onTap: () async {
                            await NotificationService.requestExactAlarms();
                            await _refreshPermissions();
                            await ref.read(reminderSchedulerProvider).rescheduleAll();
                          },
                        ),
                    ],
                  ),
          ),
          const Divider(),

          // --------------------------------------------------------------- Diario
          const _SectionLabel('Diario espiritual'),
          ListTile(
            leading: const Icon(Icons.upload_outlined),
            title: const Text('Exportar diario'),
            onTap: () async {
              final jsonString = await ref.read(journalRepositoryProvider).exportAsJson();
              await Share.share(jsonString, subject: 'Respaldo de mi diario espiritual');
            },
          ),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('Importar diario'),
            onTap: () => _showImportDialog(context),
          ),
          const Divider(),

          // ---------------------------------------------------------------- Datos
          const _SectionLabel('Datos'),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reiniciar progreso biblico'),
            subtitle: const Text('Tus favoritos y marcadores se conservan'),
            onTap: () => _confirmReset(context),
          ),
          const Divider(),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('${AppConfig.appName} v${AppConfig.appVersion}'),
            subtitle: Text(
              'Biblia: Santa Biblia libre Latinoamericano (dominio publico, eBible.org)',
            ),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reiniciar progreso biblico'),
        content: const Text(
          'Se borraran el plan de lectura, los capitulos marcados como leidos, el '
          'historial y el punto donde quedaste.\n\n'
          'Tus favoritos, marcadores, tareas y diario espiritual NO se borran.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(settingsRepositoryProvider).resetProgress();
              ref.invalidate(bibleProgressProvider);
              ref.invalidate(lastReadingPositionProvider);
              ref.invalidate(readingHistoryProvider);
              ref.invalidate(readChaptersProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progreso biblico reiniciado')),
                );
              }
            },
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Importar diario'),
        content: TextField(
          controller: controller,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Pega aqui el respaldo exportado previamente...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                await ref.read(journalRepositoryProvider).importFromJson(text);
                await ref.read(journalProvider.notifier).refresh();
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El texto no tiene un formato valido.')),
                  );
                }
              }
            },
            child: const Text('Importar'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }
}

class _NotificationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onTapTime;

  const _NotificationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.onTapTime,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 32, right: 16),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
        onTapTime != null && value ? '$subtitle · tocar para cambiar' : subtitle,
      ),
      onTap: value ? onTapTime : null,
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }
}

class _WarningTile extends StatelessWidget {
  final String text;
  final String action;
  final VoidCallback onTap;

  const _WarningTile({required this.text, required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: scheme.error, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
          TextButton(onPressed: onTap, child: Text(action)),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
