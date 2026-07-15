import 'package:flutter_test/flutter_test.dart';
import 'package:luz_para_hoy/data/datasources/bible_local_datasource.dart';
import 'package:luz_para_hoy/data/datasources/prayers_local_datasource.dart';

void main() {
  // Necesario para poder usar rootBundle (carga de assets) dentro de los tests.
  TestWidgetsFlutterBinding.ensureInitialized();

  final bible = BibleLocalDataSource();

  test('El indice tiene los 73 libros del canon catolico', () async {
    final books = await bible.getBooks();
    expect(books.length, 73);
    // Los deuterocanonicos deben estar presentes.
    final ids = books.map((b) => b.id).toSet();
    for (final id in ['tob', 'jdt', 'sab', 'eco', 'bar', '1mc', '2mc']) {
      expect(ids.contains(id), true, reason: 'Falta el libro $id');
    }
  });

  test('Cada libro carga todos sus capitulos con versiculos reales', () async {
    final books = await bible.getBooks();
    for (final book in books) {
      // Primer y ultimo capitulo de cada libro.
      for (final n in {1, book.chapterCount}) {
        final chapter = await bible.getChapter(book.id, n);
        expect(chapter.isPlaceholder, false,
            reason: '${book.name} $n quedo como marcador de posicion');
        expect(chapter.verses.isNotEmpty, true,
            reason: '${book.name} $n no tiene versiculos');
        for (final v in chapter.verses) {
          expect(v.contains('muestra en desarrollo'), false,
              reason: 'Texto de muestra en ${book.name} $n');
          expect(v.trim().isNotEmpty, true);
        }
      }
    }
  });

  test('Daniel y Ester incluyen los capitulos deuterocanonicos', () async {
    // Daniel griego: 14 capitulos (incluye Susana y Bel y el Dragon).
    final dn = await bible.getChapter('dn', 13);
    expect(dn.verses.isNotEmpty, true);
    final ester = await bible.getBooks().then((b) => b.firstWhere((x) => x.id == 'est'));
    expect(ester.chapterCount >= 10, true);
  });

  test('Los versiculos conservan su numeracion real', () async {
    final jn1 = await bible.getChapter('jn', 1);
    expect(jn1.verseNumber(0), 1);
    expect(jn1.numbers.isNotEmpty, true);
  });

  test('Hay una biblioteca amplia de oraciones', () async {
    final prayers = await PrayersLocalDataSource().getAll();
    expect(prayers.length >= 50, true, reason: 'Se esperaban 50+ oraciones');
    final cats = prayers.map((p) => p.category).toSet();
    // Categorias nuevas agregadas.
    for (final c in ['Confianza', 'Paz', 'Jesus', 'Eucaristia', 'Santos', 'Iglesia']) {
      expect(cats.contains(c), true, reason: 'Falta la categoria $c');
    }
  });
}
