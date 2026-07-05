import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/quote_model.dart';

class QuotesLocalDataSource {
  List<QuoteModel>? _quotes;

  Future<List<QuoteModel>> getAll() async {
    if (_quotes != null) return _quotes!;
    final raw = await rootBundle.loadString('assets/data/quotes/quotes.json');
    final list = json.decode(raw) as List;
    _quotes = list.map((e) => QuoteModel.fromJson(e as Map<String, dynamic>)).toList();
    return _quotes!;
  }

  /// Frase estable para el dia dado (misma frase durante todo el dia).
  Future<QuoteModel> getForDate(DateTime date) async {
    final quotes = await getAll();
    final dayOfYear = DateTime(date.year, date.month, date.day)
        .difference(DateTime(date.year, 1, 1))
        .inDays;
    final index = dayOfYear % quotes.length;
    return quotes[index];
  }
}
