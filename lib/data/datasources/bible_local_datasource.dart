import 'dart:convert';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/services.dart' show rootBundle;
import '../../core/utils/text_normalizer.dart';
import '../../domain/entities/bible_reading.dart';
import '../models/bible_book_model.dart';
import '../models/bible_chapter_model.dart';

/// Lee el indice de libros y el texto completo de cada libro desde
/// assets/data/bible. Cada libro vive en su propio archivo
/// (assets/data/bible/books/<id>.json) y se carga de forma diferida la
/// primera vez que se abre, quedando luego en cache en memoria.
///
/// Para reemplazar la traduccion basta con generar de nuevo esos archivos
/// con la misma forma `{bookId, chapters:[{chapterNumber, numbers, verses}]}`
/// y actualizar `books_index.json`; el resto de la app no cambia.
class BibleLocalDataSource {
  List<BibleBookModel>? _books;
  final Map<String, Map<int, BibleChapterModel>> _bookCache = {};
  // Versiculos ya normalizados (sin tildes, minusculas) para la busqueda.
  final Map<String, Map<int, List<String>>> _normalizedCache = {};

  Future<List<BibleBookModel>> getBooks() async {
    if (_books != null) return _books!;
    final raw = await rootBundle.loadString('assets/data/bible/books_index.json');
    final list = json.decode(raw) as List;
    _books = list.map((e) => BibleBookModel.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _books!;
  }

  /// Carga (y cachea) todos los capitulos de un libro, indexados por numero.
  /// El JSON se decodifica fuera del hilo de la interfaz para no trabar la
  /// lectura en libros grandes (Salmos, Isaias...).
  Future<Map<int, BibleChapterModel>> _loadBook(String bookId) async {
    final cached = _bookCache[bookId];
    if (cached != null) return cached;

    final map = <int, BibleChapterModel>{};
    try {
      final raw = await rootBundle.loadString('assets/data/bible/books/$bookId.json');
      final chapters = await compute(_decodeChapters, raw);
      for (final c in chapters) {
        final chapter = BibleChapterModel.fromJson(c, bookId: bookId);
        map[chapter.chapterNumber] = chapter;
      }
    } catch (_) {
      // Si por algun motivo falta el archivo del libro, se deja vacio y
      // getChapter devolvera un capitulo de salvaguarda.
    }

    _bookCache[bookId] = map;
    return map;
  }

  Future<BibleChapterModel> getChapter(String bookId, int chapterNumber) async {
    final book = await _loadBook(bookId);
    return book[chapterNumber] ?? BibleChapterModel.placeholder(bookId, chapterNumber);
  }

  /// Busca un termino en el nombre de los libros (busqueda simple offline).
  Future<List<BibleBookModel>> searchBooks(String query) async {
    final books = await getBooks();
    final q = TextNormalizer.normalize(query.trim());
    if (q.isEmpty) return books;
    return books.where((b) => TextNormalizer.normalize(b.name).contains(q)).toList();
  }

  /// Busca [query] dentro del texto de los versiculos, libro por libro, sin
  /// distinguir mayusculas ni tildes. Emite los resultados a medida que los
  /// encuentra para que la pantalla los muestre de inmediato.
  Stream<BibleSearchHit> searchText(
    String query, {
    String? testament,
    int limit = 300,
  }) async* {
    final q = TextNormalizer.normalize(query.trim());
    if (q.length < 3) return;
    final books = await getBooks();
    var found = 0;
    for (final book in books) {
      if (testament != null && book.testament != testament) continue;
      final chapters = await _loadBook(book.id);
      final normalized = _normalizedCache.putIfAbsent(
        book.id,
        () => {
          for (final e in chapters.entries)
            e.key: e.value.verses.map(TextNormalizer.normalize).toList(growable: false),
        },
      );
      final numbers = chapters.keys.toList()..sort();
      for (final n in numbers) {
        final chapter = chapters[n]!;
        final plain = normalized[n]!;
        for (var i = 0; i < chapter.verses.length; i++) {
          final text = chapter.verses[i];
          if (plain[i].contains(q)) {
            yield BibleSearchHit(
              bookId: book.id,
              chapter: n,
              verse: chapter.verseNumber(i),
              text: text,
            );
            if (++found >= limit) return;
          }
        }
      }
    }
  }
}

List<Map<String, dynamic>> _decodeChapters(String raw) {
  final data = json.decode(raw) as Map<String, dynamic>;
  return (data['chapters'] as List).cast<Map<String, dynamic>>();
}
