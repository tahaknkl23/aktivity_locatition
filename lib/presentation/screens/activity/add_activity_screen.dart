// lib/presentation/screens/activity/add_activity_screen.dart
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

  // Form data
  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Action states
  bool _isGettingLocation = false;
  bool _isUploadingFile = false;
  bool _isComparingLocation = false;
  bool _isClosingActivity = false;

  // Data states
  LocationData? _currentLocation;
  final List<AttachmentFile> _attachedFiles = [];
  CompanyAddress? _selectedAddress;
  LocationComparisonResult? _locationComparison;

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
    setState(() {
      _formData = formData;
    });
    _handleCascadeDropdowns(formData);
  }

  Future<void> _handleCascadeDropdowns(Map<String, dynamic> formData) async {
    if (_formModel == null) return;

    if (formData.containsKey('CompanyId') && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;

      // Load contacts for selected company
      final contactField = _formModel!.getFieldByKey('ContactId');
      if (contactField != null && contactField.type == FormFieldType.dropdown) {
        try {
          final contacts = await _activityApiService.loadContactsByCompany(companyId);
          setState(() {
            contactField.options = contacts;
            _formData['ContactId'] = null;
          });
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] Failed to load contacts: $e');
        }
      }

      // Load company addresses
      await _loadCompanyAddresses(companyId);
    }

    if (formData.containsKey('AddressId') && formData['AddressId'] != null && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final addressId = formData['AddressId'] as int;
      await _loadAddressDetails(companyId, addressId);
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
  // LOCATION METHODS
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

        // Auto-compare if company is selected
        if (_formData['CompanyId'] != null) {
          await _compareWithCompanyLocation();
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

  Future<void> _compareWithCompanyLocation() async {
    if (_currentLocation == null || _formData['CompanyId'] == null) return;

    setState(() => _isComparingLocation = true);

    try {
      final result = await _activityApiService.compareLocations(
        companyId: _formData['CompanyId'] as int,
        currentLat: _currentLocation!.latitude,
        currentLng: _currentLocation!.longitude,
        toleranceInMeters: 100.0,
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
      debugPrint('[ADD_ACTIVITY] Location comparison error: $e');
      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Konum kıyaslaması yapılamadı: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isComparingLocation = false);
      }
    }
  }

  // ================
  // FILE METHODS
  // ================

  void _showFileOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FileOptionsBottomSheet(
        onFileCapture: _handleFileCapture,
      ),
    );
  }

  Future<void> _handleFileCapture(Future<FileData?> Function() captureFunction) async {
    setState(() => _isUploadingFile = true);

    try {
      final fileData = await captureFunction();
      if (fileData != null) {
        await _uploadFile(fileData);
      }
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya işlemi başarısız: ${e.toString()}',
      );
    } finally {
      setState(() => _isUploadingFile = false);
    }
  }

  Future<void> _uploadFile(FileData fileData) async {
    if (savedActivityId == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite kaydedilmeden dosya yüklenemez',
      );
      return;
    }

    try {
      // TODO: FileService.instance.uploadActivityFile implementasyonunu kontrol et
      final mockFile = AttachmentFile(
        id: DateTime.now().millisecondsSinceEpoch,
        fileName: fileData.name,
        localName: fileData.name,
        fileType: fileData.isImage ? 0 : 1,
        createdUserName: 'Current User',
        createdDate: DateTime.now().toIso8601String(),
        formName: 'Aktivite',
      );

      setState(() {
        _attachedFiles.add(mockFile);
      });

      SnackbarHelper.showSuccess(
        context: context,
        message: 'Dosya eklendi (API bağlantısı gerekli)',
      );
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Upload error: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya yüklenemedi: ${e.toString()}',
      );
    }
  }

  void _onFileDeleted(AttachmentFile file) {
    setState(() {
      _attachedFiles.removeWhere((f) => f.id == file.id);
    });
    debugPrint('[ADD_ACTIVITY] File deleted: ${file.fileName}');
  }

  void _onFileUploaded(AttachmentFile file) {
    setState(() {
      _attachedFiles.add(file);
    });
    debugPrint('[ADD_ACTIVITY] File uploaded: ${file.fileName}');
  }

  // =================
  // ACTIVITY METHODS
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

      final result = await _activityApiService.saveActivity(
        formData: cleanedData,
        activityId: widget.activityId,
      );

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
  // UI BUILD METHODS
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
            savedActivityId: savedActivityId,
            onFormChanged: _onFormDataChanged,
            onFileDeleted: _onFileDeleted,
            onFileUploaded: _onFileUploaded,
            onRefreshLocation: _getCurrentLocation,
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
