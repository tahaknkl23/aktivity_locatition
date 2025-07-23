import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/file_service.dart';

class FileOptionsBottomSheet extends StatelessWidget {
  final Function(Future<FileData?> Function()) onFileCapture;

  const FileOptionsBottomSheet({
    super.key,
    required this.onFileCapture,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: isTablet ? 50 : 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Title
          Text(
            'Dosya Seçenekleri',
            style: TextStyle(
              fontSize: isTablet ? 20 : 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: isTablet ? 24 : 20),

          // Options
          _buildOptionTile(
            context: context,
            icon: Icons.camera_alt,
            iconColor: AppColors.primary,
            title: 'Fotoğraf Çek',
            subtitle: 'Kamerayı kullan',
            onTap: () {
              Navigator.pop(context);
              onFileCapture(() => FileService.instance.capturePhoto());
            },
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.photo_library,
            iconColor: AppColors.secondary,
            title: 'Galeri',
            subtitle: 'Mevcut fotoğraflardan seç',
            onTap: () {
              Navigator.pop(context);
              onFileCapture(() => FileService.instance.pickImageFromGallery());
            },
          ),

          _buildOptionTile(
            context: context,
            icon: Icons.description,
            iconColor: AppColors.info,
            title: 'Dosya Seç',
            subtitle: 'PDF, Word, Excel dosyaları',
            onTap: () {
              Navigator.pop(context);
              onFileCapture(() => FileService.instance.pickFile());
            },
          ),

          SizedBox(height: isTablet ? 24 : 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: isTablet ? 6 : 4),
      child: ListTile(
        leading: CircleAvatar(
          radius: isTablet ? 24 : 20,
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(
            icon,
            color: iconColor,
            size: isTablet ? 24 : 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: isTablet ? 16 : 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: isTablet ? 14 : 12,
            color: AppColors.textSecondary,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
