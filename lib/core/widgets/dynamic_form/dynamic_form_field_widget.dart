// lib/core/widgets/dynamic_form/dynamic_form_field_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import 'field_types/text_field_widget.dart';
import 'field_types/dropdown_field_widget.dart';
import 'field_types/date_field_widget.dart';
import 'field_types/multiselect_field_widget.dart';
import 'field_types/checkbox_field_widget.dart';
import 'field_types/map_field_widget.dart';
import 'field_types/label_field_widget.dart';
import 'field_types/empty_field_widget.dart';
import 'components/field_label_widget.dart';
import 'utils/field_value_initializer.dart';

/// Ana dinamik form field widget'ı - sadece koordinasyon yapar
class DynamicFormFieldWidget extends StatefulWidget {
  final DynamicFormField field;
  final Function(String key, dynamic value) onValueChanged;
  final Map<String, dynamic> formData;

  const DynamicFormFieldWidget({
    super.key,
    required this.field,
    required this.onValueChanged,
    required this.formData,
  });

  @override
  State<DynamicFormFieldWidget> createState() => _DynamicFormFieldWidgetState();
}

class _DynamicFormFieldWidgetState extends State<DynamicFormFieldWidget> {
  late TextEditingController _textController;
  dynamic _currentValue;

  @override
  void initState() {
    super.initState();
    _initializeField();
  }

  @override
  void didUpdateWidget(DynamicFormFieldWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.field.key != widget.field.key) {
      _initializeField();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _initializeField() {
    final initializer = FieldValueInitializer(
      field: widget.field,
      formData: widget.formData,
    );

    final result = initializer.initialize();
    _currentValue = result.value;
    _textController = result.textController;
  }

  void _onValueChanged(dynamic value) {
    setState(() {
      _currentValue = value;
    });
    widget.onValueChanged(widget.field.key, value);
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    // Hidden field için hiçbir şey gösterme
    if (widget.field.type == FormFieldType.hidden) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.field.type != FormFieldType.checkbox)
            FieldLabelWidget(
              field: widget.field,
              size: size,
            ),

          // Spacing
          if (widget.field.type != FormFieldType.checkbox) SizedBox(height: size.smallSpacing),

          // Field
          _buildFieldContent(size),
        ],
      ),
    );
  }

  Widget _buildFieldContent(AppSizes size) {
    final commonProps = FieldCommonProps(
      field: widget.field,
      currentValue: _currentValue,
      textController: _textController,
      onValueChanged: _onValueChanged,
      size: size,
    );

    // Disabled field check
    if (!widget.field.isEnabled) {
      return LabelFieldWidget(
        field: widget.field,
        currentValue: _currentValue,
        size: size,
        isDisabled: true,
      );
    }

    // Field type'a göre uygun widget döndür
    switch (widget.field.type) {
      case FormFieldType.text:
        return TextFieldWidget(props: commonProps);

      case FormFieldType.textarea:
        return TextFieldWidget(props: commonProps, isMultiline: true);

      case FormFieldType.dropdown:
        return DropdownFieldWidget(
          props: commonProps,
          formData: widget.formData,
        );

      case FormFieldType.date:
        return DateFieldWidget(props: commonProps);

      case FormFieldType.multiSelect:
        return MultiselectFieldWidget(props: commonProps);

      case FormFieldType.checkbox:
        return CheckboxFieldWidget(props: commonProps);

      case FormFieldType.map:
        return MapFieldWidget(props: commonProps);

      case FormFieldType.label:
        return LabelFieldWidget(
          field: widget.field,
          currentValue: _currentValue,
          size: size,
        );

      case FormFieldType.empty:
        return EmptyFieldWidget(
          field: widget.field,
          size: size,
        );

      case FormFieldType.hidden:
        return const SizedBox.shrink();
    }
  }
}

/// Tüm field widget'ları için ortak props
class FieldCommonProps {
  final DynamicFormField field;
  final dynamic currentValue;
  final TextEditingController textController;
  final Function(dynamic) onValueChanged;
  final AppSizes size;

  const FieldCommonProps({
    required this.field,
    required this.currentValue,
    required this.textController,
    required this.onValueChanged,
    required this.size,
  });
}
