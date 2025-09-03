// lib/presentation/widgets/report/chart_type_renderer.dart
import 'package:aktivity_location_app/presentation/screens/report/charts/enhanced_bar_chart.dart';
import 'package:aktivity_location_app/presentation/screens/report/charts/enhanced_data_grid.dart';
import 'package:aktivity_location_app/presentation/screens/report/charts/enhanced_line_chart.dart';
import 'package:aktivity_location_app/presentation/screens/report/charts/enhanced_pie_chart.dart';
import 'package:flutter/material.dart';

class ReportChartRenderer extends StatelessWidget {
  final String chartType;
  final List<Map<String, dynamic>> data;
  final String title;

  const ReportChartRenderer({
    super.key,
    required this.chartType,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _buildChartContent(context),
    );
  }

  Widget _buildChartContent(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    switch (chartType.toLowerCase()) {
      case 'bar':
        return EnhancedBarChart(data: data, title: title);
      case 'line':
        return EnhancedLineChart(data: data, title: title);
      case 'pie':
      case 'chart':
        return EnhancedPieChart(data: data, title: title);
      case 'grid':
      default:
        return EnhancedDataGrid(data: data, title: title);
    }
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _getChartIcon(),
                size: 48,
                color: Color(0xFF9CA3AF),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Veri Bulunamadı',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF374151),
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Bu ${_getChartTypeDisplayName().toLowerCase()} için veri mevcut değil',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  IconData _getChartIcon() {
    switch (chartType.toLowerCase()) {
      case 'bar':
        return Icons.bar_chart_outlined;
      case 'line':
        return Icons.show_chart_outlined;
      case 'pie':
      case 'chart':
        return Icons.pie_chart_outline;
      case 'grid':
        return Icons.table_chart_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  String _getChartTypeDisplayName() {
    switch (chartType.toLowerCase()) {
      case 'bar':
        return 'Çubuk Grafik';
      case 'line':
        return 'Çizgi Grafik';
      case 'pie':
      case 'chart':
        return 'Pasta Grafik';
      case 'grid':
        return 'Tablo';
      default:
        return chartType;
    }
  }
}
