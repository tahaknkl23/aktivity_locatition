import 'package:flutter/material.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/services/api/company_api_service.dart';
import 'base_api_service.dart';
import 'api_client.dart';

class ActivityApiService extends BaseApiService {
  Future<DynamicFormModel> loadActivityForm({int? activityId}) async {
    try {
      debugPrint('[ACTIVITY_API] 📋 Loading activity form for activity ID: $activityId');

      final response = await getFormWithData(
        controller: 'AktiviteBranchAdd', // ⬅️ FIXED: eskiden 'AktiviteBranchAdd' idi
        url: '/Dyn/AktiviteBranchAdd/Detail',
        id: activityId ?? 0,
      );

      final formModel = DynamicFormModel.fromJson(response);
      debugPrint('[ACTIVITY_API] ✅ Form loaded: ${formModel.formName}');
      debugPrint('[ACTIVITY_API] 📊 Sections count: ${formModel.sections.length}');

      return formModel;
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Load activity form error: $e');
      rethrow;
    }
  }

  /// Save activity form data
  Future<Map<String, dynamic>> saveActivity({
    required Map<String, dynamic> formData,
    int? activityId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] 💾 SAVING ACTIVITY - ID: $activityId');
      debugPrint('[ACTIVITY_API] 📊 Form data keys: ${formData.keys.toList()}');

      final webFormData = _convertToWebFormat(formData, activityId);

      debugPrint('[ACTIVITY_API] 🌐 Web format data prepared');

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/InsertData',
        body: webFormData,
      );

      debugPrint('[ACTIVITY_API] 📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[ACTIVITY_API] ✅ Save successful');

        final newId = result['Data']?['Id'] as int?;
        if (newId != null) {
          debugPrint('[ACTIVITY_API] 🆔 New Activity ID: $newId');
        }

