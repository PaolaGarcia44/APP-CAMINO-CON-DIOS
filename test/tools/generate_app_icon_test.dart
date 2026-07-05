// Herramienta: genera los PNG del icono de la app (paloma sobre morado)
// usando el propio motor de render de Flutter.
//
//   flutter test test/tools/generate_app_icon_test.dart
//
// Produce assets/icon/app_icon.png (1024x1024, con fondo) y
// assets/icon/app_icon_foreground.png (paloma centrada con margen, fondo
// transparente, para el icono adaptativo de Android).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luz_para_hoy/core/theme/app_colors.dart';

/// Paloma estilizada en vuelo (mas reconocible que la del FaithIcon
/// pequeño): ala levantada, cabeza con pico y cola en abanico.
class _DoveIconPainter extends CustomPainter {
  final Color color;
  _DoveIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    final body = Path()
      // cola (izquierda)
      ..moveTo(w * 0.06, h * 0.52)
      ..lineTo(w * 0.30, h * 0.50)
      ..lineTo(w * 0.10, h * 0.62)
      ..lineTo(w * 0.32, h * 0.58)
      ..lineTo(w * 0.16, h * 0.72)
      // vientre hacia la derecha
      ..quadraticBezierTo(w * 0.42, h * 0.78, w * 0.62, h * 0.72)
      ..quadraticBezierTo(w * 0.78, h * 0.67, w * 0.84, h * 0.55)
      // cabeza y pico
      ..quadraticBezierTo(w * 0.87, h * 0.48, w * 0.855, h * 0.435)
      ..lineTo(w * 0.945, h * 0.43)
      ..lineTo(w * 0.85, h * 0.375)
      ..quadraticBezierTo(w * 0.82, h * 0.33, w * 0.76, h * 0.335)
      // pecho de vuelta hacia la cola
      ..quadraticBezierTo(w * 0.62, h * 0.345, w * 0.52, h * 0.40)
      ..quadraticBezierTo(w * 0.38, h * 0.44, w * 0.06, h * 0.52)
      ..close();
    canvas.drawPath(body, paint);

    final wing = Path()
      ..moveTo(w * 0.42, h * 0.42)
      ..quadraticBezierTo(w * 0.40, h * 0.22, w * 0.52, h * 0.10)
      ..quadraticBezierTo(w * 0.545, h * 0.22, w * 0.60, h * 0.28)
      ..quadraticBezierTo(w * 0.56, h * 0.13, w * 0.63, h * 0.06)
      ..quadraticBezierTo(w * 0.67, h * 0.20, w * 0.70, h * 0.335)
      ..quadraticBezierTo(w * 0.58, h * 0.345, w * 0.42, h * 0.42)
      ..close();
    canvas.drawPath(wing, paint);

    // ojo (hueco en la cabeza)
    final eye = Paint()
      ..color = AppColors.purpleDeep
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.795, h * 0.405), w * 0.018, eye);
  }

  @override
  bool shouldRepaint(covariant _DoveIconPainter oldDelegate) => false;
}

class _DoveIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _DoveIcon({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _DoveIconPainter(color: color)),
    );
  }
}

Future<void> _capture(WidgetTester tester, Widget widget, String path) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: SizedBox(width: 512, height: 512, child: widget),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2); // 1024x1024
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('genera los iconos de la app', (tester) async {
    tester.view.physicalSize = const Size(600, 600);
    tester.view.devicePixelRatio = 1;

    await _capture(
      tester,
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.purple, AppColors.purpleDeep],
          ),
        ),
        child: Center(
          child: _DoveIcon(size: 380, color: Colors.white),
        ),
      ),
      'assets/icon/app_icon.png',
    );

    await _capture(
      tester,
      const ColoredBox(
        color: Colors.transparent,
        child: Center(
          // Mas pequeña: el icono adaptativo de Android recorta los bordes.
          child: _DoveIcon(size: 250, color: Colors.white),
        ),
      ),
      'assets/icon/app_icon_foreground.png',
    );
  });
}
