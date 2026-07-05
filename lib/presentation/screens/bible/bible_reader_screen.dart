import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/bible_book_model.dart';
import '../../../data/models/favorite_item.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/repository_providers.dart';
import '../../providers/settings_providers.dart';

class BibleReaderScreen extends ConsumerWidget {
  final String bookId;
  final int chapterNumber;

  const BibleReaderScreen({super.key, required this.bookId, required this.chapterNumber});

  ({String bookId, int chapter})? _shiftChapter(List<BibleBookModel> books, int direction) {
    final index = books.indexWhere((b) => b.id == bookId);
    if (index == -1) return null;
    final book = books[index];
    final target = chapterNumber + direction;
    if (target >= 1 && target <= book.chapterCount) {
      return (bookId: book.id, chapter: target);
    }
    final neighborIndex = index + direction;
    if (neighborIndex < 0 || neighborIndex >= books.length) return null;
    final neighbor = books[neighborIndex];
    return (bookId: neighbor.id, chapter: direction > 0 ? 1 : neighbor.chapterCount);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chapterAsync = ref.watch(bibleChapterProvider(ChapterRequest(bookId, chapterNumber)));
    final booksAsync = ref.watch(bibleBooksProvider);
    final fontScale = ref.watch(fontScaleProvider);
    final bookmarksAsync = ref.watch(bibleBookmarksProvider);
    final progressAsync = ref.watch(bibleProgressProvider);
    final verseKey = '$bookId:$chapterNumber';
    final isBookmarked = bookmarksAsync.maybeWhen(
      data: (keys) => keys.contains(verseKey),
      orElse: () => false,
    );

    final bookName = booksAsync.maybeWhen(
      data: (books) => books.firstWhere((b) => b.id == bookId, orElse: () => books.first).name,
      orElse: () => bookId,
    );

    final isTodayChapter = progressAsync.maybeWhen(
      data: (p) => p.currentBookId == bookId && p.currentChapter == chapterNumber,
      orElse: () => false,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('$bookName $chapterNumber'),
        actions: [
          IconButton(
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () async {
              await ref.read(bibleRepositoryProvider).toggleBookmark(verseKey);
              ref.invalidate(bibleBookmarksProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            onPressed: () => _showFontSizeSheet(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              chapterAsync.whenData((chapter) {
                final text = '$bookName $chapterNumber\n\n${chapter.verses.join('\n')}';
                Share.share(text);
              });
            },
          ),
        ],
      ),
      body: chapterAsync.when(
        data: (chapter) => Column(
          children: [
            if (chapter.isPlaceholder)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.secondaryContainer,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Contenido de muestra: se completara con una version de la Biblia con licencia.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: chapter.verses.length,
                itemBuilder: (context, i) {
                  final verse = chapter.verses[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GestureDetector(
                      onLongPress: () async {
                        final id = '$bookId:$chapterNumber:$i';
                        await ref.read(favoritesProvider.notifier).add(
                              FavoriteItem(
                                id: id,
                                type: FavoriteType.verse,
                                title: '$bookName $chapterNumber:${i + 1}',
                                content: verse,
                                dateAdded: DateTime.now(),
                              ),
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Versiculo guardado en favoritos')),
                          );
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          style: AppTextTheme.scripture.copyWith(
                            fontSize: AppTextTheme.scripture.fontSize! * fontScale,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                          children: [
                            TextSpan(
                              text: '${i + 1}  ',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            TextSpan(text: verse),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('Anterior'),
                        onPressed: booksAsync.maybeWhen(
                          data: (books) {
                            final prev = _shiftChapter(books, -1);
                            if (prev == null) return null;
                            return () => context.pushReplacement(
                                  RoutePaths.bibleRead(prev.bookId, prev.chapter),
                                );
                          },
                          orElse: () => null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: isTodayChapter
                          ? ElevatedButton(
                              onPressed: () async {
                                await ref.read(bibleProgressProvider.notifier).markTodayAsRead();
                              },
                              child: const Text('Marcar como leido'),
                            )
                          : OutlinedButton.icon(
                              icon: const Icon(Icons.chevron_right),
                              label: const Text('Siguiente'),
                              onPressed: booksAsync.maybeWhen(
                                data: (books) {
                                  final next = _shiftChapter(books, 1);
                                  if (next == null) return null;
                                  return () => context.pushReplacement(
                                        RoutePaths.bibleRead(next.bookId, next.chapter),
                                      );
                                },
                                orElse: () => null,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudo cargar el capitulo.')),
      ),
    );
  }

  void _showFontSizeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, _) {
            final scale = ref.watch(fontScaleProvider);
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Tamaño de letra', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: scale,
                    min: 0.8,
                    max: 1.6,
                    divisions: 8,
                    label: '${(scale * 100).round()}%',
                    onChanged: (v) => ref.read(fontScaleProvider.notifier).setScale(v),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
