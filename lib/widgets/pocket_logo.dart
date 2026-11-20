import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PocketLogo extends StatelessWidget {
  final double size;
  final Color primaryColor;
  final Color stitchColor;
  final double pocketScale;
  final double stitchProgress;
  final double sproutProgress;

  const PocketLogo({
    super.key,
    this.size = 130,
    this.primaryColor = AppColors.forestGreen,
    this.stitchColor = AppColors.terracotta,
    this.pocketScale = 1.0,
    this.stitchProgress = 1.0,
    this.sproutProgress = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PocketLogoPainter(
        primaryColor: primaryColor,
        stitchColor: stitchColor,
        pocketScale: pocketScale,
        stitchProgress: stitchProgress,
        sproutProgress: sproutProgress,
      ),
    );
  }
}

class _PocketLogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color stitchColor;
  final double pocketScale;
  final double sproutProgress;
  final double stitchProgress;

  _PocketLogoPainter({
    required this.primaryColor,
    required this.stitchColor,
    required this.pocketScale,
    required this.stitchProgress,
    required this.sproutProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // 1. Animated Sprout (Stem rises & leaves unfurl from behind pocket)
    if (sproutProgress > 0.01) {
      canvas.save();
      final stemBase = Offset(w * 0.50, h * 0.46);
      canvas.translate(stemBase.dx, stemBase.dy);
      canvas.scale(sproutProgress, sproutProgress);
      canvas.translate(-stemBase.dx, -stemBase.dy);

      // Stem
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.47, h * 0.25, w * 0.06, h * 0.23),
          const Radius.circular(4),
        ),
        fillPaint,
      );

      // Left Leaf
      canvas.save();
      canvas.translate(w * 0.48, h * 0.36);
      canvas.rotate((1.0 - sproutProgress) * 0.45);
      canvas.translate(-w * 0.48, -h * 0.36);
      final leftLeaf = Path()
        ..moveTo(w * 0.48, h * 0.36)
        ..quadraticBezierTo(w * 0.22, h * 0.38, w * 0.22, h * 0.16)
        ..quadraticBezierTo(w * 0.46, h * 0.14, w * 0.48, h * 0.36)
        ..close();
      canvas.drawPath(leftLeaf, fillPaint);
      canvas.restore();

      // Right Leaf
      canvas.save();
      canvas.translate(w * 0.50, h * 0.33);
      canvas.rotate(-(1.0 - sproutProgress) * 0.45);
      canvas.translate(-w * 0.50, -h * 0.33);
      final rightLeaf = Path()
        ..moveTo(w * 0.50, h * 0.33)
        ..quadraticBezierTo(w * 0.52, h * 0.10, w * 0.78, h * 0.12)
        ..quadraticBezierTo(w * 0.78, h * 0.36, w * 0.50, h * 0.33)
        ..close();
      canvas.drawPath(rightLeaf, fillPaint);
      canvas.restore();

      canvas.restore();
    }

    // 2. Animated Pocket Shield Body
    if (pocketScale > 0.01) {
      canvas.save();
      final center = Offset(w * 0.50, h * 0.66);
      canvas.translate(center.dx, center.dy);
      canvas.scale(pocketScale, pocketScale);
      canvas.translate(-center.dx, -center.dy);

      Path buildPocketPath(double inset) {
        final left = w * 0.20 + inset;
        final right = w * 0.80 - inset;
        final top = h * 0.44 + inset;
        final midY = h * 0.68 - inset * 0.4;
        final bottom = h * 0.88 - inset;

        return Path()
          ..moveTo(left, top)
          ..lineTo(right, top)
          ..lineTo(right, midY)
          ..quadraticBezierTo(right, bottom * 0.92, w * 0.50, bottom)
          ..quadraticBezierTo(left, bottom * 0.92, left, midY)
          ..close();
      }

      canvas.drawPath(buildPocketPath(0), fillPaint);

      // 3. Progressive Dashed Terracotta Stitching
      if (stitchProgress > 0.01) {
        final stitchPath = buildPocketPath(w * 0.065);
        final stitchPaint = Paint()
          ..color = stitchColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.026
          ..strokeCap = StrokeCap.round;

        for (final metric in stitchPath.computeMetrics()) {
          final activeLength = metric.length * stitchProgress;
          double distance = 0;
          final dashLen = w * 0.045;
          final gapLen = w * 0.035;
          while (distance < activeLength) {
            final next = math.min(distance + dashLen, activeLength);
            canvas.drawPath(metric.extractPath(distance, next), stitchPaint);
            distance += dashLen + gapLen;
          }
        }
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PocketLogoPainter oldDelegate) {
    return oldDelegate.pocketScale != pocketScale ||
        oldDelegate.stitchProgress != stitchProgress ||
        oldDelegate.sproutProgress != sproutProgress;
  }
}