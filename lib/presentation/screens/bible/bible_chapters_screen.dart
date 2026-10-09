import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleChaptersScreen extends ConsumerWidget {
  final String bookId;
  const BibleChaptersScreen({super.key, required this.bookId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(bibleBooksProvider);
    final readChapters = ref.watch(readChaptersProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(ref.watch(bibleBooksByIdProvider)[bookId]?.name ?? 'Capitulos'),
      ),
      body: booksAsync.when(
        data: (books) {
          final index = books.indexWhere((b) => b.id == bookId);
          if (index == -1) return const Center(child: Text('Libro no encontrado.'));
          final book = books[index];
          final read = List.generate(
            book.chapterCount,
            (i) => readChapters.contains('$bookId:${i + 1}'),
          );
          final readCount = read.where((r) => r).length;
          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    '$readCount de ${book.chapterCount} capitulos leidos',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 72,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: book.chapterCount,
                  itemBuilder: (context, i) {
                    final chapter = i + 1;
                    final isRead = read[i];
                    return Material(
                      color: isRead ? scheme.primaryContainer : Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: scheme.secondary.withValues(alpha: 0.2)),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push(RoutePaths.bibleRead(bookId, chapter)),
                        child: Stack(
                          children: [
                            Center(
                              child: Text(
                                '$chapter',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            if (isRead)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Icon(Icons.check, size: 14, color: scheme.primary),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los capitulos.')),
      ),
    );
  }
}
