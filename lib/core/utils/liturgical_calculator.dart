import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum LiturgicalSeason { adviento, navidad, cuaresma, pascua, ordinario }

class LiturgicalInfo {
  final LiturgicalSeason season;
  final String seasonName;
  final String colorName;
  final Color color;

  const LiturgicalInfo({
    required this.season,
    required this.seasonName,
    required this.colorName,
    required this.color,
  });
}

class LiturgicalFeast {
  final DateTime date;
  final String name;
  const LiturgicalFeast(this.date, this.name);
}

/// Calcula el tiempo y color liturgico a partir de la fecha, usando el
/// algoritmo de Computus (Meeus/Jones/Butcher) para hallar el Domingo de
/// Pascua. Es un calculo puramente algoritmico, sin contenido con derechos
/// de autor. El Evangelio del dia queda pendiente de una fuente con licencia.
class LiturgicalCalculator {
  LiturgicalCalculator._();

  /// Fiestas y solemnidades principales del año: las fijas mas las moviles
  /// calculadas a partir de la Pascua. Ascension y Corpus se muestran en
  /// domingo, como se celebran en Colombia y gran parte de America Latina.
  static List<LiturgicalFeast> feastsForYear(int year) {
    final easter = easterSunday(year);
    final feasts = <LiturgicalFeast>[
      LiturgicalFeast(DateTime(year, 1, 1), 'Santa Maria, Madre de Dios'),
      LiturgicalFeast(DateTime(year, 1, 6), 'Epifania del Señor (Reyes Magos)'),
      LiturgicalFeast(easter.subtract(const Duration(days: 46)), 'Miercoles de Ceniza'),
      LiturgicalFeast(DateTime(year, 3, 19), 'San Jose'),
      LiturgicalFeast(DateTime(year, 3, 25), 'Anunciacion del Señor'),
      LiturgicalFeast(easter.subtract(const Duration(days: 7)), 'Domingo de Ramos'),
      LiturgicalFeast(easter.subtract(const Duration(days: 3)), 'Jueves Santo'),
      LiturgicalFeast(easter.subtract(const Duration(days: 2)), 'Viernes Santo'),
      LiturgicalFeast(easter, 'Domingo de Pascua (Resurreccion)'),
      LiturgicalFeast(easter.add(const Duration(days: 7)), 'Divina Misericordia'),
      LiturgicalFeast(easter.add(const Duration(days: 42)), 'Ascension del Señor'),
      LiturgicalFeast(easter.add(const Duration(days: 49)), 'Pentecostes'),
      LiturgicalFeast(easter.add(const Duration(days: 56)), 'Santisima Trinidad'),
      LiturgicalFeast(easter.add(const Duration(days: 63)), 'Corpus Christi'),
      LiturgicalFeast(easter.add(const Duration(days: 68)), 'Sagrado Corazon de Jesus'),
      LiturgicalFeast(DateTime(year, 6, 29), 'San Pedro y San Pablo'),
      LiturgicalFeast(DateTime(year, 7, 16), 'Nuestra Señora del Carmen'),
      LiturgicalFeast(DateTime(year, 8, 15), 'Asuncion de la Virgen Maria'),
      LiturgicalFeast(DateTime(year, 10, 7), 'Nuestra Señora del Rosario'),
      LiturgicalFeast(DateTime(year, 11, 1), 'Todos los Santos'),
      LiturgicalFeast(DateTime(year, 11, 2), 'Fieles Difuntos'),
      LiturgicalFeast(_firstAdventSunday(year).subtract(const Duration(days: 7)), 'Cristo Rey del Universo'),
      LiturgicalFeast(_firstAdventSunday(year), 'Primer Domingo de Adviento'),
      LiturgicalFeast(DateTime(year, 12, 8), 'Inmaculada Concepcion'),
      LiturgicalFeast(DateTime(year, 12, 12), 'Nuestra Señora de Guadalupe'),
      LiturgicalFeast(DateTime(year, 12, 25), 'Navidad del Señor'),
    ]..sort((a, b) => a.date.compareTo(b.date));
    return feasts;
  }

