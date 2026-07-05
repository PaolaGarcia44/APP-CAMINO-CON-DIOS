import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bible_book_model.dart';
import '../../data/models/bible_chapter_model.dart';
import '../../domain/entities/bible_progress.dart';
import 'repository_providers.dart';

final bibleBooksProvider = FutureProvider<List<BibleBookModel>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBooks();
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

final bibleChapterProvider =
    FutureProvider.family<BibleChapterModel, ChapterRequest>((ref, request) {
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
  }
}

final bibleProgressProvider =
    StateNotifierProvider<BibleProgressNotifier, AsyncValue<BibleProgress>>(
  (ref) => BibleProgressNotifier(ref),
);

final bibleBookmarksProvider = FutureProvider<List<String>>((ref) {
  return ref.watch(bibleRepositoryProvider).getBookmarks();
});
