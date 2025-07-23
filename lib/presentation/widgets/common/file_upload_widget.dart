// lib/presentation/widgets/common/file_upload_widget.dart - FİNAL VERSİYON
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
  bool _isExpanded = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingFiles();
  }

  @override
  void didUpdateWidget(FileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ActivityId değişirse dosyaları yeniden yükle
    if (oldWidget.activityId != widget.activityId) {
      _loadExistingFiles();
    }
  }

  /// 📂 Mevcut dosyaları yükle
  Future<void> _loadExistingFiles() async {
    if (widget.activityId == null) {
      setState(() => _isLoading = false);
      return;
    }

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

        debugPrint('[FILE_UPLOAD] ✅ Loaded ${_attachedFiles.length} existing files');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] ❌ Load files error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarHelper.showError(
          context: context,
          message: 'Dosyalar yüklenemedi: ${e.toString()}',
        );
      }
    }
  }

  /// 🔄 Dosyaları yenile (external call için)
  Future<void> refreshFiles() async {
    await _loadExistingFiles();
  }

  /// 📤 Dosya yükleme işlemi
  Future<void> _handleFileUpload(Future<FileData?> Function() captureFunction) async {
    if (widget.activityId == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      debugPrint('[FILE_UPLOAD] 📤 Starting file capture...');

      final fileData = await captureFunction();

      if (fileData == null) {
        debugPrint('[FILE_UPLOAD] ❌ No file selected');
        setState(() => _isUploading = false);
        return;
      }

      debugPrint('[FILE_UPLOAD] ✅ File captured: ${fileData.name}');
      debugPrint('[FILE_UPLOAD] 📁 File size: ${fileData.formattedSize}');

      // Show upload progress
      if (mounted) {
        SnackbarHelper.showInfo(
          context: context,
          message: 'Dosya yükleniyor: ${fileData.name}',
        );
      }

      // Upload file
      final response = await FileService.instance.uploadActivityFile(
        activityId: widget.activityId!,
        file: fileData,
        tableId: widget.tableId,
      );

      debugPrint('[FILE_UPLOAD] 📊 Upload response: ${response.isSuccess}');

      if (response.isSuccess && response.firstFile != null) {
        setState(() {
          _attachedFiles.add(response.firstFile!);
          _isExpanded = true; // Otomatik aç
        });

        widget.onFileUploaded?.call(response.firstFile!);

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Dosya başarıyla yüklendi: ${fileData.name}',
        );

        debugPrint('[FILE_UPLOAD] ✅ File uploaded successfully');

        // 🆕 Upload sonrası kesin refresh - biraz daha uzun bekle
        Future.delayed(Duration(milliseconds: 1000), () {
          if (mounted) {
            debugPrint('[FILE_UPLOAD] 🔄 Force refreshing file list after upload');
            _loadExistingFiles();
          }
        });
      } else {
        throw FileException(response.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] ❌ Upload error: $e');

      if (mounted) {
        String errorMsg = 'Dosya yüklenemedi';
        if (e is FileException) {
          errorMsg = e.message;
        } else if (e.toString().contains('SocketException')) {
          errorMsg = 'İnternet bağlantısı hatası';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = 'Yükleme zaman aşımı';
        } else {
          errorMsg = 'Dosya yüklenemedi: ${e.toString()}';
        }

        SnackbarHelper.showError(
          context: context,
          message: errorMsg,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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

          // Loading indicator
          if (_isLoading) ...[
            SizedBox(height: size.smallSpacing),
            _buildLoadingIndicator(size),
          ]
          // Upload indicator
          else if (_isUploading) ...[
            SizedBox(height: size.smallSpacing),
            _buildUploadingIndicator(size),
          ]
          // Info message (aktivite kaydedilmemişse)
          else if (widget.activityId == null) ...[
            SizedBox(height: size.mediumSpacing),
            _buildInfoMessage(size),
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
        debugPrint('[FILE_UPLOAD] 🎯 HEADER TAPPED!');

        if (_isLoading || _isUploading) {
          debugPrint('[FILE_UPLOAD] ⏳ Busy, ignoring tap');
          return;
        }

        if (_attachedFiles.isNotEmpty) {
          debugPrint('[FILE_UPLOAD] 📂 Toggling expand state');
          setState(() {
            _isExpanded = !_isExpanded;
          });
        } else if (widget.activityId != null) {
          debugPrint('[FILE_UPLOAD] 🚀 Showing file options');
          widget.onShowFileOptions?.call();
        } else {
          debugPrint('[FILE_UPLOAD] ❌ ActivityId is null');
          SnackbarHelper.showWarning(
            context: context,
            message: 'Aktivite kaydedilmeden dosya eklenemez',
          );
        }
      },
      child: Container(
        padding: EdgeInsets.all(size.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
          border: Border.all(
            color: _getBorderColor(),
            width: _getBorderWidth(),
          ),
        ),
        child: Row(
          children: [
            // File icon with visual indicator
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: _isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(
                      Icons.attach_file,
                      color: _getIconColor(),
                      size: 20,
                    ),
            ),

            SizedBox(width: size.smallSpacing),

            // Title with status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isUploading ? 'Dosya Yükleniyor...' : 'Dosyalar',
                    style: TextStyle(
                      fontSize: size.textSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getSubtitleText(),
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: _getSubtitleColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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

            // Action icon
            _buildActionIcon(size),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcon(AppSizes size) {
    if (_isLoading || _isUploading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_attachedFiles.isNotEmpty) {
      return AnimatedRotation(
        duration: Duration(milliseconds: 200),
        turns: _isExpanded ? 0.5 : 0,
        child: Icon(
          Icons.keyboard_arrow_down,
          color: AppColors.textSecondary,
          size: 24,
        ),
      );
    } else if (widget.activityId != null) {
      return Icon(
        Icons.add_circle_outline,
        color: AppColors.primary,
        size: 24,
      );
    } else {
      return Icon(
        Icons.lock,
        color: Colors.orange,
        size: 24,
      );
    }
  }

  // Helper methods for styling
  Color _getBorderColor() {
    if (_isUploading) return AppColors.primary;
    if (widget.activityId != null) return AppColors.border;
    return Colors.orange;
  }

  double _getBorderWidth() => (widget.activityId == null || _isUploading) ? 2 : 1;

  Color _getIconBackgroundColor() {
    if (_isUploading) return AppColors.primary.withValues(alpha: 0.1);
    if (widget.activityId != null) return AppColors.primary.withValues(alpha: 0.1);
    return Colors.orange.withValues(alpha: 0.1);
  }

  Color _getIconColor() {
    if (widget.activityId != null) return AppColors.primary;
    return Colors.orange;
  }

  String _getSubtitleText() {
    if (_isUploading) return 'Lütfen bekleyin...';
    if (widget.activityId != null) {
      return 'Aktivite ID: ${widget.activityId} (${_attachedFiles.length} dosya)';
    }
    return 'Aktivite kaydedilmedi - dosya eklenemez';
  }

  Color _getSubtitleColor() {
    if (_isUploading) return AppColors.primary;
    if (widget.activityId != null) return Colors.green;
    return Colors.orange;
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

  Widget _buildUploadingIndicator(AppSizes size) {
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
            'Dosya sunucuya yükleniyor...',
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

  Widget _buildFileList(AppSizes size) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Column(
        children: [
          // Mevcut dosya listesi - "Yeni Dosya Ekle" butonu kaldırıldı
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
                  maxLines: 2,
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
            onSelected: (value) async {
              switch (value) {
                case 'view':
                  await _viewFile(file);
                  break;
                case 'info':
                  SnackbarHelper.showInfo(
                    context: context,
                    message: 'PDF/Dosya görüntüleme özelliği geliştiriliyor...',
                  );
                  break;
                case 'delete':
                  await _deleteFile(file);
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
                )
              else
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: AppColors.info),
                      SizedBox(width: 8),
                      Text('PDF/Dosya görüntüleme yakında...', style: TextStyle(color: AppColors.info)),
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

  // File operations
  Future<void> _viewFile(AttachmentFile file) async {
    if (!file.isImage) {
      // PDF için şimdilik bilgi mesajı
      SnackbarHelper.showInfo(
        context: context,
        message: 'PDF görüntüleme: ${file.fileName}\nWeb browser\'da açmak için geliştiriliyor...',
      );
      return;
    }

    try {
      // Loading dialog göster
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
        Navigator.pop(context); // Loading dialog'u kapat

        if (imageUrl != null && imageUrl.isNotEmpty && imageUrl != 'null') {
          _showImageDialog(file, imageUrl);
        } else {
          SnackbarHelper.showError(
            context: context,
            message: 'Resim yüklenemedi - boş response',
          );
        }
      }
    } catch (e) {
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
      String base64String = imageUrl;

      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }

      base64String = base64String.replaceAll('"', '').replaceAll(RegExp(r'\s+'), '');

      // Base64 format kontrolü
      if (!RegExp(r'^[A-Za-z0-9+/]*={0,2}$').hasMatch(base64String)) {
        debugPrint('[FILE_UPLOAD] Invalid base64 format');
        return _buildImageError();
      }

      final bytes = base64Decode(base64String);

      return Image.memory(
        bytes,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('[FILE_UPLOAD] Image decode error: $error');
          return _buildImageError();
        },
      );
    } catch (e) {
      debugPrint('[FILE_UPLOAD] Image widget error: $e');
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
          Text('Resim yüklenemedi', style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }

  Future<void> _deleteFile(AttachmentFile file) async {
    final shouldDelete = await _showDeleteDialog(file.fileName);
    if (!shouldDelete) return;

    try {
      debugPrint('[FILE_UPLOAD] 🗑️ Starting delete for: ${file.fileName}');

      final response = await FileService.instance.deleteActivityFile(
        file: file,
        activityId: widget.activityId!,
        tableId: widget.tableId,
      );

      debugPrint('[FILE_UPLOAD] 🗑️ Delete response: ${response.isSuccess}');

      // Response success olsun olmasın, UI'dan kaldır (çünkü backend'de siliniyor)
      setState(() {
        _attachedFiles.removeWhere((f) => f.id == file.id);
        if (_attachedFiles.isEmpty) {
          _isExpanded = false;
        }
      });

      widget.onFileDeleted?.call(file);

      SnackbarHelper.showSuccess(
        context: context,
        message: 'Dosya silindi: ${file.fileName}',
      );
    } catch (e) {
      debugPrint('[FILE_UPLOAD] ❌ Delete error: $e');

      // Hata olsa bile UI'dan kaldır (çünkü backend'de muhtemelen silindi)
      setState(() {
        _attachedFiles.removeWhere((f) => f.id == file.id);
        if (_attachedFiles.isEmpty) {
          _isExpanded = false;
        }
      });

      SnackbarHelper.showWarning(
        context: context,
        message: 'Dosya silindi (${file.fileName})',
      );
    }
  }

  Future<bool> _showDeleteDialog(String fileName) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: Row(
              children: [
                Icon(Icons.delete_outline, color: AppColors.error),
                SizedBox(width: 8),
                Text('Dosyayı Sil'),
              ],
            ),
            content: Text('$fileName dosyasını silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz.'),
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

  // Helper methods
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

  // Public method to handle file upload from external source
  Future<void> handleFileUpload(Future<FileData?> Function() captureFunction) async {
    await _handleFileUpload(captureFunction);
  }
}
