// lib/presentation/widgets/report/charts/enhanced_line_chart.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../utils/chart_utils.dart';
import '../painters/enhanced_line_chart_painter.dart';

class EnhancedLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const EnhancedLineChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final chartData = ChartUtils.extractChartData(data);

    if (chartData.isEmpty) {
      return ChartUtils.buildEmptyState(size, 'Çizgi Grafik');
    }

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          ChartUtils.buildChartHeader(
            title: title,
            count: data.length,
            countLabel: 'nokta',
            color: Color(0xFF10B981),
          ),

          SizedBox(height: 24),

          // Line chart
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              padding: EdgeInsets.all(16),
              child: CustomPaint(
                size: Size(double.infinity, double.infinity),
                painter: EnhancedLineChartPainter(chartData),
              ),
            ),
          ),

          SizedBox(height: 16),

          // Horizontal scrollable legend
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: chartData.length,
              separatorBuilder: (context, index) => SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = chartData[index];
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF10B981).withValues(alpha: 0.1),
                        Color(0xFF10B981).withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFF10B981).withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.label.length > 8 ? '${item.label.substring(0, 8)}...' : item.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        ChartUtils.formatValue(item.value),
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
