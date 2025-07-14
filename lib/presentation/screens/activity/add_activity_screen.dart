import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/services/api/activity_api_service.dart';

class AddActivityScreen extends StatefulWidget {
  final int? activityId; // For editing existing activity
  final int? preSelectedCompanyId; // Pre-select company if coming from company screen

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

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  bool get isEditing => widget.activityId != null && widget.activityId! > 0;

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('[ADD_ACTIVITY] Loading form data - Activity ID: ${widget.activityId}');

      final formModel = await _activityApiService.loadActivityForm(
        activityId: widget.activityId,
      );

      // Load dropdown options
      await _loadDropdownOptions(formModel);

      if (mounted) {
        setState(() {
          _formModel = formModel;
          _formData = Map<String, dynamic>.from(formModel.data);

          // Pre-select company if provided
          if (widget.preSelectedCompanyId != null && !isEditing) {
            _formData['CompanyId'] = widget.preSelectedCompanyId;
            debugPrint('[ADD_ACTIVITY] Pre-selected company: ${widget.preSelectedCompanyId}');
          }

          _isLoading = false;
        });

        debugPrint('[ADD_ACTIVITY] Form loaded successfully');
        debugPrint('[ADD_ACTIVITY] Form sections: ${formModel.sections.length}');
        debugPrint('[ADD_ACTIVITY] Form data keys: ${_formData.keys.toList()}');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Load form error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadDropdownOptions(DynamicFormModel formModel) async {
    try {
      debugPrint('[ADD_ACTIVITY] Loading dropdown options');

      // Load dropdown options for all dropdown fields dynamically
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
              debugPrint('[ADD_ACTIVITY] Loaded ${options.length} options for ${field.label} (${field.key})');

              // Log first few options for debugging
              if (options.isNotEmpty) {
                final preview = options.take(3).map((o) => '${o.value}: ${o.text}').join(', ');
                debugPrint('[ADD_ACTIVITY] Options preview for ${field.key}: $preview');
              }
            } catch (e) {
              debugPrint('[ADD_ACTIVITY] Failed to load options for ${field.label}: $e');
              field.options = [];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Load dropdown options error: $e');
    }
  }

  void _onFormDataChanged(Map<String, dynamic> formData) {
    setState(() {
      _formData = formData;
    });
    debugPrint('[ADD_ACTIVITY] Form data updated: ${formData.keys.length} fields');

    // Handle cascade dropdowns
    _handleCascadeDropdowns(formData);
  }

  Future<void> _handleCascadeDropdowns(Map<String, dynamic> formData) async {
    if (_formModel == null) return;

    // Company changed - reload contacts
    if (formData.containsKey('CompanyId') && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final contactField = _formModel!.getFieldByKey('ContactId');

      if (contactField != null && contactField.type == FormFieldType.dropdown) {
        try {
          debugPrint('[ADD_ACTIVITY] Loading contacts for company: $companyId');

          final contacts = await _activityApiService.loadContactsByCompany(companyId);

          setState(() {
            contactField.options = contacts;
            // Clear previous contact selection
            _formData['ContactId'] = null;
          });

          debugPrint('[ADD_ACTIVITY] Loaded ${contacts.length} contacts for company $companyId');
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] Failed to load contacts: $e');
        }
      }
    }
  }

  Future<void> _saveActivity() async {
    try {
      setState(() {
        _isSaving = true;
      });

      debugPrint('[ADD_ACTIVITY] Saving activity data...');
      debugPrint('[ADD_ACTIVITY] Form data: ${_formData.keys.toList()}');

      // Validate required fields
      if (!_validateRequiredFields()) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Clean form data - remove null/empty values
      final cleanedData = <String, dynamic>{};
      for (final entry in _formData.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          cleanedData[entry.key] = entry.value;
        }
      }

      // Ensure required fields are set
      _ensureRequiredFields(cleanedData);

      final result = await _activityApiService.saveActivity(
        formData: cleanedData,
        activityId: widget.activityId,
      );

      if (mounted) {
        debugPrint('[ADD_ACTIVITY] Save result: $result');

        // Show success message
        SnackbarHelper.showSuccess(
          context: context,
          message: isEditing ? 'Aktivite başarıyla güncellendi!' : 'Aktivite başarıyla kaydedildi!',
        );

        // Wait a moment then go back
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Save error: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        SnackbarHelper.showError(
          context: context,
          message: 'Kaydetme sırasında hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  bool _validateRequiredFields() {
    final requiredFields = ['ActivityType']; // ActivityType is required in API
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (_formData[field] == null || _formData[field].toString().isEmpty) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite tipi seçimi zorunludur',
      );
      return false;
    }

    return true;
  }

  void _ensureRequiredFields(Map<String, dynamic> data) {
    // Set default values if not set
    if (!isEditing) {
      // For new activities, set default dates if not set
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

      // Set default OpenOrClose to 1 (Open)
      data['OpenOrClose'] = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_formModel == null) {
      return _buildEmptyState();
    }

    return DynamicFormWidget(
      formModel: _formModel!,
      onFormChanged: _onFormDataChanged,
      onSave: _saveActivity,
      isLoading: _isSaving,
      isEditing: isEditing,
    );
  }

  Widget _buildLoadingState() {
    final size = AppSizes.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(size.cardPadding * 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(size.cardBorderRadius * 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: size.largeSpacing),
                Text(
                  isEditing ? 'Aktivite bilgileri yükleniyor...' : 'Form yükleniyor...',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  'Lütfen bekleyin',
                  style: TextStyle(
                    fontSize: size.textSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final size = AppSizes.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding * 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(size.cardBorderRadius * 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(size.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  Text(
                    'Form Yüklenemedi',
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: size.smallSpacing),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.textSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textSecondary),
                        ),
                        child: const Text('Geri Dön'),
                      ),
                      SizedBox(width: size.mediumSpacing),
                      ElevatedButton(
                        onPressed: _loadFormData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final size = AppSizes.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              'Form bulunamadı',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              'Aktivite form verisi alınamadı. Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
