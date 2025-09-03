// lib/presentation/screens/activity/add_activity_screen.dart - LOCATION CONTROL ADDED

import 'dart:async';
import 'package:aktivity_location_app/core/helpers/dynamic_cascade_helper.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/helpers/location_config_helper.dart'; // ✅ YENİ IMPORT
import '../../../core/widgets/common/loading_state_widget.dart';
import '../../../core/widgets/common/error_state_widget.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/file_service.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/services/api/activity_api_service.dart';
import '../../../data/models/attachment/attachment_file_model.dart';
import '../../widgets/activity/activity_action_chips_widget.dart';
import '../../widgets/activity/activity_app_bar_widget.dart';
import '../../widgets/activity/form_content_widget.dart';
import '../../widgets/activity/save_button_widget.dart';
import '../../widgets/activity/file_options_bottom_sheet.dart';
import '../../widgets/activity/close_activity_dialog.dart';

class AddActivityScreen extends StatefulWidget {
  final int? activityId;
  final int? preSelectedCompanyId;

  const AddActivityScreen({
    super.key,
    this.activityId,
    this.preSelectedCompanyId,
  });

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final ActivityApiService _activityApiService = ActivityApiService();
  late DynamicCascadeHelper _cascadeHelper;
  Map<String, List<CascadeDependency>> _dependencyMap = {};

  // File handlers
  Function()? _showFileOptionsHandler;
  VoidCallback? _refreshFilesHandler;

  // Form data
  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  int? _currentActivityId; // State'te activity ID tut

  // Loading states
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isGettingLocation = false;
  bool _isClosingActivity = false;
  bool isComparingLocation = false;
  String? _errorMessage;

  // Data states
  LocationData? _currentLocation;
  final List<AttachmentFile> _attachedFiles = [];
  CompanyAddress? _selectedAddress;
  LocationComparisonResult? _locationComparison;
  CompanyBranchDetails? selectedBranch;

  // 🔥 GLOBAL SAVE PROTECTION
  static bool _globalSaveInProgress = false;

  // ✅ YENİ: Location control getter'ları
  bool get _hasLocationFeatures {
    return LocationConfigHelper.shouldShowLocationFeatures(
      '/Dyn/AktiviteBranchAdd/Detail', // Form URL
      'AktiviteBranchAdd', // Controller
    );
  }

  bool get _hasBranchComparison {
    return LocationConfigHelper.shouldCompareBranchLocation('AktiviteBranchAdd');
  }

  @override
  void initState() {
    super.initState();
    _currentActivityId = widget.activityId; // Widget'tan initial değeri al

    // ✅ YENİ: Location settings debug
    LocationConfigHelper.debugLocationSettings('/Dyn/AktiviteBranchAdd/Detail', 'AktiviteBranchAdd', 'Detail');
    _cascadeHelper = DynamicCascadeHelper();

    _loadFormData();
  }

  // Getters
  bool get isEditing => _currentActivityId != null && _currentActivityId! > 0;
  int? get savedActivityId => _currentActivityId;

  // ===================
  // FORM LOADING
  // ===================

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final formModel = await _activityApiService.loadActivityForm(
        activityId: _currentActivityId,
      );

      await _loadDropdownOptions(formModel);

