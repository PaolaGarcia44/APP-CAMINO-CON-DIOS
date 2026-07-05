enum RosaryBeadType { intro, mysteryAnnounce, ourFather, hailMary, glory, jaculatoria, closing }

class RosaryBead {
  final RosaryBeadType type;
  final String title;
  final String text;
  final int? count; // posicion actual dentro de una decena (1..10) o de 3 iniciales
  final int? total;

  const RosaryBead({
    required this.type,
    required this.title,
    required this.text,
    this.count,
    this.total,
  });
}
