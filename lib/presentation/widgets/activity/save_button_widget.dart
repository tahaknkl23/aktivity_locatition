// save_button_widget.dart - MULTIPLE CLICK PROTECTION
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class SaveButtonWidget extends StatefulWidget {
  final bool isSaving;
  final bool isEditing;
  final VoidCallback onSave;
  final VoidCallback? onDelete;
  final bool showDeleteButton;

  const SaveButtonWidget({
    super.key,
    required this.isSaving,
    required this.isEditing,
    required this.onSave,
    this.onDelete,
    this.showDeleteButton = false,
  });

  @override
  State<SaveButtonWidget> createState() => _SaveButtonWidgetState();
}

class _SaveButtonWidgetState extends State<SaveButtonWidget> {
  DateTime? _lastSaveClick;
  DateTime? _lastDeleteClick;

  // 🔥 Click protection - 2 saniye içinde tekrar tıklamaya izin verme
  static const Duration _clickCooldown = Duration(seconds: 2);

  void _handleSaveClick() {
    final now = DateTime.now();

    // 🚫 Cooldown check
    if (_lastSaveClick != null && now.difference(_lastSaveClick!) < _clickCooldown) {
      debugPrint('[SaveButton] 🚫 Save click ignored - cooldown active');
      return;
    }

    // 🚫 Already saving check
    if (widget.isSaving) {
      debugPrint('[SaveButton] 🚫 Save click ignored - already saving');
      return;
    }

    _lastSaveClick = now;
    debugPrint('[SaveButton] 💾 Save click accepted at: $now');

    widget.onSave();
  }

  void _handleDeleteClick() {
    final now = DateTime.now();

    // 🚫 Cooldown check
    if (_lastDeleteClick != null && now.difference(_lastDeleteClick!) < _clickCooldown) {
      debugPrint('[SaveButton] 🚫 Delete click ignored - cooldown active');
      return;
    }

    // 🚫 Already saving check
    if (widget.isSaving) {
      debugPrint('[SaveButton] 🚫 Delete click ignored - save in progress');
      return;
    }

    if (widget.onDelete == null) {
      debugPrint('[SaveButton] 🚫 Delete click ignored - no handler');
      return;
    }

    _lastDeleteClick = now;
    debugPrint('[SaveButton] 🗑️ Delete click accepted at: $now');

    widget.onDelete!();
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final screenWidth = size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? size.cardPadding * 1.2 : size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // 🗑️ DELETE BUTTON (opsiyonel)
            if (widget.showDeleteButton && widget.isEditing && widget.onDelete != null) ...[
              Expanded(
                child: _buildDeleteButton(size, isTablet),
              ),
              SizedBox(width: size.mediumSpacing),
            ],

            // 💾 SAVE BUTTON
            Expanded(
              flex: widget.showDeleteButton && widget.isEditing ? 2 : 1,
              child: _buildSaveButton(size, isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(AppSizes size, bool isTablet) {
    final isDisabled = widget.isSaving;

    return OutlinedButton(
      onPressed: isDisabled ? null : _handleDeleteClick,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: isDisabled ? AppColors.error.withValues(alpha:  0.3) : AppColors.error,
          width: isTablet ? 2 : 1,
        ),
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? size.buttonHeight * 0.4 : size.buttonHeight * 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
        ),
        foregroundColor: isDisabled ? AppColors.error.withValues(alpha: 0.3) : AppColors.error,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: isTablet ? 22 : 20,
          ),
          SizedBox(width: size.smallSpacing),
          Text(
            'Sil',
            style: TextStyle(
              fontSize: isTablet ? size.textSize * 1.1 : size.textSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(AppSizes size, bool isTablet) {
    final isDisabled = widget.isSaving;

    return ElevatedButton(
      onPressed: isDisabled ? null : _handleSaveClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? AppColors.textTertiary : AppColors.primary,
        foregroundColor: isDisabled ? AppColors.textOnPrimary.withValues(alpha: 0.7) : AppColors.textOnPrimary,
        disabledBackgroundColor: AppColors.textTertiary,
        disabledForegroundColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
        padding: EdgeInsets.symmetric(
          vertical: isTablet ? size.buttonHeight * 0.4 : size.buttonHeight * 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
        ),
        elevation: isDisabled ? 0 : (isTablet ? 4 : 3),
      ),
      child: widget.isSaving ? _buildLoadingContent(size, isTablet) : _buildSaveContent(size, isTablet),
    );
  }

  Widget _buildLoadingContent(AppSizes size, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: isTablet ? 22 : 20,
          width: isTablet ? 22 : 20,
          child: CircularProgressIndicator(
            strokeWidth: isTablet ? 3 : 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
        ),
        SizedBox(width: size.smallSpacing),
        Text(
          widget.isEditing ? 'Güncelleniyor...' : 'Kaydediliyor...',
          style: TextStyle(
            fontSize: isTablet ? size.textSize * 1.1 : size.textSize,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildSaveContent(AppSizes size, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.isEditing ? Icons.update : Icons.save,
          size: isTablet ? 22 : 20,
        ),
        SizedBox(width: size.smallSpacing),
        Text(
          widget.isEditing ? 'Güncelle' : 'Kaydet',
          style: TextStyle(
            fontSize: isTablet ? size.textSize * 1.1 : size.textSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
