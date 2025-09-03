// lib/presentation/screens/report/dynamic_report_screen.dart - IMPROVED COMPACT VERSION
import 'package:aktivity_location_app/presentation/screens/report/report_execution_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/report_api_service.dart';

class DynamicReportScreen extends StatefulWidget {
  final String reportId;
  final String title;
  final String url;

  const DynamicReportScreen({
    super.key,
    required this.reportId,
    required this.title,
    required this.url,
  });

  @override
  State<DynamicReportScreen> createState() => _DynamicReportScreenState();
}

class _DynamicReportScreenState extends State<DynamicReportScreen> {
  final ReportApiService _reportApiService = ReportApiService();

  List<Map<String, dynamic>> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[DYNAMIC_REPORT] Loading reports for group: ${widget.reportId}');
      debugPrint('[DYNAMIC_REPORT] Title: ${widget.title}');

      final response = await _reportApiService.getReportGroupItems(
        groupId: widget.reportId,
      );

      final reportList = response['Data'] as List? ?? [];

      debugPrint('[DYNAMIC_REPORT] ✅ Loaded ${reportList.length} reports');

      if (reportList.isNotEmpty) {
        final firstReport = reportList.first;
        debugPrint('[DYNAMIC_REPORT] 📊 First report: ${firstReport['Name']} (${firstReport['ChartType']})');
      }

      setState(() {
        _reports = reportList.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[DYNAMIC_REPORT] ❌ Error: $e');
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
          if (_reports.isNotEmpty && !_isLoading)
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
                    '${_reports.length} rapor',
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
            onPressed: _loadReports,
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

    if (_reports.isEmpty) {
      return _buildEmptyState(size);
    }

    return _buildReportsList(size);
  }

  Widget _buildLoadingState(AppSizes size) {
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
                  'Raporlar yükleniyor...',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  widget.title,
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
              'Raporlar Yüklenemedi',
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
            ElevatedButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppSizes size) {
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
              Icons.assessment_outlined,
              size: 64,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: size.largeSpacing),
          Text(
            'Rapor Bulunamadı',
            style: TextStyle(
              fontSize: size.mediumText,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Bu kategoride henüz rapor yok',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList(AppSizes size) {
    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView.separated(
        padding: EdgeInsets.all(size.padding),
        itemCount: _reports.length,
        separatorBuilder: (context, index) => SizedBox(height: size.smallSpacing),
        itemBuilder: (context, index) {
          final report = _reports[index];
          return _buildCompactReportCard(report, size);
        },
      ),
    );
  }

  // IMPROVED: Çok temiz ve basit rapor listesi
  Widget _buildCompactReportCard(Map<String, dynamic> report, AppSizes size) {
    final reportName = report['Name'] as String? ?? 'İsimsiz Rapor';
    final reportId = report['Id']?.toString() ?? '';
    final chartType = report['ChartType'] as String? ?? 'Grid';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToReportDetail(reportId, reportName, report),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Color(0xFFF3F4F6),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              // Chart type icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getChartTypeColor(chartType).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getChartTypeIcon(chartType),
                  color: _getChartTypeColor(chartType),
                  size: 20,
                ),
              ),

              SizedBox(width: 16),

              // Report info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reportName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getChartTypeDisplayName(chartType),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                size: 20,
                color: Color(0xFFD1D5DB),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToReportDetail(String reportId, String reportName, Map<String, dynamic> reportData) {
    debugPrint('[DYNAMIC_REPORT] Opening report: $reportName (ID: $reportId)');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportExecutionScreen(
          reportId: reportId,
          reportName: reportName,
          reportData: reportData,
        ),
      ),
    );
  }

  Color _getChartTypeColor(String chartType) {
    switch (chartType.toLowerCase()) {
      case 'grid':
        return Color(0xFF3B82F6); // Modern blue
      case 'bar':
        return Color(0xFF10B981); // Modern green
      case 'chart':
        return Color(0xFFF59E0B); // Modern orange
      case 'pivot':
        return Color(0xFF8B5CF6); // Modern purple
      case 'line':
        return Color(0xFF06B6D4); // Modern teal
      default:
        return Color(0xFF6B7280); // Modern gray
    }
  }

  IconData _getChartTypeIcon(String chartType) {
    switch (chartType.toLowerCase()) {
      case 'grid':
        return Icons.table_chart_outlined;
      case 'bar':
        return Icons.bar_chart_outlined;
      case 'chart':
        return Icons.pie_chart_outline;
      case 'pivot':
        return Icons.pivot_table_chart_outlined;
      case 'line':
        return Icons.show_chart_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  String _getChartTypeDisplayName(String chartType) {
    switch (chartType.toLowerCase()) {
      case 'grid':
        return 'Tablo';
      case 'bar':
        return 'Çubuk';
      case 'chart':
        return 'Pasta';
      case 'pivot':
        return 'Özet';
      case 'line':
        return 'Çizgi';
      default:
        return chartType;
    }
  }
}
