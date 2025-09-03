// lib/presentation/widgets/report/charts/enhanced_pie_chart.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../models/chart_data_item.dart';
import '../utils/chart_utils.dart';
import '../painters/enhanced_pie_chart_painter.dart';
import '../bottom_sheets/pie_detail_sheet.dart';

class EnhancedPieChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;

  const EnhancedPieChart({
    super.key,
    required this.data,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final chartData = ChartUtils.extractChartData(data).take(6).toList();

    if (chartData.isEmpty) {
      return ChartUtils.buildEmptyState(size, 'Pasta Grafik');
    }

    final total = chartData.fold<double>(0, (sum, item) => sum + item.value);

    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with total
          _buildHeader(total, chartData.length),

          SizedBox(height: 24),

          // Pie chart üstte, merkezi
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Center(
              child: SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  size: Size(160, 160),
                  painter: EnhancedPieChartPainter(chartData, total),
                ),
              ),
            ),
          ),

          SizedBox(height: 20),

          // Veriler altında sıralı liste
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFFE5E7EB)),
              ),
              child: ListView.separated(
                padding: EdgeInsets.all(12),
                itemCount: chartData.length,
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _buildDataItem(context, chartData[index], index, total);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(double total, int categoryCount) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2),
              Text(
                'Toplam: ${ChartUtils.formatValue(total)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Color(0xFFF59E0B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$categoryCount kategori',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF59E0B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataItem(BuildContext context, ChartDataItem item, int index, double total) {
    final color = ChartUtils.getModernPieColors()[index % ChartUtils.getModernPieColors().length];
    final percentage = total > 0 ? ((item.value / total) * 100).toDouble() : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => PieDetailSheet.show(context, item, color, percentage, total, data),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Color(0xFFE5E7EB)),
          ),
          child: Row(
            children: [
              // Renk göstergesi
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              SizedBox(width: 12),

              // Kategori adı
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF374151),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Değer ve yüzde
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    ChartUtils.formatValue(item.value),
                    style: TextStyle(
                      fontSize: 15,
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              // Detay ikonu
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
