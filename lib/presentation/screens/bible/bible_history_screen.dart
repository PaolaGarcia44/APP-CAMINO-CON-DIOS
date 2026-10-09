import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

/// Capitulos abiertos recientemente, del mas nuevo al mas antiguo.
class BibleHistoryScreen extends ConsumerWidget {
  const BibleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(readingHistoryProvider);
    final booksById = ref.watch(bibleBooksByIdProvider);
    final readChapters = ref.watch(readChaptersProvider);
    final format = DateFormat("d MMM, h:mm a", 'es');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de lectura'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              tooltip: 'Borrar historial',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClear(context, ref),
            ),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Aqui veras los capitulos que vayas leyendo.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            )
          : ListView.separated(
              itemCount: history.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final entry = history[i];
                final name = booksById[entry.bookId]?.name ?? entry.bookId;
                final read = readChapters.contains('${entry.bookId}:${entry.chapter}');
                return ListTile(
                  leading: Icon(
                    read ? Icons.check_circle : Icons.menu_book_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    '$name ${entry.chapter}${entry.verse != null ? ':${entry.verse}' : ''}',
                  ),
                  subtitle: Text(format.format(entry.updatedAt)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(
                    RoutePaths.bibleRead(entry.bookId, entry.chapter, verse: entry.verse),
                  ),
                );
              },
            ),
    );
  }

  void _confirmClear(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Borrar historial'),
        content: const Text(
          'Se borrara la lista de capitulos recientes. Tu progreso, marcadores '
          'y favoritos no se veran afectados.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () async {
              await ref.read(bibleReadingActionsProvider).clearHistory();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }
}
