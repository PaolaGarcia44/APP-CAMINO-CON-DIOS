import 'package:flutter_test/flutter_test.dart';
import 'package:luz_para_hoy/core/utils/liturgical_calculator.dart';
import 'package:luz_para_hoy/data/datasources/calendar_local_datasource.dart';
import 'package:luz_para_hoy/domain/entities/liturgical.dart';
import 'package:luz_para_hoy/domain/usecases/catholic_calendar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CatholicCalendar calendar;

  setUpAll(() async {
    calendar = CatholicCalendar(await CalendarLocalDataSource().getFixedCelebrations());
  });

  List<String> namesOn(int y, int m, int d) =>
      calendar.celebrationsOn(DateTime(y, m, d)).map((c) => c.name).toList();

  group('Fechas moviles', () {
    test('Domingo de Pascua', () {
      expect(LiturgicalCalculator.easterSunday(2024), DateTime(2024, 3, 31));
      expect(LiturgicalCalculator.easterSunday(2025), DateTime(2025, 4, 20));
      expect(LiturgicalCalculator.easterSunday(2026), DateTime(2026, 4, 5));
      expect(LiturgicalCalculator.easterSunday(2027), DateTime(2027, 3, 28));
    });

    test('Ceniza, Adviento, Cristo Rey, Epifania y Bautismo (2026)', () {
      expect(LiturgicalCalculator.ashWednesday(2026), DateTime(2026, 2, 18));
      expect(LiturgicalCalculator.firstAdventSunday(2026), DateTime(2026, 11, 29));
      expect(LiturgicalCalculator.christTheKing(2026), DateTime(2026, 11, 22));
      expect(LiturgicalCalculator.epiphany(2026), DateTime(2026, 1, 4));
      expect(LiturgicalCalculator.baptismOfTheLord(2026), DateTime(2026, 1, 11));
    });

    test('Bautismo en lunes cuando Epifania cae el 7 u 8 de enero', () {
      expect(LiturgicalCalculator.epiphany(2023), DateTime(2023, 1, 8));
      expect(LiturgicalCalculator.baptismOfTheLord(2023), DateTime(2023, 1, 9));
    });

    test('Sagrada Familia el 30 de diciembre si Navidad es domingo', () {
      expect(LiturgicalCalculator.holyFamily(2022), DateTime(2022, 12, 30));
      expect(LiturgicalCalculator.holyFamily(2026), DateTime(2026, 12, 27));
    });
  });

  group('Traslados y precedencias', () {
    test('Anunciacion en Semana Santa pasa al lunes despues de la Misericordia', () {
      expect(namesOn(2024, 3, 25), isNot(contains('Anunciación del Señor')));
      expect(namesOn(2024, 4, 8), contains('Anunciación del Señor'));
    });

    test('Inmaculada en domingo pasa al lunes 9', () {
      expect(namesOn(2024, 12, 9).first, 'Inmaculada Concepción de la Virgen María');
    });

    test('San Jose en Semana Santa pasa al sabado anterior a Ramos', () {
      // 2035: Pascua el 25 de marzo; el 19 es Lunes Santo.
      expect(namesOn(2035, 3, 17), contains('San José, esposo de la Virgen María'));
      expect(namesOn(2035, 3, 19), isEmpty);
    });

    test('Natividad de San Juan Bautista cede ante el Sagrado Corazon', () {
      expect(namesOn(2022, 6, 24).first, 'Sagrado Corazón de Jesús');
      expect(namesOn(2022, 6, 23), contains('Natividad de San Juan Bautista'));
    });

    test('una fiesta no se celebra en un domingo de Cuaresma', () {
      // 22 feb 2026 es el I Domingo de Cuaresma.
      expect(namesOn(2026, 2, 22), isEmpty);
    });

    test('las memorias en Cuaresma pasan a ser libres', () {
      // 7 de marzo de 2025 (viernes de Cuaresma): Santas Perpetua y Felicidad.
      final c = calendar.celebrationsOn(DateTime(2025, 3, 7)).single;
      expect(c.rank, LiturgicalRank.memoriaLibre);
    });

    test('Fieles Difuntos se celebra aunque caiga en domingo', () {
      expect(namesOn(2025, 11, 2), ['Conmemoración de todos los fieles difuntos']);
    });
  });

  group('Informacion del dia', () {
    test('7 de octubre de 2026', () {
      final day = calendar.dayInfo(DateTime(2026, 10, 7));
      expect(day.season, LiturgicalSeason.ordinario);
      expect(day.weekLabel, 'Miércoles de la semana XXVII del Tiempo Ordinario');
      expect(day.principal!.name, 'Nuestra Señora del Rosario');
      expect(day.color, LiturgicalColor.blanco);
      expect(day.special, isNull); // es memoria, no fiesta
    });

    test('la Navidad termina con el Bautismo del Señor', () {
      expect(calendar.seasonFor(DateTime(2026, 1, 11)), LiturgicalSeason.navidad);
      expect(calendar.seasonFor(DateTime(2026, 1, 12)), LiturgicalSeason.ordinario);
      expect(calendar.weekLabel(DateTime(2026, 1, 12)), 'Lunes de la semana I del Tiempo Ordinario');
      expect(calendar.weekLabel(DateTime(2026, 1, 18)), 'Domingo II del Tiempo Ordinario');
    });

    test('Semana Santa, Triduo y Pascua 2026', () {
      expect(calendar.dayInfo(DateTime(2026, 3, 29)).color, LiturgicalColor.rojo); // Ramos
      expect(calendar.seasonFor(DateTime(2026, 3, 31)), LiturgicalSeason.semanaSanta);
      expect(calendar.dayInfo(DateTime(2026, 4, 3)).color, LiturgicalColor.rojo); // V. Santo
      expect(calendar.seasonFor(DateTime(2026, 4, 2)), LiturgicalSeason.triduo);
      expect(calendar.seasonFor(DateTime(2026, 5, 24)), LiturgicalSeason.pascua); // Pentecostes
      expect(calendar.dayInfo(DateTime(2026, 5, 24)).color, LiturgicalColor.rojo);
      expect(calendar.seasonFor(DateTime(2026, 5, 25)), LiturgicalSeason.ordinario);
    });

    test('domingos Gaudete y Laetare en rosa', () {
      expect(calendar.dayInfo(DateTime(2026, 12, 13)).color, LiturgicalColor.rosa);
      expect(calendar.dayInfo(DateTime(2026, 3, 15)).color, LiturgicalColor.rosa);
    });

    test('proximas fechas especiales son fiestas o superiores, en orden', () {
      final upcoming = calendar.upcomingSpecial(DateTime(2026, 10, 7), count: 5);
      // San Lucas (18 oct 2026) cae en domingo y se omite; sigue Simon y Judas.
      expect(upcoming.first.name, 'Santos Simón y Judas, apóstoles');
      expect(upcoming.every((c) => c.rank.isSpecial), true);
      for (var i = 1; i < upcoming.length; i++) {
        expect(upcoming[i].date.isBefore(upcoming[i - 1].date), false);
      }
    });

    test('cada dia del año se calcula sin errores', () {
      var day = DateTime(2026, 1, 1);
      while (day.year == 2026) {
        final info = calendar.dayInfo(day);
        expect(info.weekLabel, isNotEmpty);
        day = DateTime(day.year, day.month, day.day + 1);
      }
    });
  });
}
