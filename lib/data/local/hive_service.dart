import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_boxes.dart';

/// Inicializa Hive y abre todas las cajas usadas por la app.
/// No requiere adaptadores generados: todo se guarda como tipos
/// primitivos o Map<String, dynamic>.
class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.bibleProgress),
      Hive.openBox(HiveBoxes.bibleBookmarks),
      Hive.openBox(HiveBoxes.favorites),
      Hive.openBox(HiveBoxes.journal),
      Hive.openBox(HiveBoxes.dailyContentCache),
    ]);
    _initialized = true;
  }

  static Box box(String name) => Hive.box(name);
}
