// lib/presentation/widgets/report/utils/chart_utils.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../models/chart_data_item.dart';

class ChartUtils {
  // Data extraction
  static List<ChartDataItem> extractChartData(List<Map<String, dynamic>> data) {
    final chartItems = <ChartDataItem>[];

    for (final item in data.take(12)) {
      String label = '';
      double value = 0.0;

      // Label extraction
      final labelFields = ['Name', 'Title', 'Category', 'Kategori', 'Ay', 'Month', 'Label'];
      for (final field in labelFields) {
        if (item.containsKey(field) && item[field] != null) {
          label = item[field].toString();
          break;
        }
      }

      // Value extraction
      final valueFields = ['Value', 'Count', 'Amount', 'Total', 'Tutar', 'Adet', 'Miktar'];
      for (final field in valueFields) {
        if (item.containsKey(field) && item[field] != null) {
          final val = item[field];
          if (val is num) {
            value = val.toDouble();
            break;
          } else if (val is String) {
            value = double.tryParse(val) ?? 0.0;
            break;
          }
        }
      }

      if (label.isNotEmpty) {
        chartItems.add(ChartDataItem(label: label, value: value));
      }
    }

    return chartItems;
  }

  // Display columns for table
  static List<String> getDisplayColumns(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return [];
    return data.first.keys.where((key) => key != 'Id' && key != 'ChartType' && !key.toLowerCase().contains('hidden')).toList();
  }

  // Color palettes
  static List<Color> getModernPieColors() {
    return [
      Color(0xFF3B82F6), // Blue
      Color(0xFF10B981), // Green
      Color(0xFFF59E0B), // Orange
      Color(0xFF8B5CF6), // Purple
      Color(0xFFEF4444), // Red
      Color(0xFF06B6D4), // Cyan
      Color(0xFFF97316), // Orange-600
      Color(0xFF84CC16), // Lime
      Color(0xFFEC4899), // Pink
    ];
  }

  // Formatting
  static String formatValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
  }

  static String formatColumnName(String column) {
    const translations = {
      'Name': 'Ad',
      'Title': 'Başlık',
      'Amount': 'Tutar',
      'Count': 'Sayı',
      'Date': 'Tarih',
      'Category': 'Kategori',
      'Phone': 'Telefon',
      'Email': 'E-posta',
      'Company': 'Firma',
      'Address': 'Adres',
      'Status': 'Durum',
      'Type': 'Tür',
    };
    return translations[column] ?? column;
  }

  static String formatCellValue(dynamic value) {
    if (value == null) return '-';
    final stringValue = value.toString();
    if (stringValue.isEmpty || stringValue == 'null') return '-';
    return stringValue;
  }

  // UI builders
  static Widget buildChartHeader({
    required String title,
    required int count,
    required String countLabel,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
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
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$count $countLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildEmptyState(AppSizes size, String chartTypeName) {
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
                Icons.analytics_outlined,
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
              'Bu ${chartTypeName.toLowerCase()} için veri mevcut değil',
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
}
