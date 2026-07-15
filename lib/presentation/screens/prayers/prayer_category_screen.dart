import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/favorite_item.dart';
import '../../providers/content_providers.dart';
import '../../providers/favorites_providers.dart';

/// Recibe el indice de la categoria (no el nombre) para evitar problemas de
/// codificacion en la URL con tildes/ñ/espacios. El nombre real se resuelve
/// a partir de la lista de categorias.
class PrayerCategoryScreen extends ConsumerWidget {
  final int categoryIndex;
  const PrayerCategoryScreen({super.key, required this.categoryIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(prayerCategoriesProvider);
    return categoriesAsync.when(
      data: (categories) {
        if (categoryIndex < 0 || categoryIndex >= categories.length) {
          return Scaffold(
            appBar: AppBar(title: const Text('Oraciones')),
            body: const Center(child: Text('Categoria no encontrada.')),
          );
        }
        return _CategoryPrayers(category: categories[categoryIndex]);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => const Scaffold(
        body: Center(child: Text('No se pudieron cargar las oraciones.')),
      ),
    );
  }
}

class _CategoryPrayers extends ConsumerWidget {
  final String category;
  const _CategoryPrayers({required this.category});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prayersAsync = ref.watch(prayersByCategoryProvider(category));
    return Scaffold(
      appBar: AppBar(title: Text(category)),
      body: prayersAsync.when(
        data: (prayers) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: prayers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final prayer = prayers[i];
            return Card(
              child: ExpansionTile(
                title: Text(prayer.title, style: Theme.of(context).textTheme.titleMedium),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                children: [
                  Text(prayer.text, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () async {
                          await ref.read(favoritesProvider.notifier).add(
                                FavoriteItem(
                                  id: 'prayer_${prayer.id}',
                                  type: FavoriteType.prayer,
                                  title: prayer.title,
                                  content: prayer.text,
                                  dateAdded: DateTime.now(),
                                ),
                              );
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Guardada en favoritos')),
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.share_outlined),
                        onPressed: () => Share.share('${prayer.title}\n\n${prayer.text}'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar las oraciones.')),
      ),
    );
  }
}
