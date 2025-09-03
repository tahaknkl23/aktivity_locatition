// lib/core/widgets/dynamic_form/field_types/dropdown_field_widget.dart - GENERIC VERSION
import 'package:flutter/material.dart';
import 'package:aktivity_location_app/data/services/api/company_api_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/common/searchable_dropdown_widget.dart';
import '../dynamic_form_field_widget.dart';
import '../utils/dropdown_options_loader.dart';

class DropdownFieldWidget extends StatefulWidget {
  final FieldCommonProps props;
  final Map<String, dynamic> formData;

  const DropdownFieldWidget({
    super.key,
    required this.props,
    required this.formData,
  });

  @override
  State<DropdownFieldWidget> createState() => _DropdownFieldWidgetState();
}

class _DropdownFieldWidgetState extends State<DropdownFieldWidget> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOptionsIfNeeded();
    });
  }

  @override
  void didUpdateWidget(DropdownFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔍 DEBUG: Options değişikliği
    debugPrint('[DROPDOWN] didUpdateWidget called for ${widget.props.field.key}');
    debugPrint('[DROPDOWN] Old options: ${oldWidget.props.field.options?.length ?? 0}');
    debugPrint('[DROPDOWN] New options: ${widget.props.field.options?.length ?? 0}');

    // 🔥 OPTIONS DEĞİŞTİĞİNDE UI'I ZORLA YENİLE
    if (widget.props.field.options != oldWidget.props.field.options) {
      debugPrint('[DROPDOWN] ✅ Options changed, rebuilding UI for ${widget.props.field.key}');
      debugPrint('[DROPDOWN] ✅ FORCING setState rebuild...');

      _validateCurrentValue();

      // 🚀 ZORLA SETSTATE - HER DURUMDA UI YENİLE (DİREKT!)
      setState(() {
        // Force rebuild dropdown - options değişti!
      });
      return; // Early return - gereksiz işlemleri engelle
    }

    if (_shouldLoadOptions()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadOptionsIfNeeded();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_shouldShowNoOptionsWarning()) {
      return _buildNoOptionsState();
    }

    return _buildDropdownField();
  }

  Widget _buildDropdownField() {
    final validValue = _getValidValue();

    return SearchableDropdownWidget(
      label: '',
      // ✅ GENERIC: API label'ı kullan
      hint: '${widget.props.field.label} seçiniz...',
      options: widget.props.field.options ?? [],
      value: validValue,
      onChanged: widget.props.field.isEnabled ? (value) => widget.props.onValueChanged(value) : (value) {},
      isRequired: widget.props.field.isRequired,
      isEnabled: widget.props.field.isEnabled,
      validator: widget.props.field.isRequired
          ? (value) {
              if (value == null || (value is String && value.isEmpty)) {
                // ✅ GENERIC: API label'ı kullan
                return '${widget.props.field.label} seçimi zorunludur';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(widget.props.size.formFieldBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            // ✅ GENERIC: API label'ı kullan
            Text('${widget.props.field.label} yükleniyor...'),
          ],
        ),
      ),
    );
  }

  Widget _buildNoOptionsState() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(widget.props.size.formFieldBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_outlined, color: AppColors.warning),
            SizedBox(width: 8),
            // ✅ GENERIC: API label'ı kullan
            Text('${widget.props.field.label} seçenekleri yüklenemedi'),
          ],
        ),
      ),
    );
  }

  bool _shouldLoadOptions() {
    // 🚫 CASCADE FIELD İSE KENDİ LOADER'INI KULLANMA
    if (_isCascadeField()) {
      debugPrint('[DROPDOWN] Skipping load - cascade field: ${widget.props.field.key}');
      return false;
    }

    return (widget.props.field.options == null || widget.props.field.options!.isEmpty) &&
        widget.props.field.widget.sourceType != null &&
        widget.props.field.widget.sourceValue != null;
  }

