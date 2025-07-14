import 'package:flutter/material.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import 'base_api_service.dart';
import 'api_client.dart';

/// Company API service for handling company-related operations
class CompanyApiService extends BaseApiService {
  /// Load company form structure for add/edit operations
  Future<DynamicFormModel> loadCompanyForm({int? companyId}) async {
    try {
      debugPrint('[COMPANY_API] Loading form for company ID: $companyId');

      final response = await getFormWithData(
        controller: 'CompanyAdd',
        url: '/Dyn/CompanyAdd/Detail',
        id: companyId ?? 0,
      );

      debugPrint('[COMPANY_API] Form response received');

      final formModel = DynamicFormModel.fromJson(response);
      debugPrint('[COMPANY_API] Form parsed: ${formModel.formName}');
      debugPrint('[COMPANY_API] Sections count: ${formModel.sections.length}');

      for (final section in formModel.sections) {
        debugPrint('[COMPANY_API] Section: ${section.label} (${section.fields.length} fields)');
      }

      return formModel;
    } catch (e) {
      debugPrint('[COMPANY_API] Load form error: $e');
      rethrow;
    }
  }

  /// Load company list data
  Future<Map<String, dynamic>> loadCompanyList({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      debugPrint('[COMPANY_API] Loading company list - Page: $page, Size: $pageSize');

      final response = await getFormListData(
        controller: 'CompanyAdd',
        params: 'List',
        formPath: '/Dyn/CompanyAdd/List',
        page: page,
        pageSize: pageSize,
      );

      debugPrint('[COMPANY_API] Company list loaded');
      return response;
    } catch (e) {
      debugPrint('[COMPANY_API] Load list error: $e');
      rethrow;
    }
  }

  /// Save company form data
  Future<Map<String, dynamic>> saveCompany({
    required Map<String, dynamic> formData,
    int? companyId,
  }) async {
    try {
      debugPrint('[COMPANY_API] Saving company - ID: $companyId');
      debugPrint('[COMPANY_API] Form data keys: ${formData.keys.toList()}');

      final response = await saveFormData(
        controller: 'CompanyAdd',
        formData: formData,
        id: companyId,
      );

      debugPrint('[COMPANY_API] Company saved successfully');
      return response;
    } catch (e) {
      debugPrint('[COMPANY_API] Save error: $e');
      rethrow;
    }
  }

