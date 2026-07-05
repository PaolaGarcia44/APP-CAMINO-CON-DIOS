import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/favorite_item.dart';
import '../../providers/favorites_providers.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    (FavoriteType.verse, 'Versiculos'),
    (FavoriteType.prayer, 'Oraciones'),
    (FavoriteType.reflection, 'Reflexiones'),
    (FavoriteType.quote, 'Frases'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoritesAsync = ref.watch(favoritesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t.$2)).toList(),
        ),
      ),
      body: favoritesAsync.when(
        data: (items) => TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            final filtered = items.where((f) => f.type == t.$1).toList();
            if (filtered.isEmpty) {
              return const Center(child: Text('Aun no tienes elementos guardados aqui.'));
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final item = filtered[i];
                return Card(
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: Text(item.content, maxLines: 3, overflow: TextOverflow.ellipsis),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.share_outlined),
                          onPressed: () => Share.share('${item.title}\n\n${item.content}'),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => ref.read(favoritesProvider.notifier).remove(item.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }).toList(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => const Center(child: Text('No se pudieron cargar los favoritos.')),
      ),
    );
  }
}
