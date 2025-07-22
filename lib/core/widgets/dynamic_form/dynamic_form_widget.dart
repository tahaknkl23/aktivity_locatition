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
  final bool isLoading;
  final bool isEditing;
  final bool showHeader; // 🆕 Header gösterme kontrolü
  final bool showActions; // 🆕 Alt buton gösterme kontrolü

  const DynamicFormWidget({
    super.key,
    required this.formModel,
    required this.onFormChanged,
    this.onSave,
    this.isLoading = false,
    this.isEditing = false,
    this.showHeader = true, // Default true
    this.showActions = true, // Default true
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

  void _handleSave() {
    if (_validateForm()) {
      widget.onSave?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen tüm zorunlu alanları doldurun'),
          backgroundColor: AppColors.error,
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
            // Cancel button
            Expanded(
              child: OutlinedButton(
                onPressed: widget.isLoading ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.textSecondary),
                  padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                ),
                child: Text(
                  'İptal',
                  style: TextStyle(
                    fontSize: size.textSize,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(width: size.mediumSpacing),

            // Save button
            Expanded(
              flex: 2,
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
