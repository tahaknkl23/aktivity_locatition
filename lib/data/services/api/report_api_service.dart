// lib/data/services/api/report_api_service.dart - DYNAMIC VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import 'api_client.dart';

class ReportApiService {
  /// Get report group items - EXISTING METHOD
  Future<Map<String, dynamic>> getReportGroupItems({
    required String groupId,
  }) async {
    debugPrint('[REPORT_API] Getting report group items for Group ID: $groupId');

    try {
      final requestBody = {"take": 0, "skip": 0, "page": 1, "pageSize": 0};

      final response = await ApiClient.post(
        '/api/ReportApi/GetGroupItems/$groupId',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[REPORT_API] ✅ Group items loaded: ${(data['Data'] as List?)?.length ?? 0}');
        return data;
      } else {
        throw Exception('Failed to load report group items: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[REPORT_API] ❌ Get report group items error: $e');
      rethrow;
    }
  }

  /// 🆕 GET DYNAMIC REPORT FORM - Rapor filtreleri için form al
  Future<DynamicFormModel> getDynamicReportForm({
    required String reportId,
  }) async {
    debugPrint('[REPORT_API] 📋 Getting dynamic report form for ID: $reportId');

    try {
      // Web'deki gibi form yapısını al
      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormWithData',
        body: {
          "model": {
            "controller": "Report",
            "id": int.tryParse(reportId) ?? 0,
            "url": "/Report/Detail/$reportId",
            "formParams": {},
            "form_PATH": "/Report/Detail/$reportId",
            "culture": "tr"
          }
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[REPORT_API] ✅ Dynamic report form loaded');

        // Form model oluştur
        return DynamicFormModel.fromJson(data);
      } else {
        throw Exception('Failed to load dynamic report form: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[REPORT_API] ❌ Get dynamic report form error: $e');
      rethrow;
    }
  }

  /// 🆕 EXECUTE DYNAMIC REPORT WITH FILTERS
  Future<Map<String, dynamic>> executeDynamicReport({
    required String reportId,
    required Map<String, dynamic> filterData,
    int page = 1,
    int pageSize = 50,
  }) async {
    debugPrint('[REPORT_API] 🔄 Executing dynamic report ID: $reportId');
    debugPrint('[REPORT_API] 📊 Filter data: ${filterData.keys.toList()}');

    try {
      // Filter data'dan parametreleri oluştur
      final parameters = _buildReportParameters(filterData);

      final requestBody = {
        "model": {
          "Parameters": parameters,
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

      debugPrint('[REPORT_API] 📦 Request parameters: ${parameters.length}');

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReport/$reportId',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[REPORT_API] ✅ Dynamic report executed successfully');
        debugPrint('[REPORT_API] 📊 Result count: ${(data['Data'] as List?)?.length ?? 0}');

        return data;
      } else {
        throw Exception('Dynamic report execution failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[REPORT_API] ❌ Execute dynamic report error: $e');
      rethrow;
    }
  }

  /// 🆕 GET REPORT METADATA - Rapor bilgilerini al
  Future<ReportMetadata> getReportMetadata({
    required String reportId,
  }) async {
    debugPrint('[REPORT_API] 📋 Getting report metadata for ID: $reportId');

    try {
      // Rapor detaylarını al
      final response = await ApiClient.get('/api/ReportApi/GetReportInfo/$reportId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[REPORT_API] ✅ Report metadata loaded');

        return ReportMetadata.fromJson(data);
      } else {
        throw Exception('Failed to load report metadata: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[REPORT_API] ❌ Get report metadata error: $e');
      // Fallback: Temel metadata oluştur
      return ReportMetadata.fallback(reportId);
    }
  }

  /// 🆕 GET REPORT DROPDOWN OPTIONS - Rapor filtreleri için dropdown verilerini al
  Future<List<DropdownOption>> getReportDropdownOptions({
    required String sourceType,
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('[REPORT_API] Loading report dropdown options - Source: $sourceType/$sourceValue');

      if (sourceType == '4') {
        // Group source handling
        final response = await ApiClient.post(
          '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
          body: {
            "model": {
              "Parameters": [],
              "model": {"Text": "", "Value": ""},
              "culture": "tr",
              "form_PATH": "/Report/Detail",
              "type": "DropDownList",
              "controller": "Report",
            },
            "filter": {"logic": "and", "filters": []}
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dataList = data['Data'] as List? ?? [];

          return dataList
              .map((item) => DropdownOption(
                    value: item['Value'] ?? item['Id'],
                    text: item['Text'] as String? ?? '',
                  ))
              .where((item) => item.text.isNotEmpty)
              .toList();
        }
      } else if (sourceType == '1') {
        // SQL source
        final response = await ApiClient.post(
          '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
          body: {
            "model": {
              "Parameters": [],
              "model": {dataTextField ?? "Text": "", dataValueField ?? "Id": ""},
              "culture": "tr",
              "form_PATH": "/Report/Detail",
              "type": "DropDownList",
              "controller": "Report",
            },
            "take": "",
            "skip": 0,
            "page": 1,
            "pageSize": 0
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dataList = data['Data'] as List? ?? [];

          return dataList
              .map((item) {
                final value = item[dataValueField ?? 'Id'] ?? item['Value'] ?? item['Id'];
                final text =
                    item[dataTextField ?? 'Text'] as String? ?? item['Text'] as String? ?? item['Name'] as String? ?? value?.toString() ?? '';

                return DropdownOption(value: value, text: text);
              })
              .where((item) => item.text.isNotEmpty)
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('[REPORT_API] Load report dropdown error: $e');
      return [];
    }
  }

  /// Filter data'dan SQL parametrelerini oluştur
  List<Map<String, dynamic>> _buildReportParameters(Map<String, dynamic> filterData) {
    final parameters = <Map<String, dynamic>>[];

    filterData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        // Parametreleri SQL formatına çevir
        parameters.add({
          "Name": "@$key",
          "Type": _getParameterType(value),
          "Value": value,
        });
      }
    });

    // Varsayılan parametreler ekle
    if (!filterData.containsKey('startDate')) {
      parameters.add({
        "Name": "@startDate",
        "Type": 4, // DateTime
        "Value": null,
      });
    }

    if (!filterData.containsKey('endDate')) {
      parameters.add({
        "Name": "@endDate",
        "Type": 4, // DateTime
        "Value": null,
      });
    }

    debugPrint('[REPORT_API] Built ${parameters.length} parameters');
    return parameters;
  }

  /// Veri tipinden SQL parameter tipi belirle
  int _getParameterType(dynamic value) {
    if (value is String) return 1; // String
    if (value is int) return 2; // Int
    if (value is double) return 3; // Float
    if (value is DateTime) return 4; // DateTime
    if (value is bool) return 5; // Boolean
    return 1; // Default string
  }

  /// EXISTING METHOD - Execute report without filters
  Future<Map<String, dynamic>> executeReport({
    required String reportId,
  }) async {
    debugPrint('[REPORT_API] 🔄 Executing simple report ID: $reportId');

    try {
      final requestBody = {
        "model": {
          "Parameters": [],
          "model": {"Text": "", "Value": ""},
          "culture": "tr",
          "form_PATH": "/Report/Detail/$reportId",
          "type": "Report",
          "controller": "Report",
        },
        "take": 0,
        "skip": 0,
        "page": 1,
        "pageSize": 0,
      };

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReport/$reportId',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[REPORT_API] ✅ Simple report executed successfully');
        return data;
      } else {
        throw Exception('Report execution failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[REPORT_API] ❌ Execute simple report error: $e');
      rethrow;
    }
  }
}

/// Rapor metadata modeli
class ReportMetadata {
  final String id;
  final String name;
  final String description;
  final String chartType;
  final bool hasFilters;
  final List<String> availableColumns;

  ReportMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.chartType,
    required this.hasFilters,
    required this.availableColumns,
  });

  factory ReportMetadata.fromJson(Map<String, dynamic> json) {
    return ReportMetadata(
      id: json['Id']?.toString() ?? '',
      name: json['Name'] as String? ?? 'Bilinmeyen Rapor',
      description: json['Description'] as String? ?? '',
      chartType: json['ChartType'] as String? ?? 'Grid',
      hasFilters: json['HasFilters'] as bool? ?? false,
      availableColumns: (json['Columns'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  factory ReportMetadata.fallback(String reportId) {
    return ReportMetadata(
      id: reportId,
      name: 'Rapor $reportId',
      description: 'Dynamic rapor',
      chartType: 'Grid',
      hasFilters: true,
      availableColumns: [],
    );
  }
}
