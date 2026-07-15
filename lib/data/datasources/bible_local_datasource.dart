import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bible_book_model.dart';
import '../models/bible_chapter_model.dart';

/// Lee el indice de libros y el texto completo de cada libro desde
/// assets/data/bible. Cada libro vive en su propio archivo
/// (assets/data/bible/books/<id>.json) y se carga de forma diferida la
/// primera vez que se abre, quedando luego en cache en memoria.
class BibleLocalDataSource {
  List<BibleBookModel>? _books;
  final Map<String, Map<int, BibleChapterModel>> _bookCache = {};

  Future<List<BibleBookModel>> getBooks() async {
    if (_books != null) return _books!;
    final raw = await rootBundle.loadString('assets/data/bible/books_index.json');
    final list = json.decode(raw) as List;
    _books = list.map((e) => BibleBookModel.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _books!;
  }

  /// Carga (y cachea) todos los capitulos de un libro, indexados por numero.
  Future<Map<int, BibleChapterModel>> _loadBook(String bookId) async {
    final cached = _bookCache[bookId];
    if (cached != null) return cached;

    final map = <int, BibleChapterModel>{};
    try {
      final raw = await rootBundle.loadString('assets/data/bible/books/$bookId.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final chapters = data['chapters'] as List;
      for (final c in chapters) {
        final chapter = BibleChapterModel.fromJson(c as Map<String, dynamic>, bookId: bookId);
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
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return books;
    return books.where((b) => b.name.toLowerCase().contains(q)).toList();
  }
}
