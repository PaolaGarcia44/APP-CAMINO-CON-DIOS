import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/prayer_model.dart';

class PrayersLocalDataSource {
  List<PrayerModel>? _prayers;

  Future<List<PrayerModel>> getAll() async {
    if (_prayers != null) return _prayers!;
    final raw = await rootBundle.loadString('assets/data/prayers/prayers.json');
    final list = json.decode(raw) as List;
    _prayers = list.map((e) => PrayerModel.fromJson(e as Map<String, dynamic>)).toList();
    return _prayers!;
  }

  Future<List<String>> getCategories() async {
    final prayers = await getAll();
    final seen = <String>[];
    for (final p in prayers) {
      if (!seen.contains(p.category)) seen.add(p.category);
    }
    return seen;
  }

  Future<List<PrayerModel>> getByCategory(String category) async {
    final prayers = await getAll();
    return prayers.where((p) => p.category == category).toList();
  }

  static const _shortPrayerIds = [
    'angel_guarda',
    'ofrecimiento_manana',
    'oracion_noche',
    'accion_gracias',
  ];

  /// Oracion corta del dia, para la tarjeta de Inicio (rota segun el dia del año).
  Future<PrayerModel> getShortPrayerOfDay(DateTime date) async {
    final prayers = await getAll();
    final dayOfYear = DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays;
    final id = _shortPrayerIds[dayOfYear % _shortPrayerIds.length];
    return prayers.firstWhere((p) => p.id == id);
  }
}
