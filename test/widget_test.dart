import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luz_para_hoy/main.dart';

void main() {
  testWidgets('La app construye sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LuzParaHoyApp()));
    await tester.pump();
  });
}
