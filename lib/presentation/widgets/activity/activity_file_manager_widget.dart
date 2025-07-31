// lib/presentation/widgets/activity/activity_file_manager_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../data/models/attachment/attachment_file_model.dart';

class ActivityFileManagerWidget extends StatefulWidget {
  final List<AttachmentFile> attachedFiles;
  final int? savedActivityId;
  final Function(AttachmentFile) onFileDeleted;

  const ActivityFileManagerWidget({
    super.key,
    required this.attachedFiles,
    required this.savedActivityId,
    required this.onFileDeleted,
  });

  @override
  State<ActivityFileManagerWidget> createState() => _ActivityFileManagerWidgetState();
}

class _ActivityFileManagerWidgetState extends State<ActivityFileManagerWidget> {
  bool _showFileDetails = false;

  @override
  Widget build(BuildContext context) {
    if (widget.attachedFiles.isEmpty) return SizedBox.shrink();

    final size = AppSizes.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Header - Always visible
          InkWell(
            onTap: () {
              setState(() {
                _showFileDetails = !_showFileDetails;
              });
            },
            child: Container(
              padding: EdgeInsets.all(size.cardPadding),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.folder, color: Colors.white, size: 16),
                  ),
                  SizedBox(width: size.smallSpacing),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Eklenen Dosyalar',
                          style: TextStyle(
                            fontSize: size.smallText,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.attachedFiles.length} dosya yüklendi',
                          style: TextStyle(
                            fontSize: size.textSize,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.attachedFiles.length.toString(),
                      style: TextStyle(
                        fontSize: size.smallText,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: size.smallSpacing),
                  Icon(
                    _showFileDetails ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ),

          // Expandable file list
          if (_showFileDetails) ...[
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
              ),
              child: Column(
                children: widget.attachedFiles.map((file) => _buildFileItem(file)).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFileItem(AttachmentFile file) {
    final size = AppSizes.of(context);

    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          // File type icon
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _getFileTypeColor(file.fileType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: _getFileTypeColor(file.fileType),
              size: 16,
            ),
          ),

          SizedBox(width: size.smallSpacing),

          // File info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.fileName,
                  style: TextStyle(
                    fontSize: size.smallText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: size.tinySpacing),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: _getFileTypeColor(file.fileType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getFileTypeText(file.fileType),
                        style: TextStyle(
                          fontSize: size.smallText * 0.8,
                          color: _getFileTypeColor(file.fileType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (file.createdUserName.isNotEmpty) ...[
                      SizedBox(width: size.tinySpacing),
                      Icon(Icons.person, size: 10, color: AppColors.textTertiary),
                      SizedBox(width: 2),
                      Text(
                        file.createdUserName,
                        style: TextStyle(
                          fontSize: size.smallText * 0.8,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isImageFile(file))
                InkWell(
                  onTap: () => _viewFile(file),
                  child: Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(Icons.visibility, size: 14, color: AppColors.primary),
                  ),
                ),
              SizedBox(width: 4),
              InkWell(
                onTap: () => _deleteFile(file),
                child: Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(Icons.delete_outline, size: 14, color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // File helper methods
  Color _getFileTypeColor(int fileType) {
    switch (fileType) {
      case 0:
        return AppColors.success; // Image
      case 1:
        return AppColors.info; // Document
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getFileTypeIcon(int fileType) {
    switch (fileType) {
      case 0:
        return Icons.image;
      case 1:
        return Icons.description;
      default:
        return Icons.attach_file;
    }
  }

  String _getFileTypeText(int fileType) {
    switch (fileType) {
      case 0:
        return 'Resim';
      case 1:
        return 'Belge';
      default:
        return 'Dosya';
    }
  }

  bool _isImageFile(AttachmentFile file) {
    return file.fileType == 0 ||
        file.fileName.toLowerCase().endsWith('.jpg') ||
        file.fileName.toLowerCase().endsWith('.jpeg') ||
        file.fileName.toLowerCase().endsWith('.png') ||
        file.fileName.toLowerCase().endsWith('.gif');
  }

  // File actions
  Future<void> _viewFile(AttachmentFile file) async {
    if (!_isImageFile(file)) {
      SnackbarHelper.showInfo(
        context: context,
        message: 'Bu dosya türü için görüntüleme desteklenmiyor',
      );
      return;
    }

    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Resim yükleniyor...'),
              ],
            ),
          ),
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading

        // Geçici olarak sadece bilgi göster
        SnackbarHelper.showInfo(
          context: context,
          message: 'Resim görüntüleme özelliği geliştiriliyor...',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        SnackbarHelper.showError(
          context: context,
          message: 'Resim görüntülenemedi: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _deleteFile(AttachmentFile file) async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('Dosyayı Sil'),
              ],
            ),
            content: Text(
              '${file.fileName} dosyasını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: Text('Sil'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    try {
   
      widget.onFileDeleted(file);

      SnackbarHelper.showSuccess(
        context: context,
        message: 'Dosya listeden kaldırıldı (API bağlantısı gerekli)',
      );

    } catch (e) {
      debugPrint('[FILE_MANAGER] Delete error: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya silinemedi: ${e.toString()}',
      );
    }
  }
}
