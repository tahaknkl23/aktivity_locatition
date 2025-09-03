// lib/core/widgets/dynamic_form/utils/dropdown_options_loader.dart - FIXED VERSION
import 'package:aktivity_location_app/data/services/api/company_api_service.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';
import '../../../../data/services/api/api_client.dart';
import 'dart:convert';

class DropdownOptionsLoader {
  final CompanyApiService apiService;

  const DropdownOptionsLoader({
    required this.apiService,
  });

  Future<List<DropdownOption>> loadOptions({
    required String sourceType,
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    String? controller,
    String? formPath,
  }) async {
    debugPrint('[DropdownLoader] 🌐 Loading options...');
    debugPrint('[DropdownLoader] sourceType: $sourceType, sourceValue: $sourceValue');
    debugPrint('[DropdownLoader] controller: $controller, formPath: $formPath');

    try {
      // ✅ FIX: Controller ve FormPath bazında doğru endpoint seç
      if (sourceType == '1') {
        // SQL Source - Farklı endpoint'ler dene
        return await _loadSqlSourceOptions(
          sourceValue: sourceValue,
          dataTextField: dataTextField,
          dataValueField: dataValueField,
          controller: controller,
          formPath: formPath,
        );
      } else if (sourceType == '4') {
        // Group Source - Web format kullan
        return await _loadGroupSourceOptions(
          sourceValue: sourceValue,
          controller: controller,
          formPath: formPath,
        );
      }

      debugPrint('[DropdownLoader] ❌ Unsupported sourceType: $sourceType');
      return [];
    } catch (e) {
      debugPrint('[DropdownLoader] ❌ Error loading options: $e');
      return [];
    }
  }

  /// ✅ SQL Source için çoklu endpoint denemesi
  Future<List<DropdownOption>> _loadSqlSourceOptions({
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    String? controller,
    String? formPath,
  }) async {
    debugPrint('[DropdownLoader] 🔍 Loading SQL Source: $sourceValue');

    // ✅ FIX 1: Web format ile dene (pagination ile)
    try {
      final webResult = await _tryWebFormatSqlSource(
        sourceValue: sourceValue,
        dataTextField: dataTextField,
        dataValueField: dataValueField,
        controller: controller,
        formPath: formPath,
      );

      if (webResult.isNotEmpty) {
        debugPrint('[DropdownLoader] ✅ Web format success: ${webResult.length} items');
        return webResult;
      }
    } catch (e) {
      debugPrint('[DropdownLoader] ⚠️ Web format failed: $e');
    }

    // ✅ FIX 2: Eski mobile format ile dene
    try {
      final mobileResult = await _tryMobileFormatSqlSource(
        sourceValue: sourceValue,
        dataTextField: dataTextField,
        dataValueField: dataValueField,
        controller: controller,
        formPath: formPath,
      );

      if (mobileResult.isNotEmpty) {
        debugPrint('[DropdownLoader] ✅ Mobile format success: ${mobileResult.length} items');
        return mobileResult;
      }
    } catch (e) {
      debugPrint('[DropdownLoader] ⚠️ Mobile format failed: $e');
    }

    debugPrint('[DropdownLoader] ❌ All SQL endpoints failed for: $sourceValue');
    return [];
  }

  /// ✅ WEB FORMAT - Pagination ile tüm veriyi çek
  Future<List<DropdownOption>> _tryWebFormatSqlSource({
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    String? controller,
    String? formPath,
  }) async {
    debugPrint('[DropdownLoader] 🌐 Trying WEB format for SQL: $sourceValue');

    final allOptions = <DropdownOption>[];
    int page = 1;
    const pageSize = 50;
    bool hasMoreData = true;

    while (hasMoreData && page <= 20) {
      // Max 20 page limit
      debugPrint('[DropdownLoader] 📄 Loading page $page...');

      final requestBody = {
        "model": {
          "Parameters": [],
          "model": {
            dataTextField ?? "Adi": "",
            dataValueField ?? "UserId": "",
          },
          "culture": "tr",
          "form_PATH": formPath ?? "/Dyn/${controller ?? 'Generic'}/Detail",
          "type": "DropDownList",
          "apiUrl": null,
          "controller": controller ?? "Generic",
          "revisionNo": null,
          "dataId": null,
          "valueName": "DropDownList"
        },
        "take": pageSize,
        "skip": (page - 1) * pageSize,
        "page": page,
        "pageSize": pageSize,
        "filter": {"logic": "and", "filters": []}
      };

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final pageData = data['Data'] as List? ?? [];
        final total = data['Total'] as int? ?? 0;

        debugPrint('[DropdownLoader] 📊 Page $page: ${pageData.length} items, Total: $total');

        if (pageData.isEmpty) {
          hasMoreData = false;
          break;
        }

        // Convert to DropdownOption
        for (final item in pageData) {
          final value = item[dataValueField ?? 'UserId'] ?? item['Id'] ?? item['Value'];
          final text = item[dataTextField ?? 'Adi'] as String? ?? item['Text'] as String? ?? item['Name'] as String? ?? value?.toString() ?? '';

          if (text.isNotEmpty) {
            allOptions.add(DropdownOption(value: value, text: text));
          }
        }

        // Check if we have more data
        hasMoreData = allOptions.length < total && pageData.length == pageSize;
        page++;
      } else {
        debugPrint('[DropdownLoader] ❌ Page $page failed: ${response.statusCode}');
        break;
      }
    }

    debugPrint('[DropdownLoader] ✅ Web format total: ${allOptions.length} options');
    return allOptions;
  }

  /// ✅ MOBILE FORMAT - Eski sistem
  Future<List<DropdownOption>> _tryMobileFormatSqlSource({
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    String? controller,
    String? formPath,
  }) async {
    debugPrint('[DropdownLoader] 📱 Trying MOBILE format for SQL: $sourceValue');

    final requestBody = {
      "model": {
        "Parameters": [],
        "model": {dataTextField ?? "Text": "", dataValueField ?? "Id": ""},
        "culture": "tr",
        "form_PATH": formPath ?? "/Dyn/${controller ?? 'Generic'}/Detail",
        "type": "DropDownList",
        "controller": controller ?? "Generic",
      },
      "take": "",
      "skip": 0,
      "page": 1,
      "pageSize": 0
    };

    final response = await ApiClient.post(
      '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final dataList = data['Data'] as List? ?? [];

      return dataList
          .map((item) {
            final value = item[dataValueField ?? 'Id'] ?? item['Value'] ?? item['UserId'];
            final text = item[dataTextField ?? 'Text'] as String? ?? item['Adi'] as String? ?? item['Name'] as String? ?? value?.toString() ?? '';

            return DropdownOption(value: value, text: text);
          })
          .where((item) => item.text.isNotEmpty)
          .toList();
    }

    throw Exception('Mobile format failed: ${response.statusCode}');
  }

  /// ✅ Group Source için web format
  Future<List<DropdownOption>> _loadGroupSourceOptions({
    required dynamic sourceValue,
    String? controller,
    String? formPath,
  }) async {
    debugPrint('[DropdownLoader] 🔍 Loading Group Source: $sourceValue');

    final requestBody = {
      "model": {
        "Parameters": [],
        "model": {"Text": "", "Value": ""},
        "culture": "tr",
        "form_PATH": formPath ?? "/Dyn/${controller ?? 'Generic'}/Detail",
        "type": "DropDownList",
        "controller": controller ?? "Generic",
      },
      "filter": {"logic": "and", "filters": []}
    };

    final response = await ApiClient.post(
      '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
      body: requestBody,
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

    throw Exception('Group source failed: ${response.statusCode}');
  }
}
