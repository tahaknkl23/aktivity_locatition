// lib/presentation/widgets/activity/file_options_modal_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/file_service.dart';

class FileOptionsModalWidget extends StatelessWidget {
  final Function(Future<FileData?> Function()) onFileCapture;

  const FileOptionsModalWidget({
    super.key,
    required this.onFileCapture,
  });

  static Future<void> show({
    required BuildContext context,
    required Function(Future<FileData?> Function()) onFileCapture,
  }) {
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FileOptionsModalWidget(
        onFileCapture: onFileCapture,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          const SizedBox(height: 20),
          _buildTitle(),
          const SizedBox(height: 20),
          _buildCameraOption(context),
          _buildGalleryOption(context),
          _buildFileOption(context),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHandle() {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.textTertiary,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'Dosya Seçenekleri',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildCameraOption(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
        child: Icon(Icons.camera_alt, color: AppColors.primary),
      ),
      title: Text('Fotoğraf Çek'),
      subtitle: Text('Kamerayı kullan'),
      onTap: () {
        Navigator.pop(context);
        onFileCapture(() => FileService.instance.capturePhoto());
      },
    );
  }

  Widget _buildGalleryOption(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
        child: Icon(Icons.photo_library, color: AppColors.secondary),
      ),
      title: Text('Galeri'),
      subtitle: Text('Mevcut fotoğraflardan seç'),
      onTap: () {
        Navigator.pop(context);
        onFileCapture(() => FileService.instance.pickImageFromGallery());
      },
    );
  }

  Widget _buildFileOption(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.info.withValues(alpha: 0.1),
        child: Icon(Icons.description, color: AppColors.info),
      ),
      title: Text('Dosya Seç'),
      subtitle: Text('PDF, Word, Excel dosyaları'),
      onTap: () {
        Navigator.pop(context);
        onFileCapture(() => FileService.instance.pickFile());
      },
    );
  }
}