// 🆕 Cascade field kontrolü
  bool _isCascadeField() {
    final cascadeFields = ['CompanyBranchId', 'ContactId', 'ActivityContacts'];
    return cascadeFields.contains(widget.props.field.key);
  }

  bool _shouldShowNoOptionsWarning() {
    return !_isLoading &&
        (widget.props.field.options == null || widget.props.field.options!.isEmpty) &&
        widget.props.field.widget.sourceType != null &&
        !_shouldLoadOptions();
  }

  dynamic _getValidValue() {
    final currentValue = widget.props.currentValue;

    if (widget.props.field.options != null && currentValue != null) {
      final hasValue = widget.props.field.options!.any((option) => option.value == currentValue);

      if (!hasValue) {
        return null;
      }
    }

    return currentValue;
  }

  Future<void> _loadOptionsIfNeeded() async {
    if (widget.props.field.options != null && widget.props.field.options!.isNotEmpty) {
      debugPrint('[DropdownField] ✅ Options already loaded for ${widget.props.field.key}');
      return;
    }

    final sourceType = widget.props.field.widget.sourceType;
    final sourceValue = widget.props.field.widget.sourceValue;

    if (sourceType == null || sourceValue == null) {
      debugPrint('[DropdownField] ❌ Missing source info for ${widget.props.field.key}');
      return;
    }

    debugPrint('[DropdownField] 🔄 Loading options for ${widget.props.field.key}');

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final loader = DropdownOptionsLoader(
        apiService: CompanyApiService(),
      );

      final options = await loader.loadOptions(
        sourceType: sourceType,
        sourceValue: sourceValue,
        dataTextField: widget.props.field.widget.dataTextField,
        dataValueField: widget.props.field.widget.dataValueField,
        controller: _getControllerFromContext(),
        formPath: _getFormPathFromContext(),
      );

      debugPrint('[DropdownField] ✅ Loaded ${options.length} options for ${widget.props.field.key}');

      if (mounted) {
        setState(() {
          widget.props.field.options = options;
          _isLoading = false;
        });

        _selectInitialValueFromDDL();
      }
    } catch (e) {
      debugPrint('[DropdownField] ❌ API Error for ${widget.props.field.key}: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // ✅ GENERIC: API label'ı kullan
            content: Text('${widget.props.field.label} seçenekleri yüklenemedi: $e'),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _selectInitialValueFromDDL() {
    final ddlKey = '${widget.props.field.key}_DDL';
    final ddlValue = widget.formData[ddlKey];

    if (ddlValue == null || widget.props.field.options == null) return;

    debugPrint('[DropdownField] 🎯 Setting initial value from DDL: $ddlValue');

    try {
      dynamic targetValue;
      String targetText = '';

      if (ddlValue is Map<String, dynamic>) {
        targetValue = ddlValue['UserId'] ?? ddlValue['Id'] ?? ddlValue['Value'];
        targetText = ddlValue['Adi'] ?? ddlValue['Text'] ?? ddlValue['Name'] ?? '';
      }

      debugPrint('[DropdownField] 🔍 Looking for: value=$targetValue, text=$targetText');

      for (final option in widget.props.field.options!) {
        if (option.value == targetValue || option.value.toString() == targetValue.toString() || option.text == targetText) {
          debugPrint('[DropdownField] ✅ Found matching option: ${option.text} (${option.value})');
          widget.props.onValueChanged(option.value);
          break;
        }
      }
    } catch (e) {
      debugPrint('[DropdownField] ❌ DDL parsing error: $e');
    }
  }

  /// ✅ Context'ten controller bilgisini al
  String? _getControllerFromContext() {
    // Form route'undan controller çıkar
    final route = ModalRoute.of(context);
    if (route?.settings.name != null) {
      final routeName = route!.settings.name!;
      if (routeName.contains('AddExpense') || routeName.contains('add-expense')) {
        return 'AddExpense';
      } else if (routeName.contains('CompanyAdd') || routeName.contains('add-company')) {
        return 'CompanyAdd';
      } else if (routeName.contains('AktiviteAdd') || routeName.contains('add-activity')) {
        return 'AktiviteAdd';
      } else if (routeName.contains('AktiviteBranchAdd')) {
        return 'AktiviteBranchAdd';
      }
    }

    // Arguments'ten controller al
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    return args?['controller'] as String?;
  }

  /// ✅ Context'ten form path bilgisini al
  String? _getFormPathFromContext() {
    final controller = _getControllerFromContext();
    if (controller == null) return null;

    return '/Dyn/$controller/Detail';
  }

  void _validateCurrentValue() {
    if (widget.props.field.options != null && widget.props.currentValue != null) {
      final hasValue = widget.props.field.options!.any((option) => option.value == widget.props.currentValue);

      if (!hasValue) {
        widget.props.onValueChanged(null);
        debugPrint('[DropdownField] Value reset due to options change: ${widget.props.field.key}');
      }
    }
  }
}
