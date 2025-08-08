// lib/data/services/api/report_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';

class ReportApiService {
  /// Report verisini getir - farklı endpoint'ler dene
  Future<Map<String, dynamic>> getReportData({
    required String reportId,
    int page = 1,
    int pageSize = 50,
  }) async {
    debugPrint('[REPORT_API] 📊 Getting report data for ID: $reportId');

    // Farklı endpoint'leri sırasıyla dene
    final endpoints = [
      () => _tryReportEndpoint1(reportId, page, pageSize),
      () => _tryReportEndpoint2(reportId, page, pageSize),
      () => _tryReportEndpoint3(reportId, page, pageSize),
      () => _tryReportEndpoint4(reportId, page, pageSize),
    ];

    for (int i = 0; i < endpoints.length; i++) {
      try {
        debugPrint('[REPORT_API] 🔄 Trying endpoint ${i + 1}...');
        final result = await endpoints[i]();

        if (result != null && result.isNotEmpty) {
          debugPrint('[REPORT_API] ✅ Endpoint ${i + 1} successful!');
          return result;
        }
      } catch (e) {
        debugPrint('[REPORT_API] ❌ Endpoint ${i + 1} failed: $e');
      }
    }

    throw Exception('Tüm report endpoint\'leri başarısız oldu');
  }

  /// Endpoint 1: GetReadReport (en yaygın) - FIXED FORMAT
  Future<Map<String, dynamic>?> _tryReportEndpoint1(String reportId, int page, int pageSize) async {
    final requestBody = {
      "model": {
        "Parameters": [],
        "model": {"Text": "", "Value": ""},
        "culture": "tr",
        "form_PATH": "/Report/Detail/$reportId",
        "type": "Report",
        "controller": "Report",
      },
      "take": pageSize,
      "skip": (page - 1) * pageSize,
      "page": page,
      "pageSize": pageSize,
    };

    final response = await ApiClient.post(
      '/api/admin/DynamicFormApi/GetReadReport/$reportId',
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final rawData = jsonDecode(response.body);
      debugPrint('[REPORT_API] 🔍 Endpoint 1 raw response: $rawData');

      // API'den gelen format: {"Data": [...], "Total": 1, "Aggregates": {}}
      // Bunu DataSourceResult formatına çevir
      if (rawData['Data'] != null) {
        final convertedData = {
          'DataSourceResult': {
            'Data': rawData['Data'],
            'Total': rawData['Total'] ?? 0,
          },
          'Aggregates': rawData['Aggregates'],
          'Errors': rawData['Errors'],
        };
        debugPrint('[REPORT_API] ✅ Converted to DataSourceResult format');
        return convertedData;
      }

      return rawData;
    }
    return null;
  }

  /// Endpoint 2: GetReadReportDataAndType
  Future<Map<String, dynamic>?> _tryReportEndpoint2(String reportId, int page, int pageSize) async {
    final requestBody = {
      "model": {
        "Parameters": [],
        "LayoutData": {"element": "ReportGrid", "url": "/Report/Detail/$reportId"},
        "model": {"columns": []},
        "form_PATH": "/Report/Detail/$reportId",
        "type": "Report",
      },
      "take": pageSize,
      "skip": (page - 1) * pageSize,
      "page": page,
      "pageSize": pageSize,
    };

    final response = await ApiClient.post(
      '/api/admin/DynamicFormApi/GetReadReportDataAndType/$reportId',
      body: requestBody,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Endpoint 3: GetDataTypeMultipleReport (dashboard style)
  Future<Map<String, dynamic>?> _tryReportEndpoint3(String reportId, int page, int pageSize) async {
    final requestBody = {
      "form_PATH": "/Report/Detail/$reportId",
      "SqlIds": [reportId],
      "WidgetIds": [int.tryParse(reportId) ?? 0],
      "indexs": [0],
      "pageSize": pageSize,
    };

    final response = await ApiClient.post(
      '/api/DynamicFormApi/GetDataTypeMultipleReport',
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List && data.isNotEmpty) {
        return data.first as Map<String, dynamic>;
      }
    }
    return null;
  }

  /// Endpoint 4: Direct Report API
  Future<Map<String, dynamic>?> _tryReportEndpoint4(String reportId, int page, int pageSize) async {
    final requestBody = {
      "reportId": reportId,
      "page": page,
      "pageSize": pageSize,
      "filters": {},
    };

    final response = await ApiClient.post(
      '/api/Report/GetReportData/$reportId',
      body: requestBody,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return null;
  }

  /// Mock data for testing (geçici)
  Map<String, dynamic> getMockReportData(String reportId) {
    switch (reportId) {
      case '12': // Firma Raporları
        return {
          'DataSourceResult': {
            'Data': [
              {'Id': 1, 'Firma': 'ABC Şirketi', 'Telefon': '0212 123 45 67', 'Email': 'info@abc.com', 'Sektor': 'Teknoloji'},
              {'Id': 2, 'Firma': 'XYZ Ltd.', 'Telefon': '0312 987 65 43', 'Email': 'info@xyz.com', 'Sektor': 'İnşaat'},
              {'Id': 3, 'Firma': 'Demo A.Ş.', 'Telefon': '0542 111 22 33', 'Email': 'demo@demo.com', 'Sektor': 'Perakende'},
            ],
            'Total': 3,
          }
        };
      case '2': // Teklif Raporları
        return {
          'DataSourceResult': {
            'Data': [
              {'Id': 101, 'TeklifNo': 'T2024-001', 'Firma': 'ABC Şirketi', 'Tutar': '150.000 TL', 'Durum': 'Beklemede'},
              {'Id': 102, 'TeklifNo': 'T2024-002', 'Firma': 'XYZ Ltd.', 'Tutar': '85.000 TL', 'Durum': 'Onaylandı'},
              {'Id': 103, 'TeklifNo': 'T2024-003', 'Firma': 'Demo A.Ş.', 'Tutar': '200.000 TL', 'Durum': 'Reddedildi'},
            ],
            'Total': 3,
          }
        };
      case '3': // Fırsat Raporları
        return {
          'DataSourceResult': {
            'Data': [
              {'Id': 201, 'Konu': 'Yeni Yazılım Projesi', 'Firma': 'ABC Şirketi', 'Değer': '500.000 TL', 'Aşama': 'Görüşme'},
              {'Id': 202, 'Konu': 'ERP Implementasyonu', 'Firma': 'XYZ Ltd.', 'Değer': '300.000 TL', 'Aşama': 'Teklif'},
              {'Id': 203, 'Konu': 'Cloud Migration', 'Firma': 'Demo A.Ş.', 'Değer': '750.000 TL', 'Aşama': 'Kapalı-Kazanıldı'},
            ],
            'Total': 3,
          }
        };
      default:
        return {
          'DataSourceResult': {
            'Data': [
              {'Id': 1, 'Message': 'Rapor bulunamadı', 'ReportId': reportId, 'Status': 'Not Found'},
            ],
            'Total': 1,
          }
        };
    }
  }
}
