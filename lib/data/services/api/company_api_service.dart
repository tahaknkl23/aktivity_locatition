// company_api_service.dart - TAM HALİ (UPDATE & DELETE FIX)

import 'package:flutter/material.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../models/company/company_list_model.dart';
import '../../../data/models/activity/activity_list_model.dart'; // CompanyAddress için
import 'base_api_service.dart';
import 'api_client.dart';

/// Company API service for handling company-related operations
class CompanyApiService extends BaseApiService {
  get math => null;

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

  /// 🔧 FIXED: Save/Update company - WEB API UYUMLU
  Future<Map<String, dynamic>> saveCompany({
    required Map<String, dynamic> formData,
    int? companyId,
  }) async {
    try {
      final isUpdate = companyId != null && companyId > 0;
      debugPrint('[COMPANY_API] ${isUpdate ? 'Updating' : 'Creating'} company - ID: $companyId');
      debugPrint('[COMPANY_API] Form data keys: ${formData.keys.toList()}');

      // 🎯 FORM DATA TEMİZLİĞİ - WEB FORMAT
      final cleanedData = <String, dynamic>{};

      for (final entry in formData.entries) {
        final key = entry.key;
        final value = entry.value;

        // Null/empty kontrolü
        if (value != null && value.toString().trim().isNotEmpty) {
          // 🔧 ÖZEL CASE: Referans MultiSelectBox - Array'den String'e
          if (key == 'Referance' && value is List && value.isNotEmpty) {
            cleanedData[key] = value.first.toString();
            debugPrint('[COMPANY_API] 🔧 Referans converted: List → String = ${cleanedData[key]}');
          }
          // 🔧 ÖZEL CASE: Dropdown helper fields'ları temizle
          else if (key.endsWith('_DDL') || key.endsWith('_AutoComplateText')) {
            // Bu field'ları ekleme - web'de gerekmez
            debugPrint('[COMPANY_API] 🧹 Skipping UI helper field: $key');
            continue;
          } else {
            cleanedData[key] = value;
          }
        }
      }

      // 🎯 WEB API REQUEST BODY
      final requestBody = {
        // Form metadata
        "form_REV": false,
        "form_ID": 3,
        "form_PATH": isUpdate ? "/Dyn/CompanyAdd/Detail/$companyId" : "/Dyn/CompanyAdd/Detail",
        "IsCloneRecord": false,
        "tableId": 104,

        // Form data
        ...cleanedData,

        // ID handling
        "Id": companyId ?? 0,
      };

      debugPrint('[COMPANY_API] 🔍 Request body: $requestBody');

      // 🎯 API ENDPOINT SELECTION
      final endpoint = isUpdate ? '/api/admin/DynamicFormApi/UpdateData' : '/api/admin/DynamicFormApi/InsertData';

      final response = await ApiClient.post(endpoint, body: requestBody);

      debugPrint('[COMPANY_API] 🔍 Response status: ${response.statusCode}');
      debugPrint('[COMPANY_API] 🔍 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          // Response structure kontrolü
          if (data.containsKey('Data') && data['Data'] != null) {
            final responseData = data['Data'] as Map<String, dynamic>;
            final returnedId = responseData['Id'];
            debugPrint('[COMPANY_API] ✅ Company ${isUpdate ? 'updated' : 'saved'} successfully with ID: $returnedId');
            return data;
          }

          // Direkt data response
          if (data.containsKey('Id')) {
            debugPrint('[COMPANY_API] ✅ Company ${isUpdate ? 'updated' : 'saved'} successfully with ID: ${data['Id']}');
            return data;
          }
        }

        throw Exception('Invalid response format: ${data.toString()}');
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[COMPANY_API] ❌ ${companyId != null ? 'Update' : 'Save'} error: $e');

      // User-friendly error messages
      String userMessage = companyId != null ? 'Firma güncellenirken hata oluştu' : 'Firma kaydedilirken hata oluştu';

      if (e.toString().contains('401')) {
        userMessage = 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
      } else if (e.toString().contains('403')) {
        userMessage = 'Bu işlem için yetkiniz bulunmamaktadır.';
      } else if (e.toString().contains('404')) {
        userMessage = companyId != null ? 'Güncellenecek firma bulunamadı.' : 'API endpoint bulunamadı.';
      } else if (e.toString().contains('500')) {
        userMessage = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      } else if (e.toString().contains('network') || e.toString().contains('connection')) {
        userMessage = 'İnternet bağlantınızı kontrol edin.';
      }

      throw Exception(userMessage);
    }
  }

  /// 🆕 DELETE company - WEB API UYUMLU
  Future<Map<String, dynamic>> deleteCompany({
    required int companyId,
  }) async {
    try {
      debugPrint('[COMPANY_API] Deleting company - ID: $companyId');

      // 🎯 WEB API DELETE REQUEST BODY - EXACT MATCH
      final requestBody = {
        "tableId": 104,
        "Id": companyId,
        "form_ID": 3,
        "form_PATH": "/Dyn/CompanyAdd/Detail/$companyId",
      };

      debugPrint('[COMPANY_API] 🔍 Delete request body: $requestBody');

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/DeleteData',
        body: requestBody,
      );

      debugPrint('[COMPANY_API] 🔍 Delete response status: ${response.statusCode}');
      debugPrint('[COMPANY_API] 🔍 Delete response body: ${response.body}');

      if (response.statusCode == 200) {
        // Web'de delete genelde empty response döner veya basit JSON
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : {'success': true, 'message': 'Firma başarıyla silindi'};

        debugPrint('[COMPANY_API] ✅ Company deleted successfully');
        return data;
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[COMPANY_API] ❌ Delete error: $e');

      String userMessage = 'Firma silinirken hata oluştu';

      if (e.toString().contains('401')) {
        userMessage = 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
      } else if (e.toString().contains('403')) {
        userMessage = 'Bu işlem için yetkiniz bulunmamaktadır.';
      } else if (e.toString().contains('404')) {
        userMessage = 'Silinecek firma bulunamadı.';
      } else if (e.toString().contains('409')) {
        userMessage = 'Bu firma bağlı kayıtlar olduğu için silinemez.';
      } else if (e.toString().contains('500')) {
        userMessage = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
      }

      throw Exception(userMessage);
    }
  }

  /// 🆕 YENİ: Location data'yı forma dahil etme metodu
  Map<String, dynamic> _prepareFormDataWithLocation(
    Map<String, dynamic> formData,
    String? locationCoordinates,
    String? locationAddress,
  ) {
    final preparedData = Map<String, dynamic>.from(formData);

    // Konum verilerini ekle
    if (locationCoordinates != null && locationCoordinates.isNotEmpty) {
      preparedData['Location'] = locationCoordinates;
      debugPrint('[COMPANY_API] 📍 Added location: $locationCoordinates');
    }

    if (locationAddress != null && locationAddress.isNotEmpty) {
      preparedData['MapAdress'] = locationAddress;
      debugPrint('[COMPANY_API] 📍 Added address: $locationAddress');
    }

    // Dropdown values için _DDL suffix'li alanları temizle (web'de gerekmez)
    final keysToRemove = <String>[];
    for (final key in preparedData.keys) {
      if (key.endsWith('_DDL') || key.endsWith('_AutoComplateText')) {
        keysToRemove.add(key);
      }
    }

    for (final key in keysToRemove) {
      preparedData.remove(key);
      debugPrint('[COMPANY_API] 🧹 Removed UI helper field: $key');
    }

    return preparedData;
  }

  /// 🆕 YENİ: Konum ile birlikte kaydetme metodu
  Future<Map<String, dynamic>> saveCompanyWithLocation({
    required Map<String, dynamic> formData,
    int? companyId,
    String? locationCoordinates,
    String? locationAddress,
  }) async {
    final preparedData = _prepareFormDataWithLocation(
      formData,
      locationCoordinates,
      locationAddress,
    );

    return await saveCompany(
      formData: preparedData,
      companyId: companyId,
    );
  }