  /// La fiesta que cae exactamente en [date], si la hay.
  static LiturgicalFeast? feastFor(DateTime date) {
    for (final f in feastsForYear(date.year)) {
      if (f.date.year == date.year && f.date.month == date.month && f.date.day == date.day) {
        return f;
      }
    }
    return null;
  }

  /// Las proximas [count] fiestas a partir de [date] (exclusive hoy).
  static List<LiturgicalFeast> upcomingFeasts(DateTime date, {int count = 5}) {
    final day = DateTime(date.year, date.month, date.day);
    final all = [...feastsForYear(day.year), ...feastsForYear(day.year + 1)];
    return all.where((f) => f.date.isAfter(day)).take(count).toList();
  }

  static DateTime easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }

  static DateTime _firstAdventSunday(int year) {
    final christmas = DateTime(year, 12, 25);
    final weekdayFromSunday = christmas.weekday % 7; // domingo = 0
    final fourthSundayBefore = christmas.subtract(Duration(days: weekdayFromSunday + 21));
    return fourthSundayBefore;
  }

  static LiturgicalInfo infoFor(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    final easter = easterSunday(day.year);
    final ashWednesday = easter.subtract(const Duration(days: 46));
    final palmSunday = easter.subtract(const Duration(days: 7));
    final pentecost = easter.add(const Duration(days: 49));
    final adventStartThisYear = _firstAdventSunday(day.year);
    final adventStartNextYear = _firstAdventSunday(day.year + 1);
    final christmasEnd = DateTime(day.year, 1, 12); // aprox. Bautismo del Senor

    if (!day.isBefore(adventStartThisYear) && day.isBefore(DateTime(day.year, 12, 25))) {
      return const LiturgicalInfo(
        season: LiturgicalSeason.adviento,
        seasonName: 'Adviento',
        colorName: 'Morado',
        color: Color(0xFF6B4E8E),
      );
    }
    if (!day.isBefore(DateTime(day.year, 12, 25)) || day.isBefore(DateTime(day.year, 1, 1))) {
      return const LiturgicalInfo(
        season: LiturgicalSeason.navidad,
        seasonName: 'Navidad',
        colorName: 'Blanco',
        color: AppColors.gold,
      );
    }
    if (day.isBefore(christmasEnd) || (day.year == adventStartNextYear.year && day.isBefore(DateTime(day.year, 1, 12)))) {
      // Primeros dias de enero (antes del Bautismo del Senor).
      if (day.isBefore(DateTime(day.year, 1, 12))) {
        return const LiturgicalInfo(
          season: LiturgicalSeason.navidad,
          seasonName: 'Navidad',
          colorName: 'Blanco',
          color: AppColors.gold,
        );
      }
    }
    if (!day.isBefore(ashWednesday) && day.isBefore(easter)) {
      final isPalmSunday = day.year == palmSunday.year && day.month == palmSunday.month && day.day == palmSunday.day;
      return LiturgicalInfo(
        season: LiturgicalSeason.cuaresma,
        seasonName: isPalmSunday ? 'Semana Santa' : 'Cuaresma',
        colorName: isPalmSunday ? 'Rojo' : 'Morado',
        color: isPalmSunday ? AppColors.error : const Color(0xFF6B4E8E),
      );
    }
    if (!day.isBefore(easter) && !day.isAfter(pentecost)) {
      final isPentecost = day.year == pentecost.year && day.month == pentecost.month && day.day == pentecost.day;
      return LiturgicalInfo(
        season: LiturgicalSeason.pascua,
        seasonName: isPentecost ? 'Pentecostes' : 'Pascua',
        colorName: isPentecost ? 'Rojo' : 'Blanco',
        color: isPentecost ? AppColors.error : AppColors.gold,
      );
    }
    return const LiturgicalInfo(
      season: LiturgicalSeason.ordinario,
      seasonName: 'Tiempo Ordinario',
      colorName: 'Verde',
      color: AppColors.success,
    );
  }
}
