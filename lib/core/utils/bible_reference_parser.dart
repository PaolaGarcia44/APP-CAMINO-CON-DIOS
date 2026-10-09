import '../../data/models/bible_book_model.dart';
import '../../domain/entities/bible_reading.dart';
import 'text_normalizer.dart';

/// Interpreta referencias escritas por el usuario: "Juan 3:16", "jn 3 16",
/// "1 Cor 13", "Salmos 23,1", "genesis". Devuelve null si el texto no
/// empieza por el nombre (o abreviatura) de un libro.
class BibleReferenceParser {
  BibleReferenceParser._();

  /// Abreviaturas comunes en español que no coinciden con el inicio del
  /// nombre del libro ni con su id interno.
  static const Map<String, String> _aliases = {
    'gen': 'gn',
    'exo': 'ex',
    'lev': 'lv',
    'num': 'nm',
    'deut': 'dt',
    'jue': 'jc',
    'jueces': 'jc',
    'tb': 'tob',
    'sl': 'sal',
    'ps': 'sal',
    'prov': 'prv',
    'qo': 'ecl',
    'ct': 'cnt',
    'cant': 'cnt',
    'sb': 'sab',
    'sir': 'eco',
    'si': 'eco',
    'eclo': 'eco',
    'jer': 'jr',
    'lam': 'lm',
    'ba': 'bar',
    'dan': 'dn',
    'mat': 'mt',
    'mr': 'mc',
    'mar': 'mc',
    'luc': 'lc',
    'jua': 'jn',
    'hech': 'hch',
    'rom': 'rm',
    'gal': 'gl',
    'efe': 'ef',
    'flp': 'fp',
    'fil': 'fp',
    'heb': 'hb',
    'sant': 'st',
    'stg': 'st',
    'jds': 'jds',
    'apoc': 'ap',
  };

  static final _pattern =
      RegExp(r'^\s*(\d?\s*[a-zñ]+(?:\s+[a-zñ]+)*?)\.?\s*(?:(\d+)(?:\s*[:,.\s]\s*(\d+))?)?\s*$');

  static BibleReference? parse(String input, List<BibleBookModel> books) {
    final text = TextNormalizer.normalize(input.trim());
    if (text.isEmpty) return null;
    final match = _pattern.firstMatch(text);
    if (match == null) return null;

    final rawBook = match.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
    final book = _findBook(rawBook, books);
    if (book == null) return null;

    var chapter = match.group(2) == null ? null : int.tryParse(match.group(2)!);
    var verse = match.group(3) == null ? null : int.tryParse(match.group(3)!);
    if (chapter != null && (chapter < 1 || chapter > book.chapterCount)) {
      return null;
    }
    if (verse != null && verse < 1) verse = null;
    if (chapter == null) verse = null;
    return BibleReference(bookId: book.id, chapter: chapter, verse: verse);
  }

  static BibleBookModel? _findBook(String raw, List<BibleBookModel> books) {
    final compact = raw.replaceAll(' ', '');
    // 1) Id interno exacto ("jn", "1co", "sal").
    for (final b in books) {
      if (b.id == compact) return b;
    }
    // 2) Alias conocido, conservando el numeral ("1 cor" -> "1" + "cor").
    final numeral = RegExp(r'^(\d)').firstMatch(compact)?.group(1) ?? '';
    final word = compact.substring(numeral.length);
    final alias = _aliases[word];
    if (alias != null) {
      final id = numeral.isEmpty ? alias : '$numeral${alias.replaceFirst(RegExp(r'^\d'), '')}';
      for (final b in books) {
        if (b.id == id) return b;
      }
    }
    // 3) Prefijo del nombre del libro ("gen" -> Genesis, "1 cor" -> 1 Corintios).
    if (word.length < 2) return null;
    for (final b in books) {
      final name = TextNormalizer.normalize(b.name).replaceAll(' ', '');
      if (name.startsWith(compact)) return b;
    }
    return null;
  }
}
