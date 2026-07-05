class RosaryMysteryModel {
  final String title;
  final String verseRef;
  final String meditation;

  const RosaryMysteryModel({
    required this.title,
    required this.verseRef,
    required this.meditation,
  });

  factory RosaryMysteryModel.fromJson(Map<String, dynamic> json) {
    return RosaryMysteryModel(
      title: json['title'] as String,
      verseRef: json['verseRef'] as String,
      meditation: json['meditation'] as String,
    );
  }
}

class RosaryMysterySetModel {
  final String id; // gozosos | dolorosos | gloriosos | luminosos
  final String name;
  final List<int> weekdays; // 1 = lunes ... 7 = domingo (DateTime.weekday)
  final List<RosaryMysteryModel> mysteries;

  const RosaryMysterySetModel({
    required this.id,
    required this.name,
    required this.weekdays,
    required this.mysteries,
  });

  factory RosaryMysterySetModel.fromJson(Map<String, dynamic> json) {
    return RosaryMysterySetModel(
      id: json['id'] as String,
      name: json['name'] as String,
      weekdays: List<int>.from(json['weekdays'] as List),
      mysteries: (json['mysteries'] as List)
          .map((e) => RosaryMysteryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
