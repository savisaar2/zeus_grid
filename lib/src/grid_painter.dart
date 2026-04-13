import 'package:flutter/material.dart';
import 'models.dart';

class GridPainter extends CustomPainter {
  final GridStyle style;
  final double cellW, cellH;
  final double spacing;
  final int rows, cols;

  GridPainter({
    required this.style,
    required this.cellW,
    required this.cellH,
    required this.spacing,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw Background
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = style.backgroundColor,
    );

    if (!style.showGrid) return;

    // 2. Setup Paints
    final minorPaint = Paint()
      ..color = style.lineColor
      ..strokeWidth = style.lineWidth
      ..isAntiAlias = false;

    final majorPaint = Paint()
      ..color = style.majorLineColor
      ..strokeWidth = style.majorLineWidth
      ..isAntiAlias = false;

    // 3. Draw Grid Lines
    for (int i = 0; i <= cols; i++) {
      final isMajor = i % style.majorInterval == 0;
      final isMinor = i % style.minorInterval == 0;
      if (!isMajor && !isMinor && i != cols) continue;
      final paint = isMajor ? majorPaint : minorPaint;
      double x = (i * cellW).roundToDouble();
      if (i == cols) x = size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i <= rows; i++) {
      final isMajor = i % style.majorInterval == 0;
      final isMinor = i % style.minorInterval == 0;
      if (!isMajor && !isMinor && i != rows) continue;
      final paint = isMajor ? majorPaint : minorPaint;
      double y = (i * cellH).roundToDouble();
      if (i == rows) y = size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // 4. Draw Spacing Visualization (if spacing > 0)
    if (spacing > 0) {
      final cellPaint = Paint()
        ..color = style.lineColor.withAlpha(20)
        ..style = PaintingStyle.fill;

      for (int c = 0; c < cols; c++) {
        for (int r = 0; r < rows; r++) {
          final rect = Rect.fromLTWH(
            c * cellW + spacing / 2,
            r * cellH + spacing / 2,
            cellW - spacing,
            cellH - spacing,
          );
          if (rect.right <= size.width && rect.bottom <= size.height) {
            canvas.drawRect(rect, cellPaint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.cellW != cellW ||
        oldDelegate.cellH != cellH ||
        oldDelegate.spacing != spacing;
  }
}
