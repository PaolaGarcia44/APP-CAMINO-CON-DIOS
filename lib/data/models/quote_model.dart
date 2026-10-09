/// Mensaje del dia (frase de fe, esperanza o versiculo biblico).
///
/// [category]: 'manana' | 'esperanza' | 'dificil' | 'dios' | 'fe' | 'biblia'.
/// [reference] solo existe en los versiculos (p. ej. "Juan 14:27"); su texto
/// proviene de la misma Biblia de dominio publico que usa la app.
class QuoteModel {
  final String id;
  final String text;
  final String category;
  final String? reference;

  const QuoteModel({
    required this.id,
    required this.text,
    this.category = 'fe',
    this.reference,
  });

  /// Texto listo para mostrar o compartir, con la cita si la tiene.
  String get fullText => reference == null ? text : '$text\n— $reference';

  factory QuoteModel.fromJson(Map<String, dynamic> json) {
    return QuoteModel(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String? ?? 'fe',
      reference: json['reference'] as String?,
    );
  }
}
