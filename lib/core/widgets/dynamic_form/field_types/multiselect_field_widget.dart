// lib/core/widgets/dynamic_form/field_types/multiselect_field_widget.dart - GENERIC VERSION
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../dynamic_form_field_widget.dart';
import '../dialogs/multiselect_dialog.dart';
import '../components/selected_items_display.dart';

class MultiselectFieldWidget extends StatelessWidget {
  final FieldCommonProps props;

  const MultiselectFieldWidget({
    super.key,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    final selectedValues = _getSelectedValues();

    return InkWell(
      onTap: props.field.isEnabled ? () => _showMultiSelectDialog(context) : null,
      child: Container(
        decoration: _buildDecoration(),
        padding: EdgeInsets.symmetric(
          horizontal: props.size.cardPadding,
          vertical: props.size.cardPadding * 0.8,
        ),
        child: Row(
          children: [
            Expanded(
              child: selectedValues.isEmpty
                  ? _buildPlaceholder()
                  : SelectedItemsDisplay(
                      selectedValues: selectedValues,
                      options: props.field.options ?? [],
                      size: props.size,
                    ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: props.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    return BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(props.size.formFieldBorderRadius),
      color: props.field.isEnabled ? AppColors.surface : AppColors.surfaceVariant,
    );
  }

  Widget _buildPlaceholder() {
    return Text(
      // ✅ GENERIC: API label'ı kullan
      '${props.field.label} seçiniz...',
      style: TextStyle(
        fontSize: props.size.textSize,
        color: AppColors.textSecondary,
      ),
    );
  }

  List<dynamic> _getSelectedValues() {
    if (props.currentValue == null) return [];

    if (props.currentValue is List) {
      return List<dynamic>.from(props.currentValue);
    }

    if (props.currentValue is String && props.currentValue.toString().isNotEmpty) {
      return props.currentValue.toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    return [props.currentValue];
  }

  Future<void> _showMultiSelectDialog(BuildContext context) async {
    if (props.field.options == null || props.field.options!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // ✅ GENERIC: API label'ı kullan
          content: Text('${props.field.label} seçenekleri yükleniyor, lütfen bekleyin'),
          backgroundColor: AppColors.info,
        ),
      );
      return;
    }

    final selectedValues = _getSelectedValues();

    final result = await showDialog<List<dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return MultiselectDialog(
          title: props.field.label, // ✅ GENERIC: API label'ı kullan
          options: props.field.options!,
          selectedValues: selectedValues,
          size: props.size,
        );
      },
    );

    if (result != null) {
      props.onValueChanged(result);
    }
  }
}
