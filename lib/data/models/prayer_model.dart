class PrayerModel {
  final String id;
  final String category;
  final String title;
  final String text;

  const PrayerModel({
    required this.id,
    required this.category,
    required this.title,
    required this.text,
  });

  factory PrayerModel.fromJson(Map<String, dynamic> json) {
    return PrayerModel(
      id: json['id'] as String,
      category: json['category'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
    );
  }
}
