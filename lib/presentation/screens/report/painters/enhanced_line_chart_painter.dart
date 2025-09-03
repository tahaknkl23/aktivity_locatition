// lib/presentation/widgets/report/painters/enhanced_line_chart_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/chart_data_item.dart';

class EnhancedLineChartPainter extends CustomPainter {
  final List<ChartDataItem> data;

  EnhancedLineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || size.width <= 0 || size.height <= 0) return;

    final linePaint = Paint()
      ..color = Color(0xFF10B981)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Color(0xFF059669)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color(0xFF10B981).withValues(alpha: 0.3),
          Color(0xFF10B981).withValues(alpha: 0.0),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final values = data.map((e) => e.value).toList();
    final maxValue = values.reduce(math.max);
    final minValue = values.reduce(math.min);
    final valueRange = math.max(maxValue - minValue, 1.0);

    final path = Path();
    final shadowPath = Path();
    final points = <Offset>[];

    final margin = 40.0;
    final chartWidth = size.width - 2 * margin;
    final chartHeight = size.height - 2 * margin;

    // Draw grid
    final gridPaint = Paint()
      ..color = Color(0xFFE5E7EB)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      final y = margin + chartHeight * i / 4;
      canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), gridPaint);
    }

    // Plot points and create paths
    for (int i = 0; i < data.length; i++) {
      final x = margin + chartWidth * i / math.max(1, data.length - 1);
      final normalizedValue = valueRange > 0 ? (data[i].value - minValue) / valueRange : 0.0;
      final y = margin + chartHeight * (1 - normalizedValue);

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
        shadowPath.moveTo(x, size.height - margin);
        shadowPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        shadowPath.lineTo(x, y);
      }
    }

    // Close shadow path and draw
    if (points.isNotEmpty) {
      shadowPath.lineTo(points.last.dx, size.height - margin);
      shadowPath.close();
      canvas.drawPath(shadowPath, shadowPaint);
    }

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw points with glow effect
    for (final point in points) {
      // Glow effect
      canvas.drawCircle(point, 6, Paint()..color = Color(0xFF10B981).withValues(alpha: 0.3));
      // White border
      canvas.drawCircle(point, 4, Paint()..color = Colors.white);
      // Inner point
      canvas.drawCircle(point, 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
