class BibleBookModel {
  final int order;
  final String id;
  final String name;
  final String testament; // 'antiguo' | 'nuevo'
  final int chapterCount;

  const BibleBookModel({
    required this.order,
    required this.id,
    required this.name,
    required this.testament,
    required this.chapterCount,
  });

  factory BibleBookModel.fromJson(Map<String, dynamic> json) {
    return BibleBookModel(
      order: json['order'] as int,
      id: json['id'] as String,
      name: json['name'] as String,
      testament: json['testament'] as String,
      chapterCount: json['chapterCount'] as int,
    );
  }
}
