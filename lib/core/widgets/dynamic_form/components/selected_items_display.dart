// lib/core/widgets/dynamic_form/components/selected_items_display.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

/// Multiselect'te seçilen itemları gösteren widget
class SelectedItemsDisplay extends StatelessWidget {
  final List<dynamic> selectedValues;
  final List<DropdownOption> options;
  final AppSizes size;

  const SelectedItemsDisplay({
    super.key,
    required this.selectedValues,
    required this.options,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: selectedValues.map((value) {
        final option = _findOption(value);
        return _buildChip(option?.text ?? value.toString());
      }).toList(),
    );
  }

  Widget _buildChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: size.textSize * 0.9,
          color: AppColors.primary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  DropdownOption? _findOption(dynamic value) {
    try {
      return options.firstWhere(
        (opt) => opt.value == value,
      );
    } catch (e) {
      return null;
    }
  }
}
