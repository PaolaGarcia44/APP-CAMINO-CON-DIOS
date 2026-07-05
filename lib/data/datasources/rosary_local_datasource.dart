import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/rosary_model.dart';

class RosaryLocalDataSource {
  List<RosaryMysterySetModel>? _sets;

  Future<List<RosaryMysterySetModel>> getAll() async {
    if (_sets != null) return _sets!;
    final raw = await rootBundle.loadString('assets/data/rosary/mysteries.json');
    final list = json.decode(raw) as List;
    _sets = list.map((e) => RosaryMysterySetModel.fromJson(e as Map<String, dynamic>)).toList();
    return _sets!;
  }

  /// Devuelve el conjunto de misterios correspondiente al dia de la semana
  /// (DateTime.weekday: 1 = lunes ... 7 = domingo).
  Future<RosaryMysterySetModel> getForWeekday(int weekday) async {
    final sets = await getAll();
    return sets.firstWhere((s) => s.weekdays.contains(weekday), orElse: () => sets.first);
  }
}
