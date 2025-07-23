// lib/presentation/widgets/activity/unified_location_widget.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/services/location_service.dart';
import '../../../data/services/api/activity_api_service.dart';

class UnifiedLocationWidget extends StatelessWidget {
  final LocationData currentLocation;
  final LocationComparisonResult? locationComparison;
  final bool isGettingLocation;
  final VoidCallback onRefreshLocation;

  const UnifiedLocationWidget({
    super.key,
    required this.currentLocation,
    required this.locationComparison,
    required this.isGettingLocation,
    required this.onRefreshLocation,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final size = AppSizes.of(context);
    final comparison = locationComparison;

    // Status belirleme
    Color statusColor = AppColors.info;
    IconData statusIcon = Icons.location_on;
    String statusTitle = 'KONUM BİLGİSİ';

    if (comparison != null) {
      if (comparison.isAtSameLocation) {
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        statusTitle = 'AYNI KONUMDASINIZ';
      } else if (comparison.isDifferentLocation) {
        statusColor = AppColors.warning;
        statusIcon = Icons.warning;
        statusTitle = 'FARKLI KONUMDASINIZ';
      } else {
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        statusTitle = 'KONUM KARŞILAŞTIRILAMADI';
      }
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 20 : screenWidth * 0.04),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, statusColor, statusIcon, statusTitle),
          if (comparison?.message != null) ...[
            SizedBox(height: isTablet ? 12 : screenWidth * 0.02),
            _buildMessage(context, statusColor),
          ],
          SizedBox(height: isTablet ? 16 : screenWidth * 0.03),
          _buildLocationDetails(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color statusColor, IconData statusIcon, String statusTitle) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(isTablet ? 10 : screenWidth * 0.02),
          decoration: BoxDecoration(
            color: statusColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            statusIcon,
            color: Colors.white,
            size: isTablet ? 20 : screenWidth * 0.04,
          ),
        ),
        SizedBox(width: isTablet ? 12 : screenWidth * 0.03),
        Expanded(
          child: Text(
            statusTitle,
            style: TextStyle(
              fontSize: isTablet ? 18 : screenWidth * 0.035,
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (locationComparison?.distance != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 12 : screenWidth * 0.02,
              vertical: isTablet ? 6 : screenWidth * 0.01,
            ),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${locationComparison!.distance!.toStringAsFixed(0)}m',
              style: TextStyle(
                fontSize: isTablet ? 14 : screenWidth * 0.03,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        SizedBox(width: isTablet ? 8 : screenWidth * 0.02),
        IconButton(
          onPressed: isGettingLocation ? null : onRefreshLocation,
          icon: isGettingLocation
              ? SizedBox(
                  width: isTablet ? 20 : screenWidth * 0.04,
                  height: isTablet ? 20 : screenWidth * 0.04,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  ),
                )
              : Icon(
                  Icons.refresh,
                  color: statusColor,
                  size: isTablet ? 24 : screenWidth * 0.05,
                ),
          tooltip: 'Konumu yenile',
        ),
      ],
    );
  }

  Widget _buildMessage(BuildContext context, Color statusColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Text(
      locationComparison!.message,
      style: TextStyle(
        fontSize: isTablet ? 14 : screenWidth * 0.03,
        color: statusColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildLocationDetails(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isTablet ? 16 : screenWidth * 0.03),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Mevcut konum
          _buildLocationRow(
            context: context,
            icon: Icons.my_location,
            iconColor: AppColors.info,
            title: 'Mevcut Konumunuz:',
            subtitle: currentLocation.address,
          ),

          if (locationComparison?.companyLocation != null) ...[
            SizedBox(height: isTablet ? 8 : screenWidth * 0.02),
            Divider(height: 1),
            SizedBox(height: isTablet ? 8 : screenWidth * 0.02),

            // Firma konumu
            _buildLocationRow(
              context: context,
              icon: Icons.business,
              iconColor: AppColors.primary,
              title: 'Firma Konumu:',
              subtitle:
                  'Koordinat: ${locationComparison!.companyLocation!.latitude.toStringAsFixed(4)}, ${locationComparison!.companyLocation!.longitude.toStringAsFixed(4)}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isTablet ? 18 : screenWidth * 0.035,
          color: iconColor,
        ),
        SizedBox(width: isTablet ? 8 : screenWidth * 0.02),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: isTablet ? 14 : screenWidth * 0.03,
                  color: iconColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: isTablet ? 14 : screenWidth * 0.03,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
