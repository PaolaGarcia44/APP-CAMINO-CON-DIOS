import '../../core/utils/liturgical_calculator.dart';
import '../entities/liturgical.dart';

/// Calendario catolico offline: combina las celebraciones de fecha fija
/// (archivo JSON actualizable) con las moviles calculadas cada año, y aplica
/// las reglas basicas de precedencia y traslado.
class CatholicCalendar {
  final List<FixedCelebration> fixed;
  final Map<int, Map<String, List<Celebration>>> _cache = {};

  CatholicCalendar(this.fixed);

  static String _key(DateTime d) => '${d.year}-${d.month}-${d.day}';
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  // ---------------------------------------------------------------------------
  // Tiempos liturgicos
  // ---------------------------------------------------------------------------

  LiturgicalSeason seasonFor(DateTime date) {
    final d = _day(date);
    final y = d.year;
    final easter = LiturgicalCalculator.easterSunday(y);
    if (!d.isBefore(LiturgicalCalculator.firstAdventSunday(y)) && d.isBefore(DateTime(y, 12, 25))) {
      return LiturgicalSeason.adviento;
    }
    if (!d.isBefore(DateTime(y, 12, 25))) return LiturgicalSeason.navidad;
    if (!d.isAfter(LiturgicalCalculator.baptismOfTheLord(y))) return LiturgicalSeason.navidad;
    if (d.isBefore(LiturgicalCalculator.ashWednesday(y))) return LiturgicalSeason.ordinario;
    if (d.isBefore(LiturgicalCalculator.palmSunday(y))) return LiturgicalSeason.cuaresma;
    if (d.isBefore(LiturgicalCalculator.addDays(easter, -3))) return LiturgicalSeason.semanaSanta;
    if (d.isBefore(easter)) return LiturgicalSeason.triduo;
    if (!d.isAfter(LiturgicalCalculator.pentecost(y))) return LiturgicalSeason.pascua;
    return LiturgicalSeason.ordinario;
  }

  LiturgicalColor _seasonColor(DateTime d, LiturgicalSeason season) {
    final y = d.year;
    switch (season) {
      case LiturgicalSeason.adviento:
        // Domingo Gaudete (III de Adviento).
        final gaudete = LiturgicalCalculator.addDays(LiturgicalCalculator.firstAdventSunday(y), 14);
        return LiturgicalCalculator.isSameDay(d, gaudete) ? LiturgicalColor.rosa : LiturgicalColor.morado;
      case LiturgicalSeason.cuaresma:
        // Domingo Laetare (IV de Cuaresma).
        final laetare = LiturgicalCalculator.addDays(LiturgicalCalculator.easterSunday(y), -21);
        return LiturgicalCalculator.isSameDay(d, laetare) ? LiturgicalColor.rosa : LiturgicalColor.morado;
      case LiturgicalSeason.semanaSanta:
        return LiturgicalColor.morado;
      case LiturgicalSeason.navidad:
      case LiturgicalSeason.pascua:
      case LiturgicalSeason.triduo:
        return LiturgicalColor.blanco;
      case LiturgicalSeason.ordinario:
        return LiturgicalColor.verde;
    }
  }

  // ---------------------------------------------------------------------------
  // Celebraciones
  // ---------------------------------------------------------------------------

  List<Celebration> _movable(int y) {
    final easter = LiturgicalCalculator.easterSunday(y);
    final advent = LiturgicalCalculator.firstAdventSunday(y);
    Celebration c(DateTime date, String name, LiturgicalRank rank, LiturgicalColor color) =>
        Celebration(date: date, name: name, rank: rank, color: color);
    DateTime e(int days) => LiturgicalCalculator.addDays(easter, days);
    const p = LiturgicalRank.principal;
    const s = LiturgicalRank.solemnidad;
    const w = LiturgicalColor.blanco;
    const r = LiturgicalColor.rojo;

    return [
      c(LiturgicalCalculator.epiphany(y), 'Epifanía del Señor', s, w),
      c(LiturgicalCalculator.baptismOfTheLord(y), 'Bautismo del Señor', LiturgicalRank.fiesta, w),
      c(e(-46), 'Miércoles de Ceniza', p, LiturgicalColor.morado),
      c(e(-7), 'Domingo de Ramos de la Pasión del Señor', p, r),
      c(e(-3), 'Jueves Santo – Cena del Señor', p, w),
      c(e(-2), 'Viernes Santo – Pasión del Señor', p, r),
      c(e(-1), 'Sábado Santo – Vigilia Pascual', p, w),
      c(easter, 'Domingo de Pascua de la Resurrección del Señor', p, w),
      c(e(7), 'Domingo de la Divina Misericordia', p, w),
      c(e(42), 'Ascensión del Señor', s, w),
      c(e(49), 'Pentecostés', s, r),
      c(e(50), 'Bienaventurada Virgen María, Madre de la Iglesia', LiturgicalRank.memoria, w),
      c(e(56), 'Santísima Trinidad', s, w),
      c(e(63), 'Santísimo Cuerpo y Sangre de Cristo (Corpus Christi)', s, w),
      c(e(68), 'Sagrado Corazón de Jesús', s, w),
      c(e(69), 'Inmaculado Corazón de María', LiturgicalRank.memoria, w),
      c(LiturgicalCalculator.christTheKing(y), 'Jesucristo, Rey del Universo', s, w),
      c(advent, 'Primer Domingo de Adviento', p, LiturgicalColor.morado),
      c(LiturgicalCalculator.holyFamily(y), 'Sagrada Familia de Jesús, María y José', LiturgicalRank.fiesta,
          w),
    ];
  }

