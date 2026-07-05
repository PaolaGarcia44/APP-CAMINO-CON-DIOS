import 'package:flutter/material.dart';

enum FaithIconType { cross, dove }

/// Iconografia religiosa discreta dibujada con CustomPainter, para no
/// depender de archivos de imagen externos.
class FaithIcon extends StatelessWidget {
  final FaithIconType type;
  final double size;
  final Color color;

  const FaithIcon({
    super.key,
    this.type = FaithIconType.cross,
    this.size = 28,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: type == FaithIconType.cross
            ? _CrossPainter(color: color)
            : _DovePainter(color: color),
      ),
    );
  }
}

class _CrossPainter extends CustomPainter {
  final Color color;
  _CrossPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.14
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    canvas.drawLine(Offset(w * 0.5, h * 0.05), Offset(w * 0.5, h * 0.95), paint);
    canvas.drawLine(Offset(w * 0.22, h * 0.32), Offset(w * 0.78, h * 0.32), paint);
  }

  @override
  bool shouldRepaint(covariant _CrossPainter oldDelegate) => oldDelegate.color != color;
}

class _DovePainter extends CustomPainter {
  final Color color;
  _DovePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.5, h * 0.15)
      ..quadraticBezierTo(w * 0.85, h * 0.2, w * 0.9, h * 0.5)
      ..quadraticBezierTo(w * 0.65, h * 0.42, w * 0.55, h * 0.55)
      ..quadraticBezierTo(w * 0.7, h * 0.65, w * 0.85, h * 0.68)
      ..quadraticBezierTo(w * 0.55, h * 0.85, w * 0.3, h * 0.7)
      ..quadraticBezierTo(w * 0.1, h * 0.58, w * 0.15, h * 0.38)
      ..quadraticBezierTo(w * 0.3, h * 0.45, w * 0.4, h * 0.4)
      ..quadraticBezierTo(w * 0.3, h * 0.25, w * 0.5, h * 0.15)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DovePainter oldDelegate) => oldDelegate.color != color;
}
