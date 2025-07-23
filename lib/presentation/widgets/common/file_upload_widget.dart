// lib/presentation/widgets/common/file_upload_widget.dart - Expandable Liste
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/services/file_service.dart';
import '../../../data/models/attachment/attachment_file_model.dart';

class FileUploadWidget extends StatefulWidget {
  final int? activityId;
  final int? tableId;
  final Function(AttachmentFile)? onFileUploaded;
  final Function(AttachmentFile)? onFileDeleted;
  final Function()? onShowFileOptions;

  const FileUploadWidget({
    super.key,
    this.activityId,
    this.tableId = 102,
    this.onFileUploaded,
    this.onFileDeleted,
    this.onShowFileOptions,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final List<AttachmentFile> _attachedFiles = [];
  bool _isLoading = true;
  bool _isExpanded = false; // Expand/collapse state

  @override
  void initState() {
    super.initState();
    if (widget.activityId != null) {
      _loadExistingFiles();
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// 📂 Mevcut dosyaları yükle
  Future<void> _loadExistingFiles() async {
    if (widget.activityId == null) return;

    try {
      setState(() => _isLoading = true);

      final response = await FileService.instance.getActivityFiles(
        activityId: widget.activityId!,
        tableId: widget.tableId,
      );

      if (mounted) {
        setState(() {
          _attachedFiles.clear();
          _attachedFiles.addAll(response.data);
          _isLoading = false;
          // Dosya varsa da kapalı başla - kullanıcı isterse açar
          _isExpanded = false;
        });

        debugPrint('[FILE_UPLOAD] Loaded ${_attachedFiles.length} existing files');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] Load files error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expandable Header
          _buildExpandableHeader(size),

          // Info message (aktivite kaydedilmemişse)
          if (widget.activityId == null) ...[
            SizedBox(height: size.mediumSpacing),
            _buildInfoMessage(size),
          ]
          // Loading indicator
          else if (_isLoading) ...[
            SizedBox(height: size.smallSpacing),
            _buildLoadingIndicator(size),
          ]
          // Expanded content - dosya listesi
          else if (_isExpanded && _attachedFiles.isNotEmpty) ...[
            SizedBox(height: size.smallSpacing),
            _buildFileList(size),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableHeader(AppSizes size) {
    return GestureDetector(
      onTap: () {
        debugPrint('[FILE_UPLOAD] Header tapped, files count: ${_attachedFiles.length}, activityId: ${widget.activityId}');

        if (_attachedFiles.isNotEmpty) {
          debugPrint('[FILE_UPLOAD] Toggling expand state');
          setState(() {
            _isExpanded = !_isExpanded;
          });
        } else if (widget.activityId != null) {
          debugPrint('[FILE_UPLOAD] Calling onShowFileOptions');
          // Dosya yoksa bottom sheet aç
          widget.onShowFileOptions?.call();
        } else {
          debugPrint('[FILE_UPLOAD] ActivityId is null, cannot show file options');
        }
      },
      child: Container(
        padding: EdgeInsets.all(size.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // File icon
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.attach_file,
                color: AppColors.primary,
                size: 20,
              ),
            ),

            SizedBox(width: size.smallSpacing),

            // Title
            Expanded(
              child: Text(
                'Dosyalar',
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Count badge
            if (_attachedFiles.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.smallSpacing,
                  vertical: size.tinySpacing,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_attachedFiles.length}',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            SizedBox(width: size.smallSpacing),

            // Expand/Add icon
            if (_attachedFiles.isNotEmpty)
              AnimatedRotation(
                duration: Duration(milliseconds: 200),
                turns: _isExpanded ? 0.5 : 0,
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                  size: 24,
                ),
              )
            else if (widget.activityId != null)
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoMessage(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info, size: 20),
          SizedBox(width: size.smallSpacing),
          Expanded(
            child: Text(
              'Dosya eklemek için önce aktiviteyi kaydedin',
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.info,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator(AppSizes size) {
    return Padding(
      padding: EdgeInsets.all(size.cardPadding),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: size.smallSpacing),
          Text(
            'Dosyalar yükleniyor...',
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(AppSizes size) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          // Direkt dosya listesi - Dosya Ekle butonu yok
          ..._attachedFiles.map((file) => _buildFileItem(file, size)),
        ],
      ),
    );
  }

  Widget _buildFileItem(AttachmentFile file, AppSizes size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.smallSpacing),
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.border),
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
                Text(
                  '${file.createdUserName} • ${_formatDate(file.createdDate)}',
                  style: TextStyle(
                    fontSize: size.smallText * 0.9,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Actions
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'view':
                  _viewFile(file);
                  break;
                case 'delete':
                  _deleteFile(file);
                  break;
              }
            },
            itemBuilder: (context) => [
              if (file.isImage)
                PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 16),
                      SizedBox(width: 8),
                      Text('Görüntüle'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: AppColors.error),
                    SizedBox(width: 8),
                    Text('Sil', style: TextStyle(color: AppColors.error)),
                  ],
                ),
              ),
            ],
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
          ),
        ],
      ),
    );
  }

