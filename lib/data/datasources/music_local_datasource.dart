import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/music_model.dart';

class MusicLocalDataSource {
  List<MusicCategoryModel>? _categories;

  Future<List<MusicCategoryModel>> getAll() async {
    if (_categories != null) return _categories!;
    final raw = await rootBundle.loadString('assets/data/music/music.json');
    final list = json.decode(raw) as List;
    _categories = list.map((e) => MusicCategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    return _categories!;
  }
}
