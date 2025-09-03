// lib/presentation/screens/report/report_execution_screen.dart - IMPROVED VERSION
import 'package:aktivity_location_app/presentation/widgets/report/chart_type_renderer.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/report_api_service.dart';
import '../../../data/models/dynamic_form/form_field_model.dart';
import '../../../core/widgets/dynamic_form/dynamic_form_widget.dart';

class ReportExecutionScreen extends StatefulWidget {
  final String reportId;
  final String reportName;
  final Map<String, dynamic> reportData;

  const ReportExecutionScreen({
    super.key,
    required this.reportId,
    required this.reportName,
    required this.reportData,
  });

  @override
  State<ReportExecutionScreen> createState() => _ReportExecutionScreenState();
}

class _ReportExecutionScreenState extends State<ReportExecutionScreen> {
  final ReportApiService _reportApiService = ReportApiService();

  // Form state
  DynamicFormModel? _filterFormModel;
  Map<String, dynamic> _filterData = {};
  bool _isLoadingForm = true;
  String? _formErrorMessage;

  // Report results state
  List<Map<String, dynamic>> _reportResults = [];
  ReportMetadata? _reportMetadata;
  bool _isLoadingReport = false;
  String? _reportErrorMessage;
  bool _hasExecutedReport = false;

  @override
  void initState() {
    super.initState();
    _loadReportForm();
  }

  /// 1. LOAD REPORT FILTER FORM
  Future<void> _loadReportForm() async {
    if (!mounted) return;

    setState(() {
      _isLoadingForm = true;
      _formErrorMessage = null;
    });

    try {
      debugPrint('[REPORT_EXECUTION] Loading filter form for report: ${widget.reportName}');
      debugPrint('[REPORT_EXECUTION] Report ID: ${widget.reportId}');

      // Paralel olarak form ve metadata al
      final futures = await Future.wait([
        _reportApiService.getDynamicReportForm(reportId: widget.reportId),
        _reportApiService.getReportMetadata(reportId: widget.reportId),
      ]);

      final formModel = futures[0] as DynamicFormModel;
      final metadata = futures[1] as ReportMetadata;

      debugPrint('[REPORT_EXECUTION] Filter form loaded: ${formModel.sections.length} sections');
      debugPrint('[REPORT_EXECUTION] Report metadata loaded: ${metadata.name}');

      // Dropdown options'ları async yükle
      await _loadDropdownOptionsAsync(formModel);
      if (!mounted) return;

      setState(() {
        _filterFormModel = formModel;
        _reportMetadata = metadata;
        _filterData = Map<String, dynamic>.from(formModel.data);
        _isLoadingForm = false;
      });

      // Form yüklendikten sonra otomatik çalıştır (filtre yoksa)
      if (!metadata.hasFilters || formModel.allFields.isEmpty) {
        debugPrint('[REPORT_EXECUTION] Auto-executing report (no filters required)');
        _executeReport();
      }
    } catch (e) {
      debugPrint('[REPORT_EXECUTION] Form load error: $e');
      if (!mounted) return;

      setState(() {
        _formErrorMessage = 'Rapor filtreleri yüklenirken hata: $e';
        _isLoadingForm = false;
      });
    }
  }

  /// 2. LOAD DROPDOWN OPTIONS ASYNC
  Future<void> _loadDropdownOptionsAsync(DynamicFormModel formModel) async {
    try {
      debugPrint('[REPORT_EXECUTION] Loading dropdown options...');

      final dropdownFields =
          formModel.allFields.where((f) => f.type == FormFieldType.dropdown && f.widget.sourceType != null && f.widget.sourceValue != null).toList();

      debugPrint('[REPORT_EXECUTION] Found ${dropdownFields.length} dropdown fields');

      // Paralel dropdown yükleme
      final futures = dropdownFields.map((field) => _reportApiService
              .getReportDropdownOptions(
            sourceType: field.widget.sourceType!,
            sourceValue: field.widget.sourceValue!,
            dataTextField: field.widget.dataTextField,
            dataValueField: field.widget.dataValueField,
          )
              .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint('[REPORT_EXECUTION] Timeout for ${field.label}');
              return <DropdownOption>[];
            },
          ));

