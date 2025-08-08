// lib/presentation/screens/common/generic_dynamic_form_screen.dart
import 'package:aktivity_location_app/core/widgets/dynamic_form/dynamic_form_widget.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/base_api_service.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';

class GenericDynamicFormScreen extends StatefulWidget {
  final String controller;
  final String title;
  final String url;
  final int? id;

  const GenericDynamicFormScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.url,
    this.id,
  });

  @override
  State<GenericDynamicFormScreen> createState() => _GenericDynamicFormScreenState();
}

class _GenericDynamicFormScreenState extends State<GenericDynamicFormScreen> {
  final BaseApiService _apiService = BaseApiService();

  DynamicFormModel? _formModel;
  Map<String, dynamic> _formData = {};
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[GENERIC_FORM] 📋 Loading form for controller: ${widget.controller}');
      debugPrint('[GENERIC_FORM] 🔗 URL: ${widget.url}');

      final response = await _apiService.getFormWithData(
        controller: widget.controller,
        url: widget.url,
        id: widget.id ?? 0,
      );

      final formModel = DynamicFormModel.fromJson(response);

      setState(() {
        _formModel = formModel;
        _formData = Map<String, dynamic>.from(formModel.data);
        _isLoading = false;
      });

      debugPrint('[GENERIC_FORM] ✅ Form loaded: ${formModel.formName}');
      debugPrint('[GENERIC_FORM] 📊 Sections: ${formModel.sections.length}');

      // 🔍 RAW RESPONSE KONTROLÜ
      debugPrint('[GENERIC_FORM] 🔍 Raw response keys: ${response.keys.toList()}');
      if (response['Data'] != null) {
        final data = response['Data'];
        debugPrint('[GENERIC_FORM] 🔍 Data keys: ${data.keys.toList()}');
        if (data['Form'] != null) {
          final form = data['Form'];
          debugPrint('[GENERIC_FORM] 🔍 Form keys: ${form.keys.toList()}');
          if (form['Sections'] != null) {
            debugPrint('[GENERIC_FORM] 🔍 Sections raw: ${form['Sections']}');
          }
        }
      }

      // 🔍 SECTION DETAYLARI
      for (int i = 0; i < formModel.sections.length; i++) {
        final section = formModel.sections[i];
        debugPrint('[GENERIC_FORM] 📋 Section $i: "${section.label}" - ${section.fields.length} fields');

        // Field detayları
        for (int j = 0; j < section.fields.length; j++) {
          final field = section.fields[j];
          debugPrint('[GENERIC_FORM] 📝 Field $j: "${field.label}" (${field.type}) - visible: ${field.isVisible}');
        }
      }

