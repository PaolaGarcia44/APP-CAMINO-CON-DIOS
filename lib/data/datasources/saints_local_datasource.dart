import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/saint_model.dart';

/// Lista de muestra (incompleta a proposito). Ampliar con un santoral
/// completo de 365 dias es un trabajo de contenido pendiente.
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
    for (final s in saints) {
      if (s.month == date.month && s.day == date.day) return s;
    }
    return null;
  }
}
