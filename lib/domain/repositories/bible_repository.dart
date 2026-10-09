import '../../data/models/bible_book_model.dart';
import '../../data/models/bible_chapter_model.dart';
import '../entities/bible_progress.dart';
import '../entities/bible_reading.dart';

abstract class BibleRepository {
  Future<List<BibleBookModel>> getBooks();
  Future<List<BibleBookModel>> searchBooks(String query);
  Future<BibleChapterModel> getChapter(String bookId, int chapterNumber);

  /// Busqueda de palabras dentro del texto biblico (offline).
  Stream<BibleSearchHit> searchText(String query, {String? testament});

  /// Numero total de capitulos en toda la Biblia (para calcular el % de avance).
  Future<int> totalChapters();

  Future<BibleProgress> getProgress();

  /// Marca el dia actual como leido y avanza al siguiente capitulo en orden.
  Future<BibleProgress> advanceToNextDay();

  /// Permite saltar manualmente a un libro/capitulo especifico sin alterar
  /// el progreso guardado (navegacion libre).
  Future<int> dayNumberFor(String bookId, int chapterNumber);

  // --- Continuar leyendo e historial ---
  BibleReadingPosition? getLastPosition();

  /// Guarda el punto de lectura actual y lo agrega al historial.
  Future<void> saveLastPosition(String bookId, int chapter, {int? verse});

  List<BibleHistoryEntry> getHistory();
  Future<void> clearHistory();

  // --- Capitulos leidos (progreso real, independiente del plan) ---
  Set<String> getReadChapters();
  Future<void> setChapterRead(String bookId, int chapter, bool read);

  // --- Marcadores (capitulo o versiculo) ---
  Future<List<String>> getBookmarks();
  Future<void> toggleBookmark(String verseKey);
  Future<bool> isBookmarked(String verseKey);
}
