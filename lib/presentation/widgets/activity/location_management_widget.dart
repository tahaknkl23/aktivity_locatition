// lib/presentation/widgets/activity/location_management_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/services/location_service.dart';
import '../../../data/services/api/activity_api_service.dart';

class LocationManagementWidget extends StatefulWidget {
  final Map<String, dynamic> formData;
  final Function(Map<String, dynamic>) onLocationUpdated;
  final bool isEditing;
  final VoidCallback? onActivityClose;

  const LocationManagementWidget({
    super.key,
    required this.formData,
    required this.onLocationUpdated,
    this.isEditing = false,
    this.onActivityClose,
  });

  @override
  State<LocationManagementWidget> createState() => _LocationManagementWidgetState();
}

class _LocationManagementWidgetState extends State<LocationManagementWidget> {
  final ActivityApiService _activityApiService = ActivityApiService();

  bool _isGettingLocation = false;
  final bool _isClosingActivity = false;
  String? _currentLocationText;
  String? _realCompanyLocationText;
  LocationData? companyLocationData;

  String? get currentLocationText => widget.formData['LocationText'] ?? _currentLocationText;

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final hasLocation = currentLocationText != null;

    return Column(
      children: [
        // Ana aksiyon butonları
        _buildActionButtons(size),

        // Konum bilgisi (eğer konum alınmışsa)
        if (hasLocation) ...[
          SizedBox(height: size.mediumSpacing),
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: double.infinity,
            padding: EdgeInsets.all(size.cardPadding * 0.8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(size.cardBorderRadius),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: _buildLocationSuccess(size),
          ),
        ],
      ],
    );
  }

  Widget _buildActionButtons(AppSizes size) {
    return Row(
      children: [
        // Konumumu Al butonu
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: _isGettingLocation ? null : _getCurrentLocation,
            icon: _isGettingLocation
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  )
                : Icon(Icons.my_location, size: 18),
            label: Text(
              _isGettingLocation ? 'Alınıyor...' : 'Konumumu Al',
              style: TextStyle(
                fontSize: size.textSize * 0.9,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary, width: 1.5),
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: size.smallSpacing * 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
            ),
          ),
        ),

        // Aktivite Kapat butonu (sadece düzenleme modunda)
        if (widget.isEditing && widget.onActivityClose != null) ...[
          SizedBox(width: size.mediumSpacing),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _isClosingActivity ? null : widget.onActivityClose,
              icon: _isClosingActivity
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.close_outlined, size: 18),
              label: Text(
                _isClosingActivity ? 'Kapatılıyor...' : 'Aktiviteyi Kapat',
                style: TextStyle(
                  fontSize: size.textSize * 0.9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: size.smallSpacing * 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(size.cardBorderRadius),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSuccess(AppSizes size) {
    return Column(
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.white,
                size: 16,
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              child: Text(
                'Konum Kıyaslaması',
                style: TextStyle(
                  fontSize: size.textSize * 0.95,
                  color: AppColors.success,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Yeniden konum al
            IconButton(
              onPressed: _isGettingLocation ? null : _getCurrentLocation,
              icon: _isGettingLocation
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(Icons.refresh, color: AppColors.primary, size: 20),
              tooltip: 'Konumu yenile',
              splashRadius: 20,
            ),
            // Temizle
            IconButton(
              onPressed: _clearLocation,
              icon: Icon(Icons.close, color: AppColors.error, size: 18),
              tooltip: 'Konumu temizle',
              splashRadius: 20,
            ),
          ],
        ),

        SizedBox(height: size.mediumSpacing),

        // Konum karşılaştırması
        _buildLocationComparison(size),

        // Durum bilgisi
        if (widget.formData['LocationDistance'] != null) ...[
          SizedBox(height: size.mediumSpacing),
          _buildLocationStatus(size),
        ],
      ],
    );
  }

  Widget _buildLocationComparison(AppSizes size) {
    final companyLocation = _getCompanyLocationText();

    return Container(
      padding: EdgeInsets.all(size.cardPadding * 0.8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 0.8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          // Firma konumu
          _buildLocationRow(
            icon: Icons.business,
            iconColor: AppColors.primary,
            title: 'Firma Konumu:',
            subtitle: companyLocation ?? 'Firma konumu kayıtlı değil',
            isEmpty: companyLocation == null,
            size: size,
          ),

          // Ayırıcı
          Container(
            margin: EdgeInsets.symmetric(vertical: size.smallSpacing),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.smallSpacing),
                  child: Icon(Icons.compare_arrows, color: AppColors.textTertiary, size: 16),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),

          // Mevcut konum
          _buildLocationRow(
            icon: Icons.my_location,
            iconColor: AppColors.success,
            title: 'Mevcut Konumum:',
            subtitle: currentLocationText!,
            isEmpty: false,
            size: size,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isEmpty,
    required AppSizes size,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        SizedBox(width: size.smallSpacing),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: size.smallText * 0.9,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: size.tinySpacing),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: size.smallText,
                  color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                  fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus(AppSizes size) {
    final distance = widget.formData['LocationDistance'] as String?;
    final status = widget.formData['LocationComparisonStatus'] as String?;
    final message = widget.formData['LocationComparisonMessage'] as String?;

    if (distance == null || status == null) return SizedBox.shrink();

    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      padding: EdgeInsets.all(size.cardPadding * 0.8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 0.8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              SizedBox(width: size.smallSpacing),
              Expanded(
                child: Text(
                  _getStatusTitle(status),
                  style: TextStyle(
                    fontSize: size.textSize * 0.9,
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: size.smallSpacing,
                  vertical: size.tinySpacing,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${distance}m',
                  style: TextStyle(
                    fontSize: size.smallText * 0.8,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (message != null) ...[
            SizedBox(height: size.smallSpacing),
            Text(
              message,
              style: TextStyle(
                fontSize: size.smallText,
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() => _isGettingLocation = true);

    try {
      LocationData? locationData;

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          locationData = await LocationService.instance.getCurrentLocation().timeout(Duration(seconds: 30));
          if (locationData != null) break;
        } on TimeoutException {
          if (attempt == 3) {
            throw TimeoutException('Konum alınamadı - 3 deneme başarısız', Duration(seconds: 30));
          }
          await Future.delayed(Duration(seconds: 2));
        }
      }

      if (locationData != null && mounted) {
        final updatedFormData = Map<String, dynamic>.from(widget.formData);
        updatedFormData['Location'] = locationData.coordinates;
        updatedFormData['LocationText'] = locationData.address;

        setState(() {
          _currentLocationText = locationData!.address;
        });

        // Firma karşılaştırması
        if (widget.formData['CompanyId'] != null) {
          await _compareWithCompanyLocation(
            widget.formData['CompanyId'] as int,
            locationData.latitude,
            locationData.longitude,
            updatedFormData,
          );
        }

        widget.onLocationUpdated(updatedFormData);

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Konum alındı: ${locationData.address}',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Konum alınamadı';
        if (e is TimeoutException) {
          errorMessage = 'Konum alınamadı: Zaman aşımı. GPS\'inizi açın ve tekrar deneyin.';
        } else {
          errorMessage = 'Konum alınamadı: ${e.toString()}';
        }

        SnackbarHelper.showError(context: context, message: errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() => _isGettingLocation = false);
      }
    }
  }

  Future<void> _compareWithCompanyLocation(int companyId, double currentLat, double currentLng, Map<String, dynamic> formData) async {
    try {
      final comparisonResult = await _activityApiService.compareLocations(
        companyId: companyId,
        currentLat: currentLat,
        currentLng: currentLng,
        toleranceInMeters: 100.0,
      );

      if (mounted) {
        if (comparisonResult.companyLocation != null) {
          setState(() {
            companyLocationData = comparisonResult.companyLocation;
            _realCompanyLocationText = '${comparisonResult.companyLocation!.latitude.toStringAsFixed(6)}, '
                '${comparisonResult.companyLocation!.longitude.toStringAsFixed(6)}';
          });
        }

        final snackBarColor = comparisonResult.isAtSameLocation
            ? AppColors.success
            : comparisonResult.isDifferentLocation
                ? AppColors.warning
                : AppColors.error;

        SnackbarHelper.showInfo(
          context: context,
          message: comparisonResult.message,
          backgroundColor: snackBarColor,
        );

        formData['LocationComparisonStatus'] = comparisonResult.status.name;
        formData['LocationComparisonMessage'] = comparisonResult.message;
        formData['LocationDistance'] = comparisonResult.distance?.toStringAsFixed(0);
      }
    } catch (e) {
      debugPrint('[LOCATION] Comparison error: $e');
    }
  }

  void _clearLocation() {
    final updatedFormData = Map<String, dynamic>.from(widget.formData);
    updatedFormData.remove('Location');
    updatedFormData.remove('LocationText');
    updatedFormData.remove('LocationComparisonStatus');
    updatedFormData.remove('LocationComparisonMessage');
    updatedFormData.remove('LocationDistance');

    setState(() {
      _currentLocationText = null;
    });

    widget.onLocationUpdated(updatedFormData);

    SnackbarHelper.showInfo(
      context: context,
      message: 'Konum bilgisi temizlendi',
    );
  }

  String? _getCompanyLocationText() {
    if (_realCompanyLocationText != null) {
      final companyDropdown = widget.formData['CompanyId_DDL'] as Map<String, dynamic>?;
      if (companyDropdown != null && companyDropdown['Firma'] != null) {
        final firmaAdi = companyDropdown['Firma'] as String;
        return '$firmaAdi\n$_realCompanyLocationText';
      }
      return _realCompanyLocationText;
    }

    if (widget.formData['CompanyId'] != null) {
      final companyDropdown = widget.formData['CompanyId_DDL'] as Map<String, dynamic>?;
      if (companyDropdown != null && companyDropdown['Firma'] != null) {
        final firmaAdi = companyDropdown['Firma'] as String;
        return '$firmaAdi (konum alınmadı)';
      }
      return 'Seçilen firma (konum alınmadı)';
    }

    return null;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'atLocation':
        return AppColors.success;
      case 'nearby':
        return AppColors.info;
      case 'close':
        return AppColors.warning;
      case 'far':
      case 'veryFar':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'atLocation':
        return Icons.check_circle;
      case 'nearby':
        return Icons.location_on;
      case 'close':
        return Icons.warning;
      case 'far':
      case 'veryFar':
        return Icons.error;
      default:
        return Icons.help;
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'atLocation':
        return 'AYNI KONUMDASINIZ';
      case 'nearby':
        return 'YAKINDASINIZ';
      case 'close':
        return 'YAKIN MESAFEDE';
      case 'far':
        return 'UZAK MESAFEDE';
      case 'veryFar':
        return 'ÇOK UZAK MESAFEDE';
      case 'noCompanyLocation':
        return 'FİRMA KONUMU KAYITLI DEĞİL';
      case 'error':
        return 'KONUM KIYASLANAMADI';
      default:
        return 'DURUM BELİRSİZ';
    }
  }
}
