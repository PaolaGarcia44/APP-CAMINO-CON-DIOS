class ReflectionModel {
  final String id;
  final String title;
  final String text;
  final String verseRef;
  final String closingMessage;

  const ReflectionModel({
    required this.id,
    required this.title,
    required this.text,
    required this.verseRef,
    required this.closingMessage,
  });

  factory ReflectionModel.fromJson(Map<String, dynamic> json) {
    return ReflectionModel(
      id: json['id'] as String,
      title: json['title'] as String,
      text: json['text'] as String,
      verseRef: json['verseRef'] as String,
      closingMessage: json['closingMessage'] as String,
    );
  }
}
