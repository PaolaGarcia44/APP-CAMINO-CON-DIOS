import '../../data/models/favorite_item.dart';

abstract class FavoritesRepository {
  Future<List<FavoriteItem>> getAll();
  Future<List<FavoriteItem>> getByType(FavoriteType type);
  Future<void> add(FavoriteItem item);
  Future<void> remove(String id);
  Future<bool> isFavorite(String id);
}
