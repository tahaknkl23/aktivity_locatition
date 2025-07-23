// lib/presentation/widgets/activity/close_activity_dialog.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class CloseActivityDialog extends StatelessWidget {
  const CloseActivityDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.close_outlined, 
            color: AppColors.warning,
            size: isTablet ? 28 : 24,
          ),
          SizedBox(width: isTablet ? 12 : 8),
          Expanded(
            child: Text(
              'Aktiviteyi Kapat',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu aktiviteyi kapatmak istediğinizden emin misiniz?',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isTablet ? 16 : 12),
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline, 
                  color: AppColors.info, 
                  size: isTablet ? 20 : 16,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Text(
                    'Kapatılan aktiviteler tekrar açılamaz',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : 12,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'İptal',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 20,
              vertical: isTablet ? 12 : 10,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            'Kapat',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}