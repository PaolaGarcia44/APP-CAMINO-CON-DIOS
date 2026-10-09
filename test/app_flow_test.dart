import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:luz_para_hoy/core/constants/hive_boxes.dart';
import 'package:luz_para_hoy/main.dart';

/// Recorrido de punta a punta por la app real (sin plugins nativos: las
/// notificaciones quedan desactivadas en las pruebas).
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await Directory.systemTemp.createTemp('luz_flow_test');
    Hive.init(dir.path);
    await Future.wait(HiveBoxes.all.map(Hive.openBox));
    await Hive.box(HiveBoxes.settings).put(SettingsKeys.onboardingSeen, true);
    await initializeDateFormatting('es');
  });

  // Hive escribe en disco de verdad: se deja correr tiempo real para que esas
  // escrituras terminen, y luego se avanzan los frames.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
      await tester.pump(const Duration(milliseconds: 150));
    }
  }

  testWidgets('Inicio, Agenda, Calendario y Configuracion funcionan', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: LuzParaHoyApp()));
    await tester.pump(const Duration(seconds: 2)); // splash
    await settle(tester);

    // Inicio: secciones nuevas y ningun rastro del Rosario.
    expect(find.text('Mensaje del día'), findsOneWidget);
    expect(find.text('Rosario'), findsNothing);
    expect(find.textContaining('No olvides tu Rosario'), findsNothing);

    // Menu inferior: Inicio, Biblia, Agenda, Oraciones, Mas.
    final nav = find.byType(NavigationBar);
    for (final label in ['Inicio', 'Biblia', 'Agenda', 'Oraciones', 'Mas']) {
      expect(find.descendant(of: nav, matching: find.text(label)), findsOneWidget);
    }

    // Agenda: crear una tarea.
    await tester.tap(find.descendant(of: nav, matching: find.text('Agenda')));
    await settle(tester);
    await tester.tap(find.text('Nueva tarea'));
    await settle(tester);
    await tester.enterText(find.widgetWithText(TextFormField, 'Titulo'), 'Estudiar Python');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripcion (opcional)'),
      'Estudiar funciones y listas.',
    );
    await tester.tap(find.text('Guardar tarea'));
    await settle(tester);

    // Con recordatorio y notificaciones apagadas, ofrece activarlas.
    expect(find.text('¿Activar recordatorios?'), findsOneWidget);
    await tester.tap(find.text('Ahora no'));
    await settle(tester);

    expect(find.text('Estudiar Python'), findsOneWidget);
    final stored = Hive.box(HiveBoxes.agenda).values.cast<Map>().single;
    expect(stored['title'], 'Estudiar Python');
    expect(stored['description'], 'Estudiar funciones y listas.');
    expect(stored['reminderMinutes'], 10);

    // Completar la tarea desde la lista.
    await tester.tap(find.byTooltip('Marcar como completada'));
    await settle(tester);
    expect(find.byTooltip('Marcar como pendiente'), findsOneWidget);

    // Mas -> Calendario.
    await tester.tap(find.descendant(of: nav, matching: find.text('Mas')));
    await settle(tester);
    await tester.tap(find.text('Calendario'));
    await settle(tester);
    expect(find.textContaining('semana'), findsWidgets); // "... de la semana N ..."
    await tester.scrollUntilVisible(
      find.text('Proximas fechas especiales'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Proximas fechas especiales'), findsOneWidget);
    await tester.tap(find.byTooltip('Atrás'));
    await settle(tester);

    // Mas -> Configuracion.
    await tester.tap(find.text('Configuracion'));
    await settle(tester);
    expect(find.text('Activar notificaciones'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Reiniciar progreso biblico'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Reiniciar progreso biblico'), findsOneWidget);
    expect(find.text('Tus favoritos y marcadores se conservan'), findsOneWidget);
  });

  testWidgets('Pantallas principales sin desbordes en un telefono pequeño', (tester) async {
    tester.view.physicalSize = const Size(640, 1136); // 320 x 568 dp
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: LuzParaHoyApp()));
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);

    final nav = find.byType(NavigationBar);
    for (final label in ['Biblia', 'Agenda', 'Oraciones', 'Mas', 'Inicio']) {
      await tester.tap(find.descendant(of: nav, matching: find.text(label)));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'Error al mostrar $label');
    }
    await tester.tap(find.descendant(of: nav, matching: find.text('Mas')));
    await settle(tester);
    for (final item in ['Calendario', 'Configuracion', 'Reflexiones']) {
      await tester.ensureVisible(find.text(item, skipOffstage: false));
      await settle(tester);
      await tester.tap(find.text(item));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'Error al mostrar $item');
      await tester.tap(find.byTooltip('Atrás'));
      await settle(tester);
    }
  });
}
