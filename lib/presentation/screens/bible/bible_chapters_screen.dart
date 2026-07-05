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
    return Scaffold(
      appBar: AppBar(
        title: booksAsync.maybeWhen(
          data: (books) => Text(books.firstWhere((b) => b.id == bookId).name),
          orElse: () => const Text('Capitulos'),
        ),
      ),
      body: booksAsync.when(
        data: (books) {
          final book = books.firstWhere((b) => b.id == bookId);
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: book.chapterCount,
            itemBuilder: (context, i) {
              final chapter = i + 1;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push(RoutePaths.bibleRead(bookId, chapter)),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Center(child: Text('$chapter')),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los capitulos.')),
      ),
    );
  }
}
