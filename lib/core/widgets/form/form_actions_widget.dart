// lib/core/widgets/form/form_actions_widget.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class FormActionsWidget extends StatelessWidget {
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final Widget? additionalContent;
  final VoidCallback? onClose;

  const FormActionsWidget({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
    this.onCancel,
    this.additionalContent,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ek içerik (adres bilgisi, konum vb)
            if (additionalContent != null) ...[
              additionalContent!,
              SizedBox(height: size.mediumSpacing),
            ],

            // Ana butonlar
            Row(
              children: [
                // İptal butonu
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : (onCancel ?? () => Navigator.of(context).pop()),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.25),
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

                // Kaydet butonu
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.cardBorderRadius),
                      ),
                      elevation: 3,
                    ),
                    child: isSaving
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
                                isEditing ? Icons.update : Icons.save,
                                size: 20,
                              ),
                              SizedBox(width: size.smallSpacing),
                              Text(
                                isEditing ? 'Güncelle' : 'Kaydet',
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
          ],
        ),
      ),
    );
  }
}
