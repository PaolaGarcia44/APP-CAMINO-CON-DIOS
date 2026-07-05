import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../config/app_config.dart';
import '../../../data/services/notification_service.dart';
import '../../providers/bible_providers.dart';
import '../../providers/journal_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final vibration = ref.watch(vibrationEnabledProvider);
    final notifications = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Configuracion')),
      body: ListView(
        children: [
          const _SectionLabel('Apariencia'),
          RadioListTile<ThemeMode>(
            title: const Text('Seguir el sistema'),
            value: ThemeMode.system,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).setMode(m!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Claro'),
            value: ThemeMode.light,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).setMode(m!),
          ),
          RadioListTile<ThemeMode>(
            title: const Text('Oscuro'),
            value: ThemeMode.dark,
            groupValue: themeMode,
            onChanged: (m) => ref.read(themeModeProvider.notifier).setMode(m!),
          ),
          ListTile(
            title: const Text('Tamaño de letra'),
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
          const _SectionLabel('Rosario'),
          SwitchListTile(
            title: const Text('Vibracion al avanzar'),
            value: vibration,
            onChanged: (v) => ref.read(vibrationEnabledProvider.notifier).toggle(v),
          ),
          const Divider(),
          const _SectionLabel('Notificaciones'),
          SwitchListTile(
            title: const Text('Recordatorios diarios'),
            subtitle: const Text('Buenos dias, lectura, reflexion y Rosario'),
            value: notifications,
            onChanged: (v) async {
              await ref.read(notificationsEnabledProvider.notifier).toggle(v);
              if (v) {
                await NotificationService.scheduleDefaultReminders();
              } else {
                await NotificationService.cancelAll();
              }
            },
          ),
          const Divider(),
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
            onTap: () => _showImportDialog(context, ref),
          ),
          const Divider(),
          const _SectionLabel('Datos'),
          ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Restablecer progreso de lectura'),
            subtitle: const Text('Borra el avance de la Biblia y los marcadores'),
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(),
          ListTile(
            title: Text('${AppConfig.appName} v${AppConfig.appVersion}'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer progreso'),
        content: const Text(
          'Esto borrara tu dia de lectura biblica actual y tus marcadores. '
          'Tus favoritos y tu diario espiritual no se veran afectados. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(settingsRepositoryProvider).resetProgress();
              ref.invalidate(bibleProgressProvider);
              ref.invalidate(bibleBookmarksProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              try {
                await ref.read(journalRepositoryProvider).importFromJson(text);
                await ref.read(journalProvider.notifier).refresh();
                if (context.mounted) Navigator.pop(context);
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
        style: Theme.of(context)
            .textTheme
            .labelLarge
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
