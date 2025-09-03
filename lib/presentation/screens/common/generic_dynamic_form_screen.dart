import 'package:aktivity_location_app/core/helpers/dynamic_cascade_helper.dart';
import 'package:aktivity_location_app/core/widgets/dynamic_form/dynamic_form_widget.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/base_api_service.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';

class GenericDynamicFormScreen extends StatefulWidget {
  final String controller;
  final String title;
  final String url;
  final int? id;

  const GenericDynamicFormScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.url,
    this.id,
  });

  @override
  State<GenericDynamicFormScreen> createState() => _GenericDynamicFormScreenState();
}

class _GenericDynamicFormScreenState extends State<GenericDynamicFormScreen> {
  final BaseApiService _apiService = BaseApiService();
  final GlobalKey<State<DynamicFormWidget>> _dynamicFormKey = GlobalKey<State<DynamicFormWidget>>(); // Correct type

  // CASCADE HELPER SISTEMI
  late DynamicCascadeHelper _cascadeHelper;
  Map<String, List<CascadeDependency>> _dependencyMap = {};

  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  DynamicControllerConfig? _controllerConfig; // Dynamic config
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cascadeHelper = DynamicCascadeHelper();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[GENERIC_FORM] Loading form for controller: ${widget.controller}');
      debugPrint('[GENERIC_FORM] URL: ${widget.url}');

      // Use new dynamic method to get both form data AND config
      final result = await _apiService.getFormWithDataAndConfig(
        controller: widget.controller,
        url: widget.url,
        id: widget.id ?? 0,
      );

      // DEBUG: Raw response'u logla
      debugPrint('[GENERIC_FORM] === RAW RESPONSE DEBUG ===');
      debugPrint('[GENERIC_FORM] Response keys: ${result.formData.keys.toList()}');
      if (result.formData.containsKey('Form')) {
        debugPrint('[GENERIC_FORM] Form keys: ${result.formData['Form']?.keys?.toList()}');
      }
      if (result.formData.containsKey('Data')) {
        debugPrint('[GENERIC_FORM] Data keys: ${result.formData['Data']?.keys?.toList()}');
      }
      debugPrint('[GENERIC_FORM] === END DEBUG ===');

      final formModel = DynamicFormModel.fromJson(result.formData);

      // Store dynamic configuration
      _controllerConfig = result.config;

      debugPrint('[GENERIC_FORM] Dynamic config loaded:');
      debugPrint('[GENERIC_FORM] - FormID: ${_controllerConfig!.formId}');
      debugPrint('[GENERIC_FORM] - TableID: ${_controllerConfig!.tableId}');
      debugPrint('[GENERIC_FORM] - Extracted: ${_controllerConfig!.isExtracted}');

      await _loadDropdownOptionsAsync(formModel);

      setState(() {
        _formModel = formModel;
        _formData = Map<String, dynamic>.from(formModel.data);
        _isLoading = false;
      });

      debugPrint('[GENERIC_FORM] Form loaded: ${formModel.formName}');
      debugPrint('[GENERIC_FORM] Sections: ${formModel.sections.length}');