  /// Load dropdown options for specific field - WEB API CALLS
  Future<List<DropdownOption>> loadDropdownOptions({
    required String sourceType,
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    Map<String, dynamic>? filters,
    int? companyId, // 🔥 Company ID eklendi
  }) async {
    try {
      debugPrint('[COMPANY_API] Loading dropdown options - Source: $sourceType/$sourceValue, CompanyId: $companyId');

      if (sourceType == '4') {
        // Group source - try multiple approaches for Company

        // 🎯 SPECIAL HANDLING for Referans (1219) - MultiSelectBox
        if (sourceValue == 1219) {
          debugPrint('[COMPANY_API] 🎯 Special Referans handling for sourceValue: 1219');

          final referansEndpoints = [
            // 1. MultiSelectBox payload ile GetCategory
            () async {
              debugPrint('[COMPANY_API] Trying Referans GetCategory with MultiSelectBox payload...');
              return await ApiClient.post(
                '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
                body: {
                  "model": {
                    "Parameters": [],
                    "model": {"Text": "", "Value": ""},
                    "culture": "tr",
                    "form_PATH": "/Dyn/CompanyAdd/Detail",
                    "type": "MultiSelectBox", // 🔥 MultiSelectBox tipi
                    "apiUrl": null,
                    "controller": "CompanyAdd",
                    "revisionNo": null,
                    "dataId": null,
                    "valueName": "MultiSelectBox"
                  },
                  "take": 0,
                  "skip": 0,
                  "page": 1,
                  "pageSize": 0,
                  "filter": {"logic": "and", "filters": []}
                },
              );
            },

            // 2. Basit MultiSelectBox payload
            () async {
              debugPrint('[COMPANY_API] Trying direct MultiSelectBox payload...');
              return await ApiClient.post(
                '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
                body: {
                  "Parameters": [],
                  "model": {"Text": "", "Value": ""},
                  "culture": "tr",
                  "form_PATH": "/Dyn/CompanyAdd/Detail",
                  "type": "MultiSelectBox",
                  "controller": "CompanyAdd",
                  "valueName": "MultiSelectBox"
                },
              );
            },

            // 3. GetReadReport fallback
            () async {
              debugPrint('[COMPANY_API] Trying GetReadReport for Referans...');
              return await ApiClient.post(
                '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
                body: {
                  "model": {
                    "Parameters": [],
                    "model": {"Text": "", "Value": ""},
                    "culture": "tr",
                    "form_PATH": "/Dyn/CompanyAdd/Detail",
                    "type": "MultiSelectBox",
                    "controller": "CompanyAdd",
                  },
                  "take": 0,
                  "skip": 0,
                  "page": 1,
                  "pageSize": 0
                },
              );
            },
          ];

          for (int i = 0; i < referansEndpoints.length; i++) {
            try {
              final response = await referansEndpoints[i]();

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                final dataList = data['Data'] as List? ?? [];

                if (dataList.isNotEmpty) {
                  debugPrint('[COMPANY_API] ✅ Referans endpoint ${i + 1} success: ${dataList.length} items');
                  return dataList
                      .map((item) => DropdownOption(
                            value: item['Value'],
                            text: item['Text'] as String,
                          ))
                      .toList();
                }
              }
              debugPrint('[COMPANY_API] Referans endpoint ${i + 1} status: ${response.statusCode}');
            } catch (e) {
              debugPrint('[COMPANY_API] Referans endpoint ${i + 1} failed: $e');
            }
          }
        }

        // Diğer Group source'lar için standard endpoints
        final endpoints = [
          // 1. Try POST GetCategory with exact web payload
          () async {
            debugPrint('[COMPANY_API] Trying POST GetCategory with web payload...');
            final response = await ApiClient.post(
              '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
              body: {
                "model": {
                  "Parameters": [],
                  "model": {"Text": "", "Value": ""},
                  "culture": "tr",
                  "form_PATH": "/Dyn/CompanyAdd/Detail",
                  "type": "DropDownList",
                  "apiUrl": null,
                  "controller": "CompanyAdd",
                  "revisionNo": null,
                  "dataId": null,
                  "valueName": "DropDownList"
                },
                "take": 0,
                "skip": 0,
                "page": 1,
                "pageSize": 0,
                "filter": {"logic": "and", "filters": []}
              },
            );
            return response;
          },

          // 2. Try alternative payload
          () async {
            debugPrint('[COMPANY_API] Trying alternative DropDownList payload...');
            final response = await ApiClient.post(
              '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
              body: {
                "Parameters": [],
                "model": {"Text": "", "Value": ""},
                "culture": "tr",
                "form_PATH": "/Dyn/CompanyAdd/Detail",
                "type": "DropDownList",
                "controller": "CompanyAdd",
                "valueName": "DropDownList"
              },
            );
            return response;
          },

          // 3. Try POST GetReadReport as fallback
          () async {
            debugPrint('[COMPANY_API] Trying POST GetReadReport fallback...');
            final response = await ApiClient.post(
              '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
              body: {
                "model": {
                  "Parameters": [],
                  "model": {"Text": "", "Value": ""},
                  "culture": "tr",
                  "form_PATH": "/Dyn/CompanyAdd/Detail",
                  "type": "DropDownList",
                  "apiUrl": null,
                  "controller": "CompanyAdd",
                  "revisionNo": null,
                  "dataId": null,
                  "valueName": "DropDownList"
                },
                "take": 0,
                "skip": 0,
                "page": 1,
                "pageSize": 0,
                "filter": {"logic": "and", "filters": []}
              },
            );
            return response;
          },
        ];

        for (int i = 0; i < endpoints.length; i++) {
          try {
            final response = await endpoints[i]();

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final dataList = data['Data'] as List? ?? [];

              if (dataList.isNotEmpty) {
                debugPrint('[COMPANY_API] ✅ Endpoint ${i + 1} success: ${dataList.length} items for $sourceValue');
                return dataList
                    .map((item) => DropdownOption(
                          value: item['Value'],
                          text: item['Text'] as String,
                        ))
                    .toList();
              }
            }
            debugPrint('[COMPANY_API] Endpoint ${i + 1} status: ${response.statusCode} for $sourceValue');
          } catch (e) {
            debugPrint('[COMPANY_API] Endpoint ${i + 1} failed for $sourceValue: $e');
          }
        }
      } else if (sourceType == '1') {
        // SQL source - use POST GetReadReport

        // 🎯 SPECIAL HANDLING for Users (sourceValue: 22) - Temsilci
        if (sourceValue == 22) {
          debugPrint('[COMPANY_API] 🎯 Special Users handling for sourceValue: 22 (Temsilci)');

          // Web'deki exact payload'ı kullan
          final requestBody = {
            "model": {
              "Parameters": [],
              "model": {"Adi": "", "UserId": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/CompanyAdd/Detail", // 🔥 CompanyId olmadan
              "type": "DropDownList",
              "apiUrl": null,
              "controller": "CompanyAdd",
              "revisionNo": null,
              "dataId": null, // 🔥 null olarak gönder
              "valueName": "DropDownList"
            },
            "take": 50, // 🔥 Web'deki gibi
            "skip": 0,
            "page": 1,
            "pageSize": 50, // 🔥 Web'deki gibi
            "filter": {"logic": "and", "filters": []}
          };

          try {
            debugPrint('[COMPANY_API] Trying Users GetReadReport with exact web payload...');
            final response = await ApiClient.post(
              '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
              body: requestBody,
            );

            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final dataList = data['Data'] as List? ?? [];

              debugPrint('[COMPANY_API] ✅ Users GetReadReport success: ${dataList.length} items');
              return dataList
                  .map((item) => DropdownOption(
                        value: item['UserId'] ?? item['Id'],
                        text: item['Adi'] as String? ?? 'İsimsiz Kullanıcı',
                      ))
                  .where((item) => item.text.isNotEmpty && item.text != 'İsimsiz Kullanıcı')
                  .toList();
            }
          } catch (e) {
            debugPrint('[COMPANY_API] Users GetReadReport failed: $e');
          }
        }

        // Diğer SQL source'lar için standard handling
        try {
          debugPrint('[COMPANY_API] Trying POST GetReadReport for SQL: $sourceValue');

          final requestBody = {
            "model": {
              "Parameters": [],
              "model": sourceValue == 22
                  ? {"Adi": "", "UserId": ""} // User dropdown
                  : {"Text": "", "Value": ""}, // Standard dropdown
              "culture": "tr",
              "form_PATH": "/Dyn/CompanyAdd/Detail",
              "type": "DropDownList",
              "apiUrl": null,
              "controller": "CompanyAdd",
              "revisionNo": null,
              "dataId": null,
              "valueName": "DropDownList"
            },
            "take": sourceValue == 22 ? 50 : 0, // Users have pagination
            "skip": 0,
            "page": 1,
            "pageSize": sourceValue == 22 ? 50 : 0,
            "filter": {"logic": "and", "filters": []}
          };

          final response = await ApiClient.post(
            '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
            body: requestBody,
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dataList = data['Data'] as List? ?? [];

            debugPrint('[COMPANY_API] ✅ POST GetReadReport success: ${dataList.length} items');
            return dataList
                .map((item) {
                  final value = item[dataValueField ?? 'Id'] ?? item['Value'] ?? item['UserId'] ?? item['Id'];
                  final text = item[dataTextField ?? 'Text'] as String? ??
                      item['Text'] as String? ??
                      item['Name'] as String? ??
                      item['Adi'] as String? ??
                      value?.toString() ??
                      '';

                  return DropdownOption(value: value, text: text);
                })
                .where((item) => item.text.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('[COMPANY_API] POST GetReadReport failed: $e');
        }
      }

      debugPrint('[COMPANY_API] ⚠️ All endpoints failed for $sourceType/$sourceValue');
      return [];
    } catch (e) {
      debugPrint('[COMPANY_API] Load dropdown error: $e');
      return [];
    }
  }

