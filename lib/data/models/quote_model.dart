class QuoteModel {
  final String id;
  final String text;

  const QuoteModel({required this.id, required this.text});

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(id: json['id'] as String, text: json['text'] as String);
  }
}
