// lib/presentation/widgets/common/file_upload_widget.dart - MOBİLE UYUMLUwww.dart
import 'dart:convert';
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
  final bool showUploadButton;

  const FileUploadWidget({
    super.key,
    this.activityId,
    this.tableId = 102, // Activity table ID
    this.onFileUploaded,
    this.onFileDeleted,
    this.showUploadButton = true,
  });

  @override
  State<FileUploadWidget> createState() => _FileUploadWidgetState();
}

class _FileUploadWidgetState extends State<FileUploadWidget> {
  final List<AttachmentFile> _attachedFiles = [];
  bool _isUploading = false;
  bool _isLoading = true;

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
        });

        debugPrint('[FILE_UPLOAD] Loaded ${_attachedFiles.length} existing files');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] Load files error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Dosyalar yüklenemedi: ${e.toString()}',
        );
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
          // Header
          _buildHeader(size),

          SizedBox(height: size.mediumSpacing),

          // Upload buttons (sadece aktivite kaydedildikten sonra)
          if (widget.activityId != null && widget.showUploadButton) _buildUploadButtons(size),

          // Info message (aktivite kaydedilmemişse)
          if (widget.activityId == null) _buildInfoMessage(size),

          // Loading indicator
          if (_isLoading) ...[
            SizedBox(height: size.mediumSpacing),
            _buildLoadingIndicator(size),
          ]
          // File list
          else if (_attachedFiles.isNotEmpty) ...[
            SizedBox(height: size.mediumSpacing),
            _buildFileList(size),
          ]
          // Empty state
          else if (widget.activityId != null) ...[
            SizedBox(height: size.mediumSpacing),
            _buildEmptyState(size),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AppSizes size) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
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
        if (_attachedFiles.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: size.smallSpacing,
              vertical: size.tinySpacing,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_attachedFiles.length}',
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUploadButtons(AppSizes size) {
    return Column(
      children: [
        // İlk satır: Kamera ve Galeri
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _capturePhoto,
                icon: _isUploading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(Icons.camera_alt, size: 18),
                label: Text(
                  _isUploading ? 'Yükleniyor...' : 'Fotoğraf Çek',
                  style: TextStyle(fontSize: size.smallText),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: size.smallSpacing),
                ),
              ),
            ),
            SizedBox(width: size.smallSpacing),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickFromGallery,
                icon: Icon(Icons.photo_library, size: 18),
                label: Text(
                  'Galeri',
                  style: TextStyle(fontSize: size.smallText),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.secondary),
                  foregroundColor: AppColors.secondary,
                  padding: EdgeInsets.symmetric(vertical: size.smallSpacing),
                ),
              ),
            ),
          ],
        ),

        SizedBox(height: size.smallSpacing),

        // İkinci satır: Dosya seç
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _pickFile,
            icon: Icon(Icons.description, size: 18),
            label: Text(
              'Dosya Seç',
              style: TextStyle(fontSize: size.smallText),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.info),
              foregroundColor: AppColors.info,
              padding: EdgeInsets.symmetric(vertical: size.smallSpacing),
            ),
          ),
        ),
      ],
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
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
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
      ),
    );
  }

  Widget _buildEmptyState(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding * 1.5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.file_present,
            size: 48,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Henüz dosya eklenmemiş',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: size.tinySpacing),
          Text(
            'Fotoğraf çekmek veya dosya eklemek için yukarıdaki butonları kullanın',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(AppSizes size) {
    return Column(
      children: _attachedFiles.map((file) => _buildFileItem(file, size)).toList(),
    );
  }

  Widget _buildFileItem(AttachmentFile file, AppSizes size) {
    return Container(
      margin: EdgeInsets.only(bottom: size.smallSpacing),
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
              color: _getFileTypeColor(file.fileType).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getFileTypeIcon(file.fileType),
              color: _getFileTypeColor(file.fileType),
              size: 20,
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
                    fontSize: size.textSize,
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
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getFileTypeColor(file.fileType).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        file.fileTypeText,
                        style: TextStyle(
                          fontSize: size.smallText * 0.9,
                          color: _getFileTypeColor(file.fileType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    SizedBox(width: size.smallSpacing),
                    Expanded(
                      child: Text(
                        '${file.createdUserName} • ${_formatDate(file.createdDate)}',
                        style: TextStyle(
                          fontSize: size.smallText,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// 📸 Kameradan fotoğraf çek
  Future<void> _capturePhoto() async {
    try {
      setState(() => _isUploading = true);

      final fileData = await FileService.instance.capturePhoto();
      if (fileData != null) {
        await _uploadFile(fileData);
      }
    } catch (e) {
      SnackbarHelper.showError(context: context, message: 'Fotoğraf çekilemedi: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// 🖼️ Galeriden fotoğraf seç
  Future<void> _pickFromGallery() async {
    try {
      setState(() => _isUploading = true);

      final fileData = await FileService.instance.pickImageFromGallery();
      if (fileData != null) {
        await _uploadFile(fileData);
      }
    } catch (e) {
      SnackbarHelper.showError(context: context, message: 'Fotoğraf seçilemedi: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// 📄 Dosya seç
  Future<void> _pickFile() async {
    try {
      setState(() => _isUploading = true);

      final fileData = await FileService.instance.pickFile();
      if (fileData != null) {
        await _uploadFile(fileData);
      }
    } catch (e) {
      SnackbarHelper.showError(context: context, message: 'Dosya seçilemedi: ${e.toString()}');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  /// 📤 Dosyayı sunucuya yükle
  Future<void> _uploadFile(FileData fileData) async {
    if (widget.activityId == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite kaydedilmeden dosya yüklenemez',
      );
      return;
    }

    try {
      final response = await FileService.instance.uploadActivityFile(
        activityId: widget.activityId!,
        file: fileData,
      );

      // 🎯 WEB response'u kontrol et
      if (response.isSuccess && response.hasFiles) {
        await _loadExistingFiles(); // Refresh file list

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Dosya başarıyla yüklendi: ${fileData.name}',
        );

        // Notify parent widget with uploaded file
        if (response.firstFile != null) {
          widget.onFileUploaded?.call(response.firstFile!);
        }
      } else {
        throw FileException('Upload response invalid: ${response.errorMessage ?? "Unknown error"}');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] Upload error: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya yüklenemedi: ${e.toString()}',
      );
    }
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
      // Loading göster
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

      final imageUrl = await FileService.instance.getFileViewUrl(file);

      if (mounted) {
        Navigator.pop(context); // Loading'i kapat

        if (imageUrl != null) {
          _showImageDialog(file, imageUrl);
        } else {
          SnackbarHelper.showError(
            context: context,
            message: 'Resim yüklenemedi',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Loading'i kapat
        SnackbarHelper.showError(
          context: context,
          message: 'Resim görüntülenemedi: ${e.toString()}',
        );
      }
    }
  }

  /// 🖼️ Resim görüntüleme dialogu
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
                      child: Image.memory(
                        base64Decode(imageUrl.split(',')[1]),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: AppColors.background,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: AppColors.error),
                                SizedBox(height: 8),
                                Text('Resim yüklenemedi', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          );
                        },
                      ),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}