  /// Load users for representative dropdown
  Future<List<DropdownOption>> loadUsers() async {
    return await loadDropdownOptions(
      sourceType: '1',
      sourceValue: 22,
      dataTextField: 'Adi',
      dataValueField: 'UserId',
    );
  }

  /// Parse company list data for display
  List<CompanyListItem> parseCompanyList(Map<String, dynamic> response) {
    try {
      final dataResult = response['DataSourceResult'] as Map<String, dynamic>? ?? {};
      final dataList = dataResult['Data'] as List? ?? [];

      return dataList.whereType<Map<String, dynamic>>().map((item) => CompanyListItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('[COMPANY_API] Parse list error: $e');
      return [];
    }
  }

  /// Get total count from list response
  int getTotalCount(Map<String, dynamic> response) {
    try {
      final dataResult = response['DataSourceResult'] as Map<String, dynamic>? ?? {};
      return dataResult['Total'] as int? ?? 0;
    } catch (e) {
      debugPrint('[COMPANY_API] Get total count error: $e');
      return 0;
    }
  }
}

/// Company list item model
class CompanyListItem {
  final int id;
  final String name;
  final String phone;
  final String webAddress;
  final String email;
  final DateTime? registrationDate;
  final String sector;
  final String representative;

  CompanyListItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.webAddress,
    required this.email,
    this.registrationDate,
    required this.sector,
    required this.representative,
  });

  factory CompanyListItem.fromJson(Map<String, dynamic> json) {
    return CompanyListItem(
      id: json['Id'] as int? ?? 0,
      name: json['Firma'] as String? ?? '',
      phone: json['Telefon'] as String? ?? '-',
      webAddress: json['WebAdres'] as String? ?? '-',
      email: json['Mail'] as String? ?? '-',
      registrationDate: _parseDate(json['KayitTarihi']),
      sector: json['Sektor'] as String? ?? '-',
      representative: json['Temsilci'] as String? ?? '',
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
    } catch (e) {
      debugPrint('[CompanyListItem] Date parse error: $e');
    }
    return null;
  }

  String get formattedRegistrationDate {
    if (registrationDate == null) return '-';
    return '${registrationDate!.day.toString().padLeft(2, '0')}.${registrationDate!.month.toString().padLeft(2, '0')}.${registrationDate!.year}';
  }
}
