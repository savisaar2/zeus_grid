import 'package:flutter/material.dart';
import 'models.dart';

class GridPainter extends CustomPainter {
  final GridStyle style;
  final double cellW, cellH;
  final int rows, cols;

  GridPainter({
    required this.style,
    required this.cellW,
    required this.cellH,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!style.showGrid) return;

    final paint = Paint()
      ..color = style.lineColor
      ..strokeWidth = style.lineWidth
      ..isAntiAlias = false;

    for (int i = 0; i <= cols; i++) {
      double x = i * cellW;
      if (i == cols) x = size.width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (int i = 0; i <= rows; i++) {
      double y = i * cellH;
      if (i == rows) y = size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.cellW != cellW ||
        oldDelegate.cellH != cellH;
  }
}
