import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/services/api/company_api_service.dart';

class AddCompanyScreen extends StatefulWidget {
  final int? companyId; // For editing existing company

  const AddCompanyScreen({
    super.key,
    this.companyId,
  });

  @override
  State<AddCompanyScreen> createState() => _AddCompanyScreenState();
}

class _AddCompanyScreenState extends State<AddCompanyScreen> {
  final CompanyApiService _companyApiService = CompanyApiService();

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

  bool get isEditing => widget.companyId != null && widget.companyId! > 0;

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('[ADD_COMPANY] Loading form data - Company ID: ${widget.companyId}');

      final formModel = await _companyApiService.loadCompanyForm(
        companyId: widget.companyId,
      );

      if (mounted) {
        setState(() {
          _formModel = formModel;
          _formData = Map<String, dynamic>.from(formModel.data);
          _isLoading = false; // 🚀 Form'u hemen göster
        });

        debugPrint('[ADD_COMPANY] Form structure loaded, showing UI...');

        // 🚀 ASYNC: Dropdown'ları arka planda yükle
        _loadDropdownOptionsAsync(formModel);
      }
    } catch (e) {
      debugPrint('[ADD_COMPANY] Load form error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadDropdownOptionsAsync(DynamicFormModel formModel) async {
    try {
      debugPrint('[ADD_COMPANY] Loading dropdown options in background...');

      // 🔍 DEBUG: Tüm dropdown field'ları listele
      debugPrint('[ADD_COMPANY] 🔍 DEBUG: All form fields:');
      for (final section in formModel.sections) {
        debugPrint('[ADD_COMPANY] Section: ${section.label}');
        for (final field in section.fields) {
          debugPrint('[ADD_COMPANY] - Field: ${field.label} | Key: ${field.key} | Type: ${field.type} | Widget: ${field.widget.name}');
          if (field.type == FormFieldType.dropdown) {
            debugPrint('[ADD_COMPANY]   → Dropdown: sourceType=${field.widget.sourceType}, sourceValue=${field.widget.sourceValue}');
          }
          // 🔍 MultiSelectBox kontrolü
          if (field.widget.name == 'MultiSelectBox') {
            debugPrint('[ADD_COMPANY]   → MultiSelectBox found: sourceType=${field.widget.sourceType}, sourceValue=${field.widget.sourceValue}');
          }
        }
      }

      // 🚀 PARALEL YÜKLEME - Tüm dropdown'ları aynı anda başlat
      final futures = <Future<void>>[];
      int completedCount = 0;

      // 🔍 Hem dropdown hem de multiSelectBox field'larını dahil et
      final totalCount = formModel.sections
          .expand((s) => s.fields)
          .where((f) =>
              (f.type == FormFieldType.dropdown || f.widget.name == 'MultiSelectBox') && f.widget.sourceType != null && f.widget.sourceValue != null)
          .length;

      debugPrint('[ADD_COMPANY] 🔍 Found $totalCount dropdown/multiselect fields');

      for (final section in formModel.sections) {
        for (final field in section.fields) {
          // 🔍 Dropdown VEYA MultiSelectBox field'larını işle
          if ((field.type == FormFieldType.dropdown || field.widget.name == 'MultiSelectBox') &&
              field.widget.sourceType != null &&
              field.widget.sourceValue != null) {
            debugPrint('[ADD_COMPANY] 🔍 Processing field: ${field.label} (${field.widget.name})');

            // Her dropdown için timeout'lu future oluştur
            final future = _companyApiService
                .loadDropdownOptions(
              sourceType: field.widget.sourceType!,
              sourceValue: field.widget.sourceValue!,
              dataTextField: field.widget.dataTextField,
              dataValueField: field.widget.dataValueField,
            )
                .timeout(
              const Duration(seconds: 5), // 🚀 5 saniye timeout
              onTimeout: () {
                debugPrint('[ADD_COMPANY] ⏰ Timeout for ${field.label}');
                return <DropdownOption>[]; // Boş liste döndür
              },
            ).then((options) {
              if (mounted) {
                setState(() {
                  field.options = options;
                });
                completedCount++;
                debugPrint('[ADD_COMPANY] ✅ $completedCount/$totalCount → ${field.label} (${options.length} items)');
              }
            }).catchError((e) {
              debugPrint('[ADD_COMPANY] ❌ ${field.label}: $e');
              if (mounted) {
                setState(() {
                  field.options = [];
                });
              }
              completedCount++;
            });

            futures.add(future);
          }
        }
      }

      // 🚀 Tüm dropdown'ları paralel olarak bekle
      if (futures.isNotEmpty) {
        debugPrint('[ADD_COMPANY] Starting $totalCount parallel requests...');
        final stopwatch = Stopwatch()..start();

        await Future.wait(futures).timeout(
          const Duration(seconds: 8), // 🚀 Toplam 8 saniye max
          onTimeout: () {
            debugPrint('[ADD_COMPANY] ⏰ Global timeout reached');
            return [];
          },
        );

        stopwatch.stop();
        debugPrint('[ADD_COMPANY] ✅ All dropdowns completed in ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      debugPrint('[ADD_COMPANY] Load dropdown options error: $e');
    }
  }

  void _onFormDataChanged(Map<String, dynamic> formData) {
    setState(() {
      _formData = formData;
    });
    debugPrint('[ADD_COMPANY] Form data updated: ${formData.keys.length} fields');
  }

  /// 🔧 FIXED: Save/Update company method
  Future<void> _saveCompany() async {
    try {
      setState(() {
        _isSaving = true;
      });

      debugPrint('[ADD_COMPANY] 🚀 Starting ${isEditing ? 'update' : 'save'} process...');
      debugPrint('[ADD_COMPANY] 🔍 Company ID: ${widget.companyId}');
      debugPrint('[ADD_COMPANY] 🔍 Form data keys: ${_formData.keys.toList()}');

      // Debug: Form data içeriğini logla
      for (final entry in _formData.entries) {
        debugPrint('[ADD_COMPANY] 🔍 ${entry.key}: ${entry.value}');
      }

      // 🎯 UNIFIED SAVE/UPDATE - API service'de karar verilecek
      final result = await _companyApiService.saveCompany(
        formData: _formData,
        companyId: widget.companyId, // null ise create, değilse update
      );

      if (mounted) {
        debugPrint('[ADD_COMPANY] ✅ ${isEditing ? 'Update' : 'Save'} successful: $result');

        setState(() {
          _isSaving = false;
        });

        // Başarı mesajı göster
        SnackbarHelper.showSuccess(
          context: context,
          message: isEditing ? 'Firma başarıyla güncellendi!' : 'Firma başarıyla kaydedildi!',
        );

        // Kısa süre bekle ve geri dön
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Geri dönerken success flag'i gönder
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('[ADD_COMPANY] ❌ ${isEditing ? 'Update' : 'Save'} error: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Error mesajı göster
        SnackbarHelper.showError(
          context: context,
          message: e.toString(),
        );
      }
    }
  }

  /// 🆕 YENİ: Delete company method
  Future<void> _deleteCompany() async {
    if (!isEditing) {
      debugPrint('[ADD_COMPANY] ⚠️ Cannot delete - no company ID');
      return;
    }

    try {
      setState(() {
        _isSaving = true;
      });

      debugPrint('[ADD_COMPANY] 🗑️ Starting delete process for ID: ${widget.companyId}');

      final result = await _companyApiService.deleteCompany(
        companyId: widget.companyId!,
      );

      if (mounted) {
        debugPrint('[ADD_COMPANY] ✅ Delete successful: $result');

        setState(() {
          _isSaving = false;
        });

        // Başarı mesajı göster
        SnackbarHelper.showSuccess(
          context: context,
          message: 'Firma başarıyla silindi!',
        );

        // Kısa süre bekle ve geri dön
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Geri dönerken success flag'i gönder (silme işlemi için)
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('[ADD_COMPANY] ❌ Delete error: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Error mesajı göster
        SnackbarHelper.showError(
          context: context,
          message: e.toString(),
        );
      }
    }
  }

  /// 🔧 UPDATED: Show delete confirmation dialog
  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Silme Onayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Bu firmayı silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz!',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteCompany();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.textOnPrimary,
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Sil'),
          ),
        ],
      ),
    );
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
      onSave: _saveCompany,
      onDelete: isEditing ? _showDeleteConfirmation : null, // 🔧 Delete callback eklendi
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
          // Custom loading animation
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
                  isEditing ? 'Firma bilgileri yükleniyor...' : 'Form yükleniyor...',
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
              Icons.description_outlined,
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
              'Form verisi alınamadı. Lütfen tekrar deneyin.',
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
