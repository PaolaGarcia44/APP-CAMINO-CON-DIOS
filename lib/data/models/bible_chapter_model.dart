/// Contenido de un capitulo de la Biblia.
///
/// `verses` son los textos de los versiculos en orden y `numbers` el numero
/// real de cada versiculo (util en libros donde la numeracion no es 1..N,
/// como algunos capitulos de Ester griego o del Siracide). Cuando
/// `isPlaceholder` es true, el capitulo no tiene contenido curado disponible.
class BibleChapterModel {
  final String bookId;
  final int chapterNumber;
  final List<String> verses;
  final List<int> numbers;
  final bool isPlaceholder;

  const BibleChapterModel({
    required this.bookId,
    required this.chapterNumber,
    required this.verses,
    this.numbers = const [],
    this.isPlaceholder = false,
  });

  /// Numero de versiculo a mostrar para la posicion [index]. Si el capitulo
  /// trae numeracion explicita se usa; si no, se asume secuencial (index + 1).
  int verseNumber(int index) =>
      (index >= 0 && index < numbers.length) ? numbers[index] : index + 1;

  factory BibleChapterModel.fromJson(Map<String, dynamic> json, {String? bookId}) {
    return BibleChapterModel(
      bookId: bookId ?? json['bookId'] as String,
      chapterNumber: json['chapterNumber'] as int,
      verses: List<String>.from(json['verses'] as List),
      numbers: json['numbers'] == null
          ? const []
          : List<int>.from(json['numbers'] as List),
      isPlaceholder: json['isPlaceholder'] as bool? ?? false,
    );
  }

  /// Capitulo de relleno usado solo como salvaguarda si faltara el archivo
  /// de un libro. En la app completa no deberia generarse.
  factory BibleChapterModel.placeholder(String bookId, int chapterNumber, {int verseCount = 1}) {
    return BibleChapterModel(
      bookId: bookId,
      chapterNumber: chapterNumber,
      isPlaceholder: true,
      verses: List.generate(
        verseCount,
        (i) => 'Este capitulo no esta disponible por el momento.',
      ),
    );
  }
}
