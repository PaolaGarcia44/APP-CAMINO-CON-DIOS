/// Calculos de fechas del año liturgico. Es un calculo puramente
/// algoritmico (sin contenido con derechos de autor) basado en el Computus
/// (Meeus/Jones/Butcher) para hallar el Domingo de Pascua.
///
/// Epifania, Ascension y Corpus Christi se celebran en domingo, como en
/// Colombia y gran parte de America Latina.
class LiturgicalCalculator {
  LiturgicalCalculator._();

  static DateTime _d(int y, int m, int d) => DateTime(y, m, d);

  static DateTime addDays(DateTime date, int days) => DateTime(date.year, date.month, date.day + days);

  /// Dias de calendario entre dos fechas (sin errores por horario de verano).
  static int daysBetween(DateTime from, DateTime to) => DateTime.utc(to.year, to.month, to.day)
      .difference(DateTime.utc(from.year, from.month, from.day))
      .inDays;

  static bool isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

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
    return _d(year, month, day);
  }

  static DateTime ashWednesday(int year) => addDays(easterSunday(year), -46);
  static DateTime palmSunday(int year) => addDays(easterSunday(year), -7);
  static DateTime pentecost(int year) => addDays(easterSunday(year), 49);

  /// Cuarto domingo antes de Navidad.
  static DateTime firstAdventSunday(int year) {
    final christmas = _d(year, 12, 25);
    final weekdayFromSunday = christmas.weekday % 7; // domingo = 0
    return addDays(christmas, -(weekdayFromSunday + 21));
  }

  static DateTime christTheKing(int year) => addDays(firstAdventSunday(year), -7);

  /// Domingo entre el 2 y el 8 de enero.
  static DateTime epiphany(int year) {
    final jan2 = _d(year, 1, 2);
    return addDays(jan2, (7 - jan2.weekday) % 7);
  }

  /// Domingo despues de Epifania; si Epifania cae el 7 u 8 de enero, el
  /// Bautismo se celebra el lunes siguiente.
  static DateTime baptismOfTheLord(int year) {
    final epiphanyDate = epiphany(year);
    return epiphanyDate.day >= 7 ? addDays(epiphanyDate, 1) : addDays(epiphanyDate, 7);
  }

  /// Domingo dentro de la octava de Navidad, o el 30 de diciembre si no hay.
  static DateTime holyFamily(int year) {
    for (var day = 26; day <= 31; day++) {
      final date = _d(year, 12, day);
      if (date.weekday == DateTime.sunday) return date;
    }
    return _d(year, 12, 30);
  }

  /// Domingo igual o anterior a [date].
  static DateTime sundayOnOrBefore(DateTime date) => addDays(date, -(date.weekday % 7));
}
