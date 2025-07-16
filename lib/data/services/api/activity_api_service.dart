import 'package:aktivity_location_app/core/services/location_service.dart';
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

  /// Aktivite listesini getirir (YENİ METHOD)
  Future<ActivityListResponse> getActivityList({
    required ActivityFilter filter,
    int page = 1,
    int pageSize = 20,
    String? searchQuery,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting activity list - Filter: $filter, Page: $page, Size: $pageSize, Search: $searchQuery');

      // Determine the endpoint based on filter
      String params;
      switch (filter) {
        case ActivityFilter.open:
          params = "AcikAktiviteler";
          break;
        case ActivityFilter.closed:
          params = "KapaliAktiviteler";
          break;
        case ActivityFilter.all:
        default:
          params = "AcikAktiviteler"; // Default to open
          break;
      }

      final requestBody = {
        "controller": "AktiviteAdd",
        "params": params,
        "form_PATH": "/Dyn/AktiviteAdd/List/$params",
        "UserLocation": "0,0",
        "LayoutData": {"element": "ListGrid", "url": "/Dyn/AktiviteAdd/List/$params"},
        "take": pageSize,
        "skip": (page - 1) * pageSize,
        "page": page,
        "pageSize": pageSize,
      };

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
        debugPrint('[ACTIVITY_API] Activity list response received');
        return ActivityListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load activity list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get activity list error: $e');
      throw Exception('Aktivite listesi yüklenemedi: ${e.toString()}');
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
