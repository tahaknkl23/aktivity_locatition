// lib/presentation/widgets/activity/form_content_widget.dart - Geliştirilmiş versiyon
import 'package:flutter/material.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/models/attachment/attachment_file_model.dart';
import '../../../core/services/location_service.dart';
import '../../../data/services/api/activity_api_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/helpers/snackbar_helper.dart';
import 'address_card_widget.dart';
import 'unified_location_widget.dart';
import '../common/file_upload_widget.dart';
import 'file_options_bottom_sheet.dart';

class FormContentWidget extends StatefulWidget {
  final CompanyAddress? selectedAddress;
  final LocationData? currentLocation;
  final LocationComparisonResult? locationComparison;
  final List<AttachmentFile> attachedFiles;
  final DynamicFormModel formModel;
  final bool isSaving;
  final bool isEditing;
  final bool isGettingLocation;
  final int? savedActivityId;
  final Function(Map<String, dynamic>) onFormChanged;
  final Function(AttachmentFile) onFileDeleted;
  final Function(AttachmentFile) onFileUploaded;
  final VoidCallback onRefreshLocation;

  const FormContentWidget({
    super.key,
    required this.selectedAddress,
    required this.currentLocation,
    required this.locationComparison,
    required this.attachedFiles,
    required this.formModel,
    required this.isSaving,
    required this.isEditing,
    required this.isGettingLocation,
    required this.savedActivityId,
    required this.onFormChanged,
    required this.onFileDeleted,
    required this.onFileUploaded,
    required this.onRefreshLocation,
  });

  @override
  State<FormContentWidget> createState() => _FormContentWidgetState();
}

class _FormContentWidgetState extends State<FormContentWidget> {
  // FileUploadWidget için key - ama state'e erişemeyiz çünkü private

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 24.0 : screenWidth * 0.04;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address card widget
          if (widget.selectedAddress != null) ...[
            AddressCardWidget(selectedAddress: widget.selectedAddress!),
            SizedBox(height: padding),
          ],

          // Location comparison card
          if (widget.currentLocation != null) ...[
            UnifiedLocationWidget(
              currentLocation: widget.currentLocation!,
              locationComparison: widget.locationComparison,
              isGettingLocation: widget.isGettingLocation,
              onRefreshLocation: widget.onRefreshLocation,
            ),
            SizedBox(height: padding),
          ],

          // File upload widget - Geliştirilmiş versiyon
          FileUploadWidget(
            activityId: widget.savedActivityId,
            tableId: 102,
            onFileUploaded: _handleFileUploaded,
            onFileDeleted: _handleFileDeleted,
            onShowFileOptions: _showFileOptions,
          ),

          // Main dynamic form
          DynamicFormWidget(
            formModel: widget.formModel,
            onFormChanged: widget.onFormChanged,
            onSave: null,
            isLoading: widget.isSaving,
            isEditing: widget.isEditing,
            showHeader: false,
            showActions: false,
          ),
        ],
      ),
    );
  }

  /// 📤 Dosya yükleme seçeneklerini göster
  void _showFileOptions() {
    debugPrint('[FORM_CONTENT] 🚀 Showing file options bottom sheet');

    if (widget.savedActivityId == null) {
      SnackbarHelper.showWarning(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FileOptionsBottomSheet(
        onFileCapture: _handleFileCapture,
      ),
    );
  }

  /// 📸 Dosya yakalama işlemi
  Future<void> _handleFileCapture(Future<FileData?> Function() captureFunction) async {
    debugPrint('[FORM_CONTENT] 📸 File capture started');

    if (widget.savedActivityId == null) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite kaydedilmeden dosya eklenemez',
      );
      return;
    }

    try {
      // Direkt upload işlemi yap
      await _directFileUpload(captureFunction);
    } catch (e) {
      debugPrint('[FORM_CONTENT] ❌ File capture error: $e');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya işlemi başarısız: ${e.toString()}',
      );
    }
  }

  /// 📤 Direkt dosya yükleme (fallback)
  Future<void> _directFileUpload(Future<FileData?> Function() captureFunction) async {
    try {
      debugPrint('[FORM_CONTENT] 📤 Starting direct file upload');

      final fileData = await captureFunction();

      if (fileData == null) {
        debugPrint('[FORM_CONTENT] ❌ No file selected');
        return;
      }

      debugPrint('[FORM_CONTENT] ✅ File captured: ${fileData.name}');
      debugPrint('[FORM_CONTENT] 📁 File size: ${fileData.formattedSize}');
      debugPrint('[FORM_CONTENT] 📁 File type: ${fileData.mimeType}');

      // Show progress
      SnackbarHelper.showInfo(
        context: context,
        message: 'Dosya yükleniyor: ${fileData.name}',
      );

      // Upload file
      debugPrint('[FORM_CONTENT] 🚀 Starting upload to server');
      final response = await FileService.instance.uploadActivityFile(
        activityId: widget.savedActivityId!,
        file: fileData,
        tableId: 102,
      );

      debugPrint('[FORM_CONTENT] 📊 Upload response: ${response.isSuccess}');

      if (response.isSuccess && response.firstFile != null) {
        _handleFileUploaded(response.firstFile!);

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Dosya başarıyla yüklendi: ${fileData.name}',
        );

        debugPrint('[FORM_CONTENT] ✅ Upload completed successfully');
      } else {
        throw FileException(response.errorMessage ?? 'Upload failed');
      }
    } catch (e) {
      debugPrint('[FORM_CONTENT] ❌ Direct upload error: $e');

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

  /// 📁 Dosya yükleme başarılı callback
  void _handleFileUploaded(AttachmentFile file) {
    debugPrint('[FORM_CONTENT] ✅ File uploaded callback: ${file.fileName}');

    // Parent widget'a bildir
    widget.onFileUploaded(file);

    // State güncelle (eğer gerekirse)
    if (mounted) {
      setState(() {
        // UI güncellemesi için
      });
    }
  }

  /// 🗑️ Dosya silme callback
  void _handleFileDeleted(AttachmentFile file) {
    debugPrint('[FORM_CONTENT] 🗑️ File deleted callback: ${file.fileName}');

    // Parent widget'a bildir
    widget.onFileDeleted(file);

    // State güncelle (eğer gerekirse)
    if (mounted) {
      setState(() {
        // UI güncellemesi için
      });
    }
  }
}
