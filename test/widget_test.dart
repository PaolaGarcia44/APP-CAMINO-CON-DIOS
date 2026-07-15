import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:luz_para_hoy/core/constants/hive_boxes.dart';
import 'package:luz_para_hoy/main.dart';

void main() {
  // La app usa Hive y formato de fechas en español. En main() esto lo hace
  // HiveService.init(); aqui lo replicamos con un directorio temporal para
  // poder montar la app en un test sin depender de plugins de plataforma.
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('cami_hive_test');
    Hive.init(dir.path);
    await Future.wait([
      Hive.openBox(HiveBoxes.settings),
      Hive.openBox(HiveBoxes.bibleProgress),
      Hive.openBox(HiveBoxes.bibleBookmarks),
      Hive.openBox(HiveBoxes.favorites),
      Hive.openBox(HiveBoxes.journal),
      Hive.openBox(HiveBoxes.dailyContentCache),
    ]);
    await initializeDateFormatting('es');
  });

  testWidgets('La app construye sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuzParaHoyApp()));
    await tester.pump();

    // Se muestra el splash y la app arranca sin excepciones.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Dejamos correr el temporizador del splash (1600 ms) para que navegue
    // y no queden temporizadores pendientes al terminar el test.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 200));
  });
}
