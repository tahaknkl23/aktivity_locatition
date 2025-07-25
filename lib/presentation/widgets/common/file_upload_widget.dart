// lib/presentation/widgets/common/file_upload_widget.dart - COMPLETE FINAL VERSION
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
  final Function()? onShowFileOptions;
  final Function(Function(Future<FileData?> Function()), VoidCallback)? onRegisterHandlers;

  const FileUploadWidget({
    super.key,
    this.activityId,
    this.tableId = 102,
    this.onFileUploaded,
    this.onFileDeleted,
    this.onShowFileOptions,
    this.onRegisterHandlers,
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterHandlers?.call(handleFileUpload, refreshFiles);
    });
  }

  @override
  void didUpdateWidget(FileUploadWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activityId != widget.activityId) {
      debugPrint('[FILE_UPLOAD] 🔄 ActivityId changed: ${oldWidget.activityId} -> ${widget.activityId}');
      _loadExistingFiles();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterHandlers?.call(handleFileUpload, refreshFiles);
    });
  }

  Future<void> _loadExistingFiles() async {
    if (widget.activityId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      setState(() => _isLoading = true);

      debugPrint('[FILE_UPLOAD] 📂 Loading files for activity: ${widget.activityId}');

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

  Future<void> handleFileUpload(Future<FileData?> Function() captureFunction) async {
    debugPrint('[FILE_UPLOAD] 🚀 Starting file upload process');

    if (widget.activityId == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final fileData = await captureFunction();

      if (fileData == null) {
        debugPrint('[FILE_UPLOAD] ❌ No file selected');
        setState(() => _isUploading = false);
        return;
      }

      debugPrint('[FILE_UPLOAD] ✅ File captured: ${fileData.name} (${fileData.formattedSize})');

      if (mounted) {
        SnackbarHelper.showInfo(
          context: context,
          message: 'Dosya yükleniyor: ${fileData.name}',
        );
      }

      debugPrint('[FILE_UPLOAD] 📤 Uploading to server...');
      final response = await FileService.instance.uploadActivityFile(
        activityId: widget.activityId!,
        file: fileData,
        tableId: widget.tableId,
      );

      debugPrint('[FILE_UPLOAD] 📊 Upload response: success=${response.isSuccess}');

      if (response.isSuccess && response.firstFile != null) {
        if (mounted) {
          setState(() {
            _attachedFiles.add(response.firstFile!);
            _isExpanded = true;
            _isUploading = false;
          });

          debugPrint('[FILE_UPLOAD] ✅ File instantly added to UI: ${response.firstFile!.fileName}');

          widget.onFileUploaded?.call(response.firstFile!);

          SnackbarHelper.showSuccess(
            context: context,
            message: 'Dosya başarıyla yüklendi: ${fileData.name}',
          );
        }

        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            debugPrint('[FILE_UPLOAD] 🔄 Background refresh after upload');
            _loadExistingFiles();
          }
        });
      } else {
        throw FileException(response.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] ❌ Upload error: $e');

      if (mounted) {
        setState(() => _isUploading = false);

        String errorMsg = 'Dosya yüklenemedi';
        if (e is FileException) {
          errorMsg = e.message;
        } else if (e.toString().contains('SocketException')) {
          errorMsg = 'İnternet bağlantısı hatası';
        } else if (e.toString().contains('TimeoutException')) {
          errorMsg = 'Yükleme zaman aşımı';
        }

        SnackbarHelper.showError(
          context: context,
          message: errorMsg,
        );
      }
    }
  }

  Future<void> refreshFiles() async {
    debugPrint('[FILE_UPLOAD] 🔄 External refresh triggered');
    await _loadExistingFiles();
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // ✅ Important: min size
        children: [
          _buildHeader(size),
          if (_isLoading) ...[
            SizedBox(height: size.smallSpacing),
            _buildLoadingIndicator(size),
          ] else if (_isUploading) ...[
            SizedBox(height: size.smallSpacing),
            _buildUploadingIndicator(size),
          ] else if (widget.activityId == null) ...[
            SizedBox(height: size.mediumSpacing),
            _buildInfoMessage(size),
          ] else if (_isExpanded && _attachedFiles.isNotEmpty) ...[
            SizedBox(height: size.smallSpacing),
            _buildFileList(size),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AppSizes size) {
    return GestureDetector(
      onTap: _handleHeaderTap,
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
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getIconBackgroundColor(),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _attachedFiles.isNotEmpty ? Icons.folder : Icons.attach_file,
                color: _getIconColor(),
                size: 20,
              ),
            ),

            SizedBox(width: size.smallSpacing),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getHeaderTitle(),
                    style: TextStyle(
                      fontSize: size.textSize,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getHeaderSubtitle(),
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: _getSubtitleColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

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

            // ✅ SADECE BİR LOADING SPINNER
            if (_isLoading || _isUploading)
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            else
              _buildActionIcon(),
          ],
        ),
      ),
    );
  }

  void _handleHeaderTap() {
    debugPrint('[FILE_UPLOAD] 🎯 Header tapped');

    if (_isLoading || _isUploading) {
      debugPrint('[FILE_UPLOAD] ⏳ Busy, ignoring tap');
      return;
    }

    if (_attachedFiles.isNotEmpty) {
      debugPrint('[FILE_UPLOAD] 📂 Toggling expand state: $_isExpanded -> ${!_isExpanded}');
      setState(() {
        _isExpanded = !_isExpanded;
      });
    } else if (widget.activityId != null) {
      debugPrint('[FILE_UPLOAD] 🚀 Calling onShowFileOptions');
      widget.onShowFileOptions?.call();
    } else {
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
    }
  }

  Widget _buildActionIcon() {
    // ✅ Loading durumunda hiçbir şey gösterme (zaten başka yerde var)
    if (_isLoading || _isUploading) {
      return SizedBox.shrink();
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
        color: AppColors.background,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
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
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'view':
                  await _viewFile(file);
                  break;
                case 'delete':
                  await _deleteFile(file);
                  break;
              }
            },
            itemBuilder: (context) {
              List<PopupMenuEntry<String>> items = [];

              // Sadece gerçek resim dosyaları için görüntüle seçeneği ekle
              final isActualImage = (file.fileType == 0) && _isImageFileByName(file.fileName);

              if (isActualImage) {
                items.add(
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
                );
              }

              // Her dosya için sil seçeneği ekle
              items.add(
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
              );

              return items;
            },
            icon: Icon(Icons.more_vert, color: AppColors.textSecondary, size: 18),
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

  Future<void> _viewFile(AttachmentFile file) async {
    // Çift kontrol - sadece resimler için
    if (file.fileType != 0 && !_isImageFileByName(file.fileName)) {
      SnackbarHelper.showInfo(
        context: context,
        message: 'Bu dosya türü görüntülenemiyor: ${file.fileName}',
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

      final imageUrl = await FileService.instance.getFileViewUrl(file);

      if (mounted) {
        Navigator.pop(context);

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

  // ✅ Dosya adından resim kontrolü
  bool _isImageFileByName(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(extension);
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
      debugPrint('[FILE_UPLOAD] 🗑️ Deleting file: ${file.fileName}');

      if (mounted) {
        setState(() {
          _attachedFiles.removeWhere((f) => f.id == file.id);
          if (_attachedFiles.isEmpty) {
            _isExpanded = false;
          }
        });
      }

      widget.onFileDeleted?.call(file);

      SnackbarHelper.showSuccess(
        context: context,
        message: 'Dosya silindi: ${file.fileName}',
      );

      try {
        await FileService.instance.deleteActivityFile(
          file: file,
          activityId: widget.activityId!,
          tableId: widget.tableId,
        );
      } catch (apiError) {
        debugPrint('[FILE_UPLOAD] ⚠️ Delete API error: $apiError');
      }
    } catch (e) {
      debugPrint('[FILE_UPLOAD] ❌ Delete error: $e');

      if (mounted) {
        setState(() {
          _attachedFiles.add(file);
        });
      }

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

  String _getHeaderTitle() {
    if (_isUploading) return 'Dosya Yükleniyor...';
    if (_attachedFiles.isNotEmpty) return 'Dosyalar';
    return 'Dosya Ekle';
  }

  String _getHeaderSubtitle() {
    if (widget.activityId != null) {
      return 'Aktivite ID: ${widget.activityId} (${_attachedFiles.length} dosya)';
    }
    return 'Aktivite kaydedilmedi - dosya eklenemez';
  }

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

  Color _getSubtitleColor() {
    if (_isUploading) return AppColors.primary;
    if (widget.activityId != null) return Colors.green;
    return Colors.orange;
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
