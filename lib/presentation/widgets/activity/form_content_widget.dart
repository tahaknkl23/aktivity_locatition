// lib/presentation/widgets/activity/form_content_widget.dart
import 'package:flutter/material.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/models/activity/activity_list_model.dart';
import '../../../data/models/attachment/attachment_file_model.dart';
import '../../../core/services/location_service.dart';
import '../../../data/services/api/activity_api_service.dart';
import 'address_card_widget.dart';
import 'unified_location_widget.dart';
import '../common/file_upload_widget.dart';
import 'file_options_bottom_sheet.dart';
import '../../../core/services/file_service.dart';
import '../../../core/helpers/snackbar_helper.dart';

class FormContentWidget extends StatelessWidget {
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
          if (selectedAddress != null) ...[
            AddressCardWidget(selectedAddress: selectedAddress!),
            SizedBox(height: padding),
          ],

          // Location comparison card
          if (currentLocation != null) ...[
            UnifiedLocationWidget(
              currentLocation: currentLocation!,
              locationComparison: locationComparison,
              isGettingLocation: isGettingLocation,
              onRefreshLocation: onRefreshLocation,
            ),
            SizedBox(height: padding),
          ],

          // File upload widget - Sadece dosya listesi + header (tıklanabilir)
          FileUploadWidget(
            activityId: savedActivityId,
            tableId: 102,
            onFileUploaded: onFileUploaded,
            onFileDeleted: onFileDeleted,
            onShowFileOptions: () {
              debugPrint('[FORM_CONTENT] onShowFileOptions called');

              // Bottom sheet göster
              showModalBottomSheet(
                context: context,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) => FileOptionsBottomSheet(
                  onFileCapture: (captureFunction) async {
                    debugPrint('[FORM_CONTENT] File capture started');

                    try {
                      final fileData = await captureFunction();
                      debugPrint('[FORM_CONTENT] File captured: ${fileData?.name}');

                      if (fileData != null && savedActivityId != null) {
                        debugPrint('[FORM_CONTENT] Starting upload for activity: $savedActivityId');

                        final response = await FileService.instance.uploadActivityFile(
                          activityId: savedActivityId!,
                          file: fileData,
                        );

                        debugPrint('[FORM_CONTENT] Upload response: ${response.isSuccess}');

                        if (response.isSuccess && response.firstFile != null) {
                          debugPrint('[FORM_CONTENT] Upload successful, calling callback');
                          onFileUploaded(response.firstFile!);
                        } else {
                          debugPrint('[FORM_CONTENT] Upload failed: ${response.errorMessage}');
                          SnackbarHelper.showError(
                            context: context,
                            message: 'Dosya yüklenemedi: ${response.errorMessage ?? "Bilinmeyen hata"}',
                          );
                        }
                      } else {
                        debugPrint('[FORM_CONTENT] No file data or activity ID missing');
                        if (savedActivityId == null) {
                          SnackbarHelper.showError(
                            context: context,
                            message: 'Aktivite kaydedilmeden dosya yüklenemez',
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('[FORM_CONTENT] Upload error: $e');
                      SnackbarHelper.showError(
                        context: context,
                        message: 'Dosya yükleme hatası: ${e.toString()}',
                      );
                    }
                  },
                ),
              );
            },
          ),

          // Main dynamic form
          DynamicFormWidget(
            formModel: formModel,
            onFormChanged: onFormChanged,
            onSave: null,
            isLoading: isSaving,
            isEditing: isEditing,
            showHeader: false,
            showActions: false,
          ),
        ],
      ),
    );
  }
}
