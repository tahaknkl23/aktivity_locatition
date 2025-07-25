// lib/presentation/screens/activity/add_activity_screen.dart - DÜZELTILMIŞ ŞUBE ODAKLI VERSİYON
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

  // ✅ FormContentWidget reference - function callback ile
  Function()? _showFileOptionsHandler;
  VoidCallback? _refreshFilesHandler;

  // Form data
  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Action states
  bool _isGettingLocation = false;
  bool isUploadingFile = false;
  bool isComparingLocation = false;
  bool _isClosingActivity = false;

  // Data states
  LocationData? _currentLocation;
  final List<AttachmentFile> _attachedFiles = [];
  CompanyAddress? _selectedAddress;
  LocationComparisonResult? _locationComparison;

  // 🆕 Branch support
  CompanyBranchDetails? _selectedBranch;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  // Getters
  bool get isEditing => widget.activityId != null && widget.activityId! > 0;
  int? get savedActivityId => widget.activityId;

  // ====================
  // FORM LOADING METHODS
  // ====================

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final formModel = await _activityApiService.loadActivityForm(
        activityId: widget.activityId,
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

        if (widget.preSelectedCompanyId != null && !isEditing) {
          await _loadCompanyAddresses(widget.preSelectedCompanyId!);
          // 🆕 Load branches for pre-selected company
          await _loadCompanyBranches(widget.preSelectedCompanyId!);
        }

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

  void _onFormDataChanged(Map<String, dynamic> formData) {
    debugPrint('[ADD_ACTIVITY] 🔄 FORM DATA CHANGED CALLBACK:');
    debugPrint('[ADD_ACTIVITY] 🔍 Received data keys: ${formData.keys.toList()}');
    debugPrint('[ADD_ACTIVITY] 🔍 CompanyId in callback: ${formData['CompanyId']}');

    // ÖNCE state'i güncelle
    setState(() {
      _formData = formData;
    });

    debugPrint('[ADD_ACTIVITY] ✅ State updated, triggering cascade...');

    // SONRA cascade dropdown'ları handle et
    _handleCascadeDropdowns(formData);
  }

  Future<void> _handleCascadeDropdowns(Map<String, dynamic> formData) async {
    if (_formModel == null) {
      debugPrint('[ADD_ACTIVITY] ❌ Form model is null!');
      return;
    }

    debugPrint('[ADD_ACTIVITY] 🔄 FULL CASCADE DEBUG:');
    debugPrint('[ADD_ACTIVITY] 🔍 Form data keys: ${formData.keys.toList()}');
    debugPrint('[ADD_ACTIVITY] 🔍 CompanyId value: ${formData['CompanyId']}');
    debugPrint('[ADD_ACTIVITY] 🔍 CompanyId type: ${formData['CompanyId']?.runtimeType}');
    debugPrint('[ADD_ACTIVITY] 🔍 Current _formData: ${_formData['CompanyId']}');

    // 🔥 Firma seçilince
    if (formData.containsKey('CompanyId') && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      debugPrint('[ADD_ACTIVITY] 🏢 Company selected: $companyId');

      // Check if CompanyBranchId field exists
      final branchField = _formModel!.getFieldByKey('CompanyBranchId');
      debugPrint('[ADD_ACTIVITY] 🔍 CompanyBranchId field exists: ${branchField != null}');
      if (branchField != null) {
        debugPrint('[ADD_ACTIVITY] 🔍 CompanyBranchId field type: ${branchField.type}');
        debugPrint('[ADD_ACTIVITY] 🔍 CompanyBranchId current options: ${branchField.options?.length ?? 0}');
      }

      // 1. Load contacts for selected company
      debugPrint('[ADD_ACTIVITY] 📞 Loading contacts...');
      await _loadContactsForCompany(companyId);

      // 🆕 2. Load branches for selected company (eğer CompanyBranchId field'ı varsa)
      debugPrint('[ADD_ACTIVITY] 🏢 Loading branches...');
      await _loadCompanyBranches(companyId);

      // 3. Load company addresses
      debugPrint('[ADD_ACTIVITY] 🏠 Loading addresses...');
      await _loadCompanyAddresses(companyId);

      // 4. Reset dependent fields
      debugPrint('[ADD_ACTIVITY] 🔄 Resetting dependent fields...');
      setState(() {
        _formData['ContactId'] = null;
        _formData['CompanyBranchId'] = null; // 🆕 Reset branch selection
        _formData['AddressId'] = null;
        _selectedBranch = null; // 🆕 Clear selected branch
        _locationComparison = null; // 🆕 Clear previous comparison
      });

      debugPrint('[ADD_ACTIVITY] ✅ CASCADE COMPLETED for company: $companyId');
    } else {
      debugPrint('[ADD_ACTIVITY] ❌ CompanyId not found or null in form data');
    }

    // 🆕 Şube seçilince
    if (formData.containsKey('CompanyBranchId') && formData['CompanyBranchId'] != null && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final branchId = formData['CompanyBranchId'] as int;

      debugPrint('[ADD_ACTIVITY] 🏢 Branch selected: $branchId for company: $companyId');
      await _loadBranchDetails(companyId, branchId);
    }

    // Address seçilince (mevcut kod)
    if (formData.containsKey('AddressId') && formData['AddressId'] != null && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final addressId = formData['AddressId'] as int;
      debugPrint('[ADD_ACTIVITY] 🏠 Address selected: $addressId for company: $companyId');
      await _loadAddressDetails(companyId, addressId);
    }
  }

  Future<void> _loadCompanyBranches(int companyId) async {
    try {
      debugPrint('[ADD_ACTIVITY] 🔍 BRANCH LOADING START');
      debugPrint('[ADD_ACTIVITY] 🔍 Company ID: $companyId');

      final branchField = _formModel!.getFieldByKey('CompanyBranchId');
      if (branchField == null) {
        debugPrint('[ADD_ACTIVITY] ❌ CompanyBranchId field is NULL!');
        return;
      }

      if (branchField.type != FormFieldType.dropdown) {
        debugPrint('[ADD_ACTIVITY] ❌ CompanyBranchId field is not dropdown! Type: ${branchField.type}');
        return;
      }

      debugPrint('[ADD_ACTIVITY] ✅ CompanyBranchId field found and is dropdown');
      debugPrint('[ADD_ACTIVITY] 🏢 Loading branches for company: $companyId');

      final branches = await _activityApiService.loadCompanyBranches(companyId: companyId);

      debugPrint('[ADD_ACTIVITY] 📊 API returned ${branches.length} branches');

      if (branches.isNotEmpty) {
        debugPrint('[ADD_ACTIVITY] 🏢 First branch: ${branches.first.text} (ID: ${branches.first.value})');
      }

      setState(() {
        branchField.options = branches;
      });

      debugPrint('[ADD_ACTIVITY] ✅ Branch field options set: ${branchField.options?.length}');

      if (branches.isNotEmpty) {
        SnackbarHelper.showSuccess(
          context: context,
          message: '${branches.length} şube yüklendi',
        );
      } else {
        debugPrint('[ADD_ACTIVITY] ⚠️ No branches found for company: $companyId');
        SnackbarHelper.showWarning(
          context: context,
          message: 'Bu firma için şube bulunamadı',
        );
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ BRANCH LOADING ERROR: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Şubeler yüklenemedi: ${e.toString()}',
      );
    }
  }

  /// 🆕 Firma için kişileri yükle
  Future<void> _loadContactsForCompany(int companyId) async {
    try {
      final contactField = _formModel!.getFieldByKey('ContactId');
      if (contactField == null || contactField.type != FormFieldType.dropdown) {
        debugPrint('[ADD_ACTIVITY] ℹ️ ContactId field not found or not dropdown');
        return;
      }

      debugPrint('[ADD_ACTIVITY] 📞 Loading contacts for company: $companyId');

      final contacts = await _activityApiService.loadContactsByCompany(companyId);

      setState(() {
        contactField.options = contacts;
      });

      debugPrint('[ADD_ACTIVITY] ✅ Loaded ${contacts.length} contacts');
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Failed to load contacts: $e');
    }
  }

  /// 🆕 Şube detaylarını yükle
  Future<void> _loadBranchDetails(int companyId, int branchId) async {
    try {
      debugPrint('[ADD_ACTIVITY] 📍 Loading branch details - Company: $companyId, Branch: $branchId');

      final branchDetails = await _activityApiService.getBranchDetails(
        companyId: companyId,
        branchId: branchId,
      );

      if (branchDetails != null && mounted) {
        setState(() {
          _selectedBranch = branchDetails;
        });

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Şube seçildi: ${branchDetails.name}',
        );

        // 🎯 OTOMATIK KONUM KIYASLAMASI: Eğer mevcut konum varsa hemen kıyasla
        if (_currentLocation != null && branchDetails.hasCoordinates) {
          await _compareWithSelectedBranch(branchDetails);
        }
      } else {
        // Branch details henüz API'de implement edilmedi
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Şube seçildi',
        );
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Failed to load branch details: $e');
    }
  }

  /// 🆕 Seçilen şube ile konum kıyaslaması
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

      // Kıyaslama sonucunu oluştur
      LocationComparisonStatus status;
      String message;

      if (distance <= 100) {
        status = LocationComparisonStatus.atLocation;
        message = '✅ Seçilen şubede bulunuyorsunuz! (${distance.toStringAsFixed(0)}m)';
      } else if (distance <= 200) {
        status = LocationComparisonStatus.nearby;
        message = '📍 Şube yakınında (${distance.toStringAsFixed(0)}m)';
      } else if (distance <= 500) {
        status = LocationComparisonStatus.close;
        message = '🚶 Şubeden ${distance.toStringAsFixed(0)}m uzakta';
      } else if (distance < 1000) {
        status = LocationComparisonStatus.far;
        message = '🚗 Şubeden ${(distance / 1000).toStringAsFixed(1)}km uzakta';
      } else {
        status = LocationComparisonStatus.veryFar;
        message = '🌍 Şubeden ${(distance / 1000).toStringAsFixed(1)}km uzakta';
      }

      final result = LocationComparisonResult(
        status: status,
        message: message,
        distance: distance,
        companyLocation: LocationData(
          latitude: branch.latitude!,
          longitude: branch.longitude!,
          address: branch.name,
          timestamp: DateTime.now(),
        ),
      );

      if (mounted) {
        setState(() {
          _locationComparison = result;
        });

        SnackbarHelper.showInfo(
          context: context,
          message: result.message,
          backgroundColor: result.isAtSameLocation
              ? AppColors.success
              : result.isDifferentLocation
                  ? AppColors.warning
                  : AppColors.error,
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

      // Auto-select if only one address available
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
        );
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Failed to load address details: $e');
    }
  }

  Future<void> _loadExistingFiles() async {
    if (savedActivityId == null) return;

    try {
      debugPrint('[ADD_ACTIVITY] Loading existing files for activity: $savedActivityId');

      final response = await FileService.instance.getActivityFiles(
        activityId: savedActivityId!,
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

  // ==================
  // LOCATION METHODS - 🆕 DÜZELTILMIŞ ŞUBE ODAKLI VERSİYON
  // ==================

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
        );

        // 🆕 ŞUBE ODAKLI KONUM KIYASLAMASI
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

  /// 🆕 DÜZELTME: Aktivite ID kontrolü ile doğru koordinatı kullan
  Future<void> _compareWithSelectedActivity() async {
    if (_currentLocation == null) return;

    setState(() => isComparingLocation = true);

    try {
      debugPrint('[ADD_ACTIVITY] 🎯 ŞUBE KIYASLAMASI BAŞLIYOR...');
      debugPrint('[ADD_ACTIVITY] 🔍 Current Activity ID: ${widget.activityId}');

      // 🔄 Önce eski kıyaslamayı temizle
      setState(() {
        _locationComparison = null;
      });

      // 1. ÖNCE: JSON'dan şube koordinatını al (editing mode'da)
      if (isEditing && widget.activityId != null) {
        debugPrint('[ADD_ACTIVITY] 📍 Editing mode - JSON şube koordinatı kullanılıyor...');
        debugPrint('[ADD_ACTIVITY] 🔍 Aranan Activity ID: ${widget.activityId}');

        final activityLocation = await _getActivityCoordinatesFromAPI();
        if (activityLocation != null) {
          debugPrint('[ADD_ACTIVITY] ✅ JSON koordinatı bulundu: ${activityLocation.latitude}, ${activityLocation.longitude}');
          debugPrint('[ADD_ACTIVITY] 🏢 Bulunan şube: ${activityLocation.address}');

          final distance = LocationService.instance.calculateDistance(
            _currentLocation!.latitude,
            _currentLocation!.longitude,
            activityLocation.latitude,
            activityLocation.longitude,
          );

          debugPrint('[ADD_ACTIVITY] 📏 Hesaplanan mesafe: ${distance.toStringAsFixed(2)}m');

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
            );
          }
          return;
        } else {
          debugPrint('[ADD_ACTIVITY] ❌ JSON koordinatı bulunamadı!');
        }
      }

      // 2. SONRA: Form'dan seçili şube ID'si ile kıyaslama dene
      final branchId = _formData['CompanyBranchId'] as int?;
      final companyId = _formData['CompanyId'] as int?;

      if (branchId != null && companyId != null) {
        debugPrint('[ADD_ACTIVITY] 🏢 Form şube seçimi ile kıyaslama deneniyor: Company=$companyId, Branch=$branchId');

        // Şube detayını al ve kıyasla (eğer API çalışıyorsa)
        try {
          final branchDetails = await _activityApiService.getBranchDetails(
            companyId: companyId,
            branchId: branchId,
          );

          if (branchDetails != null && branchDetails.hasCoordinates) {
            debugPrint('[ADD_ACTIVITY] ✅ API şube koordinatı bulundu, kıyaslanıyor...');
            await _compareWithSelectedBranch(branchDetails);
            return;
          }
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] ⚠️ Branch API hatası: $e');
        }
      }

      // 3. Son çare: Hiçbir koordinat yoksa uyarı ver
      debugPrint('[ADD_ACTIVITY] ❌ Hiçbir şube koordinatı bulunamadı');
      _showNoLocationMessage("Şube koordinat bilgisi mevcut değil");
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Konum kıyaslaması hatası: $e');
      _showErrorMessage("Konum kıyaslaması yapılamadı: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isComparingLocation = false);
      }
    }
  }

  /// 🆕 Konum bulunamadığında bilgi mesajı göster
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

      SnackbarHelper.showWarning(
        context: context,
        message: message,
      );
    }
  }

  /// 🆕 Hata mesajı göster
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

      SnackbarHelper.showError(
        context: context,
        message: message,
      );
    }
  }

  /// 🆕 DÜZELTME: Doğru aktiviteyi bul ve debug bilgilerini artır
  Future<LocationData?> _getActivityCoordinatesFromAPI() async {
    try {
      if (widget.activityId == null) {
        debugPrint('[ADD_ACTIVITY] ❌ Activity ID null');
        return null;
      }

      final targetActivityId = widget.activityId!;
      debugPrint('[ADD_ACTIVITY] 🔍 API\'den aktivite detayları alınıyor...');
      debugPrint('[ADD_ACTIVITY] 🔍 Aranan Activity ID: $targetActivityId');

      ActivityListItem? targetActivity;

      // 1. Önce AÇIK aktivitelerden ara
      try {
        debugPrint('[ADD_ACTIVITY] 🔍 Açık aktiviteler listesinde aranıyor...');

        final openActivities = await _activityApiService.getActivityList(
          filter: ActivityFilter.open,
          page: 1,
          pageSize: 100,
        );

        debugPrint('[ADD_ACTIVITY] 📊 Açık aktiviteler: ${openActivities.data.length}');

        for (final activity in openActivities.data) {
          debugPrint('[ADD_ACTIVITY] 🔍 Kontrol edilen ID: ${activity.id} (aranan: $targetActivityId)');
          if (activity.id == targetActivityId) {
            targetActivity = activity;
            debugPrint('[ADD_ACTIVITY] ✅ Açık aktiviteler listesinde bulundu!');
            break;
          }
        }
      } catch (e) {
        debugPrint('[ADD_ACTIVITY] ⚠️ Açık aktiviteler araması hatası: $e');
      }

      // 2. Açık aktivitelerde bulunamadıysa KAPALI aktivitelerden ara
      if (targetActivity == null) {
        try {
          debugPrint('[ADD_ACTIVITY] 🔍 Kapalı aktiviteler listesinde aranıyor...');

          final closedActivities = await _activityApiService.getActivityList(
            filter: ActivityFilter.closed,
            page: 1,
            pageSize: 100,
          );

          debugPrint('[ADD_ACTIVITY] 📊 Kapalı aktiviteler: ${closedActivities.data.length}');

          for (final activity in closedActivities.data) {
            debugPrint('[ADD_ACTIVITY] 🔍 Kontrol edilen ID: ${activity.id} (aranan: $targetActivityId)');
            if (activity.id == targetActivityId) {
              targetActivity = activity;
              debugPrint('[ADD_ACTIVITY] ✅ Kapalı aktiviteler listesinde bulundu!');
              break;
            }
          }
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] ⚠️ Kapalı aktiviteler araması hatası: $e');
        }
      }

      // 3. Son çare: TÜM aktivitelerden ara
      if (targetActivity == null) {
        try {
          debugPrint('[ADD_ACTIVITY] 🔍 Tüm aktiviteler listesinde aranıyor...');

          final allActivities = await _activityApiService.getActivityList(
            filter: ActivityFilter.all,
            page: 1,
            pageSize: 100,
          );

          debugPrint('[ADD_ACTIVITY] 📊 Tüm aktiviteler: ${allActivities.data.length}');

          for (final activity in allActivities.data) {
            debugPrint('[ADD_ACTIVITY] 🔍 Kontrol edilen ID: ${activity.id} (aranan: $targetActivityId)');
            if (activity.id == targetActivityId) {
              targetActivity = activity;
              debugPrint('[ADD_ACTIVITY] ✅ Tüm aktiviteler listesinde bulundu!');
              break;
            }
          }
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] ⚠️ Tüm aktiviteler araması hatası: $e');
        }
      }

      if (targetActivity == null) {
        debugPrint('[ADD_ACTIVITY] ❌ Aktivite hiçbir listede bulunamadı: $targetActivityId');
        return null;
      }

      debugPrint('[ADD_ACTIVITY] ✅ DOĞRU AKTİVİTE BULUNDU:');
      debugPrint('[ADD_ACTIVITY]   - ID: ${targetActivity.id} (aranan: $targetActivityId)');
      debugPrint('[ADD_ACTIVITY]   - Firma: ${targetActivity.firma}');
      debugPrint('[ADD_ACTIVITY]   - Şube: ${targetActivity.sube}');
      debugPrint('[ADD_ACTIVITY]   - Koordinat: "${targetActivity.konum}"');

      if (targetActivity.hasValidCoordinates) {
        final (lat, lng) = targetActivity.parsedCoordinates;
        if (lat != null && lng != null) {
          debugPrint('[ADD_ACTIVITY] ✅ Koordinat parse edildi: $lat, $lng');

          return LocationData(
            latitude: lat,
            longitude: lng,
            address: targetActivity.displaySube,
            timestamp: DateTime.now(),
          );
        }
      }

      debugPrint('[ADD_ACTIVITY] ❌ Koordinat parse edilemedi veya geçersiz');
      debugPrint('[ADD_ACTIVITY] 🔍 hasValidCoordinates: ${targetActivity.hasValidCoordinates}');
      debugPrint('[ADD_ACTIVITY] 🔍 hasKonum: ${targetActivity.hasKonum}');

      return null;
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ API koordinat alma hatası: $e');
      return null;
    }
  }

  /// 🆕 YENİ METOD: Konum kıyaslama sonucu oluştur
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

  /// 🆕 YENİ METOD: Konum durumuna göre renk
  Color _getLocationStatusColor(LocationComparisonResult result) {
    switch (result.status) {
      case LocationComparisonStatus.atLocation:
        return AppColors.success;
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

  // ================
  // FILE METHODS - ✅ CLEAN VERSION (UNCHANGED)
  // ================

  /// ✅ File options bottom sheet'i göster
  void _showFileOptions() {
    debugPrint('[ADD_ACTIVITY] 🚀 _showFileOptions called');

    if (savedActivityId == null) {
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
      return;
    }

    // Registered handler'ı kullan
    if (_showFileOptionsHandler != null) {
      _showFileOptionsHandler!();
    } else {
      // Fallback - direct bottom sheet
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

  /// 🔄 Fallback file upload method
  Future<void> _fallbackFileUpload(Future<FileData?> Function() captureFunction) async {
    try {
      debugPrint('[ADD_ACTIVITY] 🔄 Fallback file upload starting');

      final fileData = await captureFunction();
      if (fileData == null) return;

      debugPrint('[ADD_ACTIVITY] 📤 Fallback upload: ${fileData.name}');

      SnackbarHelper.showInfo(
        context: context,
        message: 'Dosya yükleniyor: ${fileData.name}',
      );

      final response = await FileService.instance.uploadActivityFile(
        activityId: savedActivityId!,
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

        debugPrint('[ADD_ACTIVITY] ✅ Fallback upload successful');
      } else {
        throw FileException(response.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ Fallback upload error: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya yüklenemedi: ${e.toString()}',
      );
    }
  }

  /// ✅ File uploaded callback
  void _onFileUploaded(AttachmentFile file) {
    debugPrint('[ADD_ACTIVITY] ✅ File uploaded: ${file.fileName}');

    // State listesine ekle (duplicate check)
    if (!_attachedFiles.any((f) => f.id == file.id)) {
      setState(() {
        _attachedFiles.add(file);
      });
      debugPrint('[ADD_ACTIVITY] ✅ File added to state list');
    }

    // FormContent'e refresh sinyali gönder
    _refreshFormContentFiles();
  }

  /// ✅ File deleted callback
  void _onFileDeleted(AttachmentFile file) {
    debugPrint('[ADD_ACTIVITY] 🗑️ File deleted: ${file.fileName}');

    setState(() {
      _attachedFiles.removeWhere((f) => f.id == file.id);
    });

    // FormContent'e refresh sinyali gönder
    _refreshFormContentFiles();
  }

  /// 🔄 FormContent file listesini refresh et
  void _refreshFormContentFiles() {
    try {
      if (_refreshFilesHandler != null) {
        _refreshFilesHandler!();
        debugPrint('[ADD_ACTIVITY] ✅ FormContent file list refreshed via handler');
      } else {
        debugPrint('[ADD_ACTIVITY] ⚠️ No refresh handler registered');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] ❌ FormContent refresh error: $e');
    }
  }

  // =================
  // ACTIVITY METHODS (UNCHANGED)
  // =================

  Future<void> _saveActivity() async {
    try {
      setState(() => _isSaving = true);

      if (!_validateRequiredFields()) {
        setState(() => _isSaving = false);
        return;
      }

      final cleanedData = _cleanFormData();
      _ensureRequiredFields(cleanedData);

      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: isEditing ? 'Aktivite başarıyla güncellendi!' : 'Aktivite başarıyla kaydedildi!',
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Kaydetme sırasında hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  bool _validateRequiredFields() {
    if (_formData['ActivityType'] == null || _formData['ActivityType'].toString().isEmpty) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite tipi seçimi zorunludur',
      );
      return false;
    }
    return true;
  }

  Map<String, dynamic> _cleanFormData() {
    final cleanedData = <String, dynamic>{};
    for (final entry in _formData.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        cleanedData[entry.key] = entry.value;
      }
    }
    return cleanedData;
  }

  void _ensureRequiredFields(Map<String, dynamic> data) {
    if (!isEditing) {
      final now = DateTime.now();
      if (data['StartDate'] == null) {
        data['StartDate'] =
            '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      }
      if (data['EndDate'] == null) {
        final endTime = now.add(const Duration(minutes: 30));
        data['EndDate'] =
            '${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.${endTime.year} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      }
      data['OpenOrClose'] = 1;
    }
  }

  Future<void> _closeActivity() async {
    if (_currentLocation == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktiviteyi kapatmak için önce konum bilgisi gereklidir',
      );
      return;
    }

    final shouldClose = await _showCloseActivityDialog();
    if (!shouldClose) return;

    setState(() => _isClosingActivity = true);

    try {
      // TODO: Implement close activity API call
      await Future.delayed(Duration(seconds: 2));

      if (mounted) {
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Aktivite başarıyla kapatıldı!',
        );

        await Future.delayed(Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isClosingActivity = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Aktivite kapatılamadı: ${e.toString()}',
        );
      }
    }
  }

  Future<bool> _showCloseActivityDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => CloseActivityDialog(),
        ) ??
        false;
  }

  // ===============
  // UI BUILD METHODS (UNCHANGED)
  // ===============

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
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
          activityId: widget.activityId,
          onBack: () => Navigator.of(context).pop(),
        ),

        // Action Chips
        ActivityActionChipsWidget(
          isEditing: isEditing,
          savedActivityId: savedActivityId,
          currentLocation: _currentLocation,
          locationComparison: _locationComparison,
          attachedFiles: _attachedFiles,
          isGettingLocation: _isGettingLocation,
          isClosingActivity: _isClosingActivity,
          onGetLocation: _getCurrentLocation,
          onShowFileOptions: _showFileOptions,
          onCloseActivity: _closeActivity,
        ),

        // Form Content - ✅ Callback registration
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
            savedActivityId: savedActivityId,
            onFormChanged: _onFormDataChanged,
            onFileDeleted: _onFileDeleted,
            onFileUploaded: _onFileUploaded,
            onRefreshLocation: _getCurrentLocation,
            // ✅ Handler registration
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
