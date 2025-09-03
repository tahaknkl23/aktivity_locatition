import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';

class InputDecorationBuilder {
  static InputDecoration build({
    required AppSizes size,
    required bool isEnabled,
    String? hintText,
    Widget? suffixIcon,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.textSecondary.withValues(alpha: 0.7),
        fontSize: size.textSize,
        fontWeight: FontWeight.w400,
      ),
      suffixIcon: suffixIcon,
      prefixIcon: prefixIcon,

      // Modern borders with better radius
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12), // More rounded
        borderSide: BorderSide(
          color: AppColors.border,
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.border,
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2.5, // Thicker focus border
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.error,
          width: 2.5,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),

      // Better padding
      contentPadding: EdgeInsets.symmetric(
        horizontal: size.cardPadding + 4, // Biraz daha fazla horizontal padding
        vertical: size.cardPadding + 2, // Biraz daha fazla vertical padding
      ),

      // Fill colors
      filled: true,
      fillColor: isEnabled ? AppColors.surface : AppColors.surfaceVariant.withValues(alpha: 0.5),

      // Icon theme
      iconColor: AppColors.textSecondary,
      suffixIconColor: AppColors.textSecondary,
      prefixIconColor: AppColors.textSecondary,
    );
  }
}
