import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/utils/daily_selector.dart';
import '../models/quote_model.dart';

/// Mensajes del dia almacenados localmente (assets/data/quotes/quotes.json).
/// Para agregar mensajes basta con añadir entradas al JSON.
class QuotesLocalDataSource {
  List<QuoteModel>? _quotes;

  Future<List<QuoteModel>> getAll() async {
    if (_quotes != null) return _quotes!;
    final raw = await rootBundle.loadString('assets/data/quotes/quotes.json');
    final list = json.decode(raw) as List;
    _quotes = list.map((e) => QuoteModel.fromJson(e as Map<String, dynamic>)).toList();
    return _quotes!;
  }

  /// Mensaje estable para el dia dado, sin repetirse dos dias seguidos.
  Future<QuoteModel> getForDate(DateTime date) async {
    final quotes = await getAll();
    return quotes[DailySelector.indexFor(date, quotes.length)];
  }
}
