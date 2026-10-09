import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/art_banner.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleHomeScreen extends ConsumerWidget {
  const BibleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(bibleProgressProvider);
    final booksById = ref.watch(bibleBooksByIdProvider);
    final totalAsync = ref.watch(bibleTotalChaptersProvider);
    final lastPosition = ref.watch(lastReadingPositionProvider);
    final readCount = ref.watch(readChaptersProvider).length;
    final theme = Theme.of(context);

    final total = totalAsync.valueOrNull ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblia'),
        actions: [
          IconButton(
            tooltip: 'Buscar',
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RoutePaths.bibleSearch),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ArtBanner(
            asset: 'assets/images/pastor.jpg',
            height: 120,
            child: Text(
              'La Palabra de Dios te espera hoy',
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          if (lastPosition != null) ...[
            AppCard(
              onTap: () => context.push(
                RoutePaths.bibleRead(
                  lastPosition.bookId,
                  lastPosition.chapter,
                  verse: lastPosition.verse,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_fill_rounded, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Continuar leyendo', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(
                          '${booksById[lastPosition.bookId]?.name ?? lastPosition.bookId} '
                          '${lastPosition.chapter}'
                          '${lastPosition.verse != null ? ':${lastPosition.verse}' : ''}',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
          progressAsync.when(
            data: (progress) {
              final bookName = booksById[progress.currentBookId]?.name ?? '';
              final pct = total > 0 ? (readCount / total).clamp(0.0, 1.0) : 0.0;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Plan: la Biblia en orden', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Text('$bookName ${progress.currentChapter}', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: pct, minHeight: 8),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$readCount de $total capitulos leidos · '
                      '${(pct * 100).toStringAsFixed(pct > 0 && pct < 0.01 ? 1 : 0)}%',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Leer capitulo de hoy'),
                        onPressed: () => context.push(
                          RoutePaths.bibleRead(progress.currentBookId, progress.currentChapter),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 160, child: Center(child: CircularProgressIndicator())),
            error: (e, st) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.9,
            children: [
              _QuickAction(
                icon: Icons.library_books_outlined,
                label: 'Libros',
                onTap: () => context.push(RoutePaths.bibleBooks),
              ),
              _QuickAction(
                icon: Icons.manage_search_rounded,
                label: 'Buscar',
                onTap: () => context.push(RoutePaths.bibleSearch),
              ),
              _QuickAction(
                icon: Icons.bookmark_outline,
                label: 'Marcadores',
                onTap: () => context.push(RoutePaths.bibleBookmarks),
              ),
              _QuickAction(
                icon: Icons.history_rounded,
                label: 'Historial',
                onTap: () => context.push(RoutePaths.bibleHistory),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Texto: Santa Biblia libre Latinoamericano (dominio publico, eBible.org). '
            'Toca un versiculo para guardarlo, marcarlo o compartirlo.',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
        ],
      ),
    );
  }
}
