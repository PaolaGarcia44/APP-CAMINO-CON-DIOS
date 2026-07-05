import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/bible_book_model.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen> {
  String _query = '';
  BibleBookModel? _selectedBook;
  final _chapterController = TextEditingController();

  @override
  void dispose() {
    _chapterController.dispose();
    super.dispose();
  }

  void _goToChapter() {
    final book = _selectedBook;
    if (book == null) return;
    final chapter = int.tryParse(_chapterController.text);
    if (chapter == null || chapter < 1 || chapter > book.chapterCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingresa un capitulo entre 1 y ${book.chapterCount}')),
      );
      return;
    }
    context.push(RoutePaths.bibleRead(book.id, chapter));
  }

  @override
  Widget build(BuildContext context) {
    final booksAsync = ref.watch(bibleBooksProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar')),
      body: booksAsync.when(
        data: (books) {
          _selectedBook ??= books.first;
          final filtered = _query.isEmpty
              ? <BibleBookModel>[]
              : books.where((b) => b.name.toLowerCase().contains(_query.toLowerCase())).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Buscar libro por nombre...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              if (filtered.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...filtered.map((b) => ListTile(
                      title: Text(b.name),
                      subtitle: Text('${b.chapterCount} capitulos'),
                      onTap: () => context.push(RoutePaths.bibleChapters(b.id)),
                    )),
              ],
              const SizedBox(height: 28),
              Text('Ir directo a un capitulo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<BibleBookModel>(
                      value: _selectedBook,
                      isExpanded: true,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Libro'),
                      items: books
                          .map((b) => DropdownMenuItem(value: b, child: Text(b.name, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (b) => setState(() => _selectedBook = b),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _chapterController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Cap.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: _goToChapter, child: const Text('Ir')),
              ),
              const SizedBox(height: 20),
              Text(
                'La busqueda por texto de versiculo estara disponible cuando se integre una '
                'version completa de la Biblia con licencia.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los libros.')),
      ),
    );
  }
}
