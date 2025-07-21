import 'package:aktivity_location_app/core/services/location_service.dart';
import 'package:aktivity_location_app/data/services/api/company_api_service.dart';
import 'package:flutter/material.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../models/activity/activity_list_model.dart';
import 'base_api_service.dart';
import 'api_client.dart';

/// Activity API service for handling activity-related operations
class ActivityApiService extends BaseApiService {
  /// Load activity form structure for add/edit operations
  Future<DynamicFormModel> loadActivityForm({int? activityId}) async {
    try {
      debugPrint('[ACTIVITY_API] Loading form for activity ID: $activityId');

      final response = await getFormWithData(
        controller: 'AktiviteAdd',
        url: '/Dyn/AktiviteAdd/Detail',
        id: activityId ?? 0,
      );

      debugPrint('[ACTIVITY_API] Form response received');

      final formModel = DynamicFormModel.fromJson(response);
      debugPrint('[ACTIVITY_API] Form parsed: ${formModel.formName}');
      debugPrint('[ACTIVITY_API] Sections count: ${formModel.sections.length}');

      for (final section in formModel.sections) {
        debugPrint('[ACTIVITY_API] Section: ${section.label} (${section.fields.length} fields)');
      }

      return formModel;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load form error: $e');
      rethrow;
    }
  }

  /// Load activity list data - Açık aktiviteler
  Future<Map<String, dynamic>> loadOpenActivities({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Loading open activities - Page: $page, Size: $pageSize');

      final response = await getFormListData(
        controller: 'AktiviteAdd',
        params: 'AcikAktiviteler',
        formPath: '/Dyn/AktiviteAdd/List/AcikAktiviteler',
        page: page,
        pageSize: pageSize,
      );

      debugPrint('[ACTIVITY_API] Open activities loaded');
      return response;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load open activities error: $e');
      rethrow;
    }
  }

  /// Load all activities list
  Future<Map<String, dynamic>> loadAllActivities({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Loading all activities - Page: $page, Size: $pageSize');

      final response = await getFormListData(
        controller: 'AktiviteAdd',
        params: 'List',
        formPath: '/Dyn/AktiviteAdd/List',
        page: page,
        pageSize: pageSize,
      );

      debugPrint('[ACTIVITY_API] All activities loaded');
      return response;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load all activities error: $e');
      rethrow;
    }
  }

  /// Save activity form data - DÜZELTİLDİ!
  Future<Map<String, dynamic>> saveActivity({
    required Map<String, dynamic> formData,
    int? activityId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Saving activity - ID: $activityId');
      debugPrint('[ACTIVITY_API] Form data keys: ${formData.keys.toList()}');

      // Web'de kullanılan endpoint'i kullan
      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/InsertData',
        body: formData,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[ACTIVITY_API] Activity saved successfully');
        return result;
      } else {
        throw Exception('Save failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] Save error: $e');
      rethrow;
    }
  }

