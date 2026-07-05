class SaintModel {
  final int month;
  final int day;
  final String name;
  final String story;
  final String phrase;
  final String prayer;

  const SaintModel({
    required this.month,
    required this.day,
    required this.name,
    required this.story,
    required this.phrase,
    required this.prayer,
  });

  factory SaintModel.fromJson(Map<String, dynamic> json) {
    return SaintModel(
      month: json['month'] as int,
      day: json['day'] as int,
      name: json['name'] as String,
      story: json['story'] as String,
      phrase: json['phrase'] as String,
      prayer: json['prayer'] as String,
    );
  }
}