  /// 👁️ Dosyayı görüntüle
  Future<void> _viewFile(AttachmentFile file) async {
    if (!file.isImage) {
      SnackbarHelper.showInfo(
        context: context,
        message: 'Bu dosya türü için görüntüleme desteklenmiyor',
      );
      return;
    }

    try {
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

      debugPrint('[IMAGE_VIEW] Getting image for file: ${file.fileName}');
      debugPrint('[IMAGE_VIEW] File local name: ${file.localName}');

      final imageUrl = await FileService.instance.getFileViewUrl(file);

      if (mounted) {
        Navigator.pop(context);

        if (imageUrl != null) {
          debugPrint('[IMAGE_VIEW] Image URL received, length: ${imageUrl.length}');
          debugPrint('[IMAGE_VIEW] Image URL preview: ${imageUrl.substring(0, math.min(100, imageUrl.length))}...');
          _showImageDialog(file, imageUrl);
        } else {
          debugPrint('[IMAGE_VIEW] Image URL is null');
          SnackbarHelper.showError(
            context: context,
            message: 'Resim yüklenemedi - API\'den veri gelmedi',
          );
        }
      }
    } catch (e) {
      debugPrint('[IMAGE_VIEW] Error: $e');
      if (mounted) {
        Navigator.pop(context);
        SnackbarHelper.showError(
          context: context,
          message: 'Resim görüntülenemedi: ${e.toString()}',
        );
      }
    }
  }

  void _showImageDialog(AttachmentFile file, String imageUrl) {
    final size = AppSizes.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(size.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          file.fileName,
                          style: TextStyle(
                            fontSize: size.textSize,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close),
                      ),
                    ],
                  ),
                  SizedBox(height: size.smallSpacing),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: size.height * 0.6,
                      maxWidth: size.width * 0.9,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildImageWidget(imageUrl),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    try {
      // Base64 string'i temizle ve decode et
      String base64String = imageUrl;

      // "data:image/jpeg;base64," prefix'ini kaldır
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      // Gereksiz tırnak işaretlerini kaldır
      base64String = base64String.replaceAll('"', '');

      // Base64 string'i normalize et (whitespace ve newline'ları kaldır)
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');

      debugPrint('[IMAGE_VIEW] Cleaned base64 length: ${base64String.length}');
      debugPrint('[IMAGE_VIEW] Cleaned base64 preview: ${base64String.substring(0, math.min(50, base64String.length))}...');

      // Base64 decode yap
      final bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[IMAGE_VIEW] Image decode error: $error');
          return _buildImageError();
        },
      );
    } catch (e) {
      debugPrint('[IMAGE_VIEW] Base64 decode error: $e');
      return _buildImageError();
    }
  }

  Widget _buildImageError() {
    return Container(
      height: 200,
      color: AppColors.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: AppColors.error),
          SizedBox(height: 8),
          Text(
            'Resim yüklenemedi',
            style: TextStyle(color: AppColors.error),
          ),
          SizedBox(height: 4),
          Text(
            'Dosya formatı desteklenmiyor',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// 🗑️ Dosyayı sil
  Future<void> _deleteFile(AttachmentFile file) async {
    final shouldDelete = await _showDeleteDialog(file.fileName);
    if (!shouldDelete) return;

    try {
      final response = await FileService.instance.deleteActivityFile(
        file: file,
        activityId: widget.activityId!,
        tableId: widget.tableId,
      );

      if (response.isSuccess) {
        setState(() {
          _attachedFiles.removeWhere((f) => f.id == file.id);
          // Dosya kalmadıysa kapat
          if (_attachedFiles.isEmpty) {
            _isExpanded = false;
          }
        });

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Dosya silindi: ${file.fileName}',
        );

        widget.onFileDeleted?.call(file);
      } else {
        throw FileException('Delete failed: ${response.message ?? "Unknown error"}');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] Delete error: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya silinemedi: ${e.toString()}',
      );
    }
  }

  Future<bool> _showDeleteDialog(String fileName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('Dosyayı Sil'),
              ],
            ),
            content: Text(
              '$fileName dosyasını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.',
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
  }

  Color _getFileTypeColor(int fileType) {
    switch (fileType) {
      case 0:
        return AppColors.success;
      case 1:
        return AppColors.info;
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
