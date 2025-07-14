import 'dart:convert';
import 'package:flutter/material.dart';
import 'api_client.dart';

class BaseApiService {
  // Form API endpoints
  static const String _getFormWithData = '/api/admin/DynamicFormApi/GetFormWithData';
  static const String _getFormListDataType = '/api/admin/DynamicFormApi/GetFormListDataType';
  static const String _saveForm = '/api/admin/DynamicFormApi/SaveForm';

  // Get form definition with data (for add/edit screens)
  Future<Map<String, dynamic>> getFormWithData({
    required String controller,
    required String url,
    int? id,
    int take = 10,
    int skip = 0,
  }) async {
    // URL temizleme
    String cleanUrl = url;
    if (!cleanUrl.startsWith('/')) {
      cleanUrl = '/$cleanUrl';
    }

    final requestBody = {
      "model": {"controller": controller, "id": id ?? 0, "url": cleanUrl, "formParams": {}, "form_PATH": cleanUrl, "culture": "tr"},
      "take": take,
      "skip": skip,
      "page": 1,
      "pageSize": take
    };

    debugPrint('[API] GetFormWithData Request:');
    debugPrint('[API] - Controller: $controller');
    debugPrint('[API] - URL: $cleanUrl');
    debugPrint('[API] - ID: $id');

    try {
      final response = await ApiClient.post(
        _getFormWithData,
        body: requestBody,
      );

      debugPrint('[API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[API] Parsed response keys: ${result.keys.toList()}');
        return result;
      } else {
        debugPrint('[API] Error response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load form data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[API] Exception in getFormWithData: $e');
      rethrow;
    }
  }

  // Standard paginated list data loading
  Future<Map<String, dynamic>> getFormListData({
    required String controller,
    required String params,
    required String formPath,
    int page = 1,
    int pageSize = 50,
  }) async {
    final skip = (page - 1) * pageSize;

    final requestBody = {
      "controller": controller,
      "params": params,
      "form_PATH": formPath,
      "UserLocation": "0,0",
      "LayoutData": {"element": "ListGrid", "url": formPath},
      // Pagination parameters
      "page": page,
      "pageSize": pageSize,
      "skip": skip,
      "take": pageSize,
    };

    debugPrint('[API] GetFormListData - Controller: $controller, Params: $params, Page: $page, PageSize: $pageSize');

    final response = await ApiClient.post(
      _getFormListDataType,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final result = jsonDecode(response.body);
      debugPrint('[API] Response received - Data count: ${_extractDataCount(result)}');
      return result;
    } else {
      throw Exception('Failed to load list data: ${response.statusCode}');
    }
  }

  // Extract data count from response
  int _extractDataCount(Map<String, dynamic> response) {
    return _extractDataArray(response).length;
  }

  // Extract data array from response
  List<dynamic> _extractDataArray(Map<String, dynamic> response) {
    if (response['DataSourceResult'] != null && response['DataSourceResult']['Data'] != null) {
      return response['DataSourceResult']['Data'] as List? ?? [];
    } else if (response['Data'] != null) {
      final data = response['Data'];
      if (data is List) {
        return data;
      }
    }
    return [];
  }

  // Save form data
  Future<Map<String, dynamic>> saveFormData({
    required String controller,
    required Map<String, dynamic> formData,
    int? id,
  }) async {
    final requestBody = {
      "controller": controller,
      "id": id,
      "data": formData,
    };

    debugPrint('[API] SaveForm - Controller: $controller, ID: $id');

    final response = await ApiClient.post(
      _saveForm,
      body: requestBody,
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save form: ${response.statusCode}');
    }
  }
}
