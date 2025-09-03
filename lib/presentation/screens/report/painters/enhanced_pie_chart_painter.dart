// lib/presentation/widgets/report/painters/enhanced_pie_chart_painter.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/chart_data_item.dart';
import '../utils/chart_utils.dart';

class EnhancedPieChartPainter extends CustomPainter {
  final List<ChartDataItem> data;
  final double total;

  EnhancedPieChartPainter(this.data, this.total);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || total <= 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 3.5;
    final colors = ChartUtils.getModernPieColors();

    double startAngle = -math.pi / 2;

    // Draw shadow
    canvas.drawCircle(
      Offset(center.dx + 3, center.dy + 3),
      radius,
      Paint()..color = Colors.black.withValues(alpha: 0.15),
    );

    // Draw pie slices
    for (int i = 0; i < data.length; i++) {
      final sweepAngle = (data[i].value / total) * 2 * math.pi;
      final color = colors[i % colors.length];

      final slicePaint = Paint()
        ..shader = LinearGradient(
          colors: [color, color.withValues(alpha: 0.8)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        slicePaint,
      );

      // White border
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );

      startAngle += sweepAngle;
    }

    // Draw center circle
    canvas.drawCircle(
      center,
      radius * 0.35,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
