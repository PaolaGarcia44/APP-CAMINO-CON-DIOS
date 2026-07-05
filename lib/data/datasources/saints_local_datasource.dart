import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/saint_model.dart';

/// Santoral con los santos y fiestas mas conocidos de cada mes. Cuando un
/// dia no tiene entrada propia, [getForDate] devuelve la del dia anterior
/// mas cercano, para que la pantalla nunca quede vacia (la pantalla indica
/// la fecha real de la fiesta).
class SaintsLocalDataSource {
  List<SaintModel>? _saints;

  Future<List<SaintModel>> getAll() async {
    if (_saints != null) return _saints!;
    final raw = await rootBundle.loadString('assets/data/saints/saints.json');
    final list = json.decode(raw) as List;
    _saints = list.map((e) => SaintModel.fromJson(e as Map<String, dynamic>)).toList();
    return _saints!;
  }

  Future<SaintModel?> getForDate(DateTime date) async {
    final saints = await getAll();
    if (saints.isEmpty) return null;

    SaintModel? best;
    var bestDistance = 400; // mayor que cualquier distancia posible en dias
    final target = date.month * 31 + date.day;
    for (final s in saints) {
      final key = s.month * 31 + s.day;
      // distancia hacia atras, envolviendo el año (12 * 31 + 31 = 403)
      final distance = key <= target ? target - key : target - key + 403;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = s;
        if (distance == 0) break;
      }
    }
    return best;
  }
}
