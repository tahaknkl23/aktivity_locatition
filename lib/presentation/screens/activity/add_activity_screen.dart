import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/snackbar_helper.dart';
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

  @override
  void initState() {
    super.initState();
    _currentActivityId = widget.activityId; // Widget'tan initial değeri al
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

        // Pre-selected company için initial loading
        if (widget.preSelectedCompanyId != null && !isEditing) {
          await _loadCompanyAddresses(widget.preSelectedCompanyId!);
          await _loadCompanyBranches(widget.preSelectedCompanyId!);
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
        if (mounted && !_isSaveInProgress && !_globalSaveInProgress && _currentActivityId == null) {
          _handleCascadeDropdowns(formData, oldCompanyId: oldCompanyId);
        }
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

  Future<void> _handleCascadeDropdowns(Map<String, dynamic> formData, {dynamic oldCompanyId}) async {
    if (_formModel == null) return;

    // 🚨 SAVE PROGRESS KONTROLÜ - CASCADE'İ ENGELLE
    if (_isSaving || _isSaveInProgress || _globalSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🔒 Save in progress - CASCADE COMPLETELY BLOCKED');
      return;
    }

    // 🚨 ALREADY SAVED KONTROLÜ - CASCADE'İ ENGELLE
    if (_currentActivityId != null && _currentActivityId! > 0) {
      debugPrint('[ADD_ACTIVITY] 🔒 Activity already saved (ID: $_currentActivityId) - CASCADE BLOCKED');
      return;
    }

    // 🚨 EDIT MODE'DA CASCADE LOADING'İ TAMAMEN ENGELLE
    if (isEditing) {
      debugPrint('[ADD_ACTIVITY] 🔒 Edit mode - CASCADE COMPLETELY DISABLED for data safety');
      return;
    }

    debugPrint('[ADD_ACTIVITY] 🔄 SAFE CASCADE LOADING (NEW ACTIVITY):');
    debugPrint('[ADD_ACTIVITY] 🔍 Form data keys: ${formData.keys.toList()}');
    debugPrint('[ADD_ACTIVITY] 🔍 CompanyId value: ${formData['CompanyId']}');

    // Company selected (sadece yeni aktiviteler için, sadece ilk kez)
    if (formData.containsKey('CompanyId') && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      debugPrint('[ADD_ACTIVITY] 🏢 Company selected: $companyId');

      // Sadece ilk kez company seçildiğinde cascade yap
      if (oldCompanyId == null && companyId > 0) {
        debugPrint('[ADD_ACTIVITY] 🚀 Loading data for FIRST TIME company selection: $companyId');
        await _loadCompanyRelatedData(companyId, resetFields: true);
      } else {
        debugPrint('[ADD_ACTIVITY] ⚠️ Skipping cascade - Company change from $oldCompanyId to $companyId');
      }
    }

    // Branch selected (yeni aktiviteler için)
    if (!isEditing && formData.containsKey('CompanyBranchId') && formData['CompanyBranchId'] != null && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final branchId = formData['CompanyBranchId'] as int;
      debugPrint('[ADD_ACTIVITY] 🏢 Branch selected: $branchId');
      await _loadBranchDetails(companyId, branchId);
    }

    // Address selected (yeni aktiviteler için)
    if (!isEditing && formData.containsKey('AddressId') && formData['AddressId'] != null && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final addressId = formData['AddressId'] as int;
      debugPrint('[ADD_ACTIVITY] 🏠 Address selected: $addressId');
      await _loadAddressDetails(companyId, addressId);
    }
  }

  /// 🆕 Consolidated company related data loading
  Future<void> _loadCompanyRelatedData(int companyId, {bool resetFields = false}) async {
    debugPrint('[ADD_ACTIVITY] 🔄 Loading company related data: $companyId');

    // Load all company related data in parallel
    final futures = [
      _loadContactsForCompany(companyId),
      _loadCompanyBranches(companyId),
      _loadCompanyAddresses(companyId),
    ];

    try {
      await Future.wait(futures);

      // Reset dependent fields only if requested
      if (resetFields) {
        setState(() {
          _formData['ContactId'] = null;
          _formData['CompanyBranchId'] = null;
          _formData['AddressId'] = null;
          selectedBranch = null;
          _locationComparison = null;
        });
      }

      debugPrint('[ADD_ACTIVITY] ✅ Company related data loaded for: $companyId');
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Error loading company data: $e');
    }
  }

  Future<void> _loadContactsForCompany(int companyId) async {
    try {
      final contactField = _formModel!.getFieldByKey('ContactId');
      if (contactField == null || contactField.type != FormFieldType.dropdown) return;

      final contacts = await _activityApiService.loadContactsByCompany(companyId);
      setState(() {
        contactField.options = contacts;
      });
      debugPrint('[ADD_ACTIVITY] ✅ Loaded ${contacts.length} contacts');
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Failed to load contacts: $e');
    }
  }

  Future<void> _loadCompanyBranches(int companyId) async {
    try {
      final branchField = _formModel!.getFieldByKey('CompanyBranchId');
      debugPrint('[ADD_ACTIVITY] 🔍 Branch field check: ${branchField != null}');

      if (branchField == null) {
        debugPrint('[ADD_ACTIVITY] ❌ CompanyBranchId field is NULL!');
        return;
      }

      if (branchField.type != FormFieldType.dropdown) {
        debugPrint('[ADD_ACTIVITY] ❌ CompanyBranchId field is not dropdown! Type: ${branchField.type}');
        return;
      }

      debugPrint('[ADD_ACTIVITY] 🔍 Current options count: ${branchField.options?.length ?? 0}');

      debugPrint('[ADD_ACTIVITY] 🏢 Loading branches for company: $companyId');
      final branches = await _activityApiService.loadCompanyBranches(companyId: companyId);

      debugPrint('[ADD_ACTIVITY] 🔍 API returned ${branches.length} branches');
      if (branches.isNotEmpty) {
        debugPrint('[ADD_ACTIVITY] 🔍 First branch: ${branches.first.text} (ID: ${branches.first.value})');
      }

      setState(() {
        branchField.options = branches;
      });

      debugPrint('[ADD_ACTIVITY] 🔍 Field options after setState: ${branchField.options?.length ?? 0}');

      // Success/Warning messages
      if (branches.isNotEmpty) {
        debugPrint('[ADD_ACTIVITY] ✅ SUCCESS: ${branches.length} branches loaded');
        if (!isEditing) {
          SnackbarHelper.showSuccess(
            context: context,
            message: '${branches.length} şube yüklendi',
            duration: Duration(seconds: 1), // Kısa mesaj
          );
        }
      } else {
        debugPrint('[ADD_ACTIVITY] ⚠️ WARNING: No branches found for company $companyId');
        if (!isEditing) {
          SnackbarHelper.showWarning(
            context: context,
            message: 'Bu firma için şube bulunamadı',
            duration: Duration(seconds: 2),
          );
        }
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ CRITICAL ERROR in branch loading: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Şubeler yüklenemedi: ${e.toString()}',
      );
    }
  }

  Future<void> _loadBranchDetails(int companyId, int branchId) async {
    try {
      final branchDetails = await _activityApiService.getBranchDetails(
        companyId: companyId,
        branchId: branchId,
      );

      if (branchDetails != null && mounted) {
        setState(() {
          selectedBranch = branchDetails;
        });

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Şube seçildi: ${branchDetails.name}',
          duration: Duration(seconds: 1),
        );

        // Auto location comparison if current location exists
        if (_currentLocation != null && branchDetails.hasCoordinates) {
          await _compareWithSelectedBranch(branchDetails);
        }
      } else {
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Şube seçildi',
          duration: Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Failed to load branch details: $e');
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
  // LOCATION HANDLING
  // ===================

  Future<void> _getCurrentLocation() async {
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

        await _compareWithSelectedActivity();
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

  Future<void> _compareWithSelectedActivity() async {
    if (_currentLocation == null) return;

    setState(() => isComparingLocation = true);

    try {
      setState(() => _locationComparison = null);

      // 1. Editing mode - get coordinates from API
      if (isEditing && _currentActivityId != null) {
        final activityLocation = await _getActivityCoordinatesFromAPI();
        if (activityLocation != null) {
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
        }
      }

      // 2. Form branch selection comparison
      final branchId = _formData['CompanyBranchId'] as int?;
      final companyId = _formData['CompanyId'] as int?;

      if (branchId != null && companyId != null) {
        try {
          final branchDetails = await _activityApiService.getBranchDetails(
            companyId: companyId,
            branchId: branchId,
          );

          if (branchDetails != null && branchDetails.hasCoordinates) {
            await _compareWithSelectedBranch(branchDetails);
            return;
          }
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] ⚠️ Branch API error: $e');
        }
      }

      // 3. No coordinates available
      _showNoLocationMessage("Şube koordinat bilgisi mevcut değil");
    } catch (e) {
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
  // FILE HANDLING
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
  // SAVE & CLOSE - TAM DÜZELTİLMİŞ VERSİYON
  // ===================

  Future<void> _saveActivity() async {
    // 🚨 GLOBAL SAVE LOCK KONTROLÜ
    if (_globalSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 GLOBAL save already in progress, IGNORING!');
      return;
    }

    // 🚨 DUPLICATE SAVE KONTROLÜ
    if (_isSaving || _isSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 Instance save already in progress, ignoring...');
      return;
    }

    // 🚨 ALREADY SAVED KONTROLÜ - ÖNEMLİ!
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
      // 🔒 GLOBAL VE LOCAL LOCK
      _globalSaveInProgress = true;

      setState(() {
        _isSaving = true;
        _isSaveInProgress = true;
      });

      debugPrint('[ADD_ACTIVITY] 💾 SAVE PROCESS STARTING...');
      debugPrint('[ADD_ACTIVITY] 🔍 Is Editing: $isEditing');
      debugPrint('[ADD_ACTIVITY] 🔍 Activity ID: $_currentActivityId');
      debugPrint('[ADD_ACTIVITY] 🔒 GLOBAL and LOCAL save locks activated');

      if (!_validateRequiredFields()) {
        return; // Early return - finally block will handle cleanup
      }

      final processedData = _prepareFormDataForSave();

      debugPrint('[ADD_ACTIVITY] 🚀 Making API call...');
      final result = await _activityApiService.saveActivity(
        formData: processedData,
        activityId: _currentActivityId,
      );

      debugPrint('[ADD_ACTIVITY] ✅ API Save Result received');

      final newActivityId = result['Data']?['Id'] as int?;
      if (newActivityId != null && !isEditing) {
        debugPrint('[ADD_ACTIVITY] 🆔 New Activity Created - ID: $newActivityId');
        setState(() {
          _currentActivityId = newActivityId; // HEMEN SET ET
        });
      }

      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: isEditing ? '✅ Aktivite başarıyla güncellendi!' : '✅ Aktivite başarıyla kaydedildi! (ID: $newActivityId)',
          duration: Duration(seconds: 2),
        );

        // 🚨 IMMEDIATE CLOSE - Çoklu kayıt engellemek için hemen kapat
        await Future.delayed(Duration(milliseconds: 800)); // Kısa bekle

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
      // 🔒 CLEANUP - Her durumda çalışır
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

    // Auto-generate dates if missing
    if (preparedData['StartDate'] == null || preparedData['StartDate'].toString().isEmpty) {
      preparedData['StartDate'] =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    }

    if (preparedData['EndDate'] == null || preparedData['EndDate'].toString().isEmpty) {
      final endTime = now.add(const Duration(minutes: 30));
      preparedData['EndDate'] =
          '${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.${endTime.year} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    }

    // Set status for new activities
    if (!isEditing) {
      preparedData['OpenOrClose'] = "1";
    }

    // Add location data
    if (_currentLocation != null) {
      preparedData['StartLocation'] = _currentLocation!.coordinates;
      preparedData['StartLocationText'] = _currentLocation!.address;
    }

    // Clean empty values
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

  /// 🎯 Field bağımlılık yönetimi - Firma değiştiğinde şube seçeneklerini güncelle
  Future<void> onFieldDependencyChanged(String fieldKey, dynamic newValue) async {
    debugPrint('[ADD_ACTIVITY] 🔄 Field dependency changed: $fieldKey = $newValue');

    // 🚨 SAVE PROGRESS KONTROLÜ - Dependency loading'i engelle
    if (_isSaving || _isSaveInProgress || _globalSaveInProgress) {
      debugPrint('[ADD_ACTIVITY] 🚫 Save in progress - DEPENDENCY LOADING BLOCKED');
      return;
    }

    // 🚨 ALREADY SAVED KONTROLÜ
    if (_currentActivityId != null && _currentActivityId! > 0 && !isEditing) {
      debugPrint('[ADD_ACTIVITY] 🚫 Activity already saved (ID: $_currentActivityId) - DEPENDENCY LOADING BLOCKED');
      return;
    }

    // 🔧 SADECE FİRMA ALANI DEĞİŞTİĞİNDE ÇALIŞ - Diğer alanları ignore et
    if (fieldKey.toLowerCase() == 'companyid' ||
        (fieldKey.toLowerCase().contains('company') &&
            !fieldKey.toLowerCase().contains('branch') &&
            !fieldKey.toLowerCase().contains('sube') &&
            !fieldKey.toLowerCase().contains('şube'))) {
      debugPrint('[ADD_ACTIVITY] 🏢 Company dependency triggered: $newValue');

      if (newValue != null) {
        try {
          // Loading indicator göster
          if (mounted) {
            SnackbarHelper.showInfo(
              context: context,
              message: 'Şube seçenekleri yükleniyor...',
              duration: Duration(seconds: 1),
            );
          }

          // Şube seçeneklerini yükle
          await _loadCompanyBranches(newValue as int);

          // Diğer bağımlı alanları da yükle
          await Future.wait([
            _loadContactsForCompany(newValue),
            _loadCompanyAddresses(newValue),
          ]);

          debugPrint('[ADD_ACTIVITY] ✅ Company dependency completed for: $newValue');
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] ❌ Company dependency error: $e');

          if (mounted) {
            SnackbarHelper.showError(
              context: context,
              message: 'Firma bilgileri yüklenirken hata: ${e.toString()}',
            );
          }
        }
      }
    }

    // 🔧 DİĞER ALANLAR İÇİN HİÇBİR ŞEY YAPMA
    else {
      debugPrint('[ADD_ACTIVITY] ⚪ Field ignored for dependency: $fieldKey');
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

  // ===================
  // NAVIGATION PROTECTION
  // ===================

  Future<bool> _onWillPop() async {
    if (_isSaving || _isSaveInProgress || _globalSaveInProgress) {
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite kaydediliyor, lütfen bekleyin...',
        duration: Duration(seconds: 2),
      );
      return false; // Prevent back navigation
    }
    return true; // Allow back navigation
  }

  // ===================
  // UI BUILD
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

        // 🎯 Action Chips - SADECE EDİTİNG MODUNDA GÖSTER
        if (isEditing) ...[
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

        // Form Content
        Expanded(
          child: FormContentWidget(
            selectedAddress: _selectedAddress,
            currentLocation: _currentLocation,
            locationComparison: _locationComparison,
            attachedFiles: _attachedFiles,
            formModel: _formModel!,
            isSaving: _isSaving,
            isEditing: isEditing,
            isGettingLocation: _isGettingLocation,
            savedActivityId: _currentActivityId,
            onFormChanged: _onFormDataChanged,
            onFieldDependencyChanged: onFieldDependencyChanged,
            onFileDeleted: _onFileDeleted,
            onFileUploaded: _onFileUploaded,
            onRefreshLocation: _getCurrentLocation,
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
