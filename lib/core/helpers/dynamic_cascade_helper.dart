// ================================================
// DYNAMIC CASCADE SYSTEM - FORM FIELD DEPENDENCY
// ================================================

// lib/core/helpers/dynamic_cascade_helper.dart
import 'package:flutter/material.dart';
import '../../data/models/dynamic_form/form_field_model.dart';
import '../../data/services/api/company_api_service.dart';
import '../../data/services/api/activity_api_service.dart';

/// Dynamic Cascade System - API response'undan dependency haritası oluşturur
class DynamicCascadeHelper {
  static final DynamicCascadeHelper _instance = DynamicCascadeHelper._internal();
  factory DynamicCascadeHelper() => _instance;
  DynamicCascadeHelper._internal();

  // Dependency mapping cache
  final Map<String, List<CascadeDependency>> _dependencyMap = {};

  /// Form model'dan cascade dependency haritasını oluştur
  Map<String, List<CascadeDependency>> buildDependencyMap(DynamicFormModel formModel) {
    debugPrint('[CASCADE_HELPER] 🔗 Building dependency map...');

    _dependencyMap.clear();

    // Tüm field'ları tara
    for (final section in formModel.sections) {
      for (final field in section.fields) {
        // Cascade field mi kontrol et
        if (_hasCascadeInfo(field)) {
          final dependency = _parseCascadeInfo(field);

          if (dependency != null) {
            // Parent field'a dependency ekle
            if (!_dependencyMap.containsKey(dependency.parentField)) {
              _dependencyMap[dependency.parentField] = [];
            }

            _dependencyMap[dependency.parentField]!.add(dependency);

            debugPrint('[CASCADE_HELPER] ✅ Dependency: ${dependency.parentField} → ${dependency.childField}');
            debugPrint('[CASCADE_HELPER]   📋 SQL: ${dependency.sourceValue}, Param: ${dependency.parameterName}');
          }
        }
      }
    }

    debugPrint('[CASCADE_HELPER] 🎯 Total dependencies: ${_dependencyMap.length}');
    _dependencyMap.forEach((parent, children) {
      debugPrint('[CASCADE_HELPER] 📂 $parent → ${children.map((c) => c.childField).join(', ')}');
    });

    return Map.from(_dependencyMap);
  }

  /// Field'da cascade bilgisi var mı kontrol et
  bool _hasCascadeInfo(DynamicFormField field) {
    debugPrint('[CASCADE_HELPER] 🔍 Checking field: ${field.key} (${field.label})');

    // 🎯 MANUEL CASCADE KURALLARI
    final manualCascadeRules = {
      'CompanyBranchId': 'CompanyId', // Şube → Firmaya bağlı
      'ContactId': 'CompanyId', // Kişi → Firmaya bağlı
      'ActivityContacts': 'CompanyId', // Diğer Kişiler → Firmaya bağlı
    };

    if (manualCascadeRules.containsKey(field.key)) {
      debugPrint('[CASCADE_HELPER] ✅ Manual cascade rule found for ${field.key} → ${manualCascadeRules[field.key]}');
      return true;
    }

    // API'den gelen cascade bilgisi kontrolü (eskisi gibi)
    final widget = field.widget;
    if (widget.properties.containsKey('cascade') && widget.properties['cascade'] == true) {
      debugPrint('[CASCADE_HELPER] ✅ Found cascade=true in ${field.key}');
      return true;
    }

    debugPrint('[CASCADE_HELPER] ❌ No cascade info in ${field.key}');
    return false;
  }

