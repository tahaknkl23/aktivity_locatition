// lib/core/widgets/dynamic_form/field_types/improved_empty_field_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../data/models/dynamic_form/form_field_model.dart';

/// Empty/Info field widget'ı - İYİLEŞTİRİLMİŞ VERSİYON
class EmptyFieldWidget extends StatelessWidget {
  final DynamicFormField field;
  final AppSizes size;

  const EmptyFieldWidget({
    super.key,
    required this.field,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final content = field.widget.properties['value']?.toString() ?? '';

    if (content.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.symmetric(vertical: size.smallSpacing),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.info.withValues(alpha: 0.08),
            AppColors.info.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
        border: Border.all(
          color: AppColors.info.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info icon
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.info_outline,
                color: AppColors.info,
                size: 18,
              ),
            ),

            SizedBox(width: size.smallSpacing),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bilgi',
                    style: TextStyle(
                      fontSize: size.smallText,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    content,
                    style: TextStyle(
                      fontSize: size.textSize * 0.95,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
