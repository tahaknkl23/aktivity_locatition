import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/helpers/snackbar_helper.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';
import '../../../core/services/location_service.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../data/services/api/activity_api_service.dart';

class AddActivityScreen extends StatefulWidget {
  final int? activityId; // For editing existing activity
  final int? preSelectedCompanyId; // Pre-select company if coming from company screen

  const AddActivityScreen({
    super.key,
    this.activityId,
    this.preSelectedCompanyId,
  });

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final ActivityApiService _activityApiService = ActivityApiService();

  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  bool _isGettingLocation = false;
  String? _currentLocationText;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  bool get isEditing => widget.activityId != null && widget.activityId! > 0;

  Future<void> _loadFormData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('[ADD_ACTIVITY] Loading form data - Activity ID: ${widget.activityId}');

      final formModel = await _activityApiService.loadActivityForm(
        activityId: widget.activityId,
      );

      // Load dropdown options
      await _loadDropdownOptions(formModel);

      if (mounted) {
        setState(() {
          _formModel = formModel;
          _formData = Map<String, dynamic>.from(formModel.data);

          // Pre-select company if provided
          if (widget.preSelectedCompanyId != null && !isEditing) {
            _formData['CompanyId'] = widget.preSelectedCompanyId;
            debugPrint('[ADD_ACTIVITY] Pre-selected company: ${widget.preSelectedCompanyId}');
          }

          _isLoading = false;
        });

        debugPrint('[ADD_ACTIVITY] Form loaded successfully');
        debugPrint('[ADD_ACTIVITY] Form sections: ${formModel.sections.length}');
        debugPrint('[ADD_ACTIVITY] Form data keys: ${_formData.keys.toList()}');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Load form error: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _loadDropdownOptions(DynamicFormModel formModel) async {
    try {
      debugPrint('[ADD_ACTIVITY] Loading dropdown options');

      // Load dropdown options for all dropdown fields dynamically
      for (final section in formModel.sections) {
        for (final field in section.fields) {
          if (field.type == FormFieldType.dropdown && field.widget.sourceType != null && field.widget.sourceValue != null) {
            try {
              final options = await _activityApiService.loadDropdownOptions(
                sourceType: field.widget.sourceType!,
                sourceValue: field.widget.sourceValue!,
                dataTextField: field.widget.dataTextField,
                dataValueField: field.widget.dataValueField,
              );

              field.options = options;
              debugPrint('[ADD_ACTIVITY] Loaded ${options.length} options for ${field.label} (${field.key})');

              // Log first few options for debugging
              if (options.isNotEmpty) {
                final preview = options.take(3).map((o) => '${o.value}: ${o.text}').join(', ');
                debugPrint('[ADD_ACTIVITY] Options preview for ${field.key}: $preview');
              }
            } catch (e) {
              debugPrint('[ADD_ACTIVITY] Failed to load options for ${field.label}: $e');
              field.options = [];
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Load dropdown options error: $e');
    }
  }

  void _onFormDataChanged(Map<String, dynamic> formData) {
    setState(() {
      _formData = formData;
    });
    debugPrint('[ADD_ACTIVITY] Form data updated: ${formData.keys.length} fields');

    // Handle cascade dropdowns
    _handleCascadeDropdowns(formData);
  }

  Future<void> _handleCascadeDropdowns(Map<String, dynamic> formData) async {
    if (_formModel == null) return;

    // Company changed - reload contacts
    if (formData.containsKey('CompanyId') && formData['CompanyId'] != null) {
      final companyId = formData['CompanyId'] as int;
      final contactField = _formModel!.getFieldByKey('ContactId');

      if (contactField != null && contactField.type == FormFieldType.dropdown) {
        try {
          debugPrint('[ADD_ACTIVITY] Loading contacts for company: $companyId');

          final contacts = await _activityApiService.loadContactsByCompany(companyId);

          setState(() {
            contactField.options = contacts;
            // Clear previous contact selection
            _formData['ContactId'] = null;
          });

          debugPrint('[ADD_ACTIVITY] Loaded ${contacts.length} contacts for company $companyId');
        } catch (e) {
          debugPrint('[ADD_ACTIVITY] Failed to load contacts: $e');
        }
      }
    }
  }

  // Mevcut konumu al ve kıyasla
  Future<void> _getCurrentLocation() async {
    if (_isGettingLocation) return;

    setState(() {
      _isGettingLocation = true;
    });

    try {
      debugPrint('[ADD_ACTIVITY] Getting current location...');

      // Mevcut konumu al
      final locationData = await LocationService.instance.getCurrentLocation();

      if (locationData != null && mounted) {
        setState(() {
          _currentLocationText = locationData.address;
          // Konum bilgisini forma ekle
          _formData['Location'] = locationData.coordinates;
          _formData['LocationText'] = locationData.address;
        });

        // Seçilen firma varsa konum kıyaslaması yap
        if (_formData['CompanyId'] != null) {
          await _compareWithCompanyLocation(
            _formData['CompanyId'] as int,
            locationData.latitude,
            locationData.longitude,
          );
        }

        SnackbarHelper.showSuccess(
          context: context,
          message: 'Konum alındı: ${locationData.address}',
        );

        debugPrint('[ADD_ACTIVITY] Location saved: ${locationData.coordinates}');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Get location error: $e');

      if (mounted) {
        SnackbarHelper.showError(
          context: context,
          message: 'Konum alınamadı: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGettingLocation = false;
        });
      }
    }
  }

  // YENİ: Firma konumu ile kıyasla
  Future<void> _compareWithCompanyLocation(int companyId, double currentLat, double currentLng) async {
    try {
      debugPrint('[ADD_ACTIVITY] Comparing with company location...');

      final comparisonResult = await _activityApiService.compareLocations(
        companyId: companyId,
        currentLat: currentLat,
        currentLng: currentLng,
        toleranceInMeters: 100.0, // 100 metre tolerans
      );

      if (mounted) {
        // Konum durumunu göster
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

        // Konum durumunu state'e kaydet
        setState(() {
          _formData['LocationComparisonStatus'] = comparisonResult.status.name;
          _formData['LocationComparisonMessage'] = comparisonResult.message;
          _formData['LocationDistance'] = comparisonResult.distance?.toStringAsFixed(0);
        });

        debugPrint('[ADD_ACTIVITY] Location comparison: ${comparisonResult.message}');
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Location comparison error: $e');
    }
  }

  Future<void> _saveActivity() async {
    try {
      setState(() {
        _isSaving = true;
      });

      debugPrint('[ADD_ACTIVITY] Saving activity data...');
      debugPrint('[ADD_ACTIVITY] Form data: ${_formData.keys.toList()}');

      // Validate required fields
      if (!_validateRequiredFields()) {
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Clean form data - remove null/empty values
      final cleanedData = <String, dynamic>{};
      for (final entry in _formData.entries) {
        if (entry.value != null && entry.value.toString().isNotEmpty) {
          cleanedData[entry.key] = entry.value;
        }
      }

      // Ensure required fields are set
      _ensureRequiredFields(cleanedData);

      final result = await _activityApiService.saveActivity(
        formData: cleanedData,
        activityId: widget.activityId,
      );

      if (mounted) {
        debugPrint('[ADD_ACTIVITY] Save result: $result');

        // Show success message
        SnackbarHelper.showSuccess(
          context: context,
          message: isEditing ? 'Aktivite başarıyla güncellendi!' : 'Aktivite başarıyla kaydedildi!',
        );

        // Wait a moment then go back
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      debugPrint('[ADD_ACTIVITY] Save error: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        SnackbarHelper.showError(
          context: context,
          message: 'Kaydetme sırasında hata oluştu: ${e.toString()}',
        );
      }
    }
  }

  bool _validateRequiredFields() {
    final requiredFields = ['ActivityType']; // ActivityType is required in API
    final missingFields = <String>[];

    for (final field in requiredFields) {
      if (_formData[field] == null || _formData[field].toString().isEmpty) {
        missingFields.add(field);
      }
    }

    if (missingFields.isNotEmpty) {
      SnackbarHelper.showError(
        context: context,
        message: 'Aktivite tipi seçimi zorunludur',
      );
      return false;
    }

    return true;
  }

  void _ensureRequiredFields(Map<String, dynamic> data) {
    // Set default values if not set
    if (!isEditing) {
      // For new activities, set default dates if not set
      final now = DateTime.now();
      if (data['StartDate'] == null) {
        data['StartDate'] =
            '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      }
      if (data['EndDate'] == null) {
        final endTime = now.add(const Duration(minutes: 30));
        data['EndDate'] =
            '${endTime.day.toString().padLeft(2, '0')}.${endTime.month.toString().padLeft(2, '0')}.${endTime.year} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
      }

      // Set default OpenOrClose to 1 (Open)
      data['OpenOrClose'] = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
    );
  }

  // 🚀 HYBRID STACK VERSİYONU
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_formModel == null) {
      return _buildEmptyState();
    }

    return Stack(
      children: [
        // Ana form içeriği
        Column(
          children: [
            // Normal form (kaydet butonunu gizle)
            Expanded(
              child: DynamicFormWidget(
                formModel: _formModel!,
                onFormChanged: _onFormDataChanged,
                onSave: null, // Kaydet butonunu gizle
                isLoading: _isSaving,
                isEditing: isEditing,
              ),
            ),
          ],
        ),

        // 🚀 CUSTOM FOOTER - En altta
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildHybridFormActions(),
        ),
      ],
    );
  }

  // 🚀 HYBRID FORM ACTIONS - Konum + Kaydet butonları
  Widget _buildHybridFormActions() {
    final size = AppSizes.of(context);

    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🎯 KONUM SEKSİYONU
            _buildLocationSection(size),

            SizedBox(height: size.mediumSpacing),

            // 🎯 ANA AKSIYON BUTONLARI
            Row(
              children: [
                // Cancel button
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.textSecondary),
                      padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.cardBorderRadius),
                      ),
                    ),
                    child: Text(
                      'İptal',
                      style: TextStyle(
                        fontSize: size.textSize,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: size.mediumSpacing),

                // Save button
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveActivity,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.25),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.cardBorderRadius),
                      ),
                      elevation: 3,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isEditing ? Icons.update : Icons.save,
                                size: 20,
                              ),
                              SizedBox(width: size.smallSpacing),
                              Text(
                                isEditing ? 'Güncelle' : 'Kaydet',
                                style: TextStyle(
                                  fontSize: size.textSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 🎯 KONUM SEKSİYONU - Akıllı görünüm
  Widget _buildLocationSection(AppSizes size) {
    final bool hasLocation = _currentLocationText != null;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: double.infinity,
      padding: EdgeInsets.all(size.cardPadding * 0.8),
      decoration: BoxDecoration(
        color: hasLocation ? AppColors.success.withValues(alpha: 0.1) : AppColors.inputBackground,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(
          color: hasLocation ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
          width: 1.5,
        ),
      ),
      child: hasLocation ? _buildLocationSuccess(size) : _buildLocationEmpty(size),
    );
  }

  // 🎯 KONUM ALINDIĞINDA GÖSTERILEN GÖRÜNÜM
  // AddActivityScreen'deki _buildLocationSuccess metodunu şu şekilde güncelle:

// 🎯 KONUM ALINDIĞINDA GÖSTERILEN GÖRÜNÜM - GELİŞMİŞ
  Widget _buildLocationSuccess(AppSizes size) {
    return Column(
      children: [
        // Konum bilgisi header
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
            // Yeniden konum al butonu
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
                  : Icon(
                      Icons.refresh,
                      color: AppColors.primary,
                      size: 20,
                    ),
              tooltip: 'Konumu yenile',
              splashRadius: 20,
            ),
            // Temizle butonu
            IconButton(
              onPressed: _clearLocation,
              icon: Icon(
                Icons.close,
                color: AppColors.error,
                size: 18,
              ),
              tooltip: 'Konumu temizle',
              splashRadius: 20,
            ),
          ],
        ),

        SizedBox(height: size.mediumSpacing),

        // 🎯 KONUM KARŞILAŞTIRMASI
        _buildLocationComparison(size),

        // Mesafe ve durum bilgisi
        if (_formData['LocationDistance'] != null) ...[
          SizedBox(height: size.mediumSpacing),
          _buildLocationStatus(size),
        ],
      ],
    );
  }

