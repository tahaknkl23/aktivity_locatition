// lib/presentation/widgets/report/bottom_sheets/pie_detail_sheet.dart
import 'package:flutter/material.dart';
import '../models/chart_data_item.dart';
import '../utils/chart_utils.dart';

class PieDetailSheet {
  static void show(
    BuildContext context,
    ChartDataItem item,
    Color color,
    double percentage,
    double total,
    List<Map<String, dynamic>> allData,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _PieDetailContent(
        item: item,
        color: color,
        percentage: percentage,
        total: total,
        allData: allData,
      ),
    );
  }
}

class _PieDetailContent extends StatelessWidget {
  final ChartDataItem item;
  final Color color;
  final double percentage;
  final double total;
  final List<Map<String, dynamic>> allData;

  const _PieDetailContent({
    required this.item,
    required this.color,
    required this.percentage,
    required this.total,
    required this.allData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
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
            margin: EdgeInsets.only(top: 12, bottom: 20),
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
                  // Header
                  _buildHeader(),

                  SizedBox(height: 24),

                  // Stats cards
                  _buildStatsCards(),

                  SizedBox(height: 24),

                  // Progress bar
                  _buildProgressSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Değer',
                ChartUtils.formatValue(item.value),
                color,
                Icons.show_chart,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Oran',
                '${percentage.toStringAsFixed(1)}%',
                color,
                Icons.pie_chart,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Toplam',
                ChartUtils.formatValue(total),
                Color(0xFF6B7280),
                Icons.analytics,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sıra',
                '#${_getItemRank()}',
                Color(0xFF6B7280),
                Icons.format_list_numbered,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Oransal Gösterim',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
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
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  int _getItemRank() {
    // Find item's position in data
    for (int i = 0; i < allData.length; i++) {
      if (allData[i].values.contains(item.label)) {
        return i + 1;
      }
    }
    return 1;
  }
}