  /// Cascade bilgisini parse et
  /// Cascade bilgisini parse et
  CascadeDependency? _parseCascadeInfo(DynamicFormField field) {
    try {
      debugPrint('[CASCADE_HELPER] 🔍 === PARSING FIELD: ${field.key} ===');

      final widget = field.widget;
      final props = widget.properties;

      // 🎯 MANUEL CASCADE KURALLARI - API'de bilgi yoksa manuel tanımla
      final manualCascadeRules = {
        'CompanyBranchId': {
          'parentField': 'CompanyId',
          'sourceType': '1',
          'sourceValue': '9883', // Branch loading için SQL ID
          'parameterName': '@Id',
          'dataTextField': 'Adres3',
          'dataValueField': 'Id',
        },
        'ContactId': {
          'parentField': 'CompanyId',
          'sourceType': '1',
          'sourceValue': '23', // Contact loading için SQL ID
          'parameterName': '@CompanyId',
          'dataTextField': 'Adi',
          'dataValueField': 'Id',
        },
        'ActivityContacts': {
          'parentField': 'CompanyId',
          'sourceType': '1',
          'sourceValue': '23', // Contact loading için SQL ID
          'parameterName': '@CompanyId',
          'dataTextField': 'Adi',
          'dataValueField': 'Id',
        },
      };

      // Manuel kural var mı kontrol et
      if (manualCascadeRules.containsKey(field.key)) {
        final rule = manualCascadeRules[field.key]!;

        debugPrint('[CASCADE_HELPER] ✅ Using manual rule for ${field.key}');
        debugPrint('[CASCADE_HELPER]   Parent: ${rule['parentField']}');
        debugPrint('[CASCADE_HELPER]   SQL: ${rule['sourceValue']}, Param: ${rule['parameterName']}');

        return CascadeDependency(
          parentField: rule['parentField']!,
          childField: field.key,
          sourceType: rule['sourceType']!,
          sourceValue: rule['sourceValue']!,
          parameterName: rule['parameterName']!,
          dataTextField: rule['dataTextField'],
          dataValueField: rule['dataValueField'],
          controller: 'AktiviteBranchAdd',
          formPath: '/Dyn/AktiviteBranchAdd/Detail',
        );
      }

      // API'den gelen cascade bilgilerini kontrol et (orijinal kod)
      String? cascadeFrom;
      //String? cascadeFromField;
      // List<dynamic>? parameters;

      if (props.containsKey('cascadeFrom')) {
        cascadeFrom = props['cascadeFrom']?.toString();
      }

      if (props.containsKey('cascadeFromField')) {
        //cascadeFromField = props['cascadeFromField']?.toString();
      }

      if (props.containsKey('Parameters')) {
        // parameters = props['Parameters'] as List<dynamic>?;
      }

      if (cascadeFrom == null || cascadeFrom.isEmpty) {
        debugPrint('[CASCADE_HELPER] ⚠️ No cascade info found for ${field.key}');
        return null;
      }

      // ... geri kalan orijinal kod
    } catch (e) {
      debugPrint('[CASCADE_HELPER] ❌ Parse error for ${field.key}: $e');
      return null;
    }
    return null;
  }

  /// Parent field değiştiğinde bağımlı field'ları reload et
  Future<void> handleFieldChange({
    required String parentField,
    required dynamic newValue,
    required DynamicFormModel formModel,
    required Function(String fieldKey, List<DropdownOption> options) onOptionsLoaded,
    required Function(String fieldKey, dynamic value) onFieldReset,
  }) async {
    if (!_dependencyMap.containsKey(parentField)) {
      debugPrint('[CASCADE_HELPER] 🔍 No dependencies for field: $parentField');
      return;
    }

    final dependencies = _dependencyMap[parentField]!;
    debugPrint('[CASCADE_HELPER] 🔄 Processing ${dependencies.length} dependencies for $parentField = $newValue');

    // Parallel olarak tüm bağımlı field'ları güncelle
    final futures = dependencies.map((dependency) async {
      try {
        // Önce field'ı sıfırla
        onFieldReset(dependency.childField, null);

        if (newValue == null) {
          debugPrint('[CASCADE_HELPER] 🗑️ Parent null, clearing ${dependency.childField}');
          onOptionsLoaded(dependency.childField, []);
          return;
        }

        debugPrint('[CASCADE_HELPER] 🔄 Loading options for ${dependency.childField}...');

        // API'den yeni options yükle
        final options = await _loadDependentOptions(dependency, newValue);

        debugPrint('[CASCADE_HELPER] ✅ Loaded ${options.length} options for ${dependency.childField}');
        onOptionsLoaded(dependency.childField, options);
      } catch (e) {
        debugPrint('[CASCADE_HELPER] ❌ Error loading ${dependency.childField}: $e');
        onOptionsLoaded(dependency.childField, []);
      }
    });

    await Future.wait(futures);
    debugPrint('[CASCADE_HELPER] ✅ All dependencies processed for $parentField');
  }