  /// Dias en que no se celebran fiestas ni memorias de fecha fija.
  bool _isPrivileged(DateTime d) {
    final easter = LiturgicalCalculator.easterSunday(d.year);
    return LiturgicalCalculator.isSameDay(d, LiturgicalCalculator.ashWednesday(d.year)) ||
        (!d.isBefore(LiturgicalCalculator.palmSunday(d.year)) &&
            !d.isAfter(LiturgicalCalculator.addDays(easter, 7)));
  }

  /// Dias en que las memorias pasan a ser solo conmemoraciones (libres).
  bool _downgradesMemorials(DateTime d) {
    final season = seasonFor(d);
    final lateAdvent = d.month == 12 && d.day >= 17 && d.day <= 24;
    final christmasOctave = d.month == 12 && d.day >= 26;
    return season == LiturgicalSeason.cuaresma || lateAdvent || christmasOctave;
  }

  DateTime _transfer(FixedCelebration f, DateTime date) {
    final y = date.year;
    final easter = LiturgicalCalculator.easterSunday(y);
    final palm = LiturgicalCalculator.palmSunday(y);
    final isSunday = date.weekday == DateTime.sunday;
    final inHolyWeek = !date.isBefore(palm) && date.isBefore(easter);
    switch (f.transfer) {
      case 'san_jose':
        if (inHolyWeek) return LiturgicalCalculator.addDays(palm, -1);
        if (isSunday) return LiturgicalCalculator.addDays(date, 1);
      case 'anunciacion':
        if (!date.isBefore(palm) && !date.isAfter(LiturgicalCalculator.addDays(easter, 7))) {
          return LiturgicalCalculator.addDays(easter, 8);
        }
        if (isSunday) return LiturgicalCalculator.addDays(date, 1);
      case 'inmaculada':
        if (isSunday) return LiturgicalCalculator.addDays(date, 1);
      case 'san_juan_bautista':
        final sacredHeart = LiturgicalCalculator.addDays(easter, 68);
        final corpus = LiturgicalCalculator.addDays(easter, 63);
        if (LiturgicalCalculator.isSameDay(date, sacredHeart)) {
          return LiturgicalCalculator.addDays(date, -1);
        }
        if (LiturgicalCalculator.isSameDay(date, corpus)) return LiturgicalCalculator.addDays(date, 1);
    }
    return date;
  }

  Map<String, List<Celebration>> _buildYear(int y) {
    final byDay = <String, List<Celebration>>{};
    void add(Celebration c) => byDay.putIfAbsent(_key(c.date), () => []).add(c);

    final movable = _movable(y);
    movable.forEach(add);

    for (final f in fixed) {
      if (f.day > DateTime(y, f.month + 1, 0).day) continue;
      final original = DateTime(y, f.month, f.day);
      final date = _transfer(f, original);
      final isSunday = date.weekday == DateTime.sunday;
      final season = seasonFor(date);
      final privilegedSeason = season == LiturgicalSeason.adviento ||
          season == LiturgicalSeason.cuaresma ||
          season == LiturgicalSeason.pascua;
      final sameDayMovable = byDay[_key(date)] ?? const <Celebration>[];
      final higherMovable = sameDayMovable.any((m) => m.rank.weight >= LiturgicalRank.solemnidad.weight);

      var rank = f.rank;
      switch (rank) {
        case LiturgicalRank.solemnidad:
        case LiturgicalRank.principal:
          break;
        case LiturgicalRank.conmemoracion:
          if (_isPrivileged(date)) continue;
        case LiturgicalRank.fiesta:
          if (_isPrivileged(date) || higherMovable) continue;
          if (isSunday && (!f.overridesSunday || privilegedSeason)) continue;
        case LiturgicalRank.memoria:
        case LiturgicalRank.memoriaLibre:
          if (_isPrivileged(date) || isSunday) continue;
          if (sameDayMovable.any((m) => m.rank.weight >= LiturgicalRank.fiesta.weight)) continue;
          if (_downgradesMemorials(date)) rank = LiturgicalRank.memoriaLibre;
      }
      add(Celebration(date: date, name: f.name, rank: rank, color: f.color, region: f.region));
    }

    // Precedencia: si hay una fiesta o algo superior, las memorias se omiten.
    for (final entry in byDay.entries) {
      final list = entry.value..sort((a, b) => b.rank.weight.compareTo(a.rank.weight));
      if (list.first.rank.weight >= LiturgicalRank.fiesta.weight) {
        list.removeWhere((c) => c.rank.weight < LiturgicalRank.fiesta.weight);
      }
    }
    return byDay;
  }

