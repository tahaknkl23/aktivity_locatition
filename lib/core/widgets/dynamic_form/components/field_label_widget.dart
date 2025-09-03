import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

class FieldLabelWidget extends StatelessWidget {
  final DynamicFormField field;
  final AppSizes size;

  const FieldLabelWidget({
    super.key,
    required this.field,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: size.tinySpacing),
      child: Row(
        children: [
          Expanded(
            child: RichText(
              text: TextSpan(
                text: field.label,
                style: TextStyle(
                  fontSize: size.textSize + 1, // Slightly bigger
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
                children: [
                  if (field.isRequired)
                    TextSpan(
                      text: ' *',
                      style: TextStyle(
                        fontSize: size.textSize + 3,
                        color: AppColors.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (field.labelTooltip != null)
            Padding(
              padding: EdgeInsets.only(left: size.smallSpacing),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Tooltip(
                  message: field.labelTooltip!,
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.info,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