      if (mounted) {
        setState(() {
          _formModel = formModel;
          _formData = Map<String, dynamic>.from(formModel.data);

          if (widget.preSelectedCompanyId != null && !isEditing) {
            _formData['CompanyId'] = widget.preSelectedCompanyId;
          }

          _isLoading = false;
        });
        _initializeCascadeSystem(formModel);

        // Pre-selected company için initial loading
        if (widget.preSelectedCompanyId != null && !isEditing) {
          await _loadCompanyAddresses(widget.preSelectedCompanyId!);
        }

        // Editing mode için existing files
        if (isEditing) {
          await _loadExistingFiles();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _initializeCascadeSystem(DynamicFormModel formModel) {
    try {
      debugPrint('[ADD_ACTIVITY] 🔗 Initializing cascade system...');

      // Dependency haritasını oluştur
      _dependencyMap = _cascadeHelper.buildDependencyMap(formModel);

      // Debug info
      _cascadeHelper.debugDependencyMap();

      debugPrint('[ADD_ACTIVITY] ✅ Cascade system initialized');
      debugPrint('[ADD_ACTIVITY] 📊 Total parent fields: ${_dependencyMap.keys.length}');
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Cascade initialization error: $e');
    }
  }

  Future<void> _loadDropdownOptions(DynamicFormModel formModel) async {
    for (final section in formModel.sections) {
      for (final field in section.fields) {
        if (field.type == FormFieldType.dropdown && field.widget.sourceType != null && field.widget.sourceValue != null) {
          try {
            final options = await _activityApiService.loadDropdownOptions(
              sourceType: field.widget.sourceType!,
              sourceValue: field.widget.sourceValue!,
              dataTextField: field.widget.dataTextField,
              dataValueField: field.widget.dataValueField,
            );
            field.options = options;
          } catch (e) {
            field.options = [];
            debugPrint('[ADD_ACTIVITY] Failed to load options for ${field.label}: $e');
          }
        }
      }
    }
  }

  Future<void> _loadExistingFiles() async {
    if (_currentActivityId == null) return;

    try {
      debugPrint('[ADD_ACTIVITY] Loading existing files for activity: $_currentActivityId');

      final response = await FileService.instance.getActivityFiles(
        activityId: _currentActivityId!,
        tableId: 102,
      );

      if (mounted) {
        setState(() {
          _attachedFiles.clear();
          _attachedFiles.addAll(response.data);
        });
        debugPrint('[ADD_ACTIVITY] Loaded ${_attachedFiles.length} existing files');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Failed to load existing files: $e');
    }
  }

  // ===============================
  // FORM DATA HANDLING - TAM DÜZELTİLMİŞ VERSİYON
  // ===============================

  // 🔥 Save işlemi sırasında form data change'i engelle
  bool _isSaveInProgress = false;
  Timer? _debounceTimer;
  String? _lastCompanyChangeHash;
  int _formChangeCount = 0; // Form change sayacı

  void _onFormDataChanged(Map<String, dynamic> formData) {
    _formChangeCount++;

    // 🚨 GLOBAL SAVE PROGRESS KONTROLÜ
    if (_globalSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 GLOBAL save in progress, BLOCKING form change #$_formChangeCount');
      return;
    }

    // 🚨 SAVE PROGRESS KONTROLÜ
    if (_isSaving || _isSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 Save in progress, BLOCKING form change #$_formChangeCount');
      return;
    }

    // 🚨 ACTIVITY ALREADY SAVED KONTROLÜ - ÖNEMLİ!
    if (_currentActivityId != null && _currentActivityId! > 0 && !isEditing) {
      debugPrint('[ADD_ACTIVITY] 🚫 Activity already saved (ID: $_currentActivityId), BLOCKING all form changes');
      return; // Aktivite kaydedildikten sonra hiçbir form değişikliğine izin verme
    }

    // 🚨 SPAM KONTROLÜ - GELİŞTİRİLMİŞ
    if (_formChangeCount > 10) {
      debugPrint('[ADD_ACTIVITY] 🚫 Too many form changes ($_formChangeCount), throttling...');

      // 3 saniye bekle ve counter'ı sıfırla
      Timer(Duration(seconds: 3), () {
        _formChangeCount = 0; // Reset counter
      });
      return;
    }

    debugPrint('[ADD_ACTIVITY] 🔄 Form data changed #$_formChangeCount');

    // 🔥 COMPANY DEĞİŞİKLİĞİNİ KONTROL ET
    final oldCompanyId = _formData['CompanyId'];
    final newCompanyId = formData['CompanyId'];

    debugPrint('[ADD_ACTIVITY] 🔍 Company change check: $oldCompanyId → $newCompanyId');

    // ÖNCE state'i güncelle
    setState(() {
      _formData = formData;
    });
    _handleDynamicCascade(formData);

    // 🔥 SADECE İLK COMPANY SEÇİMİNDE CASCADE YAP
    if (oldCompanyId != newCompanyId && newCompanyId != null && oldCompanyId == null) {
      // Company değişikliği hash'i oluştur - sadece ilk seçim için
      final changeHash = 'first_company_$newCompanyId';

      // Aynı değişiklik hash'i varsa ignore et
      if (_lastCompanyChangeHash == changeHash) {
        debugPrint('[ADD_ACTIVITY] 🚫 Duplicate company change hash, ignoring');
        return;
      }

      _lastCompanyChangeHash = changeHash;
      debugPrint('[ADD_ACTIVITY] 🚀 Processing FIRST company selection: $changeHash');

      // Debounce cascade loading - daha uzun süre
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 1500), () {
        if (mounted && !_isSaveInProgress && !_globalSaveInProgress && _currentActivityId == null) {}
      });
    } else if (oldCompanyId != newCompanyId && oldCompanyId != null) {
      // Company değiştirildi (ikinci kez) - cascade yapma
      debugPrint('[ADD_ACTIVITY] ⚠️ Company changed from $oldCompanyId to $newCompanyId - NO CASCADE');
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleDynamicCascade(Map<String, dynamic> formData) async {
    if (_dependencyMap.isEmpty) {
      debugPrint('[ADD_ACTIVITY] 🔍 No cascade dependencies, skipping');
      return;
    }

    // Güvenlik kontrolleri
    if (_isSaving || _isSaveInProgress || _globalSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 Save in progress - DYNAMIC CASCADE BLOCKED');
      return;
    }

    if (_currentActivityId != null && _currentActivityId! > 0 && !isEditing) {
      debugPrint('[ADD_ACTIVITY] 🚫 Activity already saved - DYNAMIC CASCADE BLOCKED');
      return;
    }

    if (isEditing) {
      debugPrint('[ADD_ACTIVITY] 🚫 Edit mode - DYNAMIC CASCADE DISABLED for safety');
      return;
    }

    try {
      debugPrint('[ADD_ACTIVITY] 🔄 Processing dynamic cascade changes...');

      // Her field change için cascade kontrol et
      for (final entry in formData.entries) {
        final fieldKey = entry.key;
        final newValue = entry.value;

        // Bu field'ın dependency'si var mı?
        if (_dependencyMap.containsKey(fieldKey)) {
          debugPrint('[ADD_ACTIVITY] 🎯 Cascade trigger: $fieldKey = $newValue');

          await _cascadeHelper.handleFieldChange(
            parentField: fieldKey,
            newValue: newValue,
            formModel: _formModel!,
            onOptionsLoaded: (childField, options) {
              debugPrint('[ADD_ACTIVITY] ✅ Options loaded for $childField: ${options.length} items');

              // Child field'ın options'ını güncelle
              final field = _formModel!.getFieldByKey(childField);
              if (field != null && mounted) {
                setState(() {
                  field.options = options;
                });
                debugPrint('[ADD_ACTIVITY] 🔄 Field options updated for $childField');

                // 🔥 ZORLA UI REFRESH - FormContentWidget'a yeniden çiz sinyali
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      // Force UI rebuild
                    });
                  }
                });
              } else {
                debugPrint('[ADD_ACTIVITY] ❌ Field not found: $childField');
              }
            },
            onFieldReset: (childField, value) {
              debugPrint('[ADD_ACTIVITY] 🗑️ Field reset: $childField = $value');

              // Child field'ı sıfırla
              if (mounted) {
                setState(() {
                  _formData[childField] = value;
                });
              }
            },
          );
        }
      }

