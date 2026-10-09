import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_theme.dart';
import '../../../data/models/bible_book_model.dart';
import '../../../data/models/bible_chapter_model.dart';
import '../../../data/models/favorite_item.dart';
import '../../../domain/entities/bible_reading.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';
import '../../providers/favorites_providers.dart';
import '../../providers/settings_providers.dart';

class BibleReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final int chapterNumber;
  final int? initialVerse;

  const BibleReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterNumber,
    this.initialVerse,
  });

  @override
  ConsumerState<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends ConsumerState<BibleReaderScreen> {
  final _verseKey = GlobalKey();
  int? _highlightedVerse;
  bool _scrolledToVerse = false;

  String get bookId => widget.bookId;
  int get chapterNumber => widget.chapterNumber;

  @override
  void initState() {
    super.initState();
    _highlightedVerse = widget.initialVerse;
    // Guardar el punto de lectura en cuanto se abre el capitulo.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bibleReadingActionsProvider).savePosition(bookId, chapterNumber, verse: widget.initialVerse);
    });
  }

  ({String bookId, int chapter})? _shiftChapter(List<BibleBookModel> books, int direction) {
    final index = books.indexWhere((b) => b.id == bookId);
    if (index == -1) return null;
    final book = books[index];
    final target = chapterNumber + direction;
    if (target >= 1 && target <= book.chapterCount) {
      return (bookId: book.id, chapter: target);
    }
    final neighborIndex = index + direction;
    if (neighborIndex < 0 || neighborIndex >= books.length) return null;
    final neighbor = books[neighborIndex];
    return (bookId: neighbor.id, chapter: direction > 0 ? 1 : neighbor.chapterCount);
  }

  void _go(List<BibleBookModel> books, int direction) {
    final target = _shiftChapter(books, direction);
    if (target == null) return;
    context.pushReplacement(RoutePaths.bibleRead(target.bookId, target.chapter));
  }

  void _scrollToInitialVerse() {
    if (_scrolledToVerse || widget.initialVerse == null) return;
    _scrolledToVerse = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _verseKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.25,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chapterAsync = ref.watch(bibleChapterProvider(ChapterRequest(bookId, chapterNumber)));
    final booksAsync = ref.watch(bibleBooksProvider);
    final fontScale = ref.watch(readerFontScaleProvider);
    final readingMode = ref.watch(readingModeProvider);
    final bookmarks = ref.watch(bibleBookmarksProvider).valueOrNull ?? const <String>[];
    final readChapters = ref.watch(readChaptersProvider);
    final progressAsync = ref.watch(bibleProgressProvider);
    final chapterBookmark = BookmarkKey(bookId, chapterNumber);
    final isBookmarked = bookmarks.contains(chapterBookmark.value);
    final isRead = readChapters.contains('$bookId:$chapterNumber');

    final books = booksAsync.valueOrNull;
    final book = books?.firstWhere((b) => b.id == bookId, orElse: () => books.first);
    final bookName = book?.name ?? bookId;

    final isPlanChapter = progressAsync.maybeWhen(
      data: (p) => p.currentBookId == bookId && p.currentChapter == chapterNumber,
      orElse: () => false,
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sepia = readingMode == ReadingMode.sepia;
    final background =
        sepia ? (isDark ? const Color(0xFF2A2318) : const Color(0xFFF6EEDC)) : theme.scaffoldBackgroundColor;
    final textColor = sepia
        ? (isDark ? const Color(0xFFE8DCC4) : const Color(0xFF4A3B2A))
        : theme.textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: book == null ? null : () => _showChapterPicker(book),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text('$bookName $chapterNumber', overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: isBookmarked ? 'Quitar marcador' : 'Marcar capitulo',
            icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
            onPressed: () => ref.read(bibleReadingActionsProvider).toggleBookmark(chapterBookmark),
          ),
          IconButton(
            tooltip: 'Letra y modo de lectura',
            icon: const Icon(Icons.text_fields),
            onPressed: _showReadingSettings,
          ),
          IconButton(
            tooltip: 'Compartir capitulo',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              chapterAsync.whenData((chapter) {
                final body = [
                  for (var i = 0; i < chapter.verses.length; i++)
                    '${chapter.verseNumber(i)}  ${chapter.verses[i]}',
                ].join('\n');
                Share.share('$bookName $chapterNumber\n\n$body');
              });
            },
          ),
        ],
      ),
      body: chapterAsync.when(
        data: (chapter) {
          _scrollToInitialVerse();
          return Column(
            children: [
              if (chapter.isPlaceholder)
                Container(
                  width: double.infinity,
                  color: theme.colorScheme.secondaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Este capitulo no esta disponible por el momento.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              Expanded(
                child: GestureDetector(
                  // Deslizar horizontalmente cambia de capitulo.
                  onHorizontalDragEnd: books == null
                      ? null
                      : (details) {
                          final v = details.primaryVelocity ?? 0;
                          if (v.abs() < 500) return;
                          _go(books, v < 0 ? 1 : -1);
                        },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var i = 0; i < chapter.verses.length; i++)
                          _VerseTile(
                            key: chapter.verseNumber(i) == widget.initialVerse ? _verseKey : null,
                            number: chapter.verseNumber(i),
                            text: chapter.verses[i],
                            fontScale: fontScale,
                            textColor: textColor,
                            highlighted: _highlightedVerse == chapter.verseNumber(i),
                            bookmarked: bookmarks.contains(
                              BookmarkKey(bookId, chapterNumber, chapter.verseNumber(i)).value,
                            ),
                            onTap: () => _onVerseTap(chapter, i, bookName),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _ReaderBottomBar(
                canGoBack: books != null && _shiftChapter(books, -1) != null,
                canGoForward: books != null && _shiftChapter(books, 1) != null,
                onBack: () => _go(books!, -1),
                onForward: () => _go(books!, 1),
                isRead: isRead,
                isPlanChapter: isPlanChapter,
                onToggleRead: () async {
                  if (isPlanChapter && !isRead) {
                    await ref.read(bibleProgressProvider.notifier).markTodayAsRead();
                  } else {
                    await ref
                        .read(bibleReadingActionsProvider)
                        .setChapterRead(bookId, chapterNumber, !isRead);
                  }
                },
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudo cargar el capitulo.')),
      ),
    );
  }

  Future<void> _onVerseTap(BibleChapterModel chapter, int index, String bookName) async {
    final verseNumber = chapter.verseNumber(index);
    final text = chapter.verses[index];
    final reference = '$bookName $chapterNumber:$verseNumber';
    final favoriteId = '$bookId:$chapterNumber:$index';
    final bookmarkKey = BookmarkKey(bookId, chapterNumber, verseNumber);

    setState(() => _highlightedVerse = verseNumber);
    ref.read(bibleReadingActionsProvider).savePosition(bookId, chapterNumber, verse: verseNumber);

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final favorites = ref.watch(favoritesProvider).valueOrNull ?? const [];
          final isFavorite = favorites.any((f) => f.id == favoriteId);
          final bookmarks = ref.watch(bibleBookmarksProvider).valueOrNull ?? const <String>[];
          final isBookmarked = bookmarks.contains(bookmarkKey.value);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reference, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(text, maxLines: 4, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _SheetAction(
                        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                        label: 'Favorito',
                        onTap: () async {
                          final notifier = ref.read(favoritesProvider.notifier);
                          if (isFavorite) {
                            await notifier.remove(favoriteId);
                          } else {
                            await notifier.add(FavoriteItem(
                              id: favoriteId,
                              type: FavoriteType.verse,
                              title: reference,
                              content: text,
                              dateAdded: DateTime.now(),
                            ));
                          }
                        },
                      ),
                      _SheetAction(
                        icon: isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
                        label: 'Marcador',
                        onTap: () => ref.read(bibleReadingActionsProvider).toggleBookmark(bookmarkKey),
                      ),
                      _SheetAction(
                        icon: Icons.share_outlined,
                        label: 'Compartir',
                        onTap: () => Share.share('"$text"\n— $reference'),
                      ),
                      _SheetAction(
                        icon: Icons.copy_rounded,
                        label: 'Copiar',
                        onTap: () async {
                          await Clipboard.setData(ClipboardData(text: '"$text" — $reference'));
                          if (sheetContext.mounted) Navigator.pop(sheetContext);
                          if (mounted) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text('Versiculo copiado')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() => _highlightedVerse = null);
  }

  void _showChapterPicker(BibleBookModel book) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final readChapters = ref.read(readChaptersProvider);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (context, controller) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(book.name, style: Theme.of(context).textTheme.titleMedium),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.library_books_outlined, size: 18),
                      label: const Text('Otro libro'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        context.push(RoutePaths.bibleBooks);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 64,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: book.chapterCount,
                  itemBuilder: (context, i) {
                    final n = i + 1;
                    final current = n == chapterNumber;
                    final read = readChapters.contains('${book.id}:$n');
                    final scheme = Theme.of(context).colorScheme;
                    return Material(
                      color: current
                          ? scheme.primary
                          : read
                              ? scheme.primaryContainer
                              : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          if (!current) context.pushReplacement(RoutePaths.bibleRead(book.id, n));
                        },
                        child: Center(
                          child: Text(
                            '$n',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: current ? scheme.onPrimary : null,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showReadingSettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final scale = ref.watch(readerFontScaleProvider);
          final mode = ref.watch(readingModeProvider);
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tamaño de letra', style: Theme.of(context).textTheme.titleMedium),
                  Row(
                    children: [
                      const Text('A', style: TextStyle(fontSize: 14)),
                      Expanded(
                        child: Slider(
                          value: scale,
                          min: 0.8,
                          max: 1.8,
                          divisions: 10,
                          label: '${(scale * 100).round()}%',
                          onChanged: (v) => ref.read(readerFontScaleProvider.notifier).setScale(v),
                        ),
                      ),
                      const Text('A', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Modo de lectura', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  SegmentedButton<ReadingMode>(
                    segments: const [
                      ButtonSegment(
                        value: ReadingMode.standard,
                        icon: Icon(Icons.article_outlined),
                        label: Text('Estandar'),
                      ),
                      ButtonSegment(
                        value: ReadingMode.sepia,
                        icon: Icon(Icons.local_cafe_outlined),
                        label: Text('Sepia'),
                      ),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) => ref.read(readingModeProvider.notifier).setMode(s.first),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VerseTile extends StatelessWidget {
  final int number;
  final String text;
  final double fontScale;
  final Color? textColor;
  final bool highlighted;
  final bool bookmarked;
  final VoidCallback onTap;

  const _VerseTile({
    super.key,
    required this.number,
    required this.text,
    required this.fontScale,
    required this.textColor,
    required this.highlighted,
    required this.bookmarked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.gold.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text.rich(
            TextSpan(
              style: AppTextTheme.scripture.copyWith(
                fontSize: AppTextTheme.scripture.fontSize! * fontScale,
                color: textColor,
              ),
              children: [
                if (bookmarked)
                  WidgetSpan(
                    alignment: PlaceholderAlignment.middle,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(Icons.bookmark, size: 16 * fontScale, color: AppColors.gold),
                    ),
                  ),
                TextSpan(
                  text: '$number  ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: AppTextTheme.scripture.fontSize! * fontScale * 0.72,
                    color: scheme.primary,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
            // El tamaño ya lo controla el ajuste propio del lector.
            textScaler: TextScaler.noScaling,
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SheetAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 6),
            Text(label, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ),
    );
  }
}

class _ReaderBottomBar extends StatelessWidget {
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final bool isRead;
  final bool isPlanChapter;
  final VoidCallback onToggleRead;

  const _ReaderBottomBar({
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.isRead,
    required this.isPlanChapter,
    required this.onToggleRead,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(
          children: [
            IconButton.outlined(
              tooltip: 'Capitulo anterior',
              icon: const Icon(Icons.chevron_left),
              onPressed: canGoBack ? onBack : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: isRead
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle, color: AppColors.success),
                      label: const Text('Leido'),
                      onPressed: onToggleRead,
                    )
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: Text(isPlanChapter ? 'Marcar lectura de hoy' : 'Marcar como leido'),
                      onPressed: onToggleRead,
                    ),
            ),
            const SizedBox(width: 10),
            IconButton.outlined(
              tooltip: 'Capitulo siguiente',
              icon: const Icon(Icons.chevron_right),
              onPressed: canGoForward ? onForward : null,
            ),
          ],
        ),
      ),
    );
  }
}
