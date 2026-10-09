import 'dart:math';

/// Elige un elemento por dia de forma estable (el mismo durante todo el dia
/// y el mismo en la tarjeta de Inicio y en la notificacion).
///
/// Recorre todos los elementos en un orden barajado antes de repetir
/// ninguno, y garantiza que dos dias seguidos nunca muestren el mismo,
/// tampoco al pasar de una vuelta a la siguiente.
class DailySelector {
  DailySelector._();

  static final DateTime _epoch = DateTime.utc(2024, 1, 1);

  static int dayNumber(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day).difference(_epoch).inDays;

  static List<int> _cycle(int cycle, int count) {
    final order = List<int>.generate(count, (i) => i)..shuffle(Random(cycle * 7919 + 17));
    if (cycle > 0 && count > 1) {
      final previous = List<int>.generate(count, (i) => i)..shuffle(Random((cycle - 1) * 7919 + 17));
      if (order.first == previous.last) {
        final tmp = order[0];
        order[0] = order[1];
        order[1] = tmp;
      }
    }
    return order;
  }

  /// Indice (0..count-1) del elemento para [date].
  static int indexFor(DateTime date, int count) {
    if (count <= 0) throw ArgumentError.value(count, 'count', 'debe ser mayor que cero');
    if (count == 1) return 0;
    final day = dayNumber(date);
    // Con dos elementos basta alternar (el intercambio de abajo alteraria el
    // ultimo elemento de la vuelta anterior).
    if (count == 2) return day % 2;
    final cycle = day ~/ count;
    final position = day % count;
    return _cycle(cycle < 0 ? 0 : cycle, count)[position];
  }
}
