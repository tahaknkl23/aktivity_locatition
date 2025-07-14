import 'package:aktivity_location_app/core/constants/app_colors.dart';
import 'package:aktivity_location_app/core/constants/app_sizes.dart';
import 'package:aktivity_location_app/core/constants/app_strings.dart';
import 'package:flutter/material.dart';

class LoginButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const LoginButton({
    super.key,
    required this.onPressed,
    this.isLoading = false, // varsayılan false
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.blueButtonColor,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.02),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: isLoading
          ? SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  AppStrings.logIn,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: size.largeText,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(width: size.width * 0.04),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.white,
                ),
              ],
            ),
    );
  }
}