      if (futures.isNotEmpty) {
        final optionsList = await Future.wait(futures);

        if (mounted) {
          setState(() {
            for (int i = 0; i < dropdownFields.length; i++) {
              dropdownFields[i].options = optionsList[i];
              debugPrint('[REPORT_EXECUTION] ${dropdownFields[i].label}: ${optionsList[i].length} options');
            }
          });
        }
      }

      debugPrint('[REPORT_EXECUTION] All dropdown options loaded');
    } catch (e) {
      debugPrint('[REPORT_EXECUTION] Dropdown options error: $e');
    }
  }

  /// 3. EXECUTE REPORT WITH FILTERS
  Future<void> _executeReport() async {
    if (!mounted) return;

    setState(() {
      _isLoadingReport = true;
      _reportErrorMessage = null;
    });

    try {
      debugPrint('[REPORT_EXECUTION] Executing report with filters...');
      debugPrint('[REPORT_EXECUTION] Filter data: ${_filterData.keys.toList()}');

      final result = await _reportApiService.executeDynamicReport(
        reportId: widget.reportId,
        filterData: _filterData,
        pageSize: 1000,
      );

      final dataList = result['Data'] as List<dynamic>? ?? [];

      debugPrint('[REPORT_EXECUTION] Report executed: ${dataList.length} records');

      if (dataList.isNotEmpty) {
        debugPrint('[REPORT_EXECUTION] Sample record: ${dataList.first}');
      }

      setState(() {
        _reportResults = dataList.cast<Map<String, dynamic>>();
        _isLoadingReport = false;
        _hasExecutedReport = true;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('[REPORT_EXECUTION] Report execution error: $e');
      setState(() {
        _reportErrorMessage = 'Rapor çalıştırılırken hata: $e';
        _isLoadingReport = false;
        _hasExecutedReport = true;
      });
    }
  }

  /// 4. HANDLE FORM CHANGES
  void _onFilterChanged(Map<String, dynamic> filterData) {
    setState(() {
      _filterData = filterData;
    });
    debugPrint('[REPORT_EXECUTION] Filter changed: ${filterData.keys.length} fields');
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.reportName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Results count badge
          if (_reportResults.isNotEmpty && !_isLoadingReport)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_reportResults.length} kayıt',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          IconButton(
            onPressed: _isLoadingForm || _isLoadingReport ? null : _loadReportForm,
            icon: _isLoadingForm
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
    if (_isLoadingForm) {
      return _buildFormLoadingState(size);
    }

    if (_formErrorMessage != null) {
      return _buildFormErrorState(size);
    }

    // Ana responsive layout
    return size.isMobile ? _buildMobileLayout(size) : _buildDesktopLayout(size);
  }

  Widget _buildMobileLayout(AppSizes size) {
    return Column(
      children: [
        // Filter section (collapsible on mobile)
        if (_filterFormModel != null && _filterFormModel!.allFields.isNotEmpty) _buildMobileFilterSection(size),

        // Results section
        Expanded(
          child: _buildResultsSection(size),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(AppSizes size) {
    return Row(
      children: [
        // Left sidebar for filters
        if (_filterFormModel != null && _filterFormModel!.allFields.isNotEmpty)
          SizedBox(
            width: 350,
            child: _buildDesktopFilterSection(size),
          ),

        // Main content area
        Expanded(
          child: _buildResultsSection(size),
        ),
      ],
    );
  }

  Widget _buildMobileFilterSection(AppSizes size) {
    return Container(
      margin: EdgeInsets.all(size.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(Icons.filter_list, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Text(
              'Filtreler',
              style: TextStyle(
                fontSize: size.textSize,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: _isLoadingReport ? null : _executeReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: Size(0, 32),
          ),
          child: _isLoadingReport
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, size: 16),
                    SizedBox(width: 4),
                    Text('Ara', style: TextStyle(fontSize: 12)),
                  ],
                ),
        ),
        children: [
          Container(
            constraints: BoxConstraints(maxHeight: 300),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(size.cardPadding),
              child: DynamicFormWidget(
                formModel: _filterFormModel!,
                onFormChanged: _onFilterChanged,
                isLoading: false,
                isEditing: false,
                showHeader: false,
                showActions: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopFilterSection(AppSizes size) {
    return Container(
      height: double.infinity,
      margin: EdgeInsets.all(size.padding),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Filter header
          Container(
            padding: EdgeInsets.all(size.cardPadding),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.1),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(size.cardBorderRadius),
                topRight: Radius.circular(size.cardBorderRadius),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list, color: AppColors.primary, size: 20),
                SizedBox(width: size.smallSpacing),
                Expanded(
                  child: Text(
                    'Filtreler',
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(size.cardPadding),
              child: DynamicFormWidget(
                formModel: _filterFormModel!,
                onFormChanged: _onFilterChanged,
                isLoading: false,
                isEditing: false,
                showHeader: false,
                showActions: false,
              ),
            ),
          ),

          // Action button
          Container(
            padding: EdgeInsets.all(size.cardPadding),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoadingReport ? null : _executeReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoadingReport
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 18),
                          SizedBox(width: 8),
                          Text('Raporu Çalıştır'),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// RESULTS SECTION
  Widget _buildResultsSection(AppSizes size) {
    if (!_hasExecutedReport) {
      return _buildWelcomeState(size);
    }

    if (_isLoadingReport) {
      return _buildReportLoadingState(size);
    }

    if (_reportErrorMessage != null) {
      return _buildReportErrorState(size);
    }

    if (_reportResults.isEmpty) {
      return _buildEmptyResultsState(size);
    }

    return _buildReportResults(size);
  }

  Widget _buildWelcomeState(AppSizes size) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(size.padding),
        padding: EdgeInsets.all(size.cardPadding * 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(size.cardBorderRadius * 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
              child: Icon(
                Icons.analytics_outlined,
                size: 48,
                color: Colors.white,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              widget.reportName,
              style: TextStyle(
                fontSize: size.mediumText * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              'Rapor yükleniyor. ${_filterFormModel?.allFields.isNotEmpty == true ? "Filtreleri ayarlayın ve" : ""} Lütfen kapatmayın!.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportResults(AppSizes size) {
    if (_reportResults.isEmpty) return Container();

    // ChartType'ı reportData'dan al
    final chartType = widget.reportData['ChartType'] as String? ?? _reportMetadata?.chartType ?? 'Grid';

    debugPrint('🔍 Using ChartType: "$chartType" from reportData');

    return Container(
      margin: EdgeInsets.fromLTRB(size.padding, 0, size.padding, size.padding),
      child: ReportChartRenderer(
        chartType: chartType,
        data: _reportResults,
        title: widget.reportName,
      ),
    );
  }

  Widget _buildFormLoadingState(AppSizes size) {
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(height: size.largeSpacing),
                Text(
                  'Rapor yükleniyor...',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  widget.reportName,
                  style: TextStyle(
                    fontSize: size.smallText,
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

  Widget _buildReportLoadingState(AppSizes size) {
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
                SizedBox(height: size.largeSpacing),
                Text(
                  'Arama yapılıyor...',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  'Veriler getiriliyor',
                  style: TextStyle(
                    fontSize: size.smallText,
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

  Widget _buildFormErrorState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
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
              _formErrorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            ElevatedButton.icon(
              onPressed: _loadReportForm,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportErrorState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(size.cardPadding),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(size.cardBorderRadius),
              ),
              child: Icon(
                Icons.report_problem_outlined,
                size: 64,
                color: Colors.red,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            Text(
              'Arama Başarısız',
              style: TextStyle(
                fontSize: size.mediumText,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              _reportErrorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.largeSpacing),
            ElevatedButton.icon(
              onPressed: _executeReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyResultsState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(size.cardPadding),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(size.cardBorderRadius),
            ),
            child: Icon(
              Icons.search_off,
              size: 64,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: size.largeSpacing),
          Text(
            'Sonuç Bulunamadı',
            style: TextStyle(
              fontSize: size.mediumText,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Seçilen kriterlere uygun veri bulunamadı\nFarklı filtre seçenekleri deneyin',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
