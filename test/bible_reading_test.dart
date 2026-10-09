import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:luz_para_hoy/core/utils/bible_reference_parser.dart';
import 'package:luz_para_hoy/core/utils/text_normalizer.dart';
import 'package:luz_para_hoy/data/datasources/bible_local_datasource.dart';
import 'package:luz_para_hoy/data/repositories/bible_repository_impl.dart';
import 'package:luz_para_hoy/domain/entities/bible_reading.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dataSource = BibleLocalDataSource();

  group('TextNormalizer', () {
    test('quita tildes y pasa a minusculas', () {
      expect(TextNormalizer.normalize('Génesis ÁÉÍÓÚ Ñandú'), 'genesis aeiou nandu');
    });
  });

  group('BibleReferenceParser', () {
    late List books;
    setUpAll(() async => books = await dataSource.getBooks());

    BibleReference? parse(String q) => BibleReferenceParser.parse(q, books.cast());

    test('reconoce libro, capitulo y versiculo en varios formatos', () {
      expect(parse('Juan 3:16'), const BibleReference(bookId: 'jn', chapter: 3, verse: 16));
      expect(parse('jn 3 16'), const BibleReference(bookId: 'jn', chapter: 3, verse: 16));
      expect(parse('Flp 4,13'), const BibleReference(bookId: 'fp', chapter: 4, verse: 13));
      expect(parse('1 cor 13'), const BibleReference(bookId: '1co', chapter: 13));
      expect(parse('salmo 23'), const BibleReference(bookId: 'sal', chapter: 23));
      expect(parse('Génesis'), const BibleReference(bookId: 'gn'));
      expect(parse('1 jn 4:8'), const BibleReference(bookId: '1jn', chapter: 4, verse: 8));
    });

    test('rechaza capitulos inexistentes y texto que no es referencia', () {
      expect(parse('Juan 99'), isNull);
      expect(parse('misericordia'), isNull);
      expect(parse(''), isNull);
    });
  });

  group('Busqueda de texto', () {
    test('encuentra versiculos sin importar tildes', () async {
      final hits = await dataSource.searchText('Verbo', testament: 'nuevo').take(5).toList();
      expect(hits, isNotEmpty);
      expect(hits.any((h) => h.bookId == 'jn' && h.chapter == 1 && h.verse == 1), true);
    });

    test('respeta el filtro por testamento', () async {
      final hits = await dataSource.searchText('misericordia', testament: 'antiguo').take(20).toList();
      expect(hits, isNotEmpty);
      final books = await dataSource.getBooks();
      final nt = books.where((b) => b.testament == 'nuevo').map((b) => b.id).toSet();
      expect(hits.any((h) => nt.contains(h.bookId)), false);
    });

    test('no busca con menos de 3 letras', () async {
      expect(await dataSource.searchText('de').toList(), isEmpty);
    });
  });

  group('Progreso de lectura persistente', () {
    late BibleRepositoryImpl repo;

    setUp(() async {
      final dir = await Directory.systemTemp.createTemp('bible_progress_test');
      Hive.init(dir.path);
      repo = BibleRepositoryImpl(
        dataSource: dataSource,
        progressBox: await Hive.openBox('p_${dir.hashCode}'),
        bookmarksBox: await Hive.openBox('b_${dir.hashCode}'),
      );
    });

    test('recuerda la ultima posicion y arma el historial sin duplicados', () async {
      await repo.saveLastPosition('gn', 1);
      await repo.saveLastPosition('jn', 3, verse: 16);
      await repo.saveLastPosition('gn', 1, verse: 3);

      final last = repo.getLastPosition()!;
      expect(last.bookId, 'gn');
      expect(last.verse, 3);
      final history = repo.getHistory();
      expect(history.map((e) => '${e.bookId}:${e.chapter}').toList(), ['gn:1', 'jn:3']);
    });

    test('marca capitulos leidos y avanzar el plan cuenta como leido', () async {
      await repo.setChapterRead('mt', 5, true);
      expect(repo.getReadChapters(), contains('mt:5'));
      await repo.setChapterRead('mt', 5, false);
      expect(repo.getReadChapters(), isNot(contains('mt:5')));

      final next = await repo.advanceToNextDay();
      expect(repo.getReadChapters(), contains('gn:1'));
      expect(next.currentChapter, 2);
    });

    test('marcadores de capitulo y de versiculo conviven', () async {
      await repo.toggleBookmark(const BookmarkKey('sal', 23).value);
      await repo.toggleBookmark(const BookmarkKey('jn', 3, 16).value);
      final keys = (await repo.getBookmarks()).map(BookmarkKey.tryParse).toList();
      expect(keys.any((k) => k!.bookId == 'sal' && k.verse == null), true);
      expect(keys.any((k) => k!.bookId == 'jn' && k.verse == 16), true);
    });
  });
}