// 🎯 KONUM KARŞILAŞTIRMASI WİDGET'I
  Widget _buildLocationComparison(AppSizes size) {
    // Firma konumu bilgisi (eğer varsa)
    final companyLocation = _getCompanyLocationText();

    return Container(
      padding: EdgeInsets.all(size.cardPadding * 0.8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 0.8),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          // Firma konumu
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.business,
                  color: AppColors.primary,
                  size: 14,
                ),
              ),
              SizedBox(width: size.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firma Konumu:',
                      style: TextStyle(
                        fontSize: size.smallText * 0.9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: size.tinySpacing),
                    Text(
                      companyLocation ?? 'Firma konumu kayıtlı değil',
                      style: TextStyle(
                        fontSize: size.smallText,
                        color: companyLocation != null ? AppColors.textPrimary : AppColors.textTertiary,
                        fontWeight: FontWeight.w500,
                        fontStyle: companyLocation != null ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Ayırıcı çizgi
          Container(
            margin: EdgeInsets.symmetric(vertical: size.smallSpacing),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: size.smallSpacing),
                  child: Icon(
                    Icons.compare_arrows,
                    color: AppColors.textTertiary,
                    size: 16,
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: AppColors.border.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),

          // Mevcut konum
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location,
                  color: AppColors.success,
                  size: 14,
                ),
              ),
              SizedBox(width: size.smallSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mevcut Konumum:',
                      style: TextStyle(
                        fontSize: size.smallText * 0.9,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: size.tinySpacing),
                    Text(
                      _currentLocationText!,
                      style: TextStyle(
                        fontSize: size.smallText,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// 🎯 KONUM DURUMU WİDGET'I
  Widget _buildLocationStatus(AppSizes size) {
    final distance = _formData['LocationDistance'] as String?;
    final status = _formData['LocationComparisonStatus'] as String?;
    final message = _formData['LocationComparisonMessage'] as String?;

    if (distance == null || status == null) {
      return SizedBox.shrink();
    }

    // Durum rengini belirle
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'atLocation':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case 'nearby':
        statusColor = AppColors.info;
        statusIcon = Icons.location_on;
        break;
      case 'close':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning;
        break;
      case 'far':
      case 'veryFar':
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.all(size.cardPadding * 0.8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 0.8),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Durum başlığı
          Row(
            children: [
              Icon(
                statusIcon,
                color: statusColor,
                size: 18,
              ),
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
              // Mesafe badge
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

          // Durum mesajı
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

// 🎯 YARDIMCI METODLAR
  String? _getCompanyLocationText() {
    // Eğer firma seçilmişse ve firma konumu varsa
    if (_formData['CompanyId'] != null) {
      // Bu bilgi API'den gelecek, şimdilik örnek
      return 'Migros AVM, Battalgazi/Malatya';
    }
    return null;
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

// 🎯 KONUM ALINMADIĞINDA GÖSTERILEN GÖRÜNÜM
  Widget _buildLocationEmpty(AppSizes size) {
    return Column(
      children: [
        // Açıklama
        // Row(
        //   children: [
        //     Icon(
        //       Icons.info_outline,
        //       color: AppColors.textSecondary,
        //       size: 18,
        //     ),
        //     SizedBox(width: size.smallSpacing),
        //     Expanded(
        //       child: Text(
        //         'Ziyaret konumunuzu kaydetmek için konum alın',
        //         style: TextStyle(
        //           fontSize: size.smallText,
        //           color: AppColors.textSecondary,
        //           fontWeight: FontWeight.w500,
        //         ),
        //       ),
        //     ),
        //   ],
        // ),

        // SizedBox(height: size.mediumSpacing),

        // Konum al butonu
        SizedBox(
          width: double.infinity,
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
                : Icon(
                    Icons.my_location,
                    size: 18,
                  ),
            label: Text(
              _isGettingLocation ? 'Konum Alınıyor...' : 'Konumumu Al',
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
                borderRadius: BorderRadius.circular(size.cardBorderRadius * 0.8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Konum temizleme metodu
  void _clearLocation() {
    setState(() {
      _currentLocationText = null;
      _formData.remove('Location');
      _formData.remove('LocationText');
      _formData.remove('LocationComparisonStatus');
      _formData.remove('LocationComparisonMessage');
      _formData.remove('LocationDistance');
    });

    SnackbarHelper.showInfo(
      context: context,
      message: 'Konum bilgisi temizlendi',
    );
  }

  Widget _buildLoadingState() {
    final size = AppSizes.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(size.cardPadding * 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(size.cardBorderRadius * 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 60,
                  height: 60,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(height: size.largeSpacing),
                Text(
                  isEditing ? 'Aktivite bilgileri yükleniyor...' : 'Form yükleniyor...',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  'Lütfen bekleyin',
                  style: TextStyle(
                    fontSize: size.textSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    final size = AppSizes.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding * 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(size.cardBorderRadius * 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(size.cardPadding),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  Text(
                    'Form Yüklenemedi',
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: size.smallSpacing),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.textSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.textSecondary),
                        ),
                        child: const Text('Geri Dön'),
                      ),
                      SizedBox(width: size.mediumSpacing),
                      ElevatedButton(
                        onPressed: _loadFormData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textOnPrimary,
                        ),
                        child: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final size = AppSizes.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppColors.textTertiary,
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              'Form bulunamadı',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              'Aktivite form verisi alınamadı. Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
              ),
              child: const Text('Geri Dön'),
            ),
          ],
        ),
      ),
    );
  }
}
