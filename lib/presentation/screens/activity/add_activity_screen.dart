// lib/presentation/screens/activity/add_activity_screen_refactored.dart - FIXED
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../core/widgets/common/loading_state_widget.dart';
import '../../../core/widgets/common/error_state_widget.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/services/api/activity_api_service.dart';
import '../../widgets/activity/location_management_widget.dart';
import '../../widgets/activity/address_info_widget.dart';
import '../../../data/models/attachment/attachment_file_model.dart';

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

  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Address management
  CompanyAddress? _selectedAddress;

  // 📎 File management
  final List<AttachmentFile> _attachedFiles = [];
  int? savedActivityId;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  bool get isEditing => widget.activityId != null && widget.activityId! > 0;

  // 🔄 Form verilerini yükle
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

          // Pre-select company if provided
          if (widget.preSelectedCompanyId != null && !isEditing) {
            _formData['CompanyId'] = widget.preSelectedCompanyId;
          }

          // Set saved activity ID for file uploads
          if (isEditing) {
            savedActivityId = widget.activityId;
          }

          _isLoading = false;
        });

        // Load addresses if company is pre-selected
        if (widget.preSelectedCompanyId != null && !isEditing) {
          await _loadCompanyAddresses(widget.preSelectedCompanyId!);
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

  // 📦 Dropdown seçeneklerini yükle
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

  // 📝 Form verisi değiştiğinde
  void _onFormDataChanged(Map<String, dynamic> formData) {
    setState(() {
      _formData = formData;
    });
    _handleCascadeDropdowns(formData);
  }

  // 🔄 Cascade dropdown yönetimi
  Future<void> _handleCascadeDropdowns(Map<String, dynamic> formData) async {
    if (_formModel == null) return;

    // Company changed - reload contacts and addresses
    if (formData.containsKey('CompanyId') && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;

      // Load contacts
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

      // Load addresses
      await _loadCompanyAddresses(companyId);
    }

    // Address selection changed
    if (formData.containsKey('AddressId') && formData['AddressId'] != null && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final addressId = formData['AddressId'] as int;
      await _loadAddressDetails(companyId, addressId);
    }
  }

  // 🏢 Firma adreslerini yükle
  Future<void> _loadCompanyAddresses(int companyId) async {
    try {
      final addresses = await _activityApiService.getActivityAddressOptions(
        companyId: companyId,
      );

      setState(() {
        _formData['AddressId'] = null;
        _selectedAddress = null;
      });

      // Update form model address field
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
      setState(() {});
      SnackbarHelper.showError(
        context: context,
        message: 'Firma adresleri yüklenemedi: ${e.toString()}',
      );
    }
  }

  // 📍 Adres detaylarını yükle
  Future<void> _loadAddressDetails(int companyId, int addressId) async {
    try {
      final address = await _activityApiService.getSelectedAddressDetails(
        companyId: companyId,
        addressId: addressId,
      );

      if (address != null && mounted) {
        setState(() {
          _selectedAddress = address;
          _formData['AddressText'] = address.displayAddress;
          _formData['AddressFullText'] = address.fullAddress;
          _formData['AddressType'] = address.tipi;
          _formData['City'] = address.il;
          _formData['District'] = address.ilce;
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

  // 📍 Konum güncellendiğinde
  void _onLocationUpdated(Map<String, dynamic> updatedFormData) {
    setState(() {
      _formData = updatedFormData;
    });
  }

  // 📎 File upload callbacks
  void onFileUploaded(AttachmentFile file) {
    setState(() {
      _attachedFiles.add(file);
    });
    SnackbarHelper.showSuccess(
      context: context,
      message: 'Dosya yüklendi: ${file.fileName}',
    );
  }

  void onFileDeleted(AttachmentFile file) {
    setState(() {
      _attachedFiles.removeWhere((f) => f.id == file.id);
    });
    SnackbarHelper.showInfo(
      context: context,
      message: 'Dosya silindi: ${file.fileName}',
    );
  }

  // 🔒 Aktiviteyi kapat
  Future<void> _closeActivity() async {
    if (_formData['Location'] == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktiviteyi kapatmak için önce konum bilgisi gereklidir',
      );
      return;
    }

    final shouldClose = await _showCloseActivityDialog();
    if (!shouldClose) return;

    try {
      // TODO: Close activity API call
      SnackbarHelper.showSuccess(
        context: context,
        message: 'Aktivite başarıyla kapatıldı!',
      );

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite kapatılamadı: ${e.toString()}',
      );
    }
  }

  // ❓ Kapatma onay dialogu
  Future<bool> _showCloseActivityDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.close_outlined, color: AppColors.warning),
                SizedBox(width: 8),
                Text('Aktiviteyi Kapat'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bu aktiviteyi kapatmak istediğinizden emin misiniz?'),
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.info, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Kapatılan aktiviteler tekrar açılamaz',
                          style: TextStyle(fontSize: 14, color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warning,
                  foregroundColor: Colors.white,
                ),
                child: Text('Kapat'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // 💾 Aktiviteyi kaydet
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
        // Set saved activity ID for file uploads if this is a new activity
        if (!isEditing && result['Data']?['Id'] != null) {
          setState(() {
            savedActivityId = result['Data']['Id'] as int;
          });
        }

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

  // ✅ Form doğrulama
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

  // 🧹 Form verilerini temizle
  Map<String, dynamic> _cleanFormData() {
    final cleanedData = <String, dynamic>{};
    for (final entry in _formData.entries) {
      if (entry.value != null && entry.value.toString().isNotEmpty) {
        cleanedData[entry.key] = entry.value;
      }
    }
    return cleanedData;
  }

  // ⚙️ Gerekli alanları ayarla
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
      data['OpenOrClose'] = 1; // Open by default
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: buildBody(),
    );
  }

  Widget buildBody() {
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

    return Stack(
      children: [
        // Ana form içeriği
        Column(
          children: [
            Expanded(
              child: DynamicFormWidget(
                formModel: _formModel!,
                onFormChanged: _onFormDataChanged,
                onSave: null, // Kaydet butonunu gizle
                isLoading: _isSaving,
                isEditing: isEditing,
              ),
            ),
          ],
        ),

        // 🔧 FIX: Custom footer with built-in close button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(12), // Küçültüldü
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8, // Küçültüldü
                  offset: Offset(0, -1), // Küçültüldü
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 📎 Additional content (file upload, address, location) - KOMPAKT
                  if (_buildAdditionalContent() != null)
                    Padding(
                      padding: EdgeInsets.only(bottom: 12), // Küçültüldü
                      child: _buildAdditionalContent()!,
                    ),

                  // Action buttons - KOMPAKT
                  Row(
                    children: [
                      // Cancel button - küçük
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: AppColors.textSecondary),
                            padding: EdgeInsets.symmetric(vertical: 12), // Küçültüldü
                          ),
                          child: Text(
                            'İptal',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14, // Küçültüldü
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 12), // Küçültüldü

                      // Save button - küçük
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveActivity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12), // Küçültüldü
                            elevation: 3,
                          ),
                          child: _isSaving
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 16, // Küçültüldü
                                      width: 16, // Küçültüldü
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Text('Kaydediliyor...', style: TextStyle(fontSize: 14)),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(isEditing ? Icons.update : Icons.save, size: 18), // Küçültüldü
                                    SizedBox(width: 6),
                                    Text(
                                      isEditing ? 'Güncelle' : 'Kaydet',
                                      style: TextStyle(
                                        fontSize: 14, // Küçültüldü
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 📍 Ek içerik (dosya + adres + konum) - KOMPAKT
  Widget? _buildAdditionalContent() {
    return Column(
      children: [
        // 📎 KOMPAKT DOSYA UPLOAD BUTONU
        Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Dosya seç butonu
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Dosya seç
                    print('Dosya seç');
                  },
                  icon: Icon(Icons.attach_file, size: 18),
                  label: Text('Dosya Ekle', style: TextStyle(fontSize: 13)),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    side: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Yüklenen dosyalar sayısı (varsa)
        if (_attachedFiles.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_attachedFiles.length} dosya eklendi',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.success,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

        // Seçilen adres bilgisi (kompakt)
        if (_selectedAddress != null)
          Container(
            margin: EdgeInsets.only(bottom: 8),
            child: AddressInfoWidget(address: _selectedAddress!),
          ),

        // Konum yönetimi
        LocationManagementWidget(
          formData: _formData,
          onLocationUpdated: _onLocationUpdated,
          isEditing: isEditing,
          onActivityClose: _closeActivity,
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
