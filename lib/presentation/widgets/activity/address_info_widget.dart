// lib/presentation/widgets/activity/address_info_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/activity/activity_list_model.dart';

class AddressInfoWidget extends StatelessWidget {
  final CompanyAddress address;

  const AddressInfoWidget({
    super.key,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              SizedBox(width: size.smallSpacing),
              Expanded(
                child: Text(
                  'Seçilen Ziyaret Adresi',
                  style: TextStyle(
                    fontSize: size.textSize,
                    color: AppColors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (address.tipi != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    address.tipi!,
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),

          SizedBox(height: size.smallSpacing),

          // Ana adres
          Text(
            address.displayAddress,
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),

          // Tam adres (eğer farklıysa)
          if (address.fullAddress != address.displayAddress) ...[
            SizedBox(height: size.tinySpacing),
            Text(
              address.fullAddress,
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          SizedBox(height: size.smallSpacing),

          // Konum bilgisi
          Row(
            children: [
              Icon(
                Icons.place,
                size: 16,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: size.tinySpacing),
              Text(
                '${address.ilce}, ${address.il}',
                style: TextStyle(
                  fontSize: size.smallText,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