  /// Universal dropdown loader - tries different endpoints based on sourceType and sourceValue
  Future<List<DropdownOption>> loadDropdownOptions({
    required String sourceType,
    required dynamic sourceValue,
    String? dataTextField,
    String? dataValueField,
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Loading dropdown options - Source: $sourceType/$sourceValue');

      if (sourceType == '4') {
        // Group source - try multiple API endpoints with specific handling

        // 🎯 SPECIAL HANDLING for Priority (sourceValue: 63)
        if (sourceValue == 63) {
          debugPrint('[ACTIVITY_API] 🎯 Special Priority handling for sourceValue: 63');

          final priorityBodies = [
            {
              "filter": {"logic": "and", "filters": []},
              "filters": [],
              "logic": "and",
              "model": {
                "Parameters": [],
                "model": {"Text": "", "Value": ""},
                "culture": "tr",
                "form_PATH": "/Dyn/AktiviteAdd/Detail",
                "apiUrl": null,
                "controller": "AktiviteAdd",
                "revisionNo": null,
                "dataId": null,
                "type": "DropDownList",
                "valueName": "DropDownList"
              }
            },
            {
              "Parameters": [],
              "model": {"Text": "", "Value": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/AktiviteAdd/Detail",
              "type": "DropDownList",
              "controller": "AktiviteAdd",
              "valueName": "DropDownList"
            },
            {"groupId": 63, "culture": "tr"}
          ];

          for (int i = 0; i < priorityBodies.length; i++) {
            try {
              debugPrint('[ACTIVITY_API] Trying Priority POST GetCategory attempt ${i + 1}...');
              final response = await ApiClient.post(
                '/api/admin/DynamicFormApi/GetCategory/63',
                body: priorityBodies[i],
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                final dataList = data['Data'] as List? ?? [];

                if (dataList.isNotEmpty) {
                  debugPrint('[ACTIVITY_API] ✅ Priority POST GetCategory success attempt ${i + 1}: ${dataList.length} items');
                  return dataList
                      .map((item) => DropdownOption(
                            value: item['Value'],
                            text: item['Text'] as String,
                          ))
                      .toList();
                }
              }
              debugPrint('[ACTIVITY_API] Priority attempt ${i + 1} status: ${response.statusCode}');
            } catch (e) {
              debugPrint('[ACTIVITY_API] Priority attempt ${i + 1} failed: $e');
            }
          }
        }

        // 🎯 SPECIAL HANDLING for Activity Type (sourceValue: 10176)
        if (sourceValue == 10176) {
          debugPrint('[ACTIVITY_API] 🎯 Special Activity Type handling for sourceValue: 10176');

          final activityBodies = [
            {
              "filter": {"logic": "and", "filters": []},
              "filters": [],
              "logic": "and",
              "model": {
                "Parameters": [],
                "model": {"Text": "", "Value": ""},
                "culture": "tr",
                "form_PATH": "/Dyn/AktiviteAdd/Detail",
                "apiUrl": null,
                "controller": "AktiviteAdd",
                "revisionNo": null,
                "dataId": null,
                "type": "DropDownList",
                "valueName": "DropDownList"
              }
            },
            {
              "Parameters": [],
              "model": {"Text": "", "Value": ""},
              "culture": "tr",
              "form_PATH": "/Dyn/AktiviteAdd/Detail",
              "type": "DropDownList",
              "controller": "AktiviteAdd",
              "valueName": "DropDownList"
            },
            {"groupId": 10176, "culture": "tr"}
          ];

          for (int i = 0; i < activityBodies.length; i++) {
            try {
              debugPrint('[ACTIVITY_API] Trying ActivityType POST GetCategory attempt ${i + 1}...');
              final response = await ApiClient.post(
                '/api/admin/DynamicFormApi/GetCategory/10176',
                body: activityBodies[i],
              );

              if (response.statusCode == 200) {
                final data = jsonDecode(response.body);
                final dataList = data['Data'] as List? ?? [];

                if (dataList.isNotEmpty) {
                  debugPrint('[ACTIVITY_API] ✅ ActivityType POST GetCategory success attempt ${i + 1}: ${dataList.length} items');
                  return dataList
                      .map((item) => DropdownOption(
                            value: item['Value'],
                            text: item['Text'] as String,
                          ))
                      .toList();
                }
              }
              debugPrint('[ACTIVITY_API] ActivityType attempt ${i + 1} status: ${response.statusCode}');
            } catch (e) {
              debugPrint('[ACTIVITY_API] ActivityType attempt ${i + 1} failed: $e');
            }
          }
        }

        // 1. Try GetCategory endpoint first (GET method)
        try {
          debugPrint('[ACTIVITY_API] Trying GetCategory endpoint...');
          final response = await ApiClient.get(
            '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dataList = data['Data'] as List? ?? [];

            debugPrint('[ACTIVITY_API] ✅ GetCategory success: ${dataList.length} items');
            return dataList
                .map((item) => DropdownOption(
                      value: item['Value'],
                      text: item['Text'] as String,
                    ))
                .toList();
          }
        } catch (e) {
          debugPrint('[ACTIVITY_API] GetCategory failed: $e');
        }

        // 2. Try GetGroupItems endpoint (POST method)
        try {
          debugPrint('[ACTIVITY_API] Trying GetGroupItems endpoint...');
          final response = await ApiClient.post(
            '/api/admin/DynamicFormApi/GetGroupItems',
            body: {
              "groupId": sourceValue,
              "model": {"Text": "", "Value": "", "ParentId": sourceValue.toString()},
              "logic": "and",
              "filters": []
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dataList = data['Data'] as List? ?? [];

            debugPrint('[ACTIVITY_API] ✅ GetGroupItems success: ${dataList.length} items');
            return dataList
                .map((item) => DropdownOption(
                      value: item['Value'],
                      text: item['Text'] as String,
                    ))
                .toList();
          }
        } catch (e) {
          debugPrint('[ACTIVITY_API] GetGroupItems failed: $e');
        }

        // 3. Try GetReadReport endpoint (fallback)
        try {
          debugPrint('[ACTIVITY_API] Trying GetReadReport endpoint...');
          final response = await ApiClient.post(
            '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
            body: {
              "model": {
                "Parameters": [],
                "model": {"Text": "", "Value": ""},
                "culture": "tr",
                "form_PATH": "/Dyn/AktiviteAdd/Detail",
                "type": "DropDownList",
                "apiUrl": null,
                "controller": "AktiviteAdd",
                "revisionNo": null,
                "dataId": null,
                "valueName": "DropDownList"
              },
              "take": 0,
              "skip": 0,
              "page": 1,
              "pageSize": 0
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dataList = data['Data'] as List? ?? [];

            debugPrint('[ACTIVITY_API] ✅ GetReadReport success: ${dataList.length} items');
            return dataList
                .map((item) {
                  final value = item['Value'] ?? item['Id'];
                  final text = item['Text'] as String? ?? item['Name'] as String? ?? item['Adi'] as String? ?? value?.toString() ?? '';

                  return DropdownOption(value: value, text: text);
                })
                .where((item) => item.text.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('[ACTIVITY_API] GetReadReport failed: $e');
        }

        // 4. Try generic DropDown endpoint
        try {
          debugPrint('[ACTIVITY_API] Trying generic DropDown endpoint...');
          final response = await ApiClient.post(
            '/api/admin/DynamicFormApi/DropDown',
            body: {
              "sourceType": sourceType,
              "sourceValue": sourceValue,
              "dataTextField": dataTextField ?? "Text",
              "dataValueField": dataValueField ?? "Value",
              "controller": "AktiviteAdd",
              "culture": "tr"
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dataList = data['Data'] as List? ?? data as List? ?? [];

            debugPrint('[ACTIVITY_API] ✅ DropDown endpoint success: ${dataList.length} items');
            return dataList
                .map((item) => DropdownOption(
                      value: item['Value'] ?? item['Id'],
                      text: item['Text'] as String? ?? item['Name'] as String? ?? '',
                    ))
                .where((item) => item.text.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('[ACTIVITY_API] DropDown endpoint failed: $e');
        }
      } else if (sourceType == '1') {
        // SQL source - use GetReadReport
        try {
          debugPrint('[ACTIVITY_API] SQL source - using GetReadReport...');
          final response = await ApiClient.post(
            '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
            body: {
              "model": {
                "Parameters": [],
                "model": {dataTextField ?? "Text": "", dataValueField ?? "Id": ""},
                "culture": "tr",
                "form_PATH": "/Dyn/AktiviteAdd/Detail",
                "type": "DropDownList",
                "apiUrl": null,
                "controller": "AktiviteAdd",
                "revisionNo": null,
                "dataId": null,
                "valueName": "DropDownList"
              },
              "take": 0,
              "skip": 0,
              "page": 1,
              "pageSize": 0
            },
          );

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final dataList = data['Data'] as List? ?? [];

            debugPrint('[ACTIVITY_API] ✅ SQL GetReadReport success: ${dataList.length} items');
            return dataList
                .map((item) {
                  final value = item[dataValueField ?? 'Id'] ?? item['Value'] ?? item['Id'];
                  final text = item[dataTextField ?? 'Text'] as String? ??
                      item['Text'] as String? ??
                      item['Name'] as String? ??
                      item['Adi'] as String? ??
                      item['Firma'] as String? ??
                      value?.toString() ??
                      '';

                  return DropdownOption(value: value, text: text);
                })
                .where((item) => item.text.isNotEmpty)
                .toList();
          }
        } catch (e) {
          debugPrint('[ACTIVITY_API] SQL GetReadReport failed: $e');
        }
      }

      debugPrint('[ACTIVITY_API] ⚠️ All endpoints failed, returning empty list');
      return [];
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load dropdown error: $e');
      return [];
    }
  }

  /// Load activity types (sourceValue: 10176)
  Future<List<DropdownOption>> loadActivityTypes() async {
    return await loadDropdownOptions(
      sourceType: '4',
      sourceValue: 10176,
      dataTextField: 'Text',
      dataValueField: 'Value',
    );
  }

  /// Load priority levels (sourceValue: 63)
  Future<List<DropdownOption>> loadPriorityLevels() async {
    return await loadDropdownOptions(
      sourceType: '4',
      sourceValue: 63,
      dataTextField: 'Text',
      dataValueField: 'Value',
    );
  }

  /// Load companies for company dropdown
  Future<List<DropdownOption>> loadCompanies() async {
    return await loadDropdownOptions(
      sourceType: '1',
      sourceValue: 3072,
      dataTextField: 'Firma',
      dataValueField: 'Id',
    );
  }

  /// Load users for representative dropdown (sourceValue: 22)
  Future<List<DropdownOption>> loadUsers() async {
    return await loadDropdownOptions(
      sourceType: '1',
      sourceValue: 22,
      dataTextField: 'Adi',
      dataValueField: 'UserId',
    );
  }

  /// Load contacts by company ID (cascade dropdown)
  Future<List<DropdownOption>> loadContactsByCompany(int companyId) async {
    try {
      debugPrint('[ACTIVITY_API] Loading contacts for company: $companyId');

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReport/23',
        body: {
          "model": {
            "Parameters": [
              {"Name": "@CompanyId", "Type": 2, "Value": companyId},
              {"Name": "CompanyId", "Type": 2, "Value": companyId}
            ],
            "model": {"Adi": "", "Id": ""},
            "culture": "tr",
            "form_PATH": "/Dyn/AktiviteAdd/Detail",
            "type": "DropDownList",
            "apiUrl": null,
            "controller": "AktiviteAdd",
            "revisionNo": null,
            "dataId": null,
            "valueName": "DropDownList"
          },
          "take": 0,
          "skip": 0,
          "page": 1,
          "pageSize": 0
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['Data'] as List? ?? [];

        debugPrint('[ACTIVITY_API] ✅ Contacts loaded: ${dataList.length} items');
        return dataList
            .map((item) => DropdownOption(
                  value: item['Id'],
                  text: item['Adi'] as String? ?? '',
                ))
            .toList();
      }

      debugPrint('[ACTIVITY_API] ⚠️ Contacts API failed');
      return [];
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load contacts error: $e');
      return [];
    }
  }

  /// Firma konum bilgisini al
  Future<LocationData?> getCompanyLocation(int companyId) async {
    try {
      debugPrint('[ACTIVITY_API] Getting company location for ID: $companyId');

      // ANA FIRMA BİLGİLERİNİ ÇEK (CompanyAdd, CompanyAddressAdd değil)
      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormWithData',
        body: {
          "model": {
            "controller": "CompanyAdd", // DEĞİŞTİRİLDİ
            "id": companyId, // DEĞİŞTİRİLDİ
            "url": "/Dyn/CompanyAdd/Detail", // DEĞİŞTİRİLDİ
            "formParams": {},
            "form_PATH": "/Dyn/CompanyAdd/Detail",
            "culture": "tr"
          },
          "take": 10,
          "skip": 0,
          "page": 1,
          "pageSize": 10
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // DEBUG: Tüm response'u logla
        debugPrint('[ACTIVITY_API] 🔍 COMPANY MAIN DATA DEBUG:');
        debugPrint('[ACTIVITY_API] Data keys: ${data.keys.toList()}');
        debugPrint('[ACTIVITY_API] Data.Data keys: ${data['Data']?.keys.toList()}');
        debugPrint('[ACTIVITY_API] Data.Data.Data keys: ${data['Data']?['Data']?.keys.toList()}');

        // Lokasyon field'larını farklı isimlerle ara
        String? locationData;

        // 1. "Lokasyon" field'ı
        locationData = data['Data']?['Data']?['Lokasyon'] as String?;
        debugPrint('[ACTIVITY_API] 🔍 Lokasyon field: $locationData');

        // 2. "Location" field'ı
        if (locationData == null || locationData.isEmpty) {
          locationData = data['Data']?['Data']?['Location'] as String?;
          debugPrint('[ACTIVITY_API] 🔍 Location field: $locationData');
        }

        // 3. "MapLocation" field'ı
        if (locationData == null || locationData.isEmpty) {
          locationData = data['Data']?['Data']?['MapLocation'] as String?;
          debugPrint('[ACTIVITY_API] 🔍 MapLocation field: $locationData');
        }

        // 4. "Coordinates" field'ı
        if (locationData == null || locationData.isEmpty) {
          locationData = data['Data']?['Data']?['Coordinates'] as String?;
          debugPrint('[ACTIVITY_API] 🔍 Coordinates field: $locationData');
        }

        // 5. "Konum" field'ı
        if (locationData == null || locationData.isEmpty) {
          locationData = data['Data']?['Data']?['Konum'] as String?;
          debugPrint('[ACTIVITY_API] 🔍 Konum field: $locationData');
        }

        if (locationData != null && locationData.isNotEmpty) {
          // Koordinatları parse et: "38.35386520000001, 38.3206558"
          final parts = locationData.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());

            if (lat != null && lng != null) {
              debugPrint('[ACTIVITY_API] ✅ Company location found: $lat, $lng');

              return LocationData(
                latitude: lat,
                longitude: lng,
                address: 'Firma konumu',
                timestamp: DateTime.now(),
              );
            } else {
              debugPrint('[ACTIVITY_API] ❌ Invalid coordinates in location data: $locationData');
            }
          } else {
            debugPrint('[ACTIVITY_API] ❌ Invalid location format: $locationData');
          }
        } else {
          debugPrint('[ACTIVITY_API] ❌ Location data is null or empty');
        }

        debugPrint('[ACTIVITY_API] ⚠️ Company location not found in main company data');
        return null;
      } else {
        throw Exception('Failed to get company location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get company location error: $e');
      return null;
    }
  }

  /// Konum kıyaslaması yap
  Future<LocationComparisonResult> compareLocations({
    required int companyId,
    required double currentLat,
    required double currentLng,
    double toleranceInMeters = 100.0,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Comparing locations for company: $companyId');
      debugPrint('[ACTIVITY_API] Current location: $currentLat, $currentLng');

      // Firma konumunu al
      final companyLocation = await getCompanyLocation(companyId);

      if (companyLocation == null) {
        return LocationComparisonResult(
          status: LocationComparisonStatus.noCompanyLocation,
          message: '⚠️ Firma konumu kayıtlı değil. Konum kıyaslaması yapılamadı.',
          distance: null,
          companyLocation: null,
        );
      }

      // Mesafeyi hesapla
      final distance = LocationService.instance.calculateDistance(
        currentLat,
        currentLng,
        companyLocation.latitude,
        companyLocation.longitude,
      );

      debugPrint('[ACTIVITY_API] Distance: ${distance.toStringAsFixed(2)} meters');

      // Konum durumunu belirle
      LocationComparisonStatus status;
      String message;

      if (distance <= toleranceInMeters) {
        status = LocationComparisonStatus.atLocation;
        message = '✅ Aynı konumdasınız! (${distance.toStringAsFixed(0)}m)';
      } else if (distance <= toleranceInMeters * 2) {
        status = LocationComparisonStatus.nearby;
        message = '📍 Firma yakınında (${distance.toStringAsFixed(0)}m)';
      } else if (distance <= 500) {
        status = LocationComparisonStatus.close;
        message = '🚶 Farklı konumda - ${distance.toStringAsFixed(0)}m uzakta';
      } else if (distance < 1000) {
        status = LocationComparisonStatus.far;
        message = '🚗 Farklı konumda - ${(distance / 1000).toStringAsFixed(1)}km uzakta';
      } else {
        status = LocationComparisonStatus.veryFar;
        message = '🌍 Farklı konumda - ${(distance / 1000).toStringAsFixed(1)}km uzakta';
      }

      return LocationComparisonResult(
        status: status,
        message: message,
        distance: distance,
        companyLocation: companyLocation,
      );
    } catch (e) {
      debugPrint('[ACTIVITY_API] Location comparison error: $e');
      return LocationComparisonResult(
        status: LocationComparisonStatus.error,
        message: '❌ Konum kıyaslaması yapılamadı: ${e.toString()}',
        distance: null,
        companyLocation: null,
      );
    }
  }

  Future<ActivityListResponse> getActivityList({
    required ActivityFilter filter,
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting activity list - Filter: $filter, Page: $page, Size: $pageSize, Search: $searchQuery');

      // 🔧 DÜZELTİLDİ: Web'deki ile birebir aynı endpoint'ler
      String params;
      String formPath;

      switch (filter) {
        case ActivityFilter.open:
          params = "AcikAktiviteler";
          formPath = "/Dyn/AktiviteAdd/List/AcikAktiviteler";
          break;
        case ActivityFilter.closed:
          params = "KapaliAktiviteler"; // ✅ Web'deki ile aynı
          formPath = "/Dyn/AktiviteAdd/List/KapaliAktiviteler"; // ✅ Web'deki ile aynı
          break;
        case ActivityFilter.all:
          params = "List";
          formPath = "/Dyn/AktiviteAdd/List";
          break;
      }

      debugPrint('[ACTIVITY_API] 🎯 Using endpoint: $params, FormPath: $formPath');

      // 🔧 Web'deki request body ile birebir aynı
      final requestBody = {
        "controller": "AktiviteAdd",
        "params": params,
        "form_PATH": formPath,
        "UserLocation": "0,0",
        "LayoutData": {
          "element": "ListGrid",
          "url": formPath // ✅ Web'deki ile aynı
        },
        "take": pageSize,
        "skip": (page - 1) * pageSize,
        "page": page,
        "pageSize": pageSize,
      };

      // Add search filter if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody["searchQuery"] = searchQuery;
      }

      debugPrint('[ACTIVITY_API] 📤 Request body for $filter:');
      debugPrint('[ACTIVITY_API] 📤 ${requestBody.toString()}');

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormListDataType',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[ACTIVITY_API] ✅ Activity list response received for filter: $filter');
        debugPrint('[ACTIVITY_API] 📊 Response data keys: ${data.keys.toList()}');

        // Response'da data'nın içeriğini de logla
        if (data['DataSourceResult'] != null && data['DataSourceResult']['Data'] != null) {
          final activities = data['DataSourceResult']['Data'] as List;
          debugPrint('[ACTIVITY_API] 📊 Found ${activities.length} activities for filter: $filter');

          // İlk birkaç aktiviteyi logla (debug için)
          if (activities.isNotEmpty) {
            final firstActivity = activities.first;
            debugPrint('[ACTIVITY_API] 📋 First activity: ID=${firstActivity['Id']}, Tipi=${firstActivity['Tipi']}, Firma=${firstActivity['Firma']}');
          }
        }

        return ActivityListResponse.fromJson(data);
      } else {
        debugPrint('[ACTIVITY_API] ❌ Failed response: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load activity list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Get activity list error for filter $filter: $e');
      throw Exception('Aktivite listesi yüklenemedi ($filter): ${e.toString()}');
    }
  }

  /// Aktivite listesini getirir (YENİ METHOD)
  Future<ActivityListResponse> getActivityListWithAddresses({
    required ActivityFilter filter,
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting activity list with addresses - Filter: $filter, Page: $page');

      // Önce normal aktivite listesini al
      final activityResponse = await getActivityList(
        filter: filter,
        page: page,
        pageSize: pageSize,
        searchQuery: searchQuery,
      );

      // Her aktivite için adres bilgilerini zenginleştir
      final enrichedActivities = <ActivityListItem>[];

      for (final activity in activityResponse.data) {
        var enrichedActivity = activity;

        // Eğer aktivitede CompanyId ve AddressId varsa, adres detaylarını al
        if (activity.id > 0) {
          try {
            // TODO: Aktivite detayından CompanyId ve AddressId'yi al
            // Bu bilgiler aktivite API'sinden gelmelidir
            enrichedActivity = await _enrichActivityWithAddress(activity);
          } catch (e) {
            debugPrint('[ACTIVITY_API] Failed to enrich activity ${activity.id} with address: $e');
            // Hata durumunda orijinal aktiviteyi kullan
          }
        }

        enrichedActivities.add(enrichedActivity);
      }

      return ActivityListResponse(
        data: enrichedActivities,
        total: activityResponse.total,
      );
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get activity list with addresses error: $e');
      rethrow;
    }
  }

  /// 🆕 YENİ: Aktiviteyi adres bilgileriyle zenginleştir
  Future<ActivityListItem> _enrichActivityWithAddress(ActivityListItem activity) async {
    try {
      // Bu metod aktivite detay API'sinden CompanyId ve AddressId alıp
      // ilgili adres bilgilerini getirerek aktiviteyi zenginleştirir

      // TODO: Aktivite detay API'sinden company ve address ID'lerini al
      // Şimdilik mock veri ile test edelim

      return activity; // Geçici olarak orijinal aktiviteyi döndür
    } catch (e) {
      debugPrint('[ACTIVITY_API] Enrich activity error: $e');
      return activity;
    }
  }

  /// 🆕 YENİ: Aktivite için mevcut adresleri getir (firma seçilince)
  Future<List<DropdownOption>> getActivityAddressOptions({
    required int companyId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting address options for activity - Company: $companyId');

      final companyApiService = CompanyApiService();
      final addressOptions = await companyApiService.getCompanyAddressesForDropdown(
        companyId: companyId,
      );

      debugPrint('[ACTIVITY_API] Found ${addressOptions.length} address options');
      return addressOptions;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get address options error: $e');
      return [];
    }
  }

  /// 🆕 YENİ: Firma adını kullanarak activity'leri adres bilgileriyle zenginleştir
  Future<List<ActivityListItem>> enrichActivitiesWithAddressesByName(List<ActivityListItem> activities) async {
    final enrichedActivities = <ActivityListItem>[];

    // 🔍 DEBUG: Başlangıç logları
    debugPrint('[ACTIVITY_API] 🔍 DEBUG: Starting enrichment for ${activities.length} activities');
    for (int i = 0; i < activities.length; i++) {
      debugPrint('[ACTIVITY_API] 🔍 Activity $i: ID=${activities[i].id}, Firma="${activities[i].firma}"');
    }

    for (final activity in activities) {
      // 🔍 DEBUG: Her aktivite için detay
      debugPrint('[ACTIVITY_API] 🔍 Processing activity ID: ${activity.id}');
      debugPrint('[ACTIVITY_API] 🔍 Activity firma: "${activity.firma}"');
      debugPrint('[ACTIVITY_API] 🔍 Firma null? ${activity.firma == null}');
      debugPrint('[ACTIVITY_API] 🔍 Firma empty? ${activity.firma?.isEmpty ?? true}');

      if (activity.firma != null && activity.firma!.isNotEmpty) {
        try {
          debugPrint('[ACTIVITY_API] 🔄 Loading addresses for company: ${activity.firma}');

          // Company adreslerini firma adıyla bul
          final companyApiService = CompanyApiService();
          final addresses = await companyApiService.getCompanyAddressesByName(activity.firma!);

          debugPrint('[ACTIVITY_API] 🔍 Found ${addresses.length} addresses for ${activity.firma}');

          if (addresses.isNotEmpty) {
            // 🎯 AKILLI ADRES SEÇİMİ: En uygun adresi seç
            CompanyAddress selectedAddress;

            // 1. "Ana" tipi varsa onu seç
            final anaAdres = addresses.where((addr) => addr.tipi?.toLowerCase().contains('ana') == true).toList();

            // 2. "Merkez" tipi varsa onu seç
            final merkezAdres = addresses.where((addr) => addr.tipi?.toLowerCase().contains('merkez') == true).toList();

            // 3. Kısa adresi olan varsa onu seç
            final kisaAdresli = addresses.where((addr) => addr.kisaAdres != null && addr.kisaAdres!.isNotEmpty).toList();

            if (anaAdres.isNotEmpty) {
              selectedAddress = anaAdres.first;
              debugPrint('[ACTIVITY_API] 🎯 Selected ANA address: ${selectedAddress.displayAddress}');
            } else if (merkezAdres.isNotEmpty) {
              selectedAddress = merkezAdres.first;
              debugPrint('[ACTIVITY_API] 🎯 Selected MERKEZ address: ${selectedAddress.displayAddress}');
            } else if (kisaAdresli.isNotEmpty) {
              selectedAddress = kisaAdresli.first;
              debugPrint('[ACTIVITY_API] 🎯 Selected address with KisaAdres: ${selectedAddress.displayAddress}');
            } else {
              selectedAddress = addresses.first;
              debugPrint('[ACTIVITY_API] 🎯 Selected FIRST address: ${selectedAddress.displayAddress}');
            }

            // Activity'yi seçilen adres bilgileriyle zenginleştir
            final enriched = ActivityListItem(
              id: activity.id,
              tipi: activity.tipi,
              konu: activity.konu,
              firma: activity.firma,
              kisi: activity.kisi,
              baslangic: activity.baslangic,
              temsilci: activity.temsilci,
              detay: activity.detay,
              // 🆕 Seçilen adres bilgileri
              kisaAdres: selectedAddress.kisaAdres,
              acikAdres: selectedAddress.acikAdres,
              il: selectedAddress.il,
              ilce: selectedAddress.ilce,
              ulke: selectedAddress.ulke,
              adresTipi: selectedAddress.tipi,
            );

            enrichedActivities.add(enriched);
            debugPrint('[ACTIVITY_API] ✅ Address added for ${activity.firma}: ${selectedAddress.displayAddress}');
          } else {
            enrichedActivities.add(activity); // Adres bulunamadı
            debugPrint('[ACTIVITY_API] ⚠️ No address found for company: ${activity.firma}');
          }
        } catch (e) {
          enrichedActivities.add(activity); // Hata durumunda orijinal
          debugPrint('[ACTIVITY_API] ❌ Failed to load address for ${activity.firma}: $e');
        }
      } else {
        debugPrint('[ACTIVITY_API] ⚠️ SKIPPING - Firma is null or empty for activity ${activity.id}');
        enrichedActivities.add(activity); // Firma adı yok
      }
    }

    debugPrint('[ACTIVITY_API] 🔍 DEBUG: Enrichment completed. Input: ${activities.length}, Output: ${enrichedActivities.length}');
    return enrichedActivities;
  }

  /// 🆕 YENİ: Seçilen adresin detay bilgilerini getir
  Future<CompanyAddress?> getSelectedAddressDetails({
    required int companyId,
    required int addressId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting address details - Company: $companyId, Address: $addressId');

      final companyApiService = CompanyApiService();
      final address = await companyApiService.getCompanyAddressById(
        companyId: companyId,
        addressId: addressId,
      );

      if (address != null) {
        debugPrint('[ACTIVITY_API] Found address: ${address.displayAddress}');
      } else {
        debugPrint('[ACTIVITY_API] Address not found');
      }

      return address;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get address details error: $e');
      return null;
    }
  }
}

// ActivityFilter enum - dosyanın sonunda
enum ActivityFilter { open, closed, all }

// Konum kıyaslaması sonuçları
enum LocationComparisonStatus {
  atLocation, // Aynı konumda
  nearby, // Yakınında
  close, // Yakın
  far, // Uzak
  veryFar, // Çok uzak
  noCompanyLocation, // Firma konumu yok
  error, // Hata
}

class LocationComparisonResult {
  final LocationComparisonStatus status;
  final String message;
  final double? distance;
  final LocationData? companyLocation;

  LocationComparisonResult({
    required this.status,
    required this.message,
    this.distance,
    this.companyLocation,
  });

  bool get isAtSameLocation => status == LocationComparisonStatus.atLocation;
  bool get isDifferentLocation =>
      !isAtSameLocation && status != LocationComparisonStatus.noCompanyLocation && status != LocationComparisonStatus.error;
}
