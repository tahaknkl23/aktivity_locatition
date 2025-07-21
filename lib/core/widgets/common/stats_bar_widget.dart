// lib/core/widgets/common/stats_bar_widget.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class StatsBarWidget extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  final bool isLoading;

  const StatsBarWidget({
    super.key,
    required this.icon,
    required this.text,
    required this.iconColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size.cardPadding,
        vertical: size.smallSpacing,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: size.smallIcon,
            color: iconColor,
          ),
          SizedBox(width: size.smallSpacing),
          Text(
            text,
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (isLoading)
            SizedBox(
              width: size.smallIcon,
              height: size.smallIcon,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }
}
