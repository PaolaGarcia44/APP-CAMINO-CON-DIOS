import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/favorite_item.dart';
import '../../../data/models/reflection_model.dart';
import '../../providers/content_providers.dart';
import '../../providers/favorites_providers.dart';

/// Reflexiones: la del dia destacada arriba y el resto para releer.
class ReflectionsScreen extends ConsumerWidget {
  const ReflectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allReflectionsProvider);
    final today = ref.watch(reflectionOfTheDayProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Reflexiones')),
      body: allAsync.when(
        data: (all) {
          final others = all.where((r) => r.id != today?.id).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              if (today != null) ...[
                Text('Reflexión de hoy', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                _ReflectionCard(reflection: today, initiallyExpanded: true),
                const SizedBox(height: 20),
                Text('Otras reflexiones', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
              ],
              for (final r in others)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReflectionCard(reflection: r),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar las reflexiones.')),
      ),
    );
  }
}

class _ReflectionCard extends ConsumerWidget {
  final ReflectionModel reflection;
  final bool initiallyExpanded;

  const _ReflectionCard({required this.reflection, this.initiallyExpanded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favoriteId = 'reflection:${reflection.id}';
    final isFavorite = (ref.watch(favoritesProvider).valueOrNull ?? const []).any((f) => f.id == favoriteId);

    return AppCard(
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(reflection.title, style: theme.textTheme.titleMedium),
        subtitle: Text(reflection.verseRef, style: theme.textTheme.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(reflection.text, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              reflection.closingMessage,
              style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                tooltip: isFavorite ? 'Quitar de favoritos' : 'Guardar en favoritos',
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                onPressed: () {
                  final notifier = ref.read(favoritesProvider.notifier);
                  if (isFavorite) {
                    notifier.remove(favoriteId);
                  } else {
                    notifier.add(FavoriteItem(
                      id: favoriteId,
                      type: FavoriteType.reflection,
                      title: reflection.title,
                      content: '${reflection.text}\n\n${reflection.closingMessage}',
                      dateAdded: DateTime.now(),
                    ));
                  }
                },
              ),
              IconButton(
                tooltip: 'Compartir',
                icon: const Icon(Icons.share_outlined),
                onPressed: () => Share.share(
                  '${reflection.title}\n${reflection.verseRef}\n\n${reflection.text}\n\n'
                  '${reflection.closingMessage}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
