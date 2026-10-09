import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bible_book_model.dart';
import '../../data/models/bible_chapter_model.dart';
import '../../domain/entities/bible_progress.dart';
import '../../domain/entities/bible_reading.dart';
import 'repository_providers.dart';

final bibleBooksProvider = FutureProvider<List<BibleBookModel>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBooks();
});

/// Libros indexados por id, para resolver nombres rapidamente.
final bibleBooksByIdProvider = Provider<Map<String, BibleBookModel>>((ref) {
  final books = ref.watch(bibleBooksProvider).valueOrNull ?? const [];
  return {for (final b in books) b.id: b};
});

final bibleTotalChaptersProvider = FutureProvider<int>((ref) {
  return ref.watch(bibleRepositoryProvider).totalChapters();
});

class ChapterRequest {
  final String bookId;
  final int chapterNumber;
  const ChapterRequest(this.bookId, this.chapterNumber);

  @override
  bool operator ==(Object other) =>
      other is ChapterRequest && other.bookId == bookId && other.chapterNumber == chapterNumber;

  @override
  int get hashCode => Object.hash(bookId, chapterNumber);
}

final bibleChapterProvider = FutureProvider.family<BibleChapterModel, ChapterRequest>((ref, request) {
  return ref.watch(bibleRepositoryProvider).getChapter(request.bookId, request.chapterNumber);
});

class BibleProgressNotifier extends StateNotifier<AsyncValue<BibleProgress>> {
  final Ref ref;
  BibleProgressNotifier(this.ref) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await ref.read(bibleRepositoryProvider).getProgress());
  }

  Future<void> markTodayAsRead() async {
    final next = await ref.read(bibleRepositoryProvider).advanceToNextDay();
    state = AsyncValue.data(next);
    ref.invalidate(readChaptersProvider);
  }
}

final bibleProgressProvider = StateNotifierProvider<BibleProgressNotifier, AsyncValue<BibleProgress>>(
  (ref) => BibleProgressNotifier(ref),
);

final bibleBookmarksProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBookmarks();
});

/// Ultimo punto de lectura ("Continuar leyendo").
final lastReadingPositionProvider = Provider<BibleReadingPosition?>((ref) {
  return ref.watch(bibleRepositoryProvider).getLastPosition();
});

final readingHistoryProvider = Provider<List<BibleHistoryEntry>>((ref) {
  return ref.watch(bibleRepositoryProvider).getHistory();
});

/// Capitulos marcados como leidos, con clave `libro:capitulo`.
final readChaptersProvider = Provider<Set<String>>((ref) {
  return ref.watch(bibleRepositoryProvider).getReadChapters();
});

/// Acciones de lectura que actualizan el estado persistido y refrescan los
/// providers que dependen de el.
class BibleReadingActions {
  final Ref ref;
  BibleReadingActions(this.ref);

  Future<void> savePosition(String bookId, int chapter, {int? verse}) async {
    await ref.read(bibleRepositoryProvider).saveLastPosition(bookId, chapter, verse: verse);
    ref.invalidate(lastReadingPositionProvider);
    ref.invalidate(readingHistoryProvider);
  }

  Future<void> setChapterRead(String bookId, int chapter, bool read) async {
    await ref.read(bibleRepositoryProvider).setChapterRead(bookId, chapter, read);
    ref.invalidate(readChaptersProvider);
  }

  Future<void> toggleBookmark(BookmarkKey key) async {
    await ref.read(bibleRepositoryProvider).toggleBookmark(key.value);
    ref.invalidate(bibleBookmarksProvider);
  }

  Future<void> clearHistory() async {
    await ref.read(bibleRepositoryProvider).clearHistory();
    ref.invalidate(readingHistoryProvider);
  }
}

final bibleReadingActionsProvider = Provider((ref) => BibleReadingActions(ref));
