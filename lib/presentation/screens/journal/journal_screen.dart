import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/art_banner.dart';
import '../../../data/models/journal_entry.dart';
import '../../providers/journal_providers.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalProvider);
    final dateFormat = DateFormat('d MMM yyyy, HH:mm', 'es');

    return Scaffold(
      appBar: AppBar(title: const Text('Diario espiritual')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEntryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      body: entriesAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ArtBanner(
                  asset: 'assets/images/hijo_prodigo.jpg',
                  height: 150,
                  child: Text(
                    'Tu conversacion escrita con Dios',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Escribe tus agradecimientos, peticiones y reflexiones personales. '
                  'Todo se guarda solo en tu dispositivo.',
                  textAlign: TextAlign.center,
                ),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              if (i == 0) {
                return ArtBanner(
                  asset: 'assets/images/hijo_prodigo.jpg',
                  height: 120,
                  child: Text(
                    'Tu conversacion escrita con Dios',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(color: Colors.white),
                  ),
                );
              }
              final entry = entries[i - 1];
              return Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                onDismissed: (_) => ref.read(journalProvider.notifier).delete(entry.id),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                child: Card(
                  child: ListTile(
                    title: Text(entry.category.label),
                    subtitle: Text(entry.text),
                    trailing: Text(
                      dateFormat.format(entry.date),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudo cargar el diario.')),
      ),
    );
  }

  void _showEntryDialog(BuildContext context, WidgetRef ref) {
    JournalCategory category = JournalCategory.agradecimiento;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nueva entrada'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<JournalCategory>(
                    value: category,
                    items: JournalCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                        .toList(),
                    onChanged: (c) => setState(() => category = c ?? category),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Escribe aqui...',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) return;
                    ref.read(journalProvider.notifier).add(
                          JournalEntry(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            category: category,
                            text: controller.text.trim(),
                            date: DateTime.now(),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