      debugPrint('[ADD_ACTIVITY] ✅ Dynamic cascade processing completed');
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Dynamic cascade error: $e');

      if (mounted) {
        SnackbarHelper.showWarning(
          context: context,
          message: 'Bağımlı alanlar güncellenirken hata oluştu',
          duration: Duration(seconds: 2),
        );
      }
    }
  }

  Future<void> _loadCompanyAddresses(int companyId) async {
    try {
      final addresses = await _activityApiService.getActivityAddressOptions(
        companyId: companyId,
      );

      setState(() {
        _formData['AddressId'] = null;
        _selectedAddress = null;
      });

      final addressField = _formModel?.getFieldByKey('AddressId') ?? _formModel?.getFieldByKey('Address');
      if (addressField != null && addressField.type == FormFieldType.dropdown) {
        addressField.options = addresses;
      }

      // Auto-select if only one address
      if (addresses.length == 1) {
        setState(() {
          _formData['AddressId'] = addresses.first.value;
        });
        await _loadAddressDetails(companyId, addresses.first.value as int);
      }
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Firma adresleri yüklenemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _loadAddressDetails(int companyId, int addressId) async {
    try {
      final address = await _activityApiService.getSelectedAddressDetails(
        companyId: companyId,
        addressId: addressId,
      );

      if (address != null && mounted) {
        setState(() {
          _selectedAddress = address;
        });

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Adres seçildi: ${address.displayAddress}',
          duration: Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Failed to load address details: $e');
    }
  }

  // ===================
  // LOCATION HANDLING - ✅ GÜNCELLENECEK
  // ===================

  // ✅ GÜNCELLENECEK: Location alma metodu
  Future<void> _getCurrentLocation() async {
    if (!_hasLocationFeatures) {
      debugPrint('[ADD_ACTIVITY] 🚫 Location features disabled for this form');
      SnackbarHelper.showInfo(
        context: context,
        message: 'Bu form için konum özelliği aktif değil',
        duration: Duration(seconds: 2),
      );
      return;
    }

    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      final locationData = await LocationService.instance.getCurrentLocation().timeout(Duration(seconds: 60));

      if (locationData != null && mounted) {
        setState(() {
          _currentLocation = locationData;
          _formData['Location'] = locationData.coordinates;
          _formData['LocationText'] = locationData.address;
        });

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Konum başarıyla alındı!',
          duration: Duration(seconds: 1),
        );

        // ✅ GÜNCELLENECEK: Branch comparison kontrolü
        if (_hasBranchComparison) {
          await _compareWithSelectedActivity();
        } else {
          debugPrint('[ADD_ACTIVITY] 🚫 Branch comparison disabled');
        }
      }
    } on TimeoutException {
      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Konum alma zaman aşımına uğradı. GPS açık mı kontrol edin.',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Konum alınamadı: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  // ✅ GÜNCELLENECEK: Compare metodu
  // AddActivityScreen'deki _compareWithSelectedActivity() metodunun başına ekleyin:

  Future<void> _compareWithSelectedActivity() async {
    // 🔍 DEBUG: Şube karşılaştırma kontrolü
    debugPrint('🔍 [BRANCH_DEBUG] ===== BRANCH COMPARISON DEBUG =====');
    debugPrint('🔍 [BRANCH_DEBUG] _hasBranchComparison: $_hasBranchComparison');
    debugPrint('🔍 [BRANCH_DEBUG] _hasLocationFeatures: $_hasLocationFeatures');
    debugPrint('🔍 [BRANCH_DEBUG] currentLocation != null: ${_currentLocation != null}');
    debugPrint('🔍 [BRANCH_DEBUG] isEditing: $isEditing');
    debugPrint('🔍 [BRANCH_DEBUG] _currentActivityId: $_currentActivityId');
    debugPrint('🔍 [BRANCH_DEBUG] Form Data CompanyId: ${_formData['CompanyId']}');
    debugPrint('🔍 [BRANCH_DEBUG] Form Data CompanyBranchId: ${_formData['CompanyBranchId']}');
    debugPrint('🔍 [BRANCH_DEBUG] ============================================');

    if (!_hasBranchComparison) {
      debugPrint('🔍 [BRANCH_DEBUG] ❌ Branch comparison DISABLED');
      return;
    }

    if (_currentLocation == null) {
      debugPrint('🔍 [BRANCH_DEBUG] ❌ No current location');
      return;
    }

    setState(() => isComparingLocation = true);

    try {
      setState(() => _locationComparison = null);

      // 1. Editing mode - get coordinates from API
      if (isEditing && _currentActivityId != null) {
        debugPrint('🔍 [BRANCH_DEBUG] 🎯 EDITING MODE - Getting activity coordinates from API');
        final activityLocation = await _getActivityCoordinatesFromAPI();
        if (activityLocation != null) {
          debugPrint('🔍 [BRANCH_DEBUG] ✅ Activity location found from API');
          final distance = LocationService.instance.calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            activityLocation.latitude,
            activityLocation.longitude,
          );

          final result = _createLocationComparisonResult(
            distance: distance,
            targetLocation: activityLocation,
            targetName: 'Aktivite Şubesi',
          );

          if (mounted) {
            setState(() => _locationComparison = result);
            SnackbarHelper.showInfo(
              context: context,
              message: result.message,
              backgroundColor: _getLocationStatusColor(result),
              duration: Duration(seconds: 2),
            );
          }
          return;
        } else {
          debugPrint('🔍 [BRANCH_DEBUG] ❌ Activity location NOT found from API');
        }
      }

      // 2. Form branch selection comparison
      final branchId = _formData['CompanyBranchId'] as int?;
      final companyId = _formData['CompanyId'] as int?;

      debugPrint('🔍 [BRANCH_DEBUG] 🎯 FORM BRANCH COMPARISON');
      debugPrint('🔍 [BRANCH_DEBUG] branchId: $branchId');
      debugPrint('🔍 [BRANCH_DEBUG] companyId: $companyId');

      if (branchId != null && companyId != null) {
        try {
          debugPrint('🔍 [BRANCH_DEBUG] 🔄 Getting branch details from API...');
          final branchDetails = await _activityApiService.getBranchDetails(
            companyId: companyId,
            branchId: branchId,
          );

          debugPrint('🔍 [BRANCH_DEBUG] branchDetails: $branchDetails');
          debugPrint('🔍 [BRANCH_DEBUG] branchDetails.hasCoordinates: ${branchDetails?.hasCoordinates}');

          if (branchDetails != null && branchDetails.hasCoordinates) {
            debugPrint('🔍 [BRANCH_DEBUG] ✅ Branch has coordinates - comparing...');
            await _compareWithSelectedBranch(branchDetails);
            return;
          } else {
            debugPrint('🔍 [BRANCH_DEBUG] ❌ Branch has NO coordinates');
          }
        } catch (e) {
          debugPrint('🔍 [BRANCH_DEBUG] ❌ Branch API error: $e');
        }
      } else {
        debugPrint('🔍 [BRANCH_DEBUG] ❌ branchId or companyId is NULL');
      }

      // 3. No coordinates available
      debugPrint('🔍 [BRANCH_DEBUG] ❌ No coordinates available for comparison');
      _showNoLocationMessage("Şube koordinat bilgisi mevcut değil");
    } catch (e) {
      debugPrint('🔍 [BRANCH_DEBUG] ❌ General error: $e');
      _showErrorMessage("Konum kıyaslaması yapılamadı: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isComparingLocation = false);
      }
    }
  }

  Future<void> _compareWithSelectedBranch(CompanyBranchDetails branch) async {
    if (_currentLocation == null || !branch.hasCoordinates) return;

    setState(() => isComparingLocation = true);

    try {
      final distance = LocationService.instance.calculateDistance(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        branch.latitude!,
        branch.longitude!,
      );

      final result = _createLocationComparisonResult(
        distance: distance,
        targetLocation: LocationData(
          latitude: branch.latitude!,
          longitude: branch.longitude!,
          address: branch.name,
          timestamp: DateTime.now(),
        ),
        targetName: 'Şube',
      );

      if (mounted) {
        setState(() => _locationComparison = result);
        SnackbarHelper.showInfo(
          context: context,
          message: result.message,
          backgroundColor: _getLocationStatusColor(result),
          duration: Duration(seconds: 2),
        );
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Branch comparison error: $e');
    } finally {
      if (mounted) {
        setState(() => isComparingLocation = false);
      }
    }
  }

  Future<LocationData?> _getActivityCoordinatesFromAPI() async {
    try {
      if (_currentActivityId == null) return null;

      final targetActivityId = _currentActivityId!;
      debugPrint('[ADD_ACTIVITY] 🔍 Searching for activity ID: $targetActivityId');

      // Search in activity lists
      final filters = [ActivityFilter.open, ActivityFilter.closed, ActivityFilter.all];

      for (final filter in filters) {
        try {
          final activities = await _activityApiService.getActivityList(
            filter: filter,
            page: 1,
            pageSize: 100,
          );

          for (final activity in activities.data) {
            if (activity.id == targetActivityId) {
              debugPrint('[ADD_ACTIVITY] ✅ Activity found in $filter list');

              if (activity.hasValidCoordinates) {
                final (lat, lng) = activity.parsedCoordinates;
                if (lat != null && lng != null) {
                  return LocationData(
                    latitude: lat,
                    longitude: lng,
                    address: activity.displaySube,
                    timestamp: DateTime.now(),
                  );
                }
              }
              break;
            }
          }
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] ⚠️ $filter activities search error: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ API coordinate fetch error: $e');
      return null;
    }
  }

  LocationComparisonResult _createLocationComparisonResult({
    required double distance,
    required LocationData targetLocation,
    required String targetName,
  }) {
    LocationComparisonStatus status;
    String message;

    if (distance <= 100) {
      status = LocationComparisonStatus.atLocation;
      message = '✅ $targetName\'nde bulunuyorsunuz! (${distance.toStringAsFixed(0)}m)';
    } else if (distance <= 200) {
      status = LocationComparisonStatus.nearby;
      message = '📍 $targetName yakınında (${distance.toStringAsFixed(0)}m)';
    } else if (distance <= 500) {
      status = LocationComparisonStatus.close;
      message = '🚶 $targetName\'nden ${distance.toStringAsFixed(0)}m uzakta';
    } else if (distance < 1000) {
      status = LocationComparisonStatus.far;
      message = '🚗 $targetName\'nden ${(distance / 1000).toStringAsFixed(1)}km uzakta';
    } else {
      status = LocationComparisonStatus.veryFar;
      message = '🌍 $targetName\'nden ${(distance / 1000).toStringAsFixed(1)}km uzakta';
    }

    return LocationComparisonResult(
      status: status,
      message: message,
      distance: distance,
      companyLocation: targetLocation,
    );
  }

  Color _getLocationStatusColor(LocationComparisonResult result) {
    switch (result.status) {
      case LocationComparisonStatus.atLocation:
      case LocationComparisonStatus.nearby:
        return AppColors.success;
      case LocationComparisonStatus.close:
        return AppColors.warning;
      case LocationComparisonStatus.far:
      case LocationComparisonStatus.veryFar:
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  void _showNoLocationMessage(String message) {
    if (mounted) {
      setState(() {
        _locationComparison = LocationComparisonResult(
          status: LocationComparisonStatus.noCompanyLocation,
          message: '📍 $message',
          distance: null,
          companyLocation: null,
        );
      });

      SnackbarHelper.showWarning(context: context, message: message);
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      setState(() {
        _locationComparison = LocationComparisonResult(
          status: LocationComparisonStatus.error,
          message: '❌ $message',
          distance: null,
          companyLocation: null,
        );
      });

      SnackbarHelper.showError(context: context, message: message);
    }
  }

  // ===================
  // FILE HANDLING - Aynı kalıyor
  // ===================

  void _showFileOptions() {
    if (_currentActivityId == null) {
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
      return;
    }

    if (_showFileOptionsHandler != null) {
      _showFileOptionsHandler!();
    } else {
      showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) => FileOptionsBottomSheet(
          onFileCapture: _fallbackFileUpload,
        ),
      );
    }
  }

  Future<void> _fallbackFileUpload(Future<FileData?> Function() captureFunction) async {
    try {
      final fileData = await captureFunction();
      if (fileData == null) return;

      SnackbarHelper.showInfo(
        context: context,
        message: 'Dosya yükleniyor: ${fileData.name}',
      );

      final response = await FileService.instance.uploadActivityFile(
        activityId: _currentActivityId!,
        file: fileData,
        tableId: 102,
      );

      if (response.isSuccess && response.firstFile != null) {
        setState(() {
          _attachedFiles.add(response.firstFile!);
        });

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Dosya başarıyla yüklendi: ${fileData.name}',
        );
      } else {
        throw FileException(response.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya yüklenemedi: ${e.toString()}',
      );
    }
  }

  void _onFileUploaded(AttachmentFile file) {
    if (!_attachedFiles.any((f) => f.id == file.id)) {
      setState(() {
        _attachedFiles.add(file);
      });
    }
    _refreshFormContentFiles();
  }

  void _onFileDeleted(AttachmentFile file) {
    setState(() {
      _attachedFiles.removeWhere((f) => f.id == file.id);
    });
    _refreshFormContentFiles();
  }

  void _refreshFormContentFiles() {
    try {
      if (_refreshFilesHandler != null) {
        _refreshFilesHandler!();
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ FormContent refresh error: $e');
    }
  }

  // ===================
  // SAVE & CLOSE - Aynı kalıyor
  // ===================

  Future<void> _saveActivity() async {
    // Mevcut save logic aynı kalıyor...
    if (_globalSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 GLOBAL save already in progress, IGNORING!');
      return;
    }

    if (_isSaving || _isSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 Instance save already in progress, ignoring...');
      return;
    }

    if (_currentActivityId != null && _currentActivityId! > 0 && !isEditing) {
      debugPrint('[ADD_ACTIVITY] 🚫 Activity already saved (ID: $_currentActivityId), ignoring save...');
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite zaten kaydedildi (ID: $_currentActivityId)',
        duration: Duration(seconds: 2),
      );
      return;
    }

    try {
      _globalSaveInProgress = true;

      setState(() {
        _isSaving = true;
        _isSaveInProgress = true;
      });

      debugPrint('[ADD_ACTIVITY] 💾 SAVE PROCESS STARTING...');

      if (!_validateRequiredFields()) {
        return;
      }

      final processedData = _prepareFormDataForSave();
      final result = await _activityApiService.saveActivity(
        formData: processedData,
        activityId: _currentActivityId,
      );

      final newActivityId = result['Data']?['Id'] as int?;
      if (newActivityId != null && !isEditing) {
        setState(() {
          _currentActivityId = newActivityId;
        });
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: isEditing ? '✅ Aktivite başarıyla güncellendi!' : '✅ Aktivite başarıyla kaydedildi! (ID: $newActivityId)',
          duration: Duration(seconds: 2),
        );

        await Future.delayed(Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'activityId': _currentActivityId,
            'isNew': newActivityId != null,
          });
        }
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Save error: $e');

      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Kaydetme sırasında hata oluştu: ${e.toString()}',
          duration: Duration(seconds: 4),
        );
      }
    } finally {
      _globalSaveInProgress = false;

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaveInProgress = false;
        });
      }
    }
  }

  Map<String, dynamic> _prepareFormDataForSave() {
    final preparedData = Map<String, dynamic>.from(_formData);
    final now = DateTime.now();

    if (preparedData['StartDate'] == null || preparedData['StartDate'].toString().isEmpty) {
      preparedData['StartDate'] =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    if (preparedData['EndDate'] == null || preparedData['EndDate'].toString().isEmpty) {
      final endTime = now.add(const Duration(minutes: 30));
      preparedData['EndDate'] =
          '${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.${endTime.year} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    }

    if (!isEditing) {
      preparedData['OpenOrClose'] = "1";
    }

    // ✅ YENİ: Location data sadece aktifse ekle
    if (_hasLocationFeatures && _currentLocation != null) {
      preparedData['StartLocation'] = _currentLocation!.coordinates;
      preparedData['StartLocationText'] = _currentLocation!.address;
    }

    final cleanedData = <String, dynamic>{};
    preparedData.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
        cleanedData[key] = value;
      }
    });

    return cleanedData;
  }

  bool _validateRequiredFields() {
    final errors = <String>[];

    if (_formData['ActivityType'] == null || _formData['ActivityType'].toString().isEmpty) {
      errors.add('Aktivite tipi seçimi zorunludur');
    }

    if (_formData['CompanyId'] == null) {
      errors.add('Firma seçimi zorunludur');
    }

    if (errors.isNotEmpty) {
      SnackbarHelper.showError(
        context: context,
        message: 'Eksik alanlar:\n• ${errors.join('\n• ')}',
        duration: Duration(seconds: 4),
      );
      return false;
    }

    return true;
  }

  Future<void> _closeActivity() async {
    // ✅ YENİ: Close işlemi için location kontrolü
    if (!_hasLocationFeatures) {
      debugPrint('[ADD_ACTIVITY] 🚫 Close activity disabled - location features not active');
      SnackbarHelper.showWarning(
        context: context,
        message: 'Bu form için aktivite kapatma özelliği aktif değil',
      );
      return;
    }

    try {
      if (_currentLocation == null) {
        SnackbarHelper.showError(
          context: context,
          message: 'Aktiviteyi kapatmak için önce konum bilgisi gereklidir',
        );
        return;
      }

      if (_currentActivityId == null) {
        SnackbarHelper.showError(
          context: context,
          message: 'Aktivite kaydedilmeden kapatılamaz',
        );
        return;
      }

      final shouldClose = await _showCloseActivityDialog();
      if (!shouldClose) return;

      setState(() => _isClosingActivity = true);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: '🔒 Aktivite başarıyla kapatıldı!',
          duration: Duration(seconds: 3),
        );

        await Future.delayed(Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.of(context).pop({
            'success': true,
            'activityId': _currentActivityId,
            'isClosed': true,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosingActivity = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Aktivite kapatılamadı: ${e.toString()}',
          duration: Duration(seconds: 4),
        );
      }
    }
  }

  Future<bool> _showCloseActivityDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => CloseActivityDialog(
            activityTitle: _getActivityTypeText(),
            currentLocation: _currentLocation?.address,
            companyName: _getCompanyName(),
          ),
        ) ??
        false;
  }

  String? _getActivityTypeText() {
    final activityTypeValue = _formData['ActivityType'];
    if (activityTypeValue == null) return null;

    final activityField = _formModel?.getFieldByKey('ActivityType');
    if (activityField?.options != null) {
      final option = activityField!.options!.firstWhere(
        (opt) => opt.value.toString() == activityTypeValue.toString(),
        orElse: () => DropdownOption(value: activityTypeValue, text: activityTypeValue.toString()),
      );
      return option.text;
    }

    return activityTypeValue.toString();
  }

  String? _getCompanyName() {
    final companyId = _formData['CompanyId'];
    if (companyId == null) return null;

    final companyField = _formModel?.getFieldByKey('CompanyId');
    if (companyField?.options != null) {
      final option = companyField!.options!.firstWhere(
        (opt) => opt.value == companyId,
        orElse: () => DropdownOption(value: companyId, text: 'Bilinmeyen Firma'),
      );
      return option.text;
    }

    return 'Seçili Firma';
  }

  Future<bool> _onWillPop() async {
    if (_isSaving || _isSaveInProgress || _globalSaveInProgress) {
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite kaydediliyor, lütfen bekleyin...',
        duration: Duration(seconds: 2),
      );
      return false;
    }
    return true;
  }

  // ===================s
  // UI BUILD - ✅ GÜNCELLENECEK
  // ===================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return LoadingStateWidget(
        title: isEditing ? 'Aktivite bilgileri yükleniyor...' : 'Form yükleniyor...',
        subtitle: 'Lütfen bekleyin',
        isEditing: isEditing,
      );
    }

    if (_errorMessage != null) {
      return ErrorStateWidget(
        title: 'Form Yüklenemedi',
        message: _errorMessage!,
        onRetry: _loadFormData,
        onBack: () => Navigator.of(context).pop(),
      );
    }

    if (_formModel == null) {
      return ErrorStateWidget(
        title: 'Form bulunamadı',
        message: 'Aktivite form verisi alınamadı. Lütfen tekrar deneyin.',
        onBack: () => Navigator.of(context).pop(),
      );
    }

    return Column(
      children: [
        // App Bar
        ActivityAppBarWidget(
          isEditing: isEditing,
          activityId: _currentActivityId,
          onBack: () => Navigator.of(context).pop(),
        ),

        // ✅ GÜNCELLENECEK: Action Chips - LOCATION FEATURES KONTROLÜ
        if (isEditing && _hasLocationFeatures) ...[
          ActivityActionChipsWidget(
            isEditing: isEditing,
            savedActivityId: _currentActivityId,
            currentLocation: _currentLocation,
            locationComparison: _locationComparison,
            attachedFiles: _attachedFiles,
            isGettingLocation: _isGettingLocation,
            isClosingActivity: _isClosingActivity,
            onGetLocation: _getCurrentLocation,
            onShowFileOptions: _showFileOptions,
            onCloseActivity: _closeActivity,
          ),
        ],

        // ✅ YENİ: Location features disabled message
        if (isEditing && !_hasLocationFeatures) ...[
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu form için konum özellikleri aktif değil',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        // Form Content
        Expanded(
          child: FormContentWidget(
            selectedAddress: _selectedAddress,
            currentLocation: _hasLocationFeatures ? _currentLocation : null,
            locationComparison: _hasBranchComparison ? _locationComparison : null,
            attachedFiles: _attachedFiles,
            formModel: _formModel!,
            isSaving: _isSaving,
            isEditing: isEditing,
            isGettingLocation: _isGettingLocation,
            savedActivityId: _currentActivityId,
            onFormChanged: _onFormDataChanged,
            onFileDeleted: _onFileDeleted,
            onFileUploaded: _onFileUploaded,
            // ✅ FİX: Her zaman bir fonksiyon ver, içeride kontrol et
            onRefreshLocation: () {
              if (_hasLocationFeatures) {
                _getCurrentLocation();
              } else {
                debugPrint('[ADD_ACTIVITY] Location refresh ignored - features disabled');
              }
            },
            onRegisterHandlers: (showFileOptionsHandler, refreshHandler) {
              _showFileOptionsHandler = showFileOptionsHandler;
              _refreshFilesHandler = refreshHandler;
            },
          ),
        ),

        // Save Button
        SaveButtonWidget(
          isSaving: _isSaving,
          isEditing: isEditing,
          onSave: _saveActivity,
        ),
      ],
    );
  }
}

// Extension for form model
extension DynamicFormModelExtension on DynamicFormModel {
  DynamicFormField? getFieldByKey(String key) {
    for (final section in sections) {
      for (final field in section.fields) {
        if (field.key == key) return field;
      }
    }
    return null;
  }
}
