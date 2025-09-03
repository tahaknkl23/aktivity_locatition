// lib/core/widgets/dynamic_form/field_types/date_field_widget.dart - GENERIC VERSION
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../dynamic_form_field_widget.dart';
import '../utils/date_formatter.dart';
import '../utils/date_picker_helper.dart';

class DateFieldWidget extends StatelessWidget {
  final FieldCommonProps props;

  const DateFieldWidget({
    super.key,
    required this.props,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: props.field.isEnabled ? () => _selectDate(context) : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: props.size.cardPadding + 4,
          vertical: props.size.cardPadding + 2,
        ),
        decoration: BoxDecoration(
          color: props.field.isEnabled ? AppColors.surface : AppColors.surfaceVariant.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            // Calendar icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.calendar_today,
                color: props.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
                size: 18,
              ),
            ),

            SizedBox(width: props.size.smallSpacing),

            // Date text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getDisplayText(),
                    style: TextStyle(
                      fontSize: props.size.textSize,
                      color: _getTextColor(),
                      fontWeight: props.currentValue != null ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                  if (props.currentValue != null)
                    Text(
                      _getFieldTypeText(),
                      style: TextStyle(
                        fontSize: props.size.smallText,
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),

            // Arrow icon
            Icon(
              Icons.arrow_drop_down,
              color: props.field.isEnabled ? AppColors.primary : AppColors.textTertiary,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    final formattedDate = DateFormatter.format(props.currentValue);
    // ✅ GENERIC: API label'ı kullan
    return formattedDate ?? '${props.field.label} seçiniz';
  }

  String _getFieldTypeText() {
    // ✅ GENERIC: Field özelliklerine göre dinamik text
    if (_hasTimeComponent()) {
      return '${props.field.label} (Saat ile)';
    }
    return props.field.label;
  }

  Color _getTextColor() {
    if (!props.field.isEnabled) return AppColors.textTertiary;
    return props.currentValue != null ? AppColors.textPrimary : AppColors.textSecondary;
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final hasTime = _hasTimeComponent();

      final result = await DatePickerHelper.selectDate(
        context: context,
        currentValue: props.currentValue,
        hasTime: hasTime,
      );

      if (result != null) {
        props.onValueChanged(result);
      }
    } catch (e) {
      debugPrint('[DateField] Date selection error: $e');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            // ✅ GENERIC: API label'ı kullan
            content: Text('${props.field.label} seçiminde hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  bool _hasTimeComponent() {
    return props.field.widget.name.toLowerCase() == 'datetimepicker' || props.field.widget.properties['format']?.toString().contains('HH:mm') == true;
  }
}
