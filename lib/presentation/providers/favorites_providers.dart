import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/favorite_item.dart';
import 'repository_providers.dart';

class FavoritesNotifier extends StateNotifier<AsyncValue<List<FavoriteItem>>> {
  final Ref ref;
  FavoritesNotifier(this.ref) : super(const AsyncValue.loading()) {
    refresh();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await ref.read(favoritesRepositoryProvider).getAll());
  }

  Future<void> add(FavoriteItem item) async {
    await ref.read(favoritesRepositoryProvider).add(item);
    await refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(favoritesRepositoryProvider).remove(id);
    await refresh();
  }

  Future<bool> isFavorite(String id) {
    return ref.read(favoritesRepositoryProvider).isFavorite(id);
  }
}

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<FavoriteItem>>>(
  (ref) => FavoritesNotifier(ref),
);