  /// Bağımlı field için options yükle
  Future<List<DropdownOption>> _loadDependentOptions(CascadeDependency dependency, dynamic parentValue) async {
    try {
      // Controller'a göre uygun API service'i seç
      final apiService = _getApiService(dependency.controller);

      debugPrint('[CASCADE_HELPER] 🌐 API Call Details:');
      debugPrint('[CASCADE_HELPER]   SourceType: ${dependency.sourceType}');
      debugPrint('[CASCADE_HELPER]   SourceValue: ${dependency.sourceValue}');
      debugPrint('[CASCADE_HELPER]   Parameter: ${dependency.parameterName} = $parentValue');
      debugPrint('[CASCADE_HELPER]   Controller: ${dependency.controller}');
      debugPrint('[CASCADE_HELPER]   FormPath: ${dependency.formPath}');

      // Parametreli API çağrısı yap
      final options = await _loadOptionsWithParameters(
        apiService: apiService,
        dependency: dependency,
        parentValue: parentValue,
      );

      return options;
    } catch (e) {
      debugPrint('[CASCADE_HELPER] ❌ API Error for ${dependency.childField}: $e');
      return [];
    }
  }

  /// Parametreli API çağrısı - GERÇEK IMPLEMENTASYOn
  Future<List<DropdownOption>> _loadOptionsWithParameters({
    required dynamic apiService,
    required CascadeDependency dependency,
    required dynamic parentValue,
  }) async {
    // ⬆️ Bu kısım şu anki dropdown options loader'ı extend edilecek
    // Şimdilik basit implementation

    if (dependency.sourceType == '1') {
      // SQL source - parametreli
      return await _loadSqlSourceWithParameters(
        apiService: apiService,
        dependency: dependency,
        parentValue: parentValue,
      );
    } else if (dependency.sourceType == '4') {
      // Group source - genelde parametresiz
      return await apiService.loadDropdownOptions(
        sourceType: dependency.sourceType,
        sourceValue: dependency.sourceValue,
        dataTextField: dependency.dataTextField,
        dataValueField: dependency.dataValueField,
      );
    }

    return [];
  }

  /// SQL source için parametreli API çağrısı
  Future<List<DropdownOption>> _loadSqlSourceWithParameters({
    required dynamic apiService,
    required CascadeDependency dependency,
    required dynamic parentValue,
  }) async {
    debugPrint('[CASCADE_HELPER] 🔄 SQL Source with parameters...');

    // Controller'a göre uygun metotları çağır
    if (dependency.controller == 'AktiviteBranchAdd' || dependency.controller == 'AktiviteAdd') {
      // Activity API Service metotları
      if (dependency.childField == 'CompanyBranchId') {
        // Şube loading - ActivityApiService.loadCompanyBranches
        return await apiService.loadCompanyBranches(companyId: parentValue as int);
      } else if (dependency.childField == 'ContactId') {
        // Kişi loading - ActivityApiService.loadContactsByCompany
        return await apiService.loadContactsByCompany(parentValue as int);
      }
    } else if (dependency.controller == 'CompanyAdd') {
      // Company API Service metotları
      if (apiService is CompanyApiService) {
        return await apiService.loadDropdownOptions(
          sourceType: dependency.sourceType,
          sourceValue: dependency.sourceValue,
          dataTextField: dependency.dataTextField,
          dataValueField: dependency.dataValueField,
          filters: {dependency.parameterName: parentValue},
        );
      }
    }

    // Generic loading fallback
    if (apiService.runtimeType.toString().contains('ActivityApiService')) {
      return await apiService.loadDropdownOptions(
        sourceType: dependency.sourceType,
        sourceValue: dependency.sourceValue,
        dataTextField: dependency.dataTextField,
        dataValueField: dependency.dataValueField,
        filters: {dependency.parameterName: parentValue},
      );
    } else if (apiService is CompanyApiService) {
      return await apiService.loadDropdownOptions(
        sourceType: dependency.sourceType,
        sourceValue: dependency.sourceValue,
        dataTextField: dependency.dataTextField,
        dataValueField: dependency.dataValueField,
        filters: {dependency.parameterName: parentValue},
      );
    }

    return [];
  }

  /// Controller'a göre uygun API service'i getir
  dynamic _getApiService(String controller) {
    switch (controller.toLowerCase()) {
      case 'aktiviteadd':
      case 'aktivitebranchadd':
        return ActivityApiService();
      case 'companyadd':
        return CompanyApiService();
      default:
        // Default olarak Activity API Service kullan
        return ActivityApiService();
    }
  }

  /// Debug: Dependency map'i yazdır
  void debugDependencyMap() {
    debugPrint('[CASCADE_HELPER] ===== DEPENDENCY MAP DEBUG =====');

    if (_dependencyMap.isEmpty) {
      debugPrint('[CASCADE_HELPER] No dependencies found');
      return;
    }

    _dependencyMap.forEach((parent, children) {
      debugPrint('[CASCADE_HELPER] 🔗 $parent:');
      for (final child in children) {
        debugPrint('[CASCADE_HELPER]   → ${child.childField} (SQL: ${child.sourceValue}, Param: ${child.parameterName})');
      }
    });

    debugPrint('[CASCADE_HELPER] =====================================');
  }
}

