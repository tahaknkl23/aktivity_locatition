// close_activity_dialog.dart - GELİŞTİRİLMİŞ VERSİYON

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class CloseActivityDialog extends StatelessWidget {
  final String? activityTitle;
  final String? currentLocation;
  final String? companyName;

  const CloseActivityDialog({
    super.key,
    this.activityTitle,
    this.currentLocation,
    this.companyName,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
      ),
      title: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_off,
              color: AppColors.warning,
              size: 24,
            ),
          ),
          SizedBox(width: size.mediumSpacing),
          Expanded(
            child: Text(
              'Aktiviteyi Kapat',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ana mesaj
          Text(
            'Bu aktiviteyi kapatmak istediğinizden emin misiniz?',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),

          SizedBox(height: size.mediumSpacing),

          // Bilgi kartı
          Container(
            padding: EdgeInsets.all(size.cardPadding),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(size.cardBorderRadius),
              border: Border.all(
                color: AppColors.info.withValues(alpha:0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Aktivite bilgisi
                if (activityTitle != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.event,
                        size: 16,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Aktivite: $activityTitle',
                          style: TextStyle(
                            fontSize: size.smallText,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                // Firma bilgisi
                if (companyName != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.business,
                        size: 16,
                        color: AppColors.info,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Firma: $companyName',
                          style: TextStyle(
                            fontSize: size.smallText,
                            color: AppColors.info,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                ],

                // Konum bilgisi
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: AppColors.info,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentLocation != null ? 'Bitiş konumu: $currentLocation' : 'Bitiş konumu kaydedilecek',
                        style: TextStyle(
                          fontSize: size.smallText,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: size.mediumSpacing),

          // Uyarı metni
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.warning,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Kapatılan aktivite tekrar açılamaz. Tüm bilgilerin doğru olduğundan emin olun.',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // İptal butonu
        TextButton(
          onPressed: () {
            debugPrint('[CloseActivityDialog] ❌ User cancelled close action');
            Navigator.of(context).pop(false);
          },
          child: Text(
            'İptal',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size.textSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Kapat butonu
        ElevatedButton(
          onPressed: () {
            debugPrint('[CloseActivityDialog] ✅ User confirmed close action');
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.textOnPrimary,
            padding: EdgeInsets.symmetric(
              horizontal: size.largeSpacing,
              vertical: size.smallSpacing,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(size.cardBorderRadius),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.close, size: 18),
              SizedBox(width: 8),
              Text(
                'Kapat',
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
