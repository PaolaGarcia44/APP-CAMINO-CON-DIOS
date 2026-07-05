import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/app_card.dart';
import '../../../routes/route_paths.dart';
import '../../providers/bible_providers.dart';

class BibleHomeScreen extends ConsumerWidget {
  const BibleHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(bibleProgressProvider);
    final booksAsync = ref.watch(bibleBooksProvider);
    final totalAsync = ref.watch(bibleTotalChaptersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Biblia'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(RoutePaths.bibleSearch),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          progressAsync.when(
            data: (progress) {
              final bookName = booksAsync.maybeWhen(
                data: (books) => books
                    .firstWhere((b) => b.id == progress.currentBookId, orElse: () => books.first)
                    .name,
                orElse: () => '',
              );
              final total = totalAsync.maybeWhen(data: (t) => t, orElse: () => 0);
              final pct = total > 0 ? (progress.dayNumber / total).clamp(0.0, 1.0) : 0.0;
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tu lectura de hoy', style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Text('$bookName ${progress.currentChapter}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(value: pct, minHeight: 8),
                    ),
                    const SizedBox(height: 6),
                    Text('Dia ${progress.dayNumber} de $total capitulos',
                        style: Theme.of(context).textTheme.bodyMedium),
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
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.library_books_outlined,
                  label: 'Libros',
                  onTap: () => context.push(RoutePaths.bibleBooks),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickAction(
                  icon: Icons.bookmark_outline,
                  label: 'Marcadores',
                  onTap: () => context.push(RoutePaths.bibleBookmarks),
                ),
              ),
            ],
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
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
