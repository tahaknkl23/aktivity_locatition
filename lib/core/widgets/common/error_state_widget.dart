// lib/core/widgets/common/error_state_widget.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final String? retryButtonText;
  final VoidCallback? onRetry;
  final String? backButtonText;
  final VoidCallback? onBack;

  const ErrorStateWidget({
    super.key,
    required this.title,
    required this.message,
    this.retryButtonText = 'Tekrar Dene',
    this.onRetry,
    this.backButtonText = 'Geri Dön',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding * 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(size.cardBorderRadius * 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(size.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: size.smallSpacing),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.textSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onBack != null) ...[
                        OutlinedButton(
                          onPressed: onBack,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.textSecondary),
                          ),
                          child: Text(backButtonText!),
                        ),
                        if (onRetry != null) SizedBox(width: size.mediumSpacing),
                      ],
                      if (onRetry != null)
                        ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                          child: Text(retryButtonText!),
                        ),
                    ],
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