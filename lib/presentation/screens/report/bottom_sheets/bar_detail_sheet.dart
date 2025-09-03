// lib/presentation/widgets/report/bottom_sheets/bar_detail_sheet.dart
import 'package:flutter/material.dart';
import '../models/chart_data_item.dart';
import '../utils/chart_utils.dart';

class BarDetailSheet {
  static void show(
    BuildContext context,
    ChartDataItem item,
    Color color,
    double percentage,
    List<Map<String, dynamic>> allData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _BarDetailContent(
        item: item,
        color: color,
        percentage: percentage,
        allData: allData,
      ),
    );
  }
}

class _BarDetailContent extends StatelessWidget {
  final ChartDataItem item;
  final Color color;
  final double percentage;
  final List<Map<String, dynamic>> allData;

  const _BarDetailContent({
    required this.item,
    required this.color,
    required this.percentage,
    required this.allData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with color indicator
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Değer',
                          ChartUtils.formatValue(item.value),
                          color,
                          Icons.trending_up,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildStatItem(
                          'Oran',
                          '${(percentage * 100).toStringAsFixed(1)}%',
                          color,
                          Icons.pie_chart_outline,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Progress visualization
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Görsel Oran',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF374151),
                        ),
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: percentage,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withValues(alpha: 0.7)],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
