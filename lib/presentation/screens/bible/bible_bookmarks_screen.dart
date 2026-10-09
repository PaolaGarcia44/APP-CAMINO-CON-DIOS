import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/bible_reading.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleBookmarksScreen extends ConsumerWidget {
  const BibleBookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarksAsync = ref.watch(bibleBookmarksProvider);
    final booksById = ref.watch(bibleBooksByIdProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Marcadores')),
      body: bookmarksAsync.when(
        data: (raw) {
          final keys = raw.map(BookmarkKey.tryParse).whereType<BookmarkKey>().toList();
          if (keys.isEmpty) {
            return const _EmptyState(
              icon: Icons.bookmark_add_outlined,
              text: 'Aun no tienes marcadores.\nToca un versiculo o el icono de marcador en el lector.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: keys.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final key = keys[i];
              final name = booksById[key.bookId]?.name ?? key.bookId;
              final title = key.verse == null ? '$name ${key.chapter}' : '$name ${key.chapter}:${key.verse}';
              return Dismissible(
                key: ValueKey(key.value),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: const Icon(Icons.delete_outline),
                ),
                onDismissed: (_) => ref.read(bibleReadingActionsProvider).toggleBookmark(key),
                child: ListTile(
                  leading: Icon(
                    key.verse == null ? Icons.bookmark : Icons.bookmark_border,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(title),
                  subtitle:
                      key.verse == null ? const Text('Capitulo completo') : _VersePreview(bookmark: key),
                  onTap: () => context.push(
                    RoutePaths.bibleRead(key.bookId, key.chapter, verse: key.verse),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los marcadores.')),
      ),
    );
  }
}

class _VersePreview extends ConsumerWidget {
  final BookmarkKey bookmark;
  const _VersePreview({required this.bookmark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapter =
        ref.watch(bibleChapterProvider(ChapterRequest(bookmark.bookId, bookmark.chapter))).valueOrNull;
    if (chapter == null) return const SizedBox.shrink();
    var text = '';
    for (var i = 0; i < chapter.verses.length; i++) {
      if (chapter.verseNumber(i) == bookmark.verse) {
        text = chapter.verses[i];
        break;
      }
    }
    return Text(text, maxLines: 2, overflow: TextOverflow.ellipsis);
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            Text(text, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
