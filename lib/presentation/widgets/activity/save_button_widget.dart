// lib/presentation/widgets/activity/save_button_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SaveButtonWidget extends StatelessWidget {
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;

  const SaveButtonWidget({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 20 : size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isSaving ? null : onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? 16 : size.cardPadding,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
              elevation: 3,
            ),
            child: isSaving ? _buildLoadingContent(isTablet, size) : _buildSaveContent(isTablet, size),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingContent(bool isTablet, AppSizes size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: isTablet ? 24 : 20,
          width: isTablet ? 24 : 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        SizedBox(width: isTablet ? 16 : 12),
        Text(
          'Kaydediliyor...',
          style: TextStyle(
            fontSize: isTablet ? 18 : size.textSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveContent(bool isTablet, AppSizes size) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isEditing ? Icons.update : Icons.save,
          size: isTablet ? 24 : 20,
        ),
        SizedBox(width: isTablet ? 12 : 8),
        Text(
          isEditing ? 'Güncelle' : 'Kaydet',
          style: TextStyle(
            fontSize: isTablet ? 18 : size.textSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
