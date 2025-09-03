import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import 'dynamic_form_field_widget.dart';

/// Dynamic form widget that renders a complete form from API response
class DynamicFormWidget extends StatefulWidget {
  final DynamicFormModel formModel;
  final Function(Map<String, dynamic> formData) onFormChanged;
  final VoidCallback? onSave;
  final VoidCallback? onDelete;
  final bool isLoading;
  final bool isEditing;
  final bool showHeader;
  final bool showActions;

  const DynamicFormWidget({
    super.key,
    required this.formModel,
    required this.onFormChanged,
    this.onSave,
    this.onDelete,
    this.isLoading = false,
    this.isEditing = false,
    this.showHeader = true,
    this.showActions = true,
  });

  @override
  State<DynamicFormWidget> createState() => _DynamicFormWidgetState();
}

class _DynamicFormWidgetState extends State<DynamicFormWidget> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Map<String, dynamic> _formData;

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  @override
  void didUpdateWidget(DynamicFormWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.formModel != widget.formModel) {
      _initializeFormData();
    }
  }

  void _initializeFormData() {
    _formData = Map<String, dynamic>.from(widget.formModel.data);
    debugPrint('[DynamicForm] Initialized form data with ${_formData.length} fields');
  }

  void _onFieldValueChanged(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });

    widget.onFormChanged(_formData);
    debugPrint('[DynamicForm] Field changed: $key = $value');
  }

  bool _validateForm() {
    return _formKey.currentState?.validate() ?? false;
  }
  // 🆕 PUBLIC VALIDATION METHOD - GenericDynamicFormScreen için

  bool validateForm() {
    debugPrint('[DynamicForm] Public validation called');
    return _validateForm();
  }

  /// 💾 SAVE BUTTON İŞLEYİŞİ - GELİŞTİRİLMİŞ VERSİYON
  void _handleSave() {
    debugPrint('[DynamicForm] 💾 SAVE BUTTON CLICKED');
    debugPrint('[DynamicForm] 📊 Current form data: ${_formData.keys.toList()}');

    // 1. FORM VALİDASYONU
    if (!_validateForm()) {
      debugPrint('[DynamicForm] ❌ Form validation failed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lütfen tüm zorunlu alanları doldurun',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    debugPrint('[DynamicForm] ✅ Form validation passed');

    // 2. PARENT CALLBACK'E GÖNDERİ
    if (widget.onSave != null) {
      debugPrint('[DynamicForm] 🚀 Calling parent save callback...');
      widget.onSave!();
    } else {
      debugPrint('[DynamicForm] ❌ No save callback provided!');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Save işlemi tanımlanmamış',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// 🗑️ DELETE BUTTON İŞLEYİŞİ - GELİŞTİRİLMİŞ VERSİYON
  void _handleDelete() {
    debugPrint('[DynamicForm] 🗑️ DELETE BUTTON CLICKED');

    if (widget.onDelete != null) {
      // Onay dialogu göster
      showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: AppColors.error),
              SizedBox(width: 12),
              Text('Silme Onayı'),
            ],
          ),
          content: Text(
            'Bu ${widget.formModel.formName.toLowerCase()}ı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'İptal',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
              child: Text('Sil'),
            ),
          ],
        ),
      ).then((shouldDelete) {
        if (shouldDelete == true) {
          debugPrint('[DynamicForm] 🗑️ Delete confirmed, calling parent callback...');
          widget.onDelete!();
        } else {
          debugPrint('[DynamicForm] ↩️ Delete cancelled');
        }
      });
    } else {
      debugPrint('[DynamicForm] ❌ No delete callback provided!');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning_outlined, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Silme işlemi tanımlanmamış',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: AppColors.warning,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔧 Form header - sadece showHeader true ise göster
          if (widget.showHeader) ...[
            _buildFormHeader(size),
            SizedBox(height: size.largeSpacing),
          ],

          // Form sections
          Flexible(
            fit: FlexFit.loose,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: size.horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.formModel.sections.map((section) => _buildFormSection(section, size)),
                  SizedBox(height: size.extraLargeSpacing * 2),
                ],
              ),
            ),
          ),

          // 🔧 Form actions - sadece showActions true ise ve onSave null değilse göster
          if (widget.showActions && widget.onSave != null) _buildFormActions(size),
        ],
      ),
    );
  }

  Widget _buildFormHeader(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: AppColors.textOnPrimary),
            ),
            SizedBox(width: size.smallSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.formModel.formName,
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  if (widget.formModel.description.isNotEmpty) ...[
                    SizedBox(height: size.tinySpacing),
                    Text(
                      widget.formModel.description,
                      style: TextStyle(
                        fontSize: size.smallText,
                        color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (widget.isEditing)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Düzenleme',
                  style: TextStyle(
                    fontSize: size.smallText * 0.9,
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormSection(DynamicFormSection section, AppSizes size) {
    if (section.fields.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: size.largeSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          if (section.label.isNotEmpty) ...[
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.business,
                      size: 16,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  SizedBox(width: size.smallSpacing),
                  Expanded(
                    child: Text(
                      section.label,
                      style: TextStyle(
                        fontSize: size.mediumText,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Text(
                    '${section.fields.length} alan',
                    style: TextStyle(
                      fontSize: size.smallText,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: size.mediumSpacing),
          ],

          // Section fields
          _buildSectionFields(section, size),
        ],
      ),
    );
  }

  Widget _buildSectionFields(DynamicFormSection section, AppSizes size) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid layout
        final crossAxisCount = _getCrossAxisCount(constraints.maxWidth);
        final fields = section.fields;

        if (crossAxisCount == 1) {
          // Single column layout for mobile
          return Column(
            children: fields
                .map((field) => DynamicFormFieldWidget(
                      field: field,
                      onValueChanged: _onFieldValueChanged,
                      formData: _formData,
                    ))
                .toList(),
          );
        } else {
          // Grid layout for tablet/desktop
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: size.mediumSpacing,
              mainAxisSpacing: size.mediumSpacing,
              childAspectRatio: _getChildAspectRatio(fields),
            ),
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              return DynamicFormFieldWidget(
                field: field,
                onValueChanged: _onFieldValueChanged,
                formData: _formData,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildFormActions(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Delete/Sil button - sadece edit mode'da ve callback varsa göster
            if (widget.isEditing && widget.onDelete != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.isLoading ? null : _handleDelete,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(size.cardBorderRadius),
                    ),
                  ),
                  child: Text(
                    'Sil',
                    style: TextStyle(
                      fontSize: size.textSize,
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(width: size.mediumSpacing),
            ],

            // Save/Update button
            Expanded(
              flex: widget.isEditing && widget.onDelete != null ? 2 : 1, // Sil butonu varsa daha geniş
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                  elevation: 3,
                ),
                child: widget.isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.textOnPrimary,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.isEditing ? Icons.update : Icons.save,
                            size: 20,
                          ),
                          SizedBox(width: size.smallSpacing),
                          Text(
                            widget.isEditing ? 'Güncelle' : 'Kaydet',
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

  int _getCrossAxisCount(double width) {
    if (width < 600) {
      return 1; // Mobile: Single column
    } else if (width < 900) {
      return 2; // Tablet: Two columns
    } else {
      return 3; // Desktop: Three columns
    }
  }

  double _getChildAspectRatio(List<DynamicFormField> fields) {
    // Calculate average aspect ratio based on field types
    double totalRatio = 0;

    for (final field in fields) {
      switch (field.type) {
        case FormFieldType.textarea:
          totalRatio += 2.5; // Taller for textarea
          break;
        case FormFieldType.map:
          totalRatio += 1.5; // Medium height for map
          break;
        case FormFieldType.empty:
          totalRatio += 4.0; // Very tall for info text
          break;
        case FormFieldType.label:
          totalRatio += 3.5; // Tall for display labels
          break;
        default:
          totalRatio += 3.0; // Standard height for most fields
          break;
      }
    }

    return fields.isNotEmpty ? totalRatio / fields.length : 3.0;
  }
}
