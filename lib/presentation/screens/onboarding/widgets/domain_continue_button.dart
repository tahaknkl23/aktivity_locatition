import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/constants/app_colors.dart';

class DomainContinueButton extends StatelessWidget {
  final AppSizes size;
  final bool isLoading;
  final String? selectedDomain;
  final VoidCallback onPressed;

  const DomainContinueButton({
    super.key,
    required this.size,
    required this.isLoading,
    required this.selectedDomain,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      height: size.height * 0.07,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: selectedDomain == null ? Colors.grey.shade400 : AppColors.blueButtonColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: selectedDomain == null ? 0 : 8,
          shadowColor: AppColors.blueButtonColor.withValues(alpha: 0.4),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.arrow_forward, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    "Giriş Yap",
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}