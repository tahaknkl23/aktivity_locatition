// lib/presentation/widgets/activity/address_card_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/activity/activity_list_model.dart';

class AddressCardWidget extends StatelessWidget {
  final CompanyAddress selectedAddress;

  const AddressCardWidget({
    super.key,
    required this.selectedAddress,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_on, color: Colors.white, size: 16),
          ),
          SizedBox(width: size.smallSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seçilen Adres',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  selectedAddress.displayAddress,
                  style: TextStyle(
                    fontSize: size.textSize,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}