import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../domain/entities/bible_progress.dart';
import '../../domain/entities/bible_reading.dart';
import '../../domain/repositories/bible_repository.dart';
import '../datasources/bible_local_datasource.dart';
import '../models/bible_book_model.dart';
import '../models/bible_chapter_model.dart';

class BibleRepositoryImpl implements BibleRepository {
  final BibleLocalDataSource dataSource;
  final Box progressBox;
  final Box bookmarksBox;

  BibleRepositoryImpl({
    required this.dataSource,
    Box? progressBox,
    Box? bookmarksBox,
  })  : progressBox = progressBox ?? Hive.box(HiveBoxes.bibleProgress),
        bookmarksBox = bookmarksBox ?? Hive.box(HiveBoxes.bibleBookmarks);

  static const _dayNumberKey = 'day_number';
  static const _lastReadKey = 'last_read_date';
  static const _lastPositionKey = 'last_position';
  static const _historyKey = 'history';
  static const _readChaptersKey = 'read_chapters';

  static const maxHistory = 40;

  @override
  Future<List<BibleBookModel>> getBooks() => dataSource.getBooks();

  @override
  Future<List<BibleBookModel>> searchBooks(String query) => dataSource.searchBooks(query);

  @override
  Future<BibleChapterModel> getChapter(String bookId, int chapterNumber) =>
      dataSource.getChapter(bookId, chapterNumber);

  @override
  Stream<BibleSearchHit> searchText(String query, {String? testament}) =>
      dataSource.searchText(query, testament: testament);

  @override
  Future<int> totalChapters() async {
    final books = await getBooks();
    return books.fold<int>(0, (sum, b) => sum + b.chapterCount);
  }

  /// Traduce un numero de dia (1-indexado) a libro y capitulo, recorriendo
  /// la lista de libros en orden canonico.
  Future<({String bookId, int chapter})> _resolveDay(int dayNumber) async {
    final books = await getBooks();
    var remaining = dayNumber;
    for (final book in books) {
      if (remaining <= book.chapterCount) {
        return (bookId: book.id, chapter: remaining);
      }
      remaining -= book.chapterCount;
    }
    final last = books.last;
    return (bookId: last.id, chapter: last.chapterCount);
  }

  @override
  Future<int> dayNumberFor(String bookId, int chapterNumber) async {
    final books = await getBooks();
    var total = 0;
    for (final book in books) {
      if (book.id == bookId) {
        return total + chapterNumber;
      }
      total += book.chapterCount;
    }
    return 1;
  }

  @override
  Future<BibleProgress> getProgress() async {
    final dayNumber = (progressBox.get(_dayNumberKey) as int?) ?? 1;
    final lastReadRaw = progressBox.get(_lastReadKey) as String?;
    final resolved = await _resolveDay(dayNumber);
    return BibleProgress(
      dayNumber: dayNumber,
      currentBookId: resolved.bookId,
      currentChapter: resolved.chapter,
      lastReadDate: lastReadRaw != null ? DateTime.tryParse(lastReadRaw) : null,
    );
  }

  @override
  Future<BibleProgress> advanceToNextDay() async {
    final total = await totalChapters();
    final current = (progressBox.get(_dayNumberKey) as int?) ?? 1;
    final currentChapter = await _resolveDay(current);
    await setChapterRead(currentChapter.bookId, currentChapter.chapter, true);
    final next = current >= total ? 1 : current + 1; // reinicia en Genesis al terminar
    await progressBox.put(_dayNumberKey, next);
    await progressBox.put(_lastReadKey, DateTime.now().toIso8601String());
    return getProgress();
  }

  @override
  BibleReadingPosition? getLastPosition() {
    final raw = progressBox.get(_lastPositionKey);
    if (raw is! Map) return null;
    try {
      return BibleReadingPosition.fromMap(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveLastPosition(String bookId, int chapter, {int? verse}) async {
    final position = BibleReadingPosition(
      bookId: bookId,
      chapter: chapter,
      verse: verse,
      updatedAt: DateTime.now(),
    );
    await progressBox.put(_lastPositionKey, position.toMap());

    // El historial guarda un registro por capitulo (el mas reciente arriba).
    final history = getHistory().where((e) => !(e.bookId == bookId && e.chapter == chapter)).toList()
      ..insert(0, position);
    await progressBox.put(
      _historyKey,
      history.take(maxHistory).map((e) => e.toMap()).toList(),
    );
  }

  @override
  List<BibleHistoryEntry> getHistory() {
    final raw = progressBox.get(_historyKey);
    if (raw is! List) return [];
    final result = <BibleHistoryEntry>[];
    for (final item in raw) {
      if (item is Map) {
        try {
          result.add(BibleReadingPosition.fromMap(item));
        } catch (_) {}
      }
    }
    return result;
  }

  @override
  Future<void> clearHistory() => progressBox.delete(_historyKey);

  @override
  Set<String> getReadChapters() {
    final raw = progressBox.get(_readChaptersKey);
    if (raw is! List) return <String>{};
    return raw.cast<String>().toSet();
  }

  @override
  Future<void> setChapterRead(String bookId, int chapter, bool read) async {
    final set = getReadChapters();
    final key = '$bookId:$chapter';
    if (read) {
      set.add(key);
    } else {
      set.remove(key);
    }
    await progressBox.put(_readChaptersKey, set.toList());
  }

  @override
  Future<List<String>> getBookmarks() {
    return Future.value(bookmarksBox.keys.cast<String>().toList());
  }

  @override
  Future<void> toggleBookmark(String verseKey) async {
    if (bookmarksBox.containsKey(verseKey)) {
      await bookmarksBox.delete(verseKey);
    } else {
      await bookmarksBox.put(verseKey, true);
    }
  }

  @override
  Future<bool> isBookmarked(String verseKey) {
    return Future.value(bookmarksBox.containsKey(verseKey));
  }
}
