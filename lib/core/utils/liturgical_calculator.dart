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

/// Calcula el tiempo y color liturgico a partir de la fecha, usando el
/// algoritmo de Computus (Meeus/Jones/Butcher) para hallar el Domingo de
/// Pascua. Es un calculo puramente algoritmico, sin contenido con derechos
/// de autor. El Evangelio del dia queda pendiente de una fuente con licencia.
class LiturgicalCalculator {
  LiturgicalCalculator._();

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
