// lib/core/widgets/common/info_item_widget.dart
import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_sizes.dart';

class InfoItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;

  const InfoItemWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final displayValue = isEmpty ? 'Belirtilmemiş' : value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isEmpty ? AppColors.textTertiary : AppColors.textSecondary,
            ),
            SizedBox(width: size.tinySpacing),
            Text(
              label,
              style: TextStyle(
                fontSize: size.smallText * 0.9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: size.tinySpacing),
        Text(
          displayValue,
          style: TextStyle(
            fontSize: size.smallText,
            color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
