import 'package:hive/hive.dart';
import '../../core/constants/hive_boxes.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../models/favorite_item.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final Box box;

  FavoritesRepositoryImpl({Box? box}) : box = box ?? Hive.box(HiveBoxes.favorites);

  @override
  Future<List<FavoriteItem>> getAll() async {
    final items = box.values
        .map((e) => FavoriteItem.fromMap(e as Map))
        .toList()
      ..sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return items;
  }

  @override
  Future<List<FavoriteItem>> getByType(FavoriteType type) async {
    final all = await getAll();
    return all.where((f) => f.type == type).toList();
  }

  @override
  Future<void> add(FavoriteItem item) async {
    await box.put(item.id, item.toMap());
  }

  @override
  Future<void> remove(String id) async {
    await box.delete(id);
  }

  @override
  Future<bool> isFavorite(String id) async {
    return box.containsKey(id);
  }
}
