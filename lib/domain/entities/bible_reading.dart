/// Ultimo punto de lectura del usuario (libro, capitulo y, si aplica,
/// versiculo), usado para "Continuar leyendo".
class BibleReadingPosition {
  final String bookId;
  final int chapter;
  final int? verse;
  final DateTime updatedAt;

  const BibleReadingPosition({
    required this.bookId,
    required this.chapter,
    this.verse,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() => {
        'bookId': bookId,
        'chapter': chapter,
        'verse': verse,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BibleReadingPosition.fromMap(Map<dynamic, dynamic> map) {
    return BibleReadingPosition(
      bookId: map['bookId'] as String,
      chapter: map['chapter'] as int,
      verse: map['verse'] as int?,
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Capitulo abierto recientemente (historial de lectura).
typedef BibleHistoryEntry = BibleReadingPosition;

/// Resultado de la busqueda por texto dentro de la Biblia.
class BibleSearchHit {
  final String bookId;
  final int chapter;
  final int verse;
  final String text;

  const BibleSearchHit({
    required this.bookId,
    required this.chapter,
    required this.verse,
    required this.text,
  });
}

/// Referencia biblica interpretada a partir de lo que escribe el usuario
/// (p. ej. "Jn 3:16", "1 cor 13", "salmos 23,1").
class BibleReference {
  final String bookId;
  final int? chapter;
  final int? verse;

  const BibleReference({required this.bookId, this.chapter, this.verse});

  @override
  bool operator ==(Object other) =>
      other is BibleReference && other.bookId == bookId && other.chapter == chapter && other.verse == verse;

  @override
  int get hashCode => Object.hash(bookId, chapter, verse);

  @override
  String toString() => 'BibleReference($bookId $chapter:$verse)';
}

/// Clave de un marcador. Formato `libro:capitulo` (capitulo completo) o
/// `libro:capitulo:versiculo` (versiculo concreto). Los marcadores de
/// capitulo guardados por versiones anteriores siguen siendo validos.
class BookmarkKey {
  final String bookId;
  final int chapter;
  final int? verse;

  const BookmarkKey(this.bookId, this.chapter, [this.verse]);

  String get value => verse == null ? '$bookId:$chapter' : '$bookId:$chapter:$verse';

  static BookmarkKey? tryParse(String raw) {
    final parts = raw.split(':');
    if (parts.length < 2) return null;
    final chapter = int.tryParse(parts[1]);
    if (chapter == null) return null;
    final verse = parts.length > 2 ? int.tryParse(parts[2]) : null;
    return BookmarkKey(parts[0], chapter, verse);
  }
}