      _initializeCascadeSystem(formModel);
    } catch (e) {
      setState(() {
        _errorMessage = 'Form yüklenirken hata oluştu: $e';
        _isLoading = false;
      });

      debugPrint('[GENERIC_FORM] Form load error: $e');
    }
  }

  void _initializeCascadeSystem(DynamicFormModel formModel) {
    try {
      debugPrint('[GENERIC_FORM] Initializing cascade system...');

      _dependencyMap = _cascadeHelper.buildDependencyMap(formModel);
      _cascadeHelper.debugDependencyMap();

      debugPrint('[GENERIC_FORM] Cascade system initialized');
      debugPrint('[GENERIC_FORM] Total parent fields: ${_dependencyMap.keys.length}');
    } catch (e) {
      debugPrint('[GENERIC_FORM] Cascade initialization error: $e');
    }
  }

  Future<void> _loadDropdownOptionsAsync(DynamicFormModel formModel) async {
    try {
      debugPrint('[GENERIC_FORM] Loading dropdown options in background...');

      final futures = <Future<void>>[];
      int completedCount = 0;

      final totalCount = formModel.sections
          .expand((s) => s.fields)
          .where((f) =>
              (f.type == FormFieldType.dropdown || f.widget.name == 'MultiSelectBox') && f.widget.sourceType != null && f.widget.sourceValue != null)
          .length;

      debugPrint('[GENERIC_FORM] Found $totalCount dropdown/multiselect fields');

      for (final section in formModel.sections) {
        for (final field in section.fields) {
          if ((field.type == FormFieldType.dropdown || field.widget.name == 'MultiSelectBox') &&
              field.widget.sourceType != null &&
              field.widget.sourceValue != null) {
            final future = _loadSingleFieldOptions(field).timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                debugPrint('[GENERIC_FORM] Timeout for ${field.label}');
                return <DropdownOption>[];
              },
            ).then((options) {
              if (mounted) {
                setState(() {
                  field.options = options;
                });
                completedCount++;
                debugPrint('[GENERIC_FORM] $completedCount/$totalCount → ${field.label} (${options.length} items)');
              }
            }).catchError((e) {
              debugPrint('[GENERIC_FORM] ${field.label}: $e');
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

      if (futures.isNotEmpty) {
        debugPrint('[GENERIC_FORM] Starting $totalCount parallel requests...');
        final stopwatch = Stopwatch()..start();

        await Future.wait(futures).timeout(
          const Duration(seconds: 8),
          onTimeout: () {
            debugPrint('[GENERIC_FORM] Global timeout reached');
            return [];
          },
        );

        stopwatch.stop();
        debugPrint('[GENERIC_FORM] All dropdowns completed in ${stopwatch.elapsedMilliseconds}ms');
      }
    } catch (e) {
      debugPrint('[GENERIC_FORM] Load dropdown options error: $e');
    }
  }

  Future<List<DropdownOption>> _loadSingleFieldOptions(DynamicFormField field) async {
    try {
      final apiService = _getApiServiceForController(widget.controller);

      return await apiService.loadDropdownOptions(
        sourceType: field.widget.sourceType!,
        sourceValue: field.widget.sourceValue!,
        dataTextField: field.widget.dataTextField,
        dataValueField: field.widget.dataValueField,
      );
    } catch (e) {
      debugPrint('[GENERIC_FORM] Failed to load options for ${field.label}: $e');
      return [];
    }
  }

  dynamic _getApiServiceForController(String controller) {
    switch (controller.toLowerCase()) {
      case 'companyadd':
      case 'aktiviteadd':
      case 'aktivitebranchadd':
      default:
        return _apiService;
    }
  }

  void _onFormChanged(Map<String, dynamic> formData) {
    setState(() {
      _formData = formData;
    });
    debugPrint('[GENERIC_FORM] Form data updated: ${formData.keys.length} fields');

    _handleDynamicCascade(formData);
  }

  Future<void> _handleDynamicCascade(Map<String, dynamic> formData) async {
    if (_dependencyMap.isEmpty) {
      debugPrint('[GENERIC_FORM] No cascade dependencies, skipping');
      return;
    }

    if (_isSaving) {
      debugPrint('[GENERIC_FORM] Save in progress - DYNAMIC CASCADE BLOCKED');
      return;
    }

    try {
      debugPrint('[GENERIC_FORM] Processing dynamic cascade changes...');

      for (final entry in formData.entries) {
        final fieldKey = entry.key;
        final newValue = entry.value;

        if (_dependencyMap.containsKey(fieldKey)) {
          debugPrint('[GENERIC_FORM] Cascade trigger: $fieldKey = $newValue');

          await _cascadeHelper.handleFieldChange(
            parentField: fieldKey,
            newValue: newValue,
            formModel: _formModel!,
            onOptionsLoaded: (childField, options) {
              debugPrint('[GENERIC_FORM] Options loaded for $childField: ${options.length} items');

              final field = _formModel!.getFieldByKey(childField);
              if (field != null && mounted) {
                setState(() {
                  field.options = options;
                });
              }
            },
            onFieldReset: (childField, value) {
              debugPrint('[GENERIC_FORM] Field reset: $childField = $value');

              if (mounted) {
                setState(() {
                  _formData[childField] = value;
                });
              }
            },
          );
        }
      }

      debugPrint('[GENERIC_FORM] Dynamic cascade processing completed');
    } catch (e) {
      debugPrint('[GENERIC_FORM] Dynamic cascade error: $e');
    }
  }

  /// FIXED SAVE METHOD - SAME AS AddActivityScreen
  Future<void> _saveForm() async {
    if (_formModel == null || _controllerConfig == null) {
      debugPrint('[GENERIC_FORM] Cannot save - missing form model or config');
      return;
    }

    // VALIDATION CHECK - Same as AddActivityScreen
    if (!_validateRequiredFields()) {
      return; // Stop save if validation fails
    }

    setState(() => _isSaving = true);

    try {
      debugPrint('[GENERIC_FORM] ==========================================');
      debugPrint('[GENERIC_FORM] STARTING SAVE PROCESS');
      debugPrint('[GENERIC_FORM] Controller: ${widget.controller}');
      debugPrint('[GENERIC_FORM] Form ID: ${_controllerConfig!.formId}');
      debugPrint('[GENERIC_FORM] Table ID: ${_controllerConfig!.tableId}');
      debugPrint('[GENERIC_FORM] Record ID: ${widget.id}');
      debugPrint('[GENERIC_FORM] Is Update: ${widget.id != null}');
      debugPrint('[GENERIC_FORM] Data keys: ${_formData.keys.toList()}');
      debugPrint('[GENERIC_FORM] ==========================================');

      final result = await _apiService.saveWithDynamicConfig(
        controller: widget.controller,
        formData: _formData,
        id: widget.id,
      );

      debugPrint('[GENERIC_FORM] Save API Response received');
      debugPrint('[GENERIC_FORM] Response type: ${result.runtimeType}');

      final newId = result['Data']?['Id'] as int?;
      if (newId != null && widget.id == null) {
        debugPrint('[GENERIC_FORM] New record created with ID: $newId');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.id != null
                        ? '${widget.title} başarıyla güncellendi'
                        : '${widget.title} başarıyla kaydedildi${newId != null ? ' (ID: $newId)' : ''}',
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        await Future.delayed(Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      debugPrint('[GENERIC_FORM] ==========================================');
      debugPrint('[GENERIC_FORM] SAVE ERROR');
      debugPrint('[GENERIC_FORM] Error type: ${e.runtimeType}');
      debugPrint('[GENERIC_FORM] Error message: $e');
      debugPrint('[GENERIC_FORM] ==========================================');

      if (mounted) {
        String errorMessage = 'Kayıt sırasında hata oluştu';

        if (e.toString().contains('401') || e.toString().contains('oturum')) {
          errorMessage = 'Oturum süresi dolmuş. Lütfen tekrar giriş yapın.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'Bu işlem için yetkiniz bulunmuyor.';
        } else if (e.toString().contains('404')) {
          errorMessage = 'Form kaynağı bulunamadı.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
        } else if (e.toString().contains('network') || e.toString().contains('bağlantı')) {
          errorMessage = 'İnternet bağlantınızı kontrol edin.';
        } else {
          errorMessage = 'Kayıt başarısız: ${e.toString()}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  /// AddActivityScreen validation metodunu kopyaladık
  bool _validateRequiredFields() {
    final errors = <String>[];

    // Dinamik form field'larını kontrol et
    for (final section in _formModel!.sections) {
      for (final field in section.fields) {
        if (field.isRequired) {
          final value = _formData[field.key];

          if (value == null || (value is String && value.trim().isEmpty) || (value is List && value.isEmpty)) {
            errors.add(field.label);
          }
        }
      }
    }

    if (errors.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Eksik alanlar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 4),
                ...errors.map((error) => Text('• $error')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }

      debugPrint('[GENERIC_FORM] Validation failed - Required fields: $errors');
      return false;
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_formModel != null && !_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _loadForm,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: _buildBody(size),
    );
  }

  Widget _buildBody(AppSizes size) {
    if (_isLoading) {
      return _buildLoadingState(size);
    }

    if (_errorMessage != null) {
      return _buildErrorState(size);
    }

    if (_formModel == null) {
      return _buildEmptyState(size);
    }

    return _buildFormContent(size);
  }

  Widget _buildLoadingState(AppSizes size) {
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
                  '${widget.title} yükleniyor...',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  'Controller: ${widget.controller}',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
                if (_dependencyMap.isNotEmpty) ...[
                  SizedBox(height: size.smallSpacing),
                  Text(
                    '${_dependencyMap.keys.length} cascade bağımlılığı',
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri Dön'),
                ),
                SizedBox(width: size.mediumSpacing),
                ElevatedButton.icon(
                  onPressed: _loadForm,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppSizes size) {
    return Center(
      child: Text(
        'Form verisi bulunamadı',
        style: TextStyle(
          fontSize: size.mediumText,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFormContent(AppSizes size) {
    return Column(
      children: [
        SizedBox(height: size.mediumSpacing),
        Expanded(
          child: DynamicFormWidget(
            key: _dynamicFormKey, // DynamicFormWidget için key
            formModel: _formModel!,
            onFormChanged: _onFormChanged,
            isLoading: _isSaving,
            isEditing: widget.id != null,
            showHeader: false,
            showActions: false,
          ),
        ),
        _buildActionBar(size),
      ],
    );
  }

  Widget _buildActionBar(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                ),
                child: Text(
                  'İptal',
                  style: TextStyle(fontSize: size.textSize),
                ),
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: size.smallSpacing),
                          const Text('Kaydediliyor...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.id != null ? Icons.update : Icons.save,
                            size: 20,
                          ),
                          SizedBox(width: size.smallSpacing),
                          Text(
                            widget.id != null ? 'Güncelle' : 'Kaydet',
                            style: TextStyle(
                              fontSize: size.textSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
