import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/reflection_model.dart';

class ReflectionsLocalDataSource {
  List<ReflectionModel>? _reflections;

  Future<List<ReflectionModel>> getAll() async {
    if (_reflections != null) return _reflections!;
    final raw = await rootBundle.loadString('assets/data/reflections/reflections.json');
    final list = json.decode(raw) as List;
    _reflections = list.map((e) => ReflectionModel.fromJson(e as Map<String, dynamic>)).toList();
    return _reflections!;
  }

  Future<ReflectionModel> getForDate(DateTime date) async {
    final reflections = await getAll();
    final dayOfYear = DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays;
    return reflections[dayOfYear % reflections.length];
  }
}
