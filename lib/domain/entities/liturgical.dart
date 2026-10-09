/// Grado de una celebracion, de mayor a menor importancia.
enum LiturgicalRank {
  /// Triduo, Ceniza, Domingo de Ramos, Domingo de la Misericordia...
  principal('Celebración principal', 6),
  solemnidad('Solemnidad', 5),
  conmemoracion('Conmemoración', 4),
  fiesta('Fiesta', 3),
  memoria('Memoria', 2),
  memoriaLibre('Memoria libre', 1);

  final String label;
  final int weight;
  const LiturgicalRank(this.label, this.weight);

  static LiturgicalRank fromKey(String key) => switch (key) {
        'solemnidad' => solemnidad,
        'fiesta' => fiesta,
        'memoria' => memoria,
        'memoria_libre' => memoriaLibre,
        'conmemoracion' => conmemoracion,
        'principal' => principal,
        _ => memoriaLibre,
      };

  /// Las fechas de este grado o superior se consideran "especiales"
  /// (se destacan en Inicio y se pueden notificar).
  bool get isSpecial => weight >= LiturgicalRank.fiesta.weight;
}

enum LiturgicalColor {
  blanco('Blanco'),
  rojo('Rojo'),
  verde('Verde'),
  morado('Morado'),
  rosa('Rosa');

  final String label;
  const LiturgicalColor(this.label);

  static LiturgicalColor fromKey(String? key) =>
      LiturgicalColor.values.firstWhere((c) => c.name == key, orElse: () => LiturgicalColor.blanco);
}

enum LiturgicalSeason {
  adviento('Adviento'),
  navidad('Navidad'),
  ordinario('Tiempo Ordinario'),
  cuaresma('Cuaresma'),
  semanaSanta('Semana Santa'),
  triduo('Triduo Pascual'),
  pascua('Tiempo de Pascua');

  final String label;
  const LiturgicalSeason(this.label);
}

/// Celebracion de fecha fija, leida de assets/data/calendar/celebrations.json.
class FixedCelebration {
  final int month;
  final int day;
  final String name;
  final LiturgicalRank rank;
  final LiturgicalColor color;

  /// Fiestas del Señor que, al caer en domingo del Tiempo Ordinario, lo
  /// reemplazan (Presentacion, Transfiguracion, Santa Cruz...).
  final bool overridesSunday;

  /// Regla de traslado especial ('san_jose', 'anunciacion', 'inmaculada',
  /// 'san_juan_bautista').
  final String? transfer;

  /// Calendario propio ('Colombia', 'America Latina'...), si aplica.
  final String? region;

  const FixedCelebration({
    required this.month,
    required this.day,
    required this.name,
    required this.rank,
    required this.color,
    this.overridesSunday = false,
    this.transfer,
    this.region,
  });

  factory FixedCelebration.fromJson(Map<String, dynamic> json) => FixedCelebration(
        month: json['month'] as int,
        day: json['day'] as int,
        name: json['name'] as String,
        rank: LiturgicalRank.fromKey(json['rank'] as String),
        color: LiturgicalColor.fromKey(json['color'] as String?),
        overridesSunday: json['overridesSunday'] as bool? ?? false,
        transfer: json['transfer'] as String?,
        region: json['region'] as String?,
      );
}

/// Celebracion concreta en una fecha (ya aplicados traslados y precedencias).
class Celebration {
  final DateTime date;
  final String name;
  final LiturgicalRank rank;
  final LiturgicalColor color;
  final String? region;

  const Celebration({
    required this.date,
    required this.name,
    required this.rank,
    required this.color,
    this.region,
  });

  Celebration copyWith({DateTime? date, LiturgicalRank? rank}) => Celebration(
        date: date ?? this.date,
        name: name,
        rank: rank ?? this.rank,
        color: color,
        region: region,
      );

  @override
  String toString() => 'Celebration($date, $name, ${rank.name})';
}

/// Toda la informacion liturgica de un dia.
class LiturgicalDay {
  final DateTime date;
  final LiturgicalSeason season;

  /// Ej. "Martes de la semana XXVII del Tiempo Ordinario".
  final String weekLabel;
  final LiturgicalColor color;

  /// Celebraciones del dia, la principal primero.
  final List<Celebration> celebrations;

  const LiturgicalDay({
    required this.date,
    required this.season,
    required this.weekLabel,
    required this.color,
    required this.celebrations,
  });

  Celebration? get principal => celebrations.isEmpty ? null : celebrations.first;

  /// La celebracion destacada del dia (fiesta o superior), si la hay.
  Celebration? get special => principal != null && principal!.rank.isSpecial ? principal : null;
}
