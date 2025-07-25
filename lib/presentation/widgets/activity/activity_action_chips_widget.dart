// lib/presentation/widgets/activity/activity_action_chips_widget.dart - ŞUBE ODAKLI VERSİYON
import 'package:aktivity_location_app/data/services/api/activity_api_service.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/attachment/attachment_file_model.dart';

enum ChipStatus {
  inactive,
  active,
  success,
  warning,
  error,
  loading,
}

class ActivityActionChipsWidget extends StatelessWidget {
  final bool isEditing;
  final int? savedActivityId;
  final LocationData? currentLocation;
  final LocationComparisonResult? locationComparison;
  final List<AttachmentFile> attachedFiles;
  final bool isGettingLocation;
  final bool isClosingActivity;
  final VoidCallback? onGetLocation;
  final VoidCallback? onShowFileOptions;
  final VoidCallback? onCloseActivity;

  const ActivityActionChipsWidget({
    super.key,
    required this.isEditing,
    required this.savedActivityId,
    required this.currentLocation,
    required this.locationComparison,
    required this.attachedFiles,
    required this.isGettingLocation,
    required this.isClosingActivity,
    this.onGetLocation,
    this.onShowFileOptions,
    this.onCloseActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 🔧 SADECE EDİTİNG MODE'DA BUTONLAR
          if (isEditing) ...[
            _buildActionChip(
              context: context,
              icon: Icons.my_location,
              label: currentLocation != null ? 'Konum Alındı' : 'Konum Al',
              status: _getLocationChipStatus(),
              onTap: isGettingLocation ? null : onGetLocation,
            ),
            SizedBox(width: 8),
            _buildActionChip(
              context: context,
              icon: Icons.attach_file,
              label: 'Dosya',
              status: attachedFiles.isNotEmpty ? ChipStatus.success : ChipStatus.inactive,
              badge: attachedFiles.isNotEmpty ? attachedFiles.length : null,
              onTap: () => _handleFilesTap(context),
            ),
          ],
          if (isEditing && currentLocation != null) ...[
            SizedBox(width: 8),
            _buildActionChip(
              context: context,
              icon: Icons.close_outlined,
              label: 'Kapat',
              status: isClosingActivity ? ChipStatus.loading : ChipStatus.warning,
              onTap: isClosingActivity ? null : onCloseActivity,
            ),
          ],
        ],
      ),
    );
  }

  /// 🆕 ŞUBE ODAKLI Konum chip status'u
  ChipStatus _getLocationChipStatus() {
    if (isGettingLocation) return ChipStatus.loading;

    if (currentLocation != null) {
      if (locationComparison?.isAtSameLocation == true) {
        return ChipStatus.success; // Şubede
      } else if (locationComparison?.isDifferentLocation == true) {
        return ChipStatus.warning; // Şube dışında
      } else if (locationComparison?.status == LocationComparisonStatus.noCompanyLocation) {
        return ChipStatus.active; // Şube seçilmedi ama konum var
      } else {
        return ChipStatus.error; // Hata durumu
      }
    }

    return ChipStatus.inactive; // Konum yok
  }

  void _handleFilesTap(BuildContext context) {
    if (savedActivityId == null) {
      SnackbarHelper.showInfo(
        context: context,
        message: 'Dosya eklemek için önce aktiviteyi kaydedin',
      );
    } else if (onShowFileOptions != null) {
      onShowFileOptions!();
    }
  }

  Widget _buildActionChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required ChipStatus status,
    int? badge,
    VoidCallback? onTap,
  }) {
    Color backgroundColor;
    Color textColor;
    Color borderColor;

    switch (status) {
      case ChipStatus.success:
        backgroundColor = AppColors.success.withValues(alpha: 0.1);
        textColor = AppColors.success;
        borderColor = AppColors.success.withValues(alpha: 0.3);
        break;
      case ChipStatus.warning:
        backgroundColor = AppColors.warning.withValues(alpha: 0.1);
        textColor = AppColors.warning;
        borderColor = AppColors.warning.withValues(alpha: 0.3);
        break;
      case ChipStatus.error:
        backgroundColor = AppColors.error.withValues(alpha: 0.1);
        textColor = AppColors.error;
        borderColor = AppColors.error.withValues(alpha: 0.3);
        break;
      case ChipStatus.active:
        backgroundColor = AppColors.primary.withValues(alpha: 0.1);
        textColor = AppColors.primary;
        borderColor = AppColors.primary.withValues(alpha: 0.3);
        break;
      case ChipStatus.loading:
        backgroundColor = AppColors.info.withValues(alpha: 0.1);
        textColor = AppColors.info;
        borderColor = AppColors.info.withValues(alpha: 0.3);
        break;
      case ChipStatus.inactive:
        backgroundColor = AppColors.surface;
        textColor = AppColors.textSecondary;
        borderColor = AppColors.border;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == ChipStatus.loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            else
              Icon(icon, size: 18, color: textColor),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            if (badge != null) ...[
              SizedBox(width: 4),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge.toString(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
