import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bible_reference_parser.dart';
import '../../../core/utils/text_normalizer.dart';
import '../../../data/models/bible_book_model.dart';
import '../../../domain/entities/bible_reading.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';
import '../../providers/repository_providers.dart';

/// Busqueda unificada: referencia ("Jn 3:16"), libro ("Salmos") o palabras
/// dentro del texto ("misericordia").
class BibleSearchScreen extends ConsumerStatefulWidget {
  const BibleSearchScreen({super.key});

  @override
  ConsumerState<BibleSearchScreen> createState() => _BibleSearchScreenState();
}

class _BibleSearchScreenState extends ConsumerState<BibleSearchScreen> {
  final _controller = TextEditingController();
  Timer? _debounce;
  StreamSubscription<BibleSearchHit>? _subscription;

  String _query = '';
  String? _testament; // null = toda la Biblia
  final List<BibleSearchHit> _hits = [];
  bool _searching = false;

  static const _limit = 300;

  @override
  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() => _query = value.trim());
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), _runTextSearch);
  }

  void _runTextSearch() {
    _subscription?.cancel();
    setState(() {
      _hits.clear();
      _searching = _query.length >= 3;
    });
    if (_query.length < 3) return;
    _subscription = ref.read(bibleRepositoryProvider).searchText(_query, testament: _testament).listen(
      (hit) => setState(() => _hits.add(hit)),
      onDone: () {
        if (mounted) setState(() => _searching = false);
      },
      onError: (_) {
        if (mounted) setState(() => _searching = false);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final books = ref.watch(bibleBooksProvider).valueOrNull ?? const <BibleBookModel>[];
    final booksById = ref.watch(bibleBooksByIdProvider);
    final reference = BibleReferenceParser.parse(_query, books);
    final normalizedQuery = TextNormalizer.normalize(_query);
    final matchingBooks = _query.isEmpty
        ? const <BibleBookModel>[]
        : books.where((b) => TextNormalizer.normalize(b.name).contains(normalizedQuery)).take(6).toList();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Buscar en la Biblia')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _controller,
              autofocus: true,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Juan 3:16, Salmos 23 o una palabra',
                border: const OutlineInputBorder(),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _onChanged('');
                        },
                      ),
              ),
              onChanged: _onChanged,
              onSubmitted: (_) {
                _debounce?.cancel();
                _runTextSearch();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<String?>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: null, label: Text('Toda')),
                  ButtonSegment(value: 'antiguo', label: Text('A. T.')),
                  ButtonSegment(value: 'nuevo', label: Text('N. T.')),
                ],
                selected: {_testament},
                onSelectionChanged: (s) {
                  setState(() => _testament = s.first);
                  _runTextSearch();
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _query.isEmpty
                ? _SearchHelp(theme: theme)
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      if (reference != null && reference.chapter != null)
                        ListTile(
                          leading: Icon(Icons.arrow_forward_rounded, color: theme.colorScheme.primary),
                          title: Text(
                            'Ir a ${booksById[reference.bookId]?.name ?? reference.bookId} '
                            '${reference.chapter}${reference.verse != null ? ':${reference.verse}' : ''}',
                            style: theme.textTheme.titleMedium,
                          ),
                          onTap: () => context.push(
                            RoutePaths.bibleRead(
                              reference.bookId,
                              reference.chapter!,
                              verse: reference.verse,
                            ),
                          ),
                        ),
                      if (matchingBooks.isNotEmpty) ...[
                        const _Header('Libros'),
                        ...matchingBooks.map((b) => ListTile(
                              dense: true,
                              leading: const Icon(Icons.menu_book_outlined),
                              title: Text(b.name),
                              subtitle: Text('${b.chapterCount} capitulos'),
                              onTap: () => context.push(RoutePaths.bibleChapters(b.id)),
                            )),
                      ],
                      if (_query.length >= 3) ...[
                        _Header(
                          _searching
                              ? 'Buscando en el texto... (${_hits.length})'
                              : _hits.length >= _limit
                                  ? 'Primeros $_limit versiculos'
                                  : '${_hits.length} versiculos encontrados',
                        ),
                        if (_searching) const LinearProgressIndicator(minHeight: 2),
                        if (!_searching && _hits.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No se encontraron versiculos con ese texto.'),
                          ),
                        ..._hits.map((hit) => ListTile(
                              title: Text(
                                '${booksById[hit.bookId]?.name ?? hit.bookId} ${hit.chapter}:${hit.verse}',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              subtitle: _HighlightedText(
                                text: hit.text,
                                normalizedQuery: normalizedQuery,
                              ),
                              onTap: () => context.push(
                                RoutePaths.bibleRead(hit.bookId, hit.chapter, verse: hit.verse),
                              ),
                            )),
                      ] else
                        const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Escribe al menos 3 letras para buscar dentro del texto.'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _SearchHelp extends StatelessWidget {
  final ThemeData theme;
  const _SearchHelp({required this.theme});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Puedes buscar:', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        const _HelpRow(icon: Icons.menu_book_outlined, text: 'Un libro: "Salmos", "1 Cor"'),
        const _HelpRow(icon: Icons.format_list_numbered, text: 'Un capitulo: "Juan 15"'),
        const _HelpRow(icon: Icons.short_text, text: 'Un versiculo: "Jn 3:16" o "Flp 4,13"'),
        const _HelpRow(icon: Icons.text_snippet_outlined, text: 'Palabras del texto: "misericordia"'),
        const SizedBox(height: 12),
        Text(
          'La busqueda funciona sin conexion y no distingue tildes ni mayusculas.',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HelpRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HelpRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Resalta las apariciones de la busqueda dentro del versiculo. Como la
/// normalizacion conserva la longitud del texto, los indices coinciden.
class _HighlightedText extends StatelessWidget {
  final String text;
  final String normalizedQuery;

  const _HighlightedText({required this.text, required this.normalizedQuery});

  @override
  Widget build(BuildContext context) {
    final normalized = TextNormalizer.normalize(text);
    if (normalizedQuery.isEmpty || normalized.length != text.length) {
      return Text(text);
    }
    final spans = <TextSpan>[];
    var start = 0;
    while (true) {
      final index = normalized.indexOf(normalizedQuery, start);
      if (index == -1) break;
      if (index > start) spans.add(TextSpan(text: text.substring(start, index)));
      spans.add(TextSpan(
        text: text.substring(index, index + normalizedQuery.length),
        style: TextStyle(
          fontWeight: FontWeight.w700,
          backgroundColor: AppColors.gold.withValues(alpha: 0.25),
        ),
      ));
      start = index + normalizedQuery.length;
    }
    if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
    return Text.rich(TextSpan(children: spans));
  }
}
