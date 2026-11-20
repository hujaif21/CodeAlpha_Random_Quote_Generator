import 'package:flutter/material.dart';

class LeafWatermark extends StatelessWidget {
  final Color color;
  final double size;

  const LeafWatermark({
    super.key,
    required this.color,
    this.size = 165,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _LeafWatermarkPainter(color: color),
    );
  }
}

class _LeafWatermarkPainter extends CustomPainter {
  final Color color;
  _LeafWatermarkPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final w = size.width;
    final h = size.height;

    final outline = Path()
      ..moveTo(w * 0.15, h * 0.88)
      ..quadraticBezierTo(w * 0.12, h * 0.25, w * 0.92, h * 0.12)
      ..quadraticBezierTo(w * 0.85, h * 0.88, w * 0.15, h * 0.88)
      ..close();

    canvas.drawPath(outline, paint);
    canvas.drawLine(Offset(w * 0.15, h * 0.88), Offset(w * 0.92, h * 0.12), paint);
    canvas.drawLine(Offset(w * 0.38, h * 0.65), Offset(w * 0.34, h * 0.42), paint);
    canvas.drawLine(Offset(w * 0.38, h * 0.65), Offset(w * 0.62, h * 0.67), paint);
    canvas.drawLine(Offset(w * 0.58, h * 0.45), Offset(w * 0.54, h * 0.26), paint);
    canvas.drawLine(Offset(w * 0.58, h * 0.45), Offset(w * 0.78, h * 0.47), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}