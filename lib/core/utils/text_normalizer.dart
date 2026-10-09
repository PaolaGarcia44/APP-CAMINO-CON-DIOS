/// Normaliza texto en español para busquedas: minusculas y sin tildes ni
/// dieresis, de modo que "Génesis", "genesis" y "GENESIS" coincidan.
class TextNormalizer {
  TextNormalizer._();

  static final Map<int, int> _map = () {
    const from = 'áàäâãéèëêíìïîóòöôõúùüûñç';
    const to = 'aaaaaeeeeiiiiooooouuuunc';
    return {
      for (var i = 0; i < from.length; i++) from.codeUnitAt(i): to.codeUnitAt(i),
    };
  }();

  static String normalize(String input) {
    final units = input.toLowerCase().codeUnits;
    final out = List<int>.filled(units.length, 0);
    for (var i = 0; i < units.length; i++) {
      final u = units[i];
      out[i] = _map[u] ?? u;
    }
    return String.fromCharCodes(out);
  }
}
