enum FavoriteType { verse, prayer, reflection, quote }

extension FavoriteTypeX on FavoriteType {
  String get key => toString().split('.').last;

  static FavoriteType fromKey(String key) {
    return FavoriteType.values.firstWhere((e) => e.key == key);
  }
}

/// Representa un elemento guardado en favoritos. Se persiste en Hive como
/// Map<String, dynamic> (sin necesidad de un TypeAdapter generado).
class FavoriteItem {
  final String id;
  final FavoriteType type;
  final String title;
  final String content;
  final DateTime dateAdded;

  const FavoriteItem({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.dateAdded,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type.key,
        'title': title,
        'content': content,
        'dateAdded': dateAdded.toIso8601String(),
      };

  factory FavoriteItem.fromMap(Map<dynamic, dynamic> map) {
    return FavoriteItem(
      id: map['id'] as String,
      type: FavoriteTypeX.fromKey(map['type'] as String),
      title: map['title'] as String,
      content: map['content'] as String,
      dateAdded: DateTime.parse(map['dateAdded'] as String),
    );
  }
}
