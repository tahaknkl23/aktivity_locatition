// activity_api_service.dart - DÜZELTİLMİŞ VERSİYON
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
      debugPrint('[ACTIVITY_API] 📋 Loading activity form for activity ID: $activityId');

      // Direkt AktiviteBranchAdd kullan - Server kullanıcıya göre field'ları ayarlayacak
      final response = await getFormWithData(
        controller: 'AktiviteBranchAdd',
        url: '/Dyn/AktiviteBranchAdd/Detail',
        id: activityId ?? 0,
      );

      final formModel = DynamicFormModel.fromJson(response);
      debugPrint('[ACTIVITY_API] ✅ Form loaded: ${formModel.formName}');
      debugPrint('[ACTIVITY_API] 📊 Sections count: ${formModel.sections.length}');

      // Field analizi yap
      final allFields = <String>[];
      bool hasCompanyBranchId = false;
      bool hasCarId = false;
      bool hasKm = false;

      for (final section in formModel.sections) {
        debugPrint('[ACTIVITY_API] 📋 Section: ${section.label} (${section.fields.length} fields)');

        for (final field in section.fields) {
          allFields.add(field.key);

          if (field.key == 'CompanyBranchId') {
            hasCompanyBranchId = true;
            debugPrint('[ACTIVITY_API] 🎯 ŞUBE ALANI BULUNDU: ${field.label}');
          }

          if (field.key == 'CarId') {
            hasCarId = true;
            debugPrint('[ACTIVITY_API] 🚗 ARAÇ ALANI BULUNDU: ${field.label}');
          }

          if (field.key == 'Km') {
            hasKm = true;
            debugPrint('[ACTIVITY_API] 📏 KM ALANI BULUNDU: ${field.label}');
          }
        }
      }

      debugPrint('[ACTIVITY_API] 📊 USER FORM SUMMARY:');
      debugPrint('[ACTIVITY_API] 📊 Total fields: ${allFields.length}');
      debugPrint('[ACTIVITY_API] 📊 Has CompanyBranchId: $hasCompanyBranchId');
      debugPrint('[ACTIVITY_API] 📊 Has CarId: $hasCarId');
      debugPrint('[ACTIVITY_API] 📊 Has Km: $hasKm');

      return formModel;
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Load activity form error: $e');
      rethrow;
    }
  }

  /// 🆕 Şirket şubelerini yükle (CompanyBranchId için)
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
          "form_PATH": "/Dyn/AktiviteBranchAdd/Detail",
          "type": "DropDownList",
          "apiUrl": null,
          "controller": "AktiviteBranchAdd",
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

  /// 🆕 Şube detaylarını al (koordinat bilgisi için)
  Future<CompanyBranchDetails?> getBranchDetails({
    required int companyId,
    required int branchId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Getting branch details - Company: $companyId, Branch: $branchId');

      // TODO: Branch detail API implementation
      return null;
    } catch (e) {
      debugPrint('[ACTIVITY_API] Get branch details error: $e');
      return null;
    }
  }

  /// Save activity form data
  Future<Map<String, dynamic>> saveActivity({
    required Map<String, dynamic> formData,
    int? activityId,
  }) async {
    try {
      debugPrint('[ACTIVITY_API] Saving activity - ID: $activityId');
      debugPrint('[ACTIVITY_API] Form data keys: ${formData.keys.toList()}');

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

  /// Universal dropdown loader
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
          () async {
            return await ApiClient.get('/api/admin/DynamicFormApi/GetCategory/$sourceValue');
          },
          () async {
            return await ApiClient.post(
              '/api/admin/DynamicFormApi/GetCategory/$sourceValue',
              body: {
                "model": {
                  "Parameters": [],
                  "model": {"Text": "", "Value": ""},
                  "culture": "tr",
                  "form_PATH": "/Dyn/AktiviteBranchAdd/Detail",
                  "type": "DropDownList",
                  "controller": "AktiviteBranchAdd",
                },
                "filter": {"logic": "and", "filters": []}
              },
            );
          },
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
                "form_PATH": "/Dyn/AktiviteBranchAdd/Detail",
                "type": "DropDownList",
                "controller": "AktiviteBranchAdd",
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
            "form_PATH": "/Dyn/AktiviteBranchAdd/Detail",
            "type": "DropDownList",
            "controller": "AktiviteBranchAdd",
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

  /// Firma konum bilgisini al
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

  /// Konum kıyaslaması yap
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

  /// ✅ GÜNCELLENMIŞ: Aktivite listesini getirir - ŞUBE DESTEKLİ
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

      switch (filter) {
        case ActivityFilter.open:
          params = "AcikAktiviteler";
          formPath = "/Dyn/AktiviteBranchAdd/List/AcikAktiviteler";
          break;
        case ActivityFilter.closed:
          params = "KapaliAktiviteler";
          formPath = "/Dyn/AktiviteBranchAdd/List/KapaliAktiviteler";
          break;
        case ActivityFilter.all:
          params = "List";
          formPath = "/Dyn/AktiviteBranchAdd/List";
          break;
      }

      final requestBody = {
        "controller": "AktiviteBranchAdd",
        "params": params,
        "form_PATH": formPath,
        "UserLocation": "0,0",
        "LayoutData": {"element": "ListGrid", "url": formPath},
        "take": pageSize,
        "skip": (page - 1) * pageSize,
        "page": page,
        "pageSize": pageSize,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) {
        requestBody["searchQuery"] = searchQuery;
      }

      final response = await ApiClient.post(
        '/api/admin/DynamicFormApi/GetFormListDataType',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        debugPrint('[ACTIVITY_API] ✅ Response received for filter: $filter');

        if (data['DataSourceResult'] != null && data['DataSourceResult']['Data'] != null) {
          final activities = data['DataSourceResult']['Data'] as List;
          debugPrint('[ACTIVITY_API] 📊 Found ${activities.length} activities');

          if (activities.isNotEmpty) {
            final firstActivity = activities.first;
            debugPrint('[ACTIVITY_API] 🔍 Sample: ID=${firstActivity['Id']}, Sube="${firstActivity['Sube']}", Konum="${firstActivity['Konum']}"');
          }

          final activitiesWithSube = activities.where((act) => act['Sube'] != null && act['Sube'].toString().isNotEmpty).length;
          final activitiesWithKonum = activities.where((act) => act['Konum'] != null && act['Konum'].toString().isNotEmpty).length;
          debugPrint('[ACTIVITY_API] 🏢 Activities with Sube: $activitiesWithSube/${activities.length}');
          debugPrint('[ACTIVITY_API] 📍 Activities with Konum: $activitiesWithKonum/${activities.length}');
        }

        return ActivityListResponse.fromJson(data);
      } else {
        throw Exception('Failed to load activity list: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ Get activity list error for filter $filter: $e');
      throw Exception('Aktivite listesi yüklenemedi ($filter): ${e.toString()}');
    }
  }

  /// 🆕 ENHANCED: Aktivite listesini adres bilgileriyle zenginleştir (ŞUBE ÖNCE)
  Future<List<ActivityListItem>> enrichActivitiesWithAddressesByName(List<ActivityListItem> activities) async {
    final enrichedActivities = <ActivityListItem>[];

    debugPrint('[ACTIVITY_API] 🔍 Starting enrichment for ${activities.length} activities');

    for (final activity in activities) {
      // 🎯 1. ÖNCE ŞUBE BİLGİSİ VAR MI KONTROL ET
      if (activity.hasSube) {
        debugPrint('[ACTIVITY_API] 🏢 Activity already has Sube info: ${activity.sube}');
        enrichedActivities.add(activity); // Şube varsa enrichment'a gerek yok
        continue;
      }

      // 🎯 2. ŞUBE YOKSA ADRES ENRİCHMENT YAPMAYI DENE
      if (activity.firma != null && activity.firma!.isNotEmpty) {
        try {
          final companyApiService = CompanyApiService();
          final addresses = await companyApiService.getCompanyAddressesByName(activity.firma!);

          if (addresses.isNotEmpty) {
            // AKILLI ADRES SEÇİMİ
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

            // ENRİCHED AKTİVİTE OLUŞTUR
            final enriched = ActivityListItem(
              id: activity.id,
              tipi: activity.tipi,
              konu: activity.konu,
              firma: activity.firma,
              kisi: activity.kisi,
              sube: activity.sube, // Mevcut şube bilgisini koru
              konum: activity.konum, // 🆕 Koordinat bilgisini koru
              baslangic: activity.baslangic,
              bitis: activity.bitis, // Bitiş bilgisini koru
              temsilci: activity.temsilci,
              detay: activity.detay,
              // Seçilen adres bilgileri ekle
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

  /// Get activity address options
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

  /// 🎯 TEST METHOD: JSON response'unu test et
  Future<void> testActivityListResponse() async {
    try {
      debugPrint('[ACTIVITY_API] 🧪 TESTING ACTIVITY LIST RESPONSE...');

      final openActivities = await getActivityList(
        filter: ActivityFilter.open,
        page: 1,
        pageSize: 5,
      );

      debugPrint('[ACTIVITY_API] 🧪 OPEN ACTIVITIES TEST:');
      debugPrint('[ACTIVITY_API] 📊 Total: ${openActivities.total}');
      debugPrint('[ACTIVITY_API] 📊 Loaded: ${openActivities.data.length}');

      for (int i = 0; i < openActivities.data.length && i < 3; i++) {
        final activity = openActivities.data[i];
        debugPrint('[ACTIVITY_API] 🧪 Activity $i:');
        debugPrint('[ACTIVITY_API]   ID: ${activity.id}');
        debugPrint('[ACTIVITY_API]   Tipi: ${activity.tipi}');
        debugPrint('[ACTIVITY_API]   Firma: ${activity.firma}');
        debugPrint('[ACTIVITY_API]   Sube: ${activity.sube}');
        debugPrint('[ACTIVITY_API]   Konum: ${activity.konum}');
        debugPrint('[ACTIVITY_API]   HasSube: ${activity.hasSube}');
        debugPrint('[ACTIVITY_API]   HasKonum: ${activity.hasKonum}');
        debugPrint('[ACTIVITY_API]   HasValidCoordinates: ${activity.hasValidCoordinates}');
        debugPrint('[ACTIVITY_API]   TimeRange: ${activity.timeRange}');
      }
    } catch (e) {
      debugPrint('[ACTIVITY_API] ❌ TEST FAILED: $e');
    }
  }
}

// ENUMS VE CLASS'LAR
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
