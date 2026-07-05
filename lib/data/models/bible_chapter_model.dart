/// Contenido de un capitulo. Cuando `isPlaceholder` es true, el texto es
/// un marcador de posicion pendiente de reemplazar con una version de la
/// Biblia debidamente licenciada.
class BibleChapterModel {
  final String bookId;
  final int chapterNumber;
  final List<String> verses;
  final bool isPlaceholder;

  const BibleChapterModel({
    required this.bookId,
    required this.chapterNumber,
    required this.verses,
    this.isPlaceholder = false,
  });

  factory BibleChapterModel.fromJson(Map<String, dynamic> json) {
    return BibleChapterModel(
      bookId: json['bookId'] as String,
      chapterNumber: json['chapterNumber'] as int,
      verses: List<String>.from(json['verses'] as List),
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
    );
  }

  /// Genera un capitulo de relleno cuando aun no existe contenido curado.
  factory BibleChapterModel.placeholder(String bookId, int chapterNumber, {int verseCount = 12}) {
    return BibleChapterModel(
      bookId: bookId,
      chapterNumber: chapterNumber,
      isPlaceholder: true,
      verses: List.generate(
        verseCount,
        (i) => 'Texto de muestra en desarrollo. Este capitulo se completara '
            'con una version de la Biblia debidamente licenciada.',
      ),
    );
  }
}