  /// 🆕 YENİ: Firma adreslerini getir
  Future<CompanyAddressResponse> getCompanyAddresses({
    required int companyId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      debugPrint('[COMPANY_API] Loading addresses for company ID: $companyId');

      final requestBody = {
        "model": {
          "Parameters": [
            {"Name": "@Id", "Type": 2, "Value": companyId},
            {"Name": "@FormId", "Type": 2, "Value": 3}
          ],
          "LayoutData": {"element": "MultiDataTabSection_grid_146", "url": "/Dyn/CompanyAdd/Detail"},
          "model": {"columns": []},
          "form_PATH": "Dyn/CompanyAddressAdd/Detail",
          "type": "MultiDataGrid",
          "apiUrl": null
        },
        "take": pageSize,
        "skip": (page - 1) * pageSize,
        "page": page,
        "pageSize": pageSize
      };

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReportDataAndType/146',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[COMPANY_API] Company addresses loaded successfully');
        return CompanyAddressResponse.fromJson(data);
      } else {
        throw Exception('Failed to load company addresses: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[COMPANY_API] Get company addresses error: $e');
      throw Exception('Firma adresleri yüklenemedi: ${e.toString()}');
    }
  }

  /// 🆕 YENİ: Aktivite için firma adreslerini getir (select için)
  Future<List<DropdownOption>> getCompanyAddressesForDropdown({
    required int companyId,
  }) async {
    try {
      debugPrint('[COMPANY_API] Loading address options for company: $companyId');

      final addressResponse = await getCompanyAddresses(
        companyId: companyId,
        pageSize: 50, // Maksimum 50 adres
      );

      // Adresleri dropdown option'a çevir
      final options = addressResponse.data.map((address) {
        return DropdownOption(
          value: address.id,
          text: address.displayAddress,
        );
      }).toList();

      debugPrint('[COMPANY_API] Loaded ${options.length} address options');
      return options;
    } catch (e) {
      debugPrint('[COMPANY_API] Load address options error: $e');
      return [];
    }
  }

  /// 🆕 YENİ: Belirli bir adresi getir
  Future<CompanyAddress?> getCompanyAddressById({
    required int companyId,
    required int addressId,
  }) async {
    try {
      debugPrint('[COMPANY_API] Getting specific address: $addressId for company: $companyId');

      final addressResponse = await getCompanyAddresses(companyId: companyId);

      // Listede ara
      for (final address in addressResponse.data) {
        if (address.id == addressId) {
          debugPrint('[COMPANY_API] Found address: ${address.displayAddress}');
          return address;
        }
      }

      debugPrint('[COMPANY_API] Address not found: $addressId');
      return null;
    } catch (e) {
      debugPrint('[COMPANY_API] Get address by ID error: $e');
      return null;
    }
  }

  /// Load dropdown options for specific field - WEB API CALLS
  Future<List<DropdownOption>> loadDropdownOptions({
    required String sourceType,
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    Map<String, dynamic>? filters,
    int? companyId,
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
                    "type": "MultiSelectBox",
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

          final requestBody = {
            "model": {
              "Parameters": [],
              "model": {"Adi": "", "UserId": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/CompanyAdd/Detail",
              "type": "DropDownList",
              "apiUrl": null,
              "controller": "CompanyAdd",
              "revisionNo": null,
              "dataId": null,
              "valueName": "DropDownList"
            },
            "take": 50,
            "skip": 0,
            "page": 1,
            "pageSize": 50,
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
              "model": sourceValue == 22 ? {"Adi": "", "UserId": ""} : {"Text": "", "Value": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/CompanyAdd/Detail",
              "type": "DropDownList",
              "apiUrl": null,
              "controller": "CompanyAdd",
              "revisionNo": null,
              "dataId": null,
              "valueName": "DropDownList"
            },
            "take": sourceValue == 22 ? 50 : 0,
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

  Future<CompanyListResponse> getCompanyList({
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      debugPrint('[COMPANY_API] 🎯 Getting company list - Page: $page, Size: $pageSize, Search: $searchQuery');

      // ⬅️ TÜM VERİLER İÇİN PARAMETRELERİ DÜZELT
      Map<String, dynamic> requestBody;

      if (pageSize >= 999999) {
        // TÜM VERİLER GELSİN
        requestBody = {
          "controller": "CompanyAdd",
          "form_PATH": "/Dyn/CompanyAdd/List",
          "UserLocation": "0,0",
          "LayoutData": {"element": "ListGrid", "url": "/Dyn/CompanyAdd/List"},
          "take": "", // ⬅️ BOŞ STRING
          "skip": 0, // ⬅️ 0
          "page": "", // ⬅️ BOŞ STRING
          "pageSize": "", // ⬅️ BOŞ STRING
        };
        debugPrint('[COMPANY_API] 📋 Request for ALL DATA - take: "", page: "", pageSize: ""');
      } else {
        // NORMAL PAGINATION
        requestBody = {
          "controller": "CompanyAdd",
          "form_PATH": "/Dyn/CompanyAdd/List",
          "UserLocation": "0,0",
          "LayoutData": {"element": "ListGrid", "url": "/Dyn/CompanyAdd/List"},
          "take": pageSize.toString(),
          "skip": (page - 1) * pageSize,
          "page": page.toString(),
          "pageSize": pageSize.toString(),
        };
        debugPrint('[COMPANY_API] 📋 Request for PAGINATION - take: $pageSize, page: $page');
      }

      // Add search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody["searchQuery"] = searchQuery;
      }

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormListDataType',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[COMPANY_API] ✅ Response received');
        return CompanyListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load company list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[COMPANY_API] ❌ Get company list error: $e');
      throw Exception('Firma listesi yüklenemedi: ${e.toString()}');
    }
  }

  /// 🆕 YENİ: Firma adına göre company'yi bulup adreslerini getir
  Future<List<CompanyAddress>> getCompanyAddressesByName(String companyName) async {
    try {
      debugPrint('[COMPANY_API] 🔍 Searching company by name: $companyName');

      // 🆕 YENİ: Multi-page search - tüm firmaları çek
      List<CompanyListItem> allCompanies = [];
      int page = 1;
      bool hasMore = true;

      while (hasMore && page <= 10) {
        // Max 10 sayfa kontrol et
        debugPrint('[COMPANY_API] 🔍 Loading page $page...');

        final companyList = await getCompanyList(
          page: page,
          pageSize: 50, // Her sayfadan 50 firma
        );

        debugPrint('[COMPANY_API] 🔍 Page $page: ${companyList.data.length} companies');

        allCompanies.addAll(companyList.data);

        // Eğer sayfa boyutundan az gelirse, son sayfa
        hasMore = companyList.data.length >= 50;
        page++;

        // Erken çıkış: Aradığımız firmayı bulduk mu?
        final found = allCompanies.any((company) => company.firma.toLowerCase().trim() == companyName.toLowerCase().trim());
        if (found) {
          debugPrint('[COMPANY_API] 🎯 Early exit - found target company on page ${page - 1}');
          break;
        }
      }

      debugPrint('[COMPANY_API] 🔍 Total companies loaded: ${allCompanies.length}');

      // 2. Exact match ara
      CompanyListItem? matchedCompany;
      for (final company in allCompanies) {
        if (company.firma.toLowerCase().trim() == companyName.toLowerCase().trim()) {
          matchedCompany = company;
          debugPrint('[COMPANY_API] ✅ EXACT MATCH FOUND: "${company.firma}"');
          break;
        }
      }

      // 3. Partial match ara
      if (matchedCompany == null) {
        debugPrint('[COMPANY_API] 🔍 No exact match, trying partial match...');
        for (final company in allCompanies) {
          if (company.firma.toLowerCase().contains(companyName.toLowerCase()) || companyName.toLowerCase().contains(company.firma.toLowerCase())) {
            debugPrint('[COMPANY_API] 🔍 Partial match found: "${company.firma}"');
            matchedCompany = company;
            break;
          }
        }
      }

      if (matchedCompany == null) {
        debugPrint('[COMPANY_API] ❌ Company not found: $companyName');
        debugPrint('[COMPANY_API] 🔍 Total available companies: ${allCompanies.length}');
        debugPrint('[COMPANY_API] 🔍 Sample companies: ${allCompanies.take(5).map((c) => c.firma).toList()}');
        return [];
      }

      debugPrint('[COMPANY_API] ✅ Found company: ${matchedCompany.firma} (ID: ${matchedCompany.id})');

      // 4. Company'nin adreslerini çek
      final addressResponse = await getCompanyAddresses(
        companyId: matchedCompany.id,
        pageSize: 10,
      );

      debugPrint('[COMPANY_API] 🔍 Found ${addressResponse.data.length} addresses');
      return addressResponse.data;
    } catch (e) {
      debugPrint('[COMPANY_API] ❌ Error searching company by name: $e');
      return [];
    }
  }

  /// 🧪 TEST: Mevcut firmalardan birini test et
  Future<void> testExistingCompany() async {
    try {
      debugPrint('[COMPANY_API] 🧪 TEST: Testing with existing company...');

      // Mevcut firmalardan MİGROS'u test edelim
      final addresses = await getCompanyAddressesByName("MİGROS A.Ş.");

      debugPrint('[COMPANY_API] 🧪 TEST RESULT: Found ${addresses.length} addresses for MİGROS A.Ş.');
      for (final addr in addresses) {
        debugPrint('[COMPANY_API] 🧪 Address: ${addr.displayAddress}');
      }
    } catch (e) {
      debugPrint('[COMPANY_API] 🧪 TEST ERROR: $e');
    }
  }
}
