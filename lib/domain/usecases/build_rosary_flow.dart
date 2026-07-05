import '../../data/models/prayer_model.dart';
import '../../data/models/rosary_model.dart';
import '../entities/rosary_bead.dart';

/// Arma la secuencia completa del Rosario (señal de la cruz, credo, los
/// cinco misterios con sus decenas, y las oraciones de cierre) a partir de
/// los misterios del dia y la biblioteca de oraciones ya cargada.
class BuildRosaryFlow {
  static List<RosaryBead> call({
    required RosaryMysterySetModel mysterySet,
    required List<PrayerModel> prayers,
  }) {
    String textOf(String id) => prayers.firstWhere((p) => p.id == id).text;

    final beads = <RosaryBead>[];

    beads.add(const RosaryBead(
      type: RosaryBeadType.intro,
      title: 'Señal de la Cruz',
      text: 'Por la señal de la Santa Cruz, de nuestros enemigos, libranos Señor, Dios nuestro. '
          'En el nombre del Padre, del Hijo y del Espiritu Santo. Amen.',
    ));
    beads.add(RosaryBead(type: RosaryBeadType.intro, title: 'Credo', text: textOf('credo')));
    beads.add(RosaryBead(type: RosaryBeadType.ourFather, title: 'Padre Nuestro', text: textOf('padre_nuestro')));

    for (var i = 1; i <= 3; i++) {
      beads.add(RosaryBead(
        type: RosaryBeadType.hailMary,
        title: 'Ave Maria',
        text: textOf('ave_maria'),
        count: i,
        total: 3,
      ));
    }
    beads.add(RosaryBead(type: RosaryBeadType.glory, title: 'Gloria', text: textOf('gloria')));

    for (var m = 0; m < mysterySet.mysteries.length; m++) {
      final mystery = mysterySet.mysteries[m];
      beads.add(RosaryBead(
        type: RosaryBeadType.mysteryAnnounce,
        title: '${m + 1}. ${mystery.title}',
        text: '${mystery.meditation}\n\nLectura: ${mystery.verseRef}',
      ));
      beads.add(RosaryBead(type: RosaryBeadType.ourFather, title: 'Padre Nuestro', text: textOf('padre_nuestro')));
      for (var i = 1; i <= 10; i++) {
        beads.add(RosaryBead(
          type: RosaryBeadType.hailMary,
          title: 'Ave Maria',
          text: textOf('ave_maria'),
          count: i,
          total: 10,
        ));
      }
      beads.add(RosaryBead(type: RosaryBeadType.glory, title: 'Gloria', text: textOf('gloria')));
      beads.add(const RosaryBead(
        type: RosaryBeadType.jaculatoria,
        title: 'Jaculatoria',
        text: 'Oh Jesus mio, perdona nuestros pecados, libranos del fuego del infierno y '
            'lleva al cielo a todas las almas, especialmente a las mas necesitadas de tu misericordia.',
      ));
    }

    beads.add(RosaryBead(type: RosaryBeadType.closing, title: 'Salve', text: textOf('salve')));
    beads.add(const RosaryBead(
      type: RosaryBeadType.closing,
      title: 'Letanias y oracion final',
      text: 'Se pueden rezar aqui las Letanias Lauretanas. Terminamos con la oracion final: '
          'Oh Dios, cuyo Unigenito Hijo nos alcanzo con su vida, muerte y resurreccion los premios '
          'de la salvacion eterna, concedenos, te suplicamos, que meditando estos misterios del '
          'Santisimo Rosario de la Virgen Maria, imitemos lo que contienen y alcancemos lo que prometen. Amen.',
    ));

    return beads;
  }
}