      // 🔍 FORM DATA DETAYLARI
      debugPrint('[GENERIC_FORM] 📊 Form data keys: ${formModel.data.keys.toList()}');
      debugPrint('[GENERIC_FORM] 📊 All fields count: ${formModel.allFields.length}');
    } catch (e) {
      setState(() {
        _errorMessage = 'Form yüklenirken hata oluştu: $e';
        _isLoading = false;
      });

      debugPrint('[GENERIC_FORM] ❌ Form load error: $e');
    }
  }

  Future<void> _saveForm() async {
    if (_formModel == null) return;

    setState(() => _isSaving = true);

    try {
      debugPrint('[GENERIC_FORM] 💾 Saving form data...');
      debugPrint('[GENERIC_FORM] 📊 Data keys: ${_formData.keys.toList()}');

    

      debugPrint('[GENERIC_FORM] ✅ Form saved successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('${widget.title} başarıyla kaydedildi'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Başarılı kayıt sonrası geri dön
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('[GENERIC_FORM] ❌ Save error: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Kayıt sırasında hata: $e')),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _onFormChanged(Map<String, dynamic> formData) {
    setState(() {
      _formData = formData;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_formModel != null && !_isLoading)
            IconButton(
              onPressed: _isSaving ? null : _loadForm,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.refresh),
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: _buildBody(size),
    );
  }

  Widget _buildBody(AppSizes size) {
    if (_isLoading) {
      return _buildLoadingState(size);
    }

    if (_errorMessage != null) {
      return _buildErrorState(size);
    }

    if (_formModel == null) {
      return _buildEmptyState(size);
    }

    return _buildFormContent(size);
  }

  Widget _buildLoadingState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: size.mediumSpacing),
          Text(
            '${widget.title} yükleniyor...',
            style: TextStyle(
              fontSize: size.mediumText,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Controller: ${widget.controller}',
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textTertiary,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
              child: Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri Dön'),
                ),
                SizedBox(width: size.mediumSpacing),
                ElevatedButton.icon(
                  onPressed: _loadForm,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppSizes size) {
    return Center(
      child: Text(
        'Form verisi bulunamadı',
        style: TextStyle(
          fontSize: size.mediumText,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildFormContent(AppSizes size) {
    // 🚨 TEMPORARY FIX: Raw field display
    if (_formModel!.sections.isEmpty || _formModel!.allFields.isEmpty) {
      return _buildRawDataDisplay(size);
    }

    return Column(
      children: [
        // Form content
        Expanded(
          child: DynamicFormWidget(
            formModel: _formModel!,
            onFormChanged: _onFormChanged,
            isLoading: _isSaving,
            isEditing: widget.id != null,
            showHeader: false, // AppBar'da zaten başlık var
            showActions: false, // Custom action bar kullanacağız
          ),
        ),

        // Custom action bar
        _buildActionBar(size),
      ],
    );
  }

  // 🆕 Raw data display (temporary)
  Widget _buildRawDataDisplay(AppSizes size) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(size.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form info
                Container(
                  padding: EdgeInsets.all(size.cardPadding),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Form Parse Problemi',
                        style: TextStyle(
                          fontSize: size.mediumText,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      SizedBox(height: size.smallSpacing),
                      Text(
                        'Field parsing çalışmıyor. Raw data aşağıda gösteriliyor:',
                        style: TextStyle(
                          fontSize: size.textSize,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.largeSpacing),

                // Form data as simple fields
                Text(
                  'Form Verileri:',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.mediumSpacing),

                // Display form data as simple text fields
                ..._buildSimpleFields(size),
              ],
            ),
          ),
        ),

        // Action bar
        _buildActionBar(size),
      ],
    );
  }

  List<Widget> _buildSimpleFields(AppSizes size) {
    final fields = <Widget>[];
    final skipKeys = ['_AutoComplateText', '_DDL', 'Id'];

    _formData.forEach((key, value) {
      // Skip helper fields
      if (skipKeys.any((skip) => key.contains(skip))) return;

      fields.add(
        Container(
          margin: EdgeInsets.only(bottom: size.mediumSpacing),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _formatFieldLabel(key),
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: size.smallSpacing),
              TextFormField(
                initialValue: value?.toString() ?? '',
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(size.formFieldBorderRadius),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                ),
                onChanged: (newValue) {
                  setState(() {
                    _formData[key] = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      );
    });

    return fields;
  }

  String _formatFieldLabel(String key) {
    // Field isimlerini daha okunabilir yap
    const fieldNames = {
      'CompanyId': 'Firma',
      'DocumentDate': 'Belge Tarihi',
      'AppointedUserId': 'Atanan Kullanıcı',
      'ContactId': 'İletişim Kişisi',
      'Subject': 'Konu',
      'DocumentNo1': 'Belge No',
      'Explanation': 'Açıklama',
      'OpportunityId': 'Fırsat',
      'AvailableDate': 'Geçerlilik Tarihi',
      'PaymentType': 'Ödeme Türü',
      'TransportType': 'Taşıma Türü',
      'Status': 'Durum',
      'ProcessStep': 'İşlem Adımı',
      'ProcessType': 'İşlem Türü',
    };

    return fieldNames[key] ?? key;
  }

  Widget _buildActionBar(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Cancel button
            Expanded(
              child: OutlinedButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                ),
                child: Text(
                  'İptal',
                  style: TextStyle(fontSize: size.textSize),
                ),
              ),
            ),
            SizedBox(width: size.mediumSpacing),

            // Save button
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: size.buttonHeight * 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(size.cardBorderRadius),
                  ),
                ),
                child: _isSaving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: size.smallSpacing),
                          const Text('Kaydediliyor...'),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.save, size: 20),
                          SizedBox(width: size.smallSpacing),
                          Text(
                            widget.id != null ? 'Güncelle' : 'Kaydet',
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
      ),
    );
  }
}
