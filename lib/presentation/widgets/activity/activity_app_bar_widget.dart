// lib/presentation/widgets/activity/activity_app_bar_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ActivityAppBarWidget extends StatelessWidget {
  final bool isEditing;
  final int? activityId;
  final VoidCallback onBack;

  const ActivityAppBarWidget({
    super.key,
    required this.isEditing,
    required this.activityId,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * (isTablet ? 0.03 : 0.04),
            vertical: isTablet ? 16 : 12,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: isTablet ? 28 : 24,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'Aktivite Düzenle' : 'Yeni Aktivite',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : screenWidth * 0.045,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isEditing)
                      Text(
                        'ID: $activityId',
                        style: TextStyle(
                          fontSize: isTablet ? 14 : screenWidth * 0.03,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
              ),
              if (isEditing)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 16 : screenWidth * 0.03,
                    vertical: isTablet ? 8 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Düzenleme',
                    style: TextStyle(
                      fontSize: isTablet ? 14 : screenWidth * 0.03,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
