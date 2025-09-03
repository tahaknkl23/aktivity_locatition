// lib/core/widgets/dynamic_form/field_types/checkbox_field_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../dynamic_form_field_widget.dart';

/// Checkbox field widget'ı
class CheckboxFieldWidget extends StatelessWidget {
  final FieldCommonProps props;

  const CheckboxFieldWidget({
    super.key,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
        value: props.currentValue == true,
        onChanged: props.field.isEnabled ? (value) => props.onValueChanged(value) : null,
        title: Text(
          props.field.label,
          style: TextStyle(fontSize: props.size.textSize),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        activeColor: AppColors.primary);
  }
}