        return result;
      } else {
        debugPrint('[ACTIVITY_API] ❌ Save failed: ${response.statusCode}');
        throw Exception('Save failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Save error: $e');
      rethrow;
    }
  }

  /// Close activity
  Future<Map<String, dynamic>> closeActivity({
    required int activityId,
    required String currentLocation,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] 🔒 CLOSING ACTIVITY: $activityId');
      debugPrint('[ACTIVITY_API] 📍 Location: $currentLocation');

      final closeData = {
        "tableId": 102,
        "Id": activityId,
        "form_ID": 5895,
        "form_PATH": "/Dyn/AktiviteBranchAdd/Detail/$activityId",
        "EndLocation": currentLocation,
        "OpenOrClose": "0",
      };

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/UpdateData',
        body: closeData,
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        debugPrint('[ACTIVITY_API] ✅ Activity closed successfully');
        return result;
      } else {
        throw Exception('Close failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Close activity error: $e');
      rethrow;
    }
  }

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
        // Group source handling
        final endpoints = [
          () async => await ApiClient.get('/api/admin/DynamicFormApi/GetCategory/$sourceValue'),
          () async => await ApiClient.post(
                '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
                body: {
                  "model": {
                    "Parameters": [],
                    "model": {"Text": "", "Value": ""},
                    "culture": "tr",
                    "form_PATH": "/Dyn/AktiviteBranchAdd/Detail", // ⬅️ FIXED
                    "type": "DropDownList",
                    "controller": "AktiviteBranchAdd", // ⬅️ FIXED
                  },
                  "filter": {"logic": "and", "filters": []}
                },
              ),
        ];

        for (int i = 0; i < endpoints.length; i++) {
          try {
            final response = await endpoints[i]();
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              final dataList = data['Data'] as List? ?? [];

              if (dataList.isNotEmpty) {
                debugPrint('[ACTIVITY_API] ✅ Endpoint ${i + 1} success: ${dataList.length} items');
                return dataList
                    .map((item) => DropdownOption(
                          value: item['Value'] ?? item['Id'],
                          text: item['Text'] as String? ?? '',
                        ))
                    .where((item) => item.text.isNotEmpty)
                    .toList();
              }
            }
          } catch (e) {
            debugPrint('[ACTIVITY_API] Endpoint ${i + 1} failed: $e');
          }
        }
      } else if (sourceType == '1') {
        // SQL source
        try {
          final response = await ApiClient.post(
            '/api/admin/DynamicFormApi/GetReadReport/$sourceValue',
            body: {
              "model": {
                "Parameters": [],
                "model": {dataTextField ?? "Text": "", dataValueField ?? "Id": ""},
                "culture": "tr",
                "form_PATH": "/Dyn/AktiviteBranchAdd/Detail", // ⬅️ FIXED
                "type": "DropDownList",
                "controller": "AktiviteBranchAdd", // ⬅️ FIXED
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

      return [];
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load dropdown error: $e');
      return [];
    }
  }

  /// Load contacts by company ID
  Future<List<DropdownOption>> loadContactsByCompany(int companyId) async {
    try {
      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReport/23',
        body: {
          "model": {
            "Parameters": [
              {"Name": "@CompanyId", "Type": 2, "Value": companyId},
            ],
            "model": {"Adi": "", "Id": ""},
            "culture": "tr",
            "form_PATH": "/Dyn/AktiviteBranchAdd/Detail", // ⬅️ FIXED
            "type": "DropDownList",
            "controller": "AktiviteBranchAdd", // ⬅️ FIXED
          },
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['Data'] as List? ?? [];

        return dataList
            .map((item) => DropdownOption(
                  value: item['Id'],
                  text: item['Adi'] as String? ?? '',
                ))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load contacts error: $e');
      return [];
    }
  }

  /// Load company branches
  Future<List<DropdownOption>> loadCompanyBranches({
    required int companyId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Loading branches for company: $companyId');

      final requestBody = {
        "model": {
          "Parameters": [
            {"Name": "@Id", "Type": 2, "Value": companyId},
          ],
          "model": {"Adres3": "", "Id": ""},
          "culture": "tr",
          "form_PATH": "/Dyn/AktiviteBranchAdd/Detail", // ⬅️ FIXED
          "type": "DropDownList",
          "apiUrl": null,
          "controller": "AktiviteBranchAdd", // ⬅️ FIXED
          "revisionNo": null,
          "dataId": null,
          "valueName": "DropDownList"
        },
        "take": "",
        "skip": 0,
        "page": 1,
        "pageSize": 50,
        "filter": {"logic": "and", "filters": []}
      };

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetReadReport/9883',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final dataList = data['Data'] as List? ?? [];

        debugPrint('[ACTIVITY_API] ✅ Company branches loaded: ${dataList.length} items');

        return dataList
            .map((item) => DropdownOption(
                  value: item['Id'],
                  text: item['Adres3'] as String? ?? 'İsimsiz Şube',
                ))
            .where((item) => item.text.isNotEmpty && item.text != 'İsimsiz Şube')
            .toList();
      } else {
        debugPrint('[ACTIVITY_API] ⚠️ Branch API failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] Load company branches error: $e');
      return [];
    }
  }

  /// Get branch details (placeholder - implement when API ready)
  Future<CompanyBranchDetails?> getBranchDetails({
    required int companyId,
    required int branchId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting branch details - Company: $companyId, Branch: $branchId');
      return null;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get branch details error: $e');
      return null;
    }
  }

  Future<LocationData?> getCompanyLocation(int companyId) async {
    try {
      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormWithData',
        body: {
          "model": {
            "controller": "CompanyAdd",
            "id": companyId,
            "url": "/Dyn/CompanyAdd/Detail",
            "formParams": {},
            "form_PATH": "/Dyn/CompanyAdd/Detail",
            "culture": "tr"
          },
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String? locationData = data['Data']?['Data']?['Lokasyon'] as String? ?? data['Data']?['Data']?['Location'] as String?;

        if (locationData != null && locationData.isNotEmpty) {
          final parts = locationData.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0].trim());
            final lng = double.tryParse(parts[1].trim());

            if (lat != null && lng != null) {
              return LocationData(
                latitude: lat,
                longitude: lng,
                address: 'Firma konumu',
                timestamp: DateTime.now(),
              );
            }
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get company location error: $e');
      return null;
    }
  }

  /// Compare locations - SİZİN ANA İHTİYACINIZ!
  Future<LocationComparisonResult> compareLocations({
    required int companyId,
    required double currentLat,
    required double currentLng,
    double toleranceInMeters = 100.0,
  }) async {
    try {
      final companyLocation = await getCompanyLocation(companyId);

      if (companyLocation == null) {
        return LocationComparisonResult(
          status: LocationComparisonStatus.noCompanyLocation,
          message: '⚠️ Firma konumu kayıtlı değil.',
          distance: null,
          companyLocation: null,
        );
      }

      final distance = LocationService.instance.calculateDistance(
        currentLat,
        currentLng,
        companyLocation.latitude,
        companyLocation.longitude,
      );

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
      debugPrint('[ACTIVITY_API] 🎯 Getting activity list - Filter: $filter, Page: $page, Size: $pageSize');

      String params;
      String formPath;
      String controller;

      switch (filter) {
        case ActivityFilter.open:
          params = "AcikAktiviteler";
          formPath = "/Dyn/AktiviteBranchAdd/List/AcikAktiviteler"; // ⬅️ SADECE BURADA DEĞİŞTİ
          controller = "AktiviteBranchAdd"; // ⬅️ SADECE BURADA DEĞİŞTİ
          break;
        case ActivityFilter.closed:
          params = "KapaliAktiviteler";
          formPath = "/Dyn/AktiviteBranchAdd/List/KapaliAktiviteler"; // ⬅️ SADECE BURADA DEĞİŞTİ
          controller = "AktiviteBranchAdd"; // ⬅️ SADECE BURADA DEĞİŞTİ
          break;
        case ActivityFilter.all:
          params = "List";
          formPath = "/Dyn/AktiviteBranchAdd/List"; // ⬅️ SADECE BURADA DEĞİŞTİ
          controller = "AktiviteBranchAdd"; // ⬅️ SADECE BURADA DEĞİŞTİ
          break;
      }

      // ⬅️ TÜM VERİLER İÇİN PARAMETRELERİ DÜZELT
      Map<String, dynamic> requestBody;

      if (pageSize >= 999999) {
        // TÜM VERİLER GELSİN - WEB FORMAT
        requestBody = {
          "take": "", // ⬅️ BOŞ STRING
          "skip": 0, // ⬅️ 0
          "page": "", // ⬅️ BOŞ STRING
          "pageSize": "", // ⬅️ BOŞ STRING
          "model": {
            "Parameters": [
              {"Type": 4, "Name": "@startDate"},
              {"Type": 4, "Name": "@finishDate"},
              {"Type": 1, "Name": "@MenuTitle", "Value": filter == ActivityFilter.open ? "Açık Aktiviteler" : "Kapalı Aktiviteler"}
            ],
            "controller": controller,
            "params": params,
            "form_PATH": formPath,
            "UserLocation": "0,0",
            "IsAachSpaceSplitLikeFilter": false
          }
        };
        debugPrint('[ACTIVITY_API] 📋 Request for ALL DATA - take: "", page: "", pageSize: ""');
      } else {
        // NORMAL PAGINATION
        requestBody = {
          "take": pageSize.toString(),
          "skip": (page - 1) * pageSize,
          "page": page.toString(),
          "pageSize": pageSize.toString(),
          "model": {
            "Parameters": [
              {
                "Type": 1,
                "Name": "@UserId",
                "Value": null // ⬅️ Kullanıcı ID'si gerekiyorsa buraya ekleyin
              },
              {"Type": 4, "Name": "@startDate"},
              {"Type": 4, "Name": "@finishDate"},
              {"Type": 1, "Name": "@MenuTitle", "Value": filter == ActivityFilter.open ? "Açık Aktiviteler" : "Kapalı Aktiviteler"}
            ],
            "controller": controller,
            "params": params,
            "form_PATH": formPath,
            "UserLocation": "0,0",
            "IsAachSpaceSplitLikeFilter": false
          }
        };
        debugPrint('[ACTIVITY_API] 📋 Request for PAGINATION - take: $pageSize, page: $page');
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody["searchQuery"] = searchQuery;
      }

      // ⬅️ ENDPOINT DEĞİŞTİ: GetFormListData (Parameters ile)
      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormListData', // ⬅️ SADECE BURADA DEĞİŞTİ
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[ACTIVITY_API] ✅ Response received for filter: $filter');
        return ActivityListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load activity list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Get activity list error for filter $filter: $e');
      throw Exception('Aktivite listesi yüklenemedi ($filter): ${e.toString()}');
    }
  }

  /// Enrich activities with address information (BRANCH FIRST) - ÖNEMLİ FONKSİYON!
  Future<List<ActivityListItem>> enrichActivitiesWithAddressesByName(List<ActivityListItem> activities) async {
    final enrichedActivities = <ActivityListItem>[];

    debugPrint('[ACTIVITY_API] 🔍 Starting enrichment for ${activities.length} activities');

    for (final activity in activities) {
      // 1. Check if branch info already exists
      if (activity.hasSube) {
        debugPrint('[ACTIVITY_API] 🏢 Activity already has Sube info: ${activity.sube}');
        enrichedActivities.add(activity); // No enrichment needed if branch exists
        continue;
      }

      // 2. Try address enrichment if no branch info
      if (activity.firma != null && activity.firma!.isNotEmpty) {
        try {
          final companyApiService = CompanyApiService();
          final addresses = await companyApiService.getCompanyAddressesByName(activity.firma!);

          if (addresses.isNotEmpty) {
            // Smart address selection
            CompanyAddress selectedAddress;

            final anaAdres = addresses.where((addr) => addr.tipi?.toLowerCase().contains('ana') == true).toList();
            final merkezAdres = addresses.where((addr) => addr.tipi?.toLowerCase().contains('merkez') == true).toList();
            final kisaAdresli = addresses.where((addr) => addr.kisaAdres != null && addr.kisaAdres!.isNotEmpty).toList();

            if (anaAdres.isNotEmpty) {
              selectedAddress = anaAdres.first;
            } else if (merkezAdres.isNotEmpty) {
              selectedAddress = merkezAdres.first;
            } else if (kisaAdresli.isNotEmpty) {
              selectedAddress = kisaAdresli.first;
            } else {
              selectedAddress = addresses.first;
            }

            // Create enriched activity
            final enriched = ActivityListItem(
              id: activity.id,
              tipi: activity.tipi,
              konu: activity.konu,
              firma: activity.firma,
              kisi: activity.kisi,
              sube: activity.sube, // Keep existing branch info
              konum: activity.konum, // Keep coordinate info
              baslangic: activity.baslangic,
              bitis: activity.bitis, // Keep end info
              temsilci: activity.temsilci,
              detay: activity.detay,
              // Add selected address info
              kisaAdres: selectedAddress.kisaAdres,
              acikAdres: selectedAddress.acikAdres,
              il: selectedAddress.il,
              ilce: selectedAddress.ilce,
              ulke: selectedAddress.ulke,
              adresTipi: selectedAddress.tipi,
            );

            enrichedActivities.add(enriched);
          } else {
            enrichedActivities.add(activity);
          }
        } catch (e) {
          enrichedActivities.add(activity);
        }
      } else {
        enrichedActivities.add(activity);
      }
    }

    debugPrint('[ACTIVITY_API] 🎯 ENRICHMENT SUMMARY:');
    debugPrint('[ACTIVITY_API] 📊 Input: ${activities.length}, Output: ${enrichedActivities.length}');

    final withSube = enrichedActivities.where((a) => a.hasSube).length;
    final withAddress = enrichedActivities.where((a) => a.hasAddress).length;

    debugPrint('[ACTIVITY_API] 🏢 With Sube: $withSube, With Address: $withAddress');

    return enrichedActivities;
  }

  Future<List<DropdownOption>> getActivityAddressOptions({
    required int companyId,
  }) async {
    try {
      final companyApiService = CompanyApiService();
      return await companyApiService.getCompanyAddressesForDropdown(
        companyId: companyId,
      );
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get address options error: $e');
      return [];
    }
  }

  /// Get selected address details
  Future<CompanyAddress?> getSelectedAddressDetails({
    required int companyId,
    required int addressId,
  }) async {
    try {
      final companyApiService = CompanyApiService();
      return await companyApiService.getCompanyAddressById(
        companyId: companyId,
        addressId: addressId,
      );
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get address details error: $e');
      return null;
    }
  }

  Map<String, dynamic> _convertToWebFormat(Map<String, dynamic> formData, int? activityId) {
    final webData = <String, dynamic>{
      // Form metadata
      "form_REV": false,
      "form_ID": 5895,
      "form_PATH": "/Dyn/AktiviteBranchAdd/Detail", // ⬅️ FIXED
      "IsCloneRecord": false,
      "tableId": 102,
      "Id": activityId ?? 0,

      // Main fields
      "CompanyId": formData['CompanyId'],
      "CompanyBranchId": formData['CompanyBranchId'],
      "ContactId": formData['ContactId'],
      "Subject": formData['Subject'],
      "StartDate": formData['StartDate'],
      "EndDate": formData['EndDate'],
      "Notes": formData['Notes'],
      "ActivityType": formData['ActivityType'],
      "Priority": formData['Priority'],
      "CarId": formData['CarId'],
      "Km": formData['Km'],
      "OpenOrClose": formData['OpenOrClose'] ?? "1",
      "AppointedUserId": formData['AppointedUserId'],
      "LastPrintFormat": formData['LastPrintFormat'] ?? "24",
      "OpportunityId": formData['OpportunityId'],
      "Saha1": formData['Saha1'],
      "Serial": formData['Serial'],
      "BasicId": formData['BasicId'],

      // Dropdown metadata (empty objects)
      "CompanyId_AutoComplateText": {},
      "CompanyBranchId_AutoComplateText": {},
      "ContactId_AutoComplateText": {},
      "LastPrintFormat_AutoComplateText": {},
      "OpportunityId_AutoComplateText": {},
      "AppointedUserId_AutoComplateText": {},
      "ActivityType_AutoComplateText": {},
      "Priority_AutoComplateText": {},
      "CarId_AutoComplateText": {},

      // Contacts array
      "ActivityContacts": _buildActivityContacts(formData),
      "ActivityContacts_DDL": [null],

      // Dropdown values
      "DropText_CompanyId": "0",
      "DropText_ContactId": "0",
    };

    // Remove null values
    webData.removeWhere((key, value) => value == null);
    return webData;
  }

  /// Build activity contacts array
  List<dynamic> _buildActivityContacts(Map<String, dynamic> formData) {
    final contactId = formData['ContactId'];
    if (contactId != null) {
      return [contactId];
    }
    return [];
  }
}

enum ActivityFilter { open, closed, all }

enum LocationComparisonStatus {
  atLocation,
  nearby,
  close,
  far,
  veryFar,
  noCompanyLocation,
  error,
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

class CompanyBranchDetails {
  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? koordinat;

  CompanyBranchDetails({
    required this.id,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    this.koordinat,
  });

  factory CompanyBranchDetails.fromJson(Map<String, dynamic> json) {
    double? lat, lng;
    final koordinatStr = json['Location'] as String? ?? json['Koordinat'] as String?;

    if (koordinatStr != null && koordinatStr.isNotEmpty) {
      try {
        final parts = koordinatStr.split(',');
        if (parts.length == 2) {
          lat = double.tryParse(parts[0].trim());
          lng = double.tryParse(parts[1].trim());
        }
      } catch (e) {
        debugPrint('[BRANCH_DETAILS] Koordinat parse error: $e');
      }
    }

    return CompanyBranchDetails(
      id: json['Id'] as int? ?? 0,
      name: json['Adres3'] as String? ?? 'İsimsiz Şube',
      address: json['Adres'] as String?,
      latitude: lat,
      longitude: lng,
      koordinat: koordinatStr,
    );
  }

  bool get hasCoordinates => latitude != null && longitude != null;
}