/// Cascade dependency model
class CascadeDependency {
  final String parentField;
  final String childField;
  final String sourceType;
  final String sourceValue;
  final String parameterName;
  final String? dataTextField;
  final String? dataValueField;
  final String controller;
  final String formPath;

  CascadeDependency({
    required this.parentField,
    required this.childField,
    required this.sourceType,
    required this.sourceValue,
    required this.parameterName,
    this.dataTextField,
    this.dataValueField,
    required this.controller,
    required this.formPath,
  });

  @override
  String toString() {
    return 'CascadeDependency(parent: $parentField, child: $childField, sql: $sourceValue, param: $parameterName)';
  }
}

// ================================================
// FORM FIELD MODEL EXTENSION - CASCADE DETECTION
// ================================================

extension DynamicFormFieldCascadeExtension on DynamicFormField {
  /// Bu field cascade field mi?
  bool get isCascadeField {
    return widget.properties.containsKey('cascade') && widget.properties['cascade'] == true;
  }

  /// Bu field'ın bağlı olduğu parent field
  String? get cascadeFrom {
    if (!isCascadeField) return null;
    return widget.properties['cascadeFrom']?.toString();
  }

  /// Bu field'ın cascade parameter adı
  String? get cascadeParameter {
    if (!isCascadeField) return null;

    // cascadeFromField'dan al
    if (widget.properties.containsKey('cascadeFromField')) {
      return widget.properties['cascadeFromField']?.toString();
    }

    // Parameters array'den al
    if (widget.properties.containsKey('Parameters')) {
      final params = widget.properties['Parameters'] as List<dynamic>?;
      if (params != null && params.isNotEmpty) {
        final firstParam = params.first;
        if (firstParam is Map<String, dynamic> && firstParam.containsKey('Name')) {
          return firstParam['Name']?.toString();
        }
      }
    }

    return '@$cascadeFrom';
  }

  /// Debug cascade bilgisi
  void debugCascadeInfo() {
    debugPrint('[FIELD_CASCADE] Field: $key');
    debugPrint('[FIELD_CASCADE] IsCascade: $isCascadeField');
    debugPrint('[FIELD_CASCADE] CascadeFrom: $cascadeFrom');
    debugPrint('[FIELD_CASCADE] CascadeParameter: $cascadeParameter');
    debugPrint('[FIELD_CASCADE] SourceType: ${widget.sourceType}');
    debugPrint('[FIELD_CASCADE] SourceValue: ${widget.sourceValue}');
  }
}

// ================================================
// USAGE EXAMPLE - FORM SCREEN'DE KULLANIM
// ================================================

/*
// Form screen'de kullanım:

class _AddActivityScreenState extends State<AddActivityScreen> {
  late DynamicCascadeHelper _cascadeHelper;
  Map<String, List<CascadeDependency>> _dependencyMap = {};

  @override
  void initState() {
    super.initState();
    _cascadeHelper = DynamicCascadeHelper();
  }
  
  void _onFormLoaded(DynamicFormModel formModel) {
    // Dependency map'i oluştur
    _dependencyMap = _cascadeHelper.buildDependencyMap(formModel);
    _cascadeHelper.debugDependencyMap();
  }
  
  void _onFormDataChanged(Map<String, dynamic> formData) {
    // Normal form change handling
    setState(() {
      _formData = formData;
    });
    
    // Cascade handling için async
    _handleCascadeChanges(formData);
  }
  
  Future<void> _handleCascadeChanges(Map<String, dynamic> formData) async {
    // Her field change'i için cascade kontrol et
    for (final entry in formData.entries) {
      final fieldKey = entry.key;
      final newValue = entry.value;
      
      if (_dependencyMap.containsKey(fieldKey)) {
        await _cascadeHelper.handleFieldChange(
          parentField: fieldKey,
          newValue: newValue,
          formModel: _formModel!,
          onOptionsLoaded: (childField, options) {
            // Child field'ın options'ını güncelle
            final field = _formModel!.getFieldByKey(childField);
            if (field != null && mounted) {
              setState(() {
                field.options = options;
              });
            }
          },
          onFieldReset: (childField, value) {
            // Child field'ı sıfırla
            if (mounted) {
              setState(() {
                _formData[childField] = value;
              });
            }
          },
        );
      }s
    }
  }
}
*/
