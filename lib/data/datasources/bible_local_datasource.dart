import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/bible_book_model.dart';
import '../models/bible_chapter_model.dart';

/// Lee el indice de libros y los capitulos de muestra desde assets/data/bible.
/// Para capitulos que no tienen contenido curado, genera un marcador de
/// posicion, de modo que la navegacion secuencial funcione en toda la Biblia.
class BibleLocalDataSource {
  List<BibleBookModel>? _books;
  Map<String, BibleChapterModel>? _sampleChapters;

  Future<List<BibleBookModel>> getBooks() async {
    if (_books != null) return _books!;
    final raw = await rootBundle.loadString('assets/data/bible/books_index.json');
    final list = json.decode(raw) as List;
    _books = list.map((e) => BibleBookModel.fromJson(e as Map<String, dynamic>)).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return _books!;
  }

  Future<Map<String, BibleChapterModel>> _loadSamples() async {
    if (_sampleChapters != null) return _sampleChapters!;
    final raw = await rootBundle.loadString('assets/data/bible/sample_chapters.json');
    final map = json.decode(raw) as Map<String, dynamic>;
    final chapters = (map['chapters'] as List)
        .map((e) => BibleChapterModel.fromJson(e as Map<String, dynamic>))
        .toList();
    _sampleChapters = {
      for (final c in chapters) _key(c.bookId, c.chapterNumber): c,
    };
    return _sampleChapters!;
  }

  String _key(String bookId, int chapter) => '$bookId:$chapter';

  Future<BibleChapterModel> getChapter(String bookId, int chapterNumber) async {
    final samples = await _loadSamples();
    final found = samples[_key(bookId, chapterNumber)];
    if (found != null) return found;
    return BibleChapterModel.placeholder(bookId, chapterNumber);
  }

  /// Busca un termino en el nombre de los libros (busqueda simple offline).
  Future<List<BibleBookModel>> searchBooks(String query) async {
    final books = await getBooks();
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return books;
    return books.where((b) => b.name.toLowerCase().contains(q)).toList();
  }
}
