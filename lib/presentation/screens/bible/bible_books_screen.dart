import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../data/models/bible_book_model.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleBooksScreen extends ConsumerStatefulWidget {
  const BibleBooksScreen({super.key});

  @override
  ConsumerState<BibleBooksScreen> createState() => _BibleBooksScreenState();
}

class _BibleBooksScreenState extends ConsumerState<BibleBooksScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);
    final readChapters = ref.watch(readChaptersProvider);

    int readIn(BibleBookModel b) => readChapters.where((k) => k.startsWith('${b.id}:')).length;

    Widget tile(BibleBookModel b) {
      final read = readIn(b);
      return ListTile(
        title: Text(b.name),
        subtitle:
            Text(read == 0 ? '${b.chapterCount} capitulos' : '${b.chapterCount} capitulos · $read leidos'),
        trailing: read == b.chapterCount
            ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary)
            : const Icon(Icons.chevron_right),
        onTap: () => context.push(RoutePaths.bibleChapters(b.id)),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Libros')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Buscar libro...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _query = TextNormalizer.normalize(v.trim())),
            ),
          ),
          Expanded(
            child: booksAsync.when(
              data: (books) {
                final filtered = _query.isEmpty
                    ? books
                    : books.where((b) => TextNormalizer.normalize(b.name).contains(_query)).toList();
                final antiguo = filtered.where((b) => b.testament == 'antiguo').toList();
                final nuevo = filtered.where((b) => b.testament == 'nuevo').toList();
                return ListView(
                  children: [
                    if (antiguo.isNotEmpty) const _TestamentHeader('Antiguo Testamento'),
                    ...antiguo.map(tile),
                    if (nuevo.isNotEmpty) const _TestamentHeader('Nuevo Testamento'),
                    ...nuevo.map(tile),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => const Center(child: Text('No se pudieron cargar los libros.')),
            ),
          ),
        ],
      ),
    );
  }
}

class _TestamentHeader extends StatelessWidget {
  final String title;
  const _TestamentHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}