  Map<String, List<Celebration>> _year(int y) => _cache.putIfAbsent(y, () => _buildYear(y));

  List<Celebration> celebrationsOn(DateTime date) =>
      List.unmodifiable(_year(date.year)[_key(date)] ?? const <Celebration>[]);

  /// Celebraciones del año ordenadas por fecha.
  List<Celebration> celebrationsForYear(int year) {
    final all = _year(year).values.expand((l) => l).toList()..sort((a, b) => a.date.compareTo(b.date));
    return all;
  }

  /// Proximas fechas especiales (fiesta o superior) despues de [from].
  List<Celebration> upcomingSpecial(DateTime from, {int count = 8}) {
    final start = _day(from);
    final result = <Celebration>[];
    for (final year in [start.year, start.year + 1]) {
      for (final c in celebrationsForYear(year)) {
        if (c.date.isAfter(start) && c.rank.isSpecial) result.add(c);
        if (result.length >= count) return result;
      }
    }
    return result;
  }

  LiturgicalDay dayInfo(DateTime date) {
    final d = _day(date);
    final season = seasonFor(d);
    final celebrations = celebrationsOn(d);
    final principal = celebrations.isEmpty ? null : celebrations.first;
    final usesOwnColor = principal != null && principal.rank.weight >= LiturgicalRank.memoria.weight;
    return LiturgicalDay(
      date: d,
      season: season,
      weekLabel: weekLabel(d),
      color: usesOwnColor ? principal.color : _seasonColor(d, season),
      celebrations: celebrations,
    );
  }

  // ---------------------------------------------------------------------------
  // Nombre del dia ("Martes de la semana XXVII del Tiempo Ordinario")
  // ---------------------------------------------------------------------------

  static const _weekdays = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  static String roman(int n) {
    const values = [10, 9, 5, 4, 1];
    const symbols = ['X', 'IX', 'V', 'IV', 'I'];
    var result = '';
    var rest = n;
    for (var i = 0; i < values.length; i++) {
      while (rest >= values[i]) {
        result += symbols[i];
        rest -= values[i];
      }
    }
    return result;
  }

  String _weekOf(DateTime d, int week, String seasonName) {
    if (d.weekday == DateTime.sunday) return 'Domingo ${roman(week)} $seasonName';
    return '${_weekdays[d.weekday - 1]} de la semana ${roman(week)} $seasonName';
  }

  String weekLabel(DateTime date) {
    final d = _day(date);
    final y = d.year;
    final easter = LiturgicalCalculator.easterSunday(y);
    int weeksSince(DateTime start) => LiturgicalCalculator.daysBetween(start, d) ~/ 7;

    switch (seasonFor(d)) {
      case LiturgicalSeason.adviento:
        return _weekOf(d, weeksSince(LiturgicalCalculator.firstAdventSunday(y)) + 1, 'de Adviento');
      case LiturgicalSeason.navidad:
        if (d.month == 12 || (d.month == 1 && d.day == 1)) {
          return d.month == 12 && d.day == 25 ? 'Natividad del Señor' : 'Octava de Navidad';
        }
        return 'Tiempo de Navidad';
      case LiturgicalSeason.cuaresma:
        final ash = LiturgicalCalculator.ashWednesday(y);
        final firstSunday = LiturgicalCalculator.addDays(ash, 4);
        if (d.isBefore(firstSunday)) {
          return LiturgicalCalculator.isSameDay(d, ash)
              ? 'Miércoles de Ceniza'
              : '${_weekdays[d.weekday - 1]} después de Ceniza';
        }
        return _weekOf(d, weeksSince(firstSunday) + 1, 'de Cuaresma');
      case LiturgicalSeason.semanaSanta:
        return d.weekday == DateTime.sunday ? 'Domingo de Ramos' : '${_weekdays[d.weekday - 1]} Santo';
      case LiturgicalSeason.triduo:
        return '${_weekdays[d.weekday - 1]} Santo';
      case LiturgicalSeason.pascua:
        if (d.isBefore(LiturgicalCalculator.addDays(easter, 7)) && d.weekday != DateTime.sunday) {
          return 'Octava de Pascua';
        }
        return _weekOf(d, weeksSince(easter) + 1, 'de Pascua');
      case LiturgicalSeason.ordinario:
        if (d.isBefore(LiturgicalCalculator.ashWednesday(y))) {
          final ref = LiturgicalCalculator.sundayOnOrBefore(LiturgicalCalculator.baptismOfTheLord(y));
          return _weekOf(d, weeksSince(ref) + 1, 'del Tiempo Ordinario');
        }
        final sunday = LiturgicalCalculator.sundayOnOrBefore(d);
        final week =
            34 - LiturgicalCalculator.daysBetween(sunday, LiturgicalCalculator.christTheKing(y)) ~/ 7;
        return _weekOf(d, week, 'del Tiempo Ordinario');
    }
  }
}
