// lib/presentation/widgets/report/charts/enhanced_bar_chart.dart
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_sizes.dart';
import '../utils/chart_utils.dart';
import '../bottom_sheets/bar_detail_sheet.dart';

class EnhancedBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const EnhancedBarChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final chartData = ChartUtils.extractChartData(data);

    if (chartData.isEmpty) {
      return ChartUtils.buildEmptyState(size, 'Çubuk Grafik');
    }

    final maxValue = chartData.map((e) => e.value).reduce(math.max).toDouble();

    return Column(
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 28,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Toplam: ${data.length} kategori',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Simple list - no cards
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 20),
            itemCount: chartData.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF3F4F6),
            ),
            itemBuilder: (context, index) {
              final item = chartData[index];
              final percentage = maxValue > 0 ? (item.value / maxValue) : 0.0;
              final colors = _getCardColors();
              final color = colors[index % colors.length];

              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => BarDetailSheet.show(context, item, color, percentage, data),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                    child: Row(
                      children: [
                        // Color indicator
                        Container(
                          width: 6,
                          height: 44,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),

                        SizedBox(width: 16),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title and value
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1F2937),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    ChartUtils.formatValue(item.value),
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: 8),

                              // Progress bar
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF3F4F6),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: FractionallySizedBox(
                                        alignment: Alignment.centerLeft,
                                        widthFactor: percentage,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    '${(percentage * 100).toStringAsFixed(0)}%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: 12),

                        // Arrow
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Color(0xFFD1D5DB),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<Color> _getCardColors() {
    return [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Emerald
      Color(0xFFF59E0B), // Amber
      Color(0xFF8B5CF6), // Violet
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF97316), // Orange
      Color(0xFF84CC16), // Lime
      Color(0xFFEC4899), // Pink
    ];
  }
}
