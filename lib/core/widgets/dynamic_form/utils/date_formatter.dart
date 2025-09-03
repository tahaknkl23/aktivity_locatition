// lib/core/widgets/dynamic_form/utils/date_formatter.dart
import 'package:flutter/material.dart';

/// Date formatting utility
class DateFormatter {
  /// Değeri uygun date formatına çevirir
  static String? format(dynamic value) {
    if (value == null) return null;

    try {
      if (value is String) {
        String dateStr = value.trim();

        // Zaten doğru formatta ise direkt döndür
        if (dateStr.contains('.') && (dateStr.contains(':') || dateStr.contains(' '))) {
          return dateStr;
        }

        // ISO format ise parse et
        if (dateStr.contains('-') || dateStr.contains('T')) {
          final date = DateTime.parse(dateStr);
          return _formatDateTime(date);
        }

        // Başka bir format varsa olduğu gibi döndür
        return dateStr;
      }

      if (value is DateTime) {
        return _formatDateTime(value);
      }
    } catch (e) {
      debugPrint('[DateFormatter] Format error for value: $value - Error: $e');
      return value.toString();
    }

    return value.toString();
  }

  /// DateTime'ı string'e çevirir
  static String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Sadece date formatı
  static String formatDateOnly(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  /// String'i DateTime'a parse eder
  static DateTime? parseDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) return null;

    try {
      String cleanStr = dateStr.trim();

      // dd.MM.yyyy HH:mm formatı
      if (cleanStr.contains('.') && cleanStr.contains(' ') && cleanStr.contains(':')) {
        List<String> mainParts = cleanStr.split(' ');
        if (mainParts.length >= 2) {
          List<String> dateParts = mainParts[0].split('.');
          List<String> timeParts = mainParts[1].split(':');

          if (dateParts.length == 3 && timeParts.length >= 2) {
            return DateTime(
              int.parse(dateParts[2]), // year
              int.parse(dateParts[1]), // month
              int.parse(dateParts[0]), // day
              int.parse(timeParts[0]), // hour
              int.parse(timeParts[1]), // minute
            );
          }
        }
      }

      // dd.MM.yyyy formatı
      if (cleanStr.contains('.')) {
        List<String> dateParts = cleanStr.split('.');
        if (dateParts.length == 3) {
          return DateTime(
            int.parse(dateParts[2]), // year
            int.parse(dateParts[1]), // month
            int.parse(dateParts[0]), // day
          );
        }
      }

      // ISO format dene
      return DateTime.tryParse(cleanStr);
    } catch (e) {
      debugPrint('[DateFormatter] Parse error for: $dateStr - Error: $e');
      return null;
    }
  }
}