import 'package:aktivity_location_app/core/constants/app_colors.dart';
import 'package:aktivity_location_app/core/constants/app_sizes.dart';
import 'package:aktivity_location_app/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class ForgotPassword extends StatelessWidget {
  final VoidCallback onTap;
  const ForgotPassword({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    return Padding(
      padding: EdgeInsets.only(top: size.height * 0.01),
      child: TextButton(
        onPressed: onTap,
        child: Text(
          AppStrings.forgotMyPassword,
          style: TextStyle(
            fontSize: size.textSize, // 🎯 DEĞİŞTİRİLDİ: smallText → textSize
            color: AppColors.dividerColor,
            decoration: TextDecoration.underline,
            decorationStyle: TextDecorationStyle.solid,
            decorationColor: AppColors.dividerColor,
          ),
        ),
      ),
    );
  }
}