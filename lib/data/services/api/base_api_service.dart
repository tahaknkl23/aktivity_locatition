import 'dart:convert';
import 'package:aktivity_location_app/data/models/dynamic_form/form_field_model.dart';
import 'package:flutter/material.dart';
import 'api_client.dart';

class BaseApiService {
  static const String _getFormWithData = '/api/admin/DynamicFormApi/GetFormWithData';
  static const String _getFormListData = '/api/admin/DynamicFormApi/GetFormListData';
  static const String _insertData = '/api/admin/DynamicFormApi/InsertData';
  static const String _updateData = '/api/admin/DynamicFormApi/UpdateData';

  // Cache for dynamic configurations
  static final Map<String, DynamicControllerConfig> _configCache = {};

  /// Get form with data and extract dynamic configuration
  Future<FormWithConfigResult> getFormWithDataAndConfig({
    required String controller,
    required String url,
    int? id,
  }) async {
    try {
      String cleanUrl = url;
      if (!cleanUrl.startsWith('/')) {
        cleanUrl = '/$cleanUrl';
      }

      final requestBody = {
        "model": {"controller": controller, "id": id ?? 0, "url": cleanUrl, "formParams": {}, "form_PATH": cleanUrl, "culture": "tr"},
        "take": 10,
        "skip": 0,
        "page": 1,
        "pageSize": 10
      };

      debugPrint('[BASE_API] GetFormWithData Request:');
      debugPrint('[BASE_API] - Controller: $controller');
      debugPrint('[BASE_API] - URL: $cleanUrl');
      debugPrint('[BASE_API] - ID: $id');

      final response = await ApiClient.post(_getFormWithData, body: requestBody);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);

        // Extract dynamic configuration from response
        final config = _extractDynamicConfig(result, controller, cleanUrl);

        // Cache the configuration
        _configCache[controller.toLowerCase()] = config;

        debugPrint('[BASE_API] Dynamic config extracted:');
        debugPrint('[BASE_API] - FormID: ${config.formId}');
        debugPrint('[BASE_API] - TableID: ${config.tableId}');
        debugPrint('[BASE_API] - FormPath: ${config.formPath}');

        return FormWithConfigResult(
          formData: result,
          config: config,
        );
      } else {
        throw Exception('Failed to load form data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BASE_API] GetFormWithData error: $e');
      rethrow;
    }
  }

  /// Extract dynamic configuration from form response - ENHANCED
  DynamicControllerConfig _extractDynamicConfig(Map<String, dynamic> response, String controller, String formPath) {
    try {
      debugPrint('[BASE_API] === EXTRACTING DYNAMIC CONFIG ===');
      debugPrint('[BASE_API] Response keys: ${response.keys.toList()}');

      int? formId;
      int? tableId;

      // Method 1: Check Data.Form structure
      if (response['Data']?['Form'] != null) {
        final form = response['Data']['Form'] as Map<String, dynamic>;
        debugPrint('[BASE_API] Data.Form keys: ${form.keys.toList()}');

        formId = form['Id'] as int? ?? form['FormId'] as int? ?? form['form_ID'] as int?;
        tableId = form['TableId'] as int? ?? form['tableId'] as int? ?? form['table_ID'] as int?;

        debugPrint('[BASE_API] From Data.Form - FormID: $formId, TableID: $tableId');
      }

      // Method 2: Check Data.Data structure
      if ((formId == null || tableId == null) && response['Data']?['Data'] != null) {
        final data = response['Data']['Data'] as Map<String, dynamic>;
        debugPrint('[BASE_API] Data.Data keys: ${data.keys.toList()}');

        formId ??= data['form_ID'] as int? ?? data['FormId'] as int? ?? data['formId'] as int?;
        tableId ??= data['tableId'] as int? ?? data['TableId'] as int? ?? data['table_ID'] as int?;

        debugPrint('[BASE_API] From Data.Data - FormID: $formId, TableID: $tableId');
      }

      // Method 3: Check root Data structure
      if ((formId == null || tableId == null) && response['Data'] != null) {
        final rootData = response['Data'] as Map<String, dynamic>;
        debugPrint('[BASE_API] Root Data keys: ${rootData.keys.toList()}');

        formId ??= rootData['form_ID'] as int? ?? rootData['FormId'] as int? ?? rootData['formId'] as int?;
        tableId ??= rootData['tableId'] as int? ?? rootData['TableId'] as int? ?? rootData['table_ID'] as int?;

        debugPrint('[BASE_API] From Root Data - FormID: $formId, TableID: $tableId');
      }

      // Method 4: Deep search in all nested objects
      if (formId == null || tableId == null) {
        debugPrint('[BASE_API] Deep searching for FormID/TableID...');
        _searchNestedForIds(response, (fId, tId) {
          formId ??= fId;
          tableId ??= tId;
          debugPrint('[BASE_API] Deep search found - FormID: $fId, TableID: $tId');
        });
      }

      // Method 5: Static fallback
      if (formId == null || tableId == null) {
        debugPrint('[BASE_API] No dynamic config found, using static fallback');
        final staticConfig = _getStaticControllerConfig(controller);
        formId ??= staticConfig.formId;
        tableId ??= staticConfig.tableId;

        debugPrint('[BASE_API] Static config - FormID: $formId, TableID: $tableId');

        return DynamicControllerConfig(
          controller: controller,
          formId: formId!,
          tableId: tableId!,
          formPath: formPath,
          listPath: formPath.replaceAll('/Detail', '/List'),
          isExtracted: false, // Static fallback
        );
      }

      debugPrint('[BASE_API] SUCCESS: Dynamic config extracted - FormID: $formId, TableID: $tableId');
      debugPrint('[BASE_API] === END EXTRACTION ===');

      return DynamicControllerConfig(
        controller: controller,
        formId: formId!,
        tableId: tableId!,
        formPath: formPath,
        listPath: formPath.replaceAll('/Detail', '/List'),
        isExtracted: true, // Successfully extracted
      );
    } catch (e) {
      debugPrint('[BASE_API] Config extraction error: $e, using static fallback');
      final staticConfig = _getStaticControllerConfig(controller);
      return DynamicControllerConfig(
        controller: controller,
        formId: staticConfig.formId,
        tableId: staticConfig.tableId,
        formPath: formPath,
        listPath: formPath.replaceAll('/Detail', '/List'),
        isExtracted: false,
      );
    }
  }

  /// Recursively search for FormId and TableId in nested objects
  void _searchNestedForIds(dynamic obj, Function(int?, int?) callback) {
    if (obj is Map<String, dynamic>) {
      int? formId;
      int? tableId;

      // Check current level
      if (obj.containsKey('FormId') || obj.containsKey('formId') || obj.containsKey('form_ID')) {
        formId = obj['FormId'] ?? obj['formId'] ?? obj['form_ID'];
      }
      if (obj.containsKey('TableId') || obj.containsKey('tableId') || obj.containsKey('table_ID')) {
        tableId = obj['TableId'] ?? obj['tableId'] ?? obj['table_ID'];
      }

      if (formId != null || tableId != null) {
        callback(formId, tableId);
      }

      // Recursively search nested objects
      for (final value in obj.values) {
        if (value is Map<String, dynamic> || value is List) {
          _searchNestedForIds(value, callback);
        }
      }
    } else if (obj is List) {
      for (final item in obj) {
        _searchNestedForIds(item, callback);
      }
    }
  }

  /// Get cached or default configuration
  DynamicControllerConfig getControllerConfig(String controller) {
    final cached = _configCache[controller.toLowerCase()];
    if (cached != null) {
      debugPrint('[BASE_API] Using cached config for $controller: FormID=${cached.formId}, TableID=${cached.tableId}');
      return cached;
    }

    debugPrint('[BASE_API] No cached config for $controller, using static');
    final staticConfig = _getStaticControllerConfig(controller);
    return DynamicControllerConfig(
      controller: controller,
      formId: staticConfig.formId,
      tableId: staticConfig.tableId,
      formPath: staticConfig.formPath,
      listPath: staticConfig.listPath,
      isExtracted: false,
    );
  }

  /// Static fallback configurations - ENHANCED WITH MORE CONTROLLERS
  ControllerConfig _getStaticControllerConfig(String controller) {
    switch (controller.toLowerCase()) {
      case 'companyadd':
        return ControllerConfig(formId: 3, tableId: 104, formPath: '/Dyn/CompanyAdd/Detail', listPath: '/Dyn/CompanyAdd/List');
      case 'contactadd':
        return ControllerConfig(formId: 5, tableId: 105, formPath: '/Dyn/ContactAdd/Detail', listPath: '/Dyn/ContactAdd/List');
      case 'aktiviteadd':
      case 'aktivitebranchadd':
        return ControllerConfig(formId: 5895, tableId: 102, formPath: '/Dyn/AktiviteBranchAdd/Detail', listPath: '/Dyn/AktiviteBranchAdd/List');
      case 'addexpense':
        return ControllerConfig(formId: 5898, tableId: 316, formPath: '/Dyn/AddExpense/Detail', listPath: '/Dyn/AddExpense/List');
      case 'vehiclerentadd':
        return ControllerConfig(formId: 163, tableId: 272, formPath: '/Dyn/VehicleRentAdd/Detail', listPath: '/Dyn/VehicleRentAdd/List');
      case 'degertahsilatadd':
        return ControllerConfig(formId: 3531, tableId: 3548, formPath: '/Dyn/DegerTahsilatAdd/Detail', listPath: '/Dyn/DegerTahsilatAdd/List');
      default:
        return ControllerConfig(formId: 1, tableId: 100, formPath: '/Dyn/$controller/Detail', listPath: '/Dyn/$controller/List');
    }
  }

  /// Save with dynamic configuration - FIXED WEB API FORMAT
  Future<Map<String, dynamic>> saveWithDynamicConfig({
    required String controller,
    required Map<String, dynamic> formData,
    int? id,
  }) async {
    final config = getControllerConfig(controller);
    final isUpdate = id != null && id > 0;

    debugPrint('[BASE_API] ${isUpdate ? 'UPDATE' : 'SAVE'} with ${config.isExtracted ? "DYNAMIC" : "STATIC"} config');
    debugPrint('[BASE_API] FormID: ${config.formId}, TableID: ${config.tableId}');
    debugPrint('[BASE_API] Controller: $controller, ID: $id');

    return await _saveDataWebFormat(
      controller: controller,
      formData: formData,
      id: id,
      formId: config.formId,
      tableId: config.tableId,
      formPath: config.formPath,
      isUpdate: isUpdate,
    );
  }

  /// Internal save method - WEB API FORMAT EXACT MATCH
  Future<Map<String, dynamic>> _saveDataWebFormat({
    required String controller,
    required Map<String, dynamic> formData,
    int? id,
    required int formId,
    required int tableId,
    required String formPath,
    required bool isUpdate,
  }) async {
    try {
      debugPrint('[BASE_API] ==========================================');
      debugPrint('[BASE_API] ${isUpdate ? 'UPDATING' : 'CREATING'} RECORD');
      debugPrint('[BASE_API] Controller: $controller');
      debugPrint('[BASE_API] FormID: $formId, TableID: $tableId');
      debugPrint('[BASE_API] RecordID: $id');
      debugPrint('[BASE_API] ==========================================');

      // CLEAN FORM DATA - Remove null/empty values but keep _DDL objects
      final cleanedData = _cleanFormDataWebFormat(formData);

      // BUILD WEB API REQUEST BODY - EXACT FORMAT MATCH
      final requestBody = <String, dynamic>{
        "form_REV": false,
        "form_ID": formId,
        "form_PATH": isUpdate ? "$formPath/$id" : formPath,
        "IsCloneRecord": false,
        "Id": isUpdate ? id : 0,
      };

      // Add all cleaned form data
      requestBody.addAll(cleanedData);

      // Add tableId for BOTH insert and update operations (web format requires it)
      requestBody["tableId"] = tableId;

      debugPrint('[BASE_API] Request body keys: ${requestBody.keys.length}');
      debugPrint('[BASE_API] Main fields: ${cleanedData.keys.where((k) => !k.contains('_')).toList()}');
      debugPrint('[BASE_API] DDL fields: ${cleanedData.keys.where((k) => k.contains('_DDL')).length}');
      debugPrint('[BASE_API] AutoComplete fields: ${cleanedData.keys.where((k) => k.contains('_AutoComplateText')).length}');

      // SELECT ENDPOINT
      final endpoint = isUpdate ? _updateData : _insertData;
      debugPrint('[BASE_API] Endpoint: $endpoint');

      final response = await ApiClient.post(endpoint, body: requestBody);

      debugPrint('[BASE_API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[BASE_API] ${isUpdate ? 'Update' : 'Save'} successful');

        // Extract new ID for insert operations
        final newId = result['Data']?['Id'] as int?;
        if (newId != null && !isUpdate) {
          debugPrint('[BASE_API] New record created with ID: $newId');
        }

        return result;
      } else {
        debugPrint('[BASE_API] HTTP Error: ${response.statusCode}');
        debugPrint('[BASE_API] Response body: ${response.body}');
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[BASE_API] ${isUpdate ? 'Update' : 'Save'} error: $e');
      rethrow;
    }
  }

  /// Clean form data for web API format - PRESERVE _DDL OBJECTS
  Map<String, dynamic> _cleanFormDataWebFormat(Map<String, dynamic> formData) {
    final cleanedData = <String, dynamic>{};

    debugPrint('[BASE_API] Cleaning form data: ${formData.keys.length} fields');

    for (final entry in formData.entries) {
      final key = entry.key;
      final value = entry.value;

      // PRESERVE _DDL and _AutoComplateText fields - they are required by web API
      if (key.endsWith('_DDL') || key.endsWith('_AutoComplateText')) {
        cleanedData[key] = value ?? {};
        debugPrint('[BASE_API] Preserved $key: ${value != null ? 'has_data' : 'empty_object'}');
        continue;
      }

      // Clean main field values
      if (value != null) {
        final stringValue = value.toString().trim();
        if (stringValue.isNotEmpty && stringValue != 'null') {
          // Special handling for Referance field (List to String)
          if (key == 'Referance' && value is List && value.isNotEmpty) {
            cleanedData[key] = value.first.toString();
            debugPrint('[BASE_API] Referance field converted: List → String = ${cleanedData[key]}');
          } else {
            cleanedData[key] = value;
          }
        }
      }
    }

    debugPrint('[BASE_API] Cleaned data: ${cleanedData.keys.length} fields');
    debugPrint('[BASE_API] Main fields: ${cleanedData.keys.where((k) => !k.contains('_')).length}');
    debugPrint('[BASE_API] Helper fields: ${cleanedData.keys.where((k) => k.contains('_')).length}');

    return cleanedData;
  }

  /// Load dropdown options
  Future<List<DropdownOption>> loadDropdownOptions({
    required String sourceType,
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('[BASE_API] Loading dropdown options - Source: $sourceType/$sourceValue');

      if (sourceType == '4') {
        // Group source
        final response = await ApiClient.post(
          '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
          body: {
            "model": {
              "Parameters": [],
              "model": {"Text": "", "Value": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/GenericForm/Detail",
              "type": "DropDownList",
              "controller": "GenericForm",
            },
            "filter": {"logic": "and", "filters": []}
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dataList = data['Data'] as List? ?? [];

          return dataList
              .map((item) => DropdownOption(
                    value: item['Value'],
                    text: item['Text'] as String,
                  ))
              .toList();
        }
      } else if (sourceType == '1') {
        // SQL source
        final response = await ApiClient.post(
          '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
          body: {
            "model": {
              "Parameters": [],
              "model": {"Text": "", "Value": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/GenericForm/Detail",
              "type": "DropDownList",
              "controller": "GenericForm",
            },
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final dataList = data['Data'] as List? ?? [];

          return dataList
              .map((item) => DropdownOption(
                    value: item['Id'] ?? item['Value'],
                    text: item['Text'] as String? ?? item['Name'] as String? ?? '',
                  ))
              .where((item) => item.text.isNotEmpty)
              .toList();
        }
      }

      return [];
    } catch (e) {
      debugPrint('[BASE_API] Load dropdown error: $e');
      return [];
    }
  }

  // Keep existing methods for backward compatibility
  Future<Map<String, dynamic>> getFormWithData({
    required String controller,
    required String url,
    int? id,
    int take = 10,
    int skip = 0,
  }) async {
    final result = await getFormWithDataAndConfig(
      controller: controller,
      url: url,
      id: id,
    );
    return result.formData;
  }

  Future<Map<String, dynamic>> getFormListData({
    required String controller,
    required String params,
    required String formPath,
    int page = 1,
    int pageSize = 50,
  }) async {
    final skip = (page - 1) * pageSize;

    final requestBody = {
      "take": pageSize.toString(),
      "skip": skip,
      "page": page.toString(),
      "pageSize": pageSize.toString(),
      "model": {
        "Parameters": [
          {"Type": 1, "Name": "@UserId", "Value": 5608},
          {"Type": 4, "Name": "@startDate"},
          {"Type": 4, "Name": "@finishDate"},
          {"Type": 1, "Name": "@MenuTitle", "Value": _getMenuTitle(controller)},
        ],
        "controller": controller,
        "form_PATH": "/$formPath",
        "UserLocation": "0,0",
        "IsAachSpaceSplitLikeFilter": false,
      },
    };

    try {
      final response = await ApiClient.post(_getFormListData, body: requestBody);

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        return result;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BASE_API] GetFormListData error: $e');
      rethrow;
    }
  }

  String _getMenuTitle(String controller) {
    switch (controller.toLowerCase()) {
      case 'contactadd':
        return 'Kişileri Listele';
      case 'companyadd':
        return 'Firmaları Listele';
      case 'addexpense':
        return 'Masrafları Listele';
      case 'vehiclerentadd':
        return 'Araç Kiraları Listele';
      case 'aktiviteadd':
      case 'aktivitebranchadd':
        return 'Aktiviteleri Listele';
      case 'degertahsilatadd':
        return 'Tahsilatları Listele';
      default:
        return 'Liste';
    }
  }

  // Special report method for AttachmentListScreen
  Future<Map<String, dynamic>> getSpecialReport({
    required String specialName,
    required Map<String, dynamic> parameters,
    int page = 1,
    int pageSize = 50,
  }) async {
    debugPrint('[BASE_API] Special Report Request:');
    debugPrint('[BASE_API] Special Name: $specialName');
    debugPrint('[BASE_API] Parameters: $parameters');

    final requestBody = {
      "specialName": specialName,
      "parameters": parameters,
      "take": pageSize.toString(),
      "skip": ((page - 1) * pageSize),
      "page": page.toString(),
      "pageSize": pageSize.toString(),
    };

    debugPrint('[BASE_API] Special Report Payload: ${jsonEncode(requestBody)}');

    try {
      final response = await ApiClient.post(
        '/api/ReportApi/GetSpecialReport',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[BASE_API] Special Report Response successful');
        return result;
      } else {
        throw Exception('Special Report failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[BASE_API] Special Report Exception: $e');
      rethrow;
    }
  }
}

// Result class for form with configuration
class FormWithConfigResult {
  final Map<String, dynamic> formData;
  final DynamicControllerConfig config;

  FormWithConfigResult({
    required this.formData,
    required this.config,
  });
}

// Dynamic configuration class
class DynamicControllerConfig {
  final String controller;
  final int formId;
  final int tableId;
  final String formPath;
  final String listPath;
  final bool isExtracted; // True if extracted from response, false if using static

  DynamicControllerConfig({
    required this.controller,
    required this.formId,
    required this.tableId,
    required this.formPath,
    required this.listPath,
    required this.isExtracted,
  });

  @override
  String toString() {
    return 'DynamicControllerConfig(controller: $controller, formId: $formId, tableId: $tableId, extracted: $isExtracted)';
  }
}

// Static configuration class (for fallback)
class ControllerConfig {
  final int formId;
  final int tableId;
  final String formPath;
  final String listPath;

  ControllerConfig({
    required this.formId,
    required this.tableId,
    required this.formPath,
    required this.listPath,
  });
}
