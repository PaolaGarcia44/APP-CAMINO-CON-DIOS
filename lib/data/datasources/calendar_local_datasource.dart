import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../domain/entities/liturgical.dart';

/// Celebraciones de fecha fija del calendario catolico. Para actualizar el
/// calendario basta con editar assets/data/calendar/celebrations.json
/// (y subir su "version"); las fechas moviles se calculan en la app.
class CalendarLocalDataSource {
  List<FixedCelebration>? _cache;

  Future<List<FixedCelebration>> getFixedCelebrations() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/calendar/celebrations.json');
    final data = json.decode(raw) as Map<String, dynamic>;
    _cache = (data['celebrations'] as List)
        .map((e) => FixedCelebration.fromJson(e as Map<String, dynamic>))
        .toList();
    return _cache!;
  }
}
