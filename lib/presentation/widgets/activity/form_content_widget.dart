// lib/presentation/widgets/activity/form_content_widget.dart - FINAL CLEAN VERSION
import 'package:flutter/material.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/models/attachment/attachment_file_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../data/services/api/activity_api_service.dart';
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
  // ✅ Handler registration callback
  final Function(VoidCallback, VoidCallback)? onRegisterHandlers;

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
    this.onRegisterHandlers,
  });

  @override
  State<FormContentWidget> createState() => _FormContentWidgetState();
}

class _FormContentWidgetState extends State<FormContentWidget> {
  // ✅ FileUploadWidget reference - function callback ile
  Function(Future<FileData?> Function())? _fileUploadHandler;
  VoidCallback? _fileRefreshHandler;

  @override
  void initState() {
    super.initState();

    // ✅ Register handlers after widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onRegisterHandlers?.call(_showFileOptions, refreshFiles);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final padding = isTablet ? 24.0 : screenWidth * 0.04;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address card widget
          if (widget.selectedAddress != null) ...[
            Padding(
              padding: EdgeInsets.all(padding),
              child: AddressCardWidget(selectedAddress: widget.selectedAddress!),
            ),
          ],

          // Location comparison card
          if (widget.currentLocation != null) ...[
            Padding(
              padding: EdgeInsets.all(padding),
              child: UnifiedLocationWidget(
                currentLocation: widget.currentLocation!,
                locationComparison: widget.locationComparison,
                isGettingLocation: widget.isGettingLocation,
                onRefreshLocation: widget.onRefreshLocation,
              ),
            ),
          ],

          // ✅ FileUploadWidget - Sadece editing modda
          if (widget.isEditing) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: padding),
              child: FileUploadWidget(
                activityId: widget.savedActivityId,
                tableId: 102,
                onFileUploaded: widget.onFileUploaded,
                onFileDeleted: widget.onFileDeleted,
                onShowFileOptions: _showFileOptions,
                onRegisterHandlers: (uploadHandler, refreshHandler) {
                  _fileUploadHandler = uploadHandler;
                  _fileRefreshHandler = refreshHandler;
                },
              ),
            ),
          ],

          // Main dynamic form - Padding ile (Expanded değil!)
          Padding(
            padding: EdgeInsets.all(padding),
            child: DynamicFormWidget(
              formModel: widget.formModel,
              onFormChanged: widget.onFormChanged,
              onSave: null,
              isLoading: widget.isSaving,
              isEditing: widget.isEditing,
              showHeader: false,
              showActions: false,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ File options modal'ını aç
  void _showFileOptions() {
    debugPrint('[FORM_CONTENT] 🚀 _showFileOptions called');

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
      isScrollControlled: true,
      builder: (context) => FileOptionsBottomSheet(
        onFileCapture: _handleFileCapture,
      ),
    );
  }

  /// ✅ File capture işlemi - Registered handler'a delegate et
  Future<void> _handleFileCapture(Future<FileData?> Function() captureFunction) async {
    debugPrint('[FORM_CONTENT] 🎯 _handleFileCapture called');

    // Registered upload handler'ı kullan
    if (_fileUploadHandler != null) {
      debugPrint('[FORM_CONTENT] ✅ Using registered upload handler');
      await _fileUploadHandler!(captureFunction);
    } else {
      debugPrint('[FORM_CONTENT] ❌ No upload handler registered');
      SnackbarHelper.showError(
        context: context,
        message: 'Dosya yükleme servisi henüz hazır değil',
      );
    }
  }

  /// ✅ Public refresh method - Registered handler'ı kullan
  void refreshFiles() {
    debugPrint('[FORM_CONTENT] 🔄 refreshFiles called');

    if (_fileRefreshHandler != null) {
      _fileRefreshHandler!();
      debugPrint('[FORM_CONTENT] ✅ Files refreshed via registered handler');
    } else {
      debugPrint('[FORM_CONTENT] ⚠️ No refresh handler registered');
    }
  }
}
