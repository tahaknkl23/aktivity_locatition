// lib/presentation/screens/report/dynamic_report_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/report_api_service.dart';
import '../../../data/models/menu/menu_model.dart';
import '../../providers/menu_provider.dart';

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
  
  List<Map<String, dynamic>> _reportData = [];
  List<MenuItem> _reportMenuItems = [];
  bool _isLoading = true;
  bool _isMenuLoading = true;
  String? _errorMessage;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadReportMenus();
    _loadReportData();
  }

  /// API'den report menülerini getir
  Future<void> _loadReportMenus() async {
    try {
      final menuProvider = context.read<MenuProvider>();
      
      // Menü zaten yüklüyse kullan
      if (menuProvider.hasMenuItems) {
        _extractReportMenus(menuProvider.menuItems);
      } else {
        // Menü yüklenmemişse yükle
        await menuProvider.loadMenu();
        if (menuProvider.hasMenuItems) {
          _extractReportMenus(menuProvider.menuItems);
        }
      }
    } catch (e) {
      debugPrint('[DYNAMIC_REPORT] ❌ Menu load error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMenuLoading = false;
        });
      }
    }
  }

  /// Menüden rapor öğelerini çıkar
  void _extractReportMenus(List<MenuItem> menuItems) {
    final reportMenus = <MenuItem>[];
    
    for (final mainMenu in menuItems) {
      // "Raporlar" ana menüsünü bul
      if (mainMenu.cleanTitle.toLowerCase().contains('rapor')) {
        debugPrint('[DYNAMIC_REPORT] 📊 Found reports menu: ${mainMenu.cleanTitle}');
        debugPrint('[DYNAMIC_REPORT] 📊 Sub items: ${mainMenu.items.length}');
        
        // Alt menüleri ekle
        for (final subItem in mainMenu.items) {
          if (subItem.url != null && subItem.url!.startsWith('Report/Detail/')) {
            reportMenus.add(subItem);
            debugPrint('[DYNAMIC_REPORT] 📊 Added report: ${subItem.cleanTitle} (${subItem.url})');
          }
        }
        break;
      }
    }
    
    if (mounted) {
      setState(() {
        _reportMenuItems = reportMenus;
      });
    }
    
    debugPrint('[DYNAMIC_REPORT] ✅ Found ${reportMenus.length} report menu items');
  }

  /// Mevcut rapor verisini yükle
  Future<void> _loadReportData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[DYNAMIC_REPORT] 📊 Loading data for report ID: ${widget.reportId}');
      
      final result = await _reportApiService.getReportData(
        reportId: widget.reportId,
        page: 1,
        pageSize: 50,
      );

      final dataSourceResult = result['DataSourceResult'] as Map<String, dynamic>? ?? {};
      final newData = dataSourceResult['Data'] as List<dynamic>? ?? [];
      final total = dataSourceResult['Total'] as int? ?? 0;

      if (mounted) {
        setState(() {
          _reportData = newData.cast<Map<String, dynamic>>();
          _totalCount = total;
          _isLoading = false;
        });
        
        debugPrint('[DYNAMIC_REPORT] ✅ Loaded ${newData.length} records');
      }
    } catch (e) {
      debugPrint('[DYNAMIC_REPORT] ❌ Data load error: $e');
      
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Başka rapora geç
  void _navigateToReport(MenuItem reportItem) {
    final reportUrl = reportItem.url!;
    final reportId = reportUrl.split('/').last;
    
    debugPrint('[DYNAMIC_REPORT] 🔄 Navigating to report: ${reportItem.cleanTitle} (ID: $reportId)');
    
    // Yeni rapor sayfasına git
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DynamicReportScreen(
          reportId: reportId,
          title: reportItem.cleanTitle,
          url: reportUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _loadReportData,
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
          ),
        ],
      ),
      body: Row(
        children: [
          // Sol Menü - API'den gelen raporlar
          Container(
            width: size.isMobile ? 80 : 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: _buildDynamicSideMenu(size),
          ),
          
          // Ana İçerik
          Expanded(
            child: _buildMainContent(size),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicSideMenu(AppSizes size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Container(
          padding: EdgeInsets.all(size.padding),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.assessment, color: AppColors.primary, size: 20),
              if (!size.isMobile) ...[
                SizedBox(width: size.smallSpacing),
                Expanded(
                  child: Text(
                    'Raporlar',
                    style: TextStyle(
                      fontSize: size.textSize,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
              if (_isMenuLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
            ],
          ),
        ),

        // Menü öğeleri - API'den gelenler
        Expanded(
          child: _isMenuLoading
              ? _buildMenuLoadingState(size)
              : _reportMenuItems.isEmpty
                  ? _buildMenuEmptyState(size)
                  : ListView.builder(
                      itemCount: _reportMenuItems.length,
                      itemBuilder: (context, index) {
                        final item = _reportMenuItems[index];
                        final reportId = item.url!.split('/').last;
                        final isActive = reportId == widget.reportId;
                        
                        return Container(
                          margin: EdgeInsets.symmetric(
                            horizontal: size.isMobile ? 4 : 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isActive ? AppColors.primary.withValues(alpha: 0.1) : null,
                            borderRadius: BorderRadius.circular(8),
                            border: isActive ? Border.all(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ) : null,
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getReportIcon(item.cleanTitle),
                              color: isActive ? AppColors.primary : AppColors.textSecondary,
                              size: size.isMobile ? 18 : 20,
                            ),
                            title: size.isMobile ? null : Text(
                              item.cleanTitle,
                              style: TextStyle(
                                fontSize: size.smallText,
                                color: isActive ? AppColors.primary : AppColors.textPrimary,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: size.isMobile ? null : Text(
                              'ID: $reportId',
                              style: TextStyle(
                                fontSize: size.smallText * 0.8,
                                color: AppColors.textTertiary,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: size.isMobile ? 8 : 12,
                              vertical: size.isMobile ? 12 : 8,
                            ),
                            onTap: isActive ? null : () => _navigateToReport(item),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMenuLoadingState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            SizedBox(height: size.mediumSpacing),
            Text(
              'Raporlar yükleniyor...',
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuEmptyState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Text(
          'Rapor bulunamadı',
          style: TextStyle(
            fontSize: size.smallText,
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Rapor türüne göre ikon belirle
  IconData _getReportIcon(String title) {
    final lowerTitle = title.toLowerCase();
    
    if (lowerTitle.contains('firma') || lowerTitle.contains('company')) return Icons.business;
    if (lowerTitle.contains('kişi') || lowerTitle.contains('contact')) return Icons.people;
    if (lowerTitle.contains('stok') || lowerTitle.contains('stock')) return Icons.inventory;
    if (lowerTitle.contains('fırsat') || lowerTitle.contains('opportunity')) return Icons.lightbulb;
    if (lowerTitle.contains('teklif') || lowerTitle.contains('offer')) return Icons.description;
    if (lowerTitle.contains('sipariş') || lowerTitle.contains('order')) return Icons.shopping_cart;
    if (lowerTitle.contains('satış') || lowerTitle.contains('sales')) return Icons.trending_up;
    if (lowerTitle.contains('maliyet') || lowerTitle.contains('cost')) return Icons.analytics;
    if (lowerTitle.contains('fiyat') || lowerTitle.contains('price')) return Icons.attach_money;
    
    return Icons.bar_chart;
  }

  Widget _buildMainContent(AppSizes size) {
    return Column(
      children: [
        // Üst bilgi çubuğu
        Container(
          padding: EdgeInsets.all(size.padding),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: size.mediumText,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Rapor ID: ${widget.reportId}',
                      style: TextStyle(
                        fontSize: size.smallText,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _totalCount > 0 
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _totalCount > 0 
                        ? AppColors.success.withValues(alpha: 0.3)
                        : AppColors.warning.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _totalCount > 0 ? Icons.data_usage : Icons.info_outline,
                      size: 16,
                      color: _totalCount > 0 ? AppColors.success : AppColors.warning,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _totalCount > 0 ? '$_totalCount Kayıt' : 'Veri Yok',
                      style: TextStyle(
                        fontSize: size.smallText,
                        color: _totalCount > 0 ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // İçerik alanı
        Expanded(
          child: _buildContentArea(size),
        ),
      ],
    );
  }

  Widget _buildContentArea(AppSizes size) {
    if (_isLoading) {
      return _buildLoadingState(size);
    }

    if (_errorMessage != null) {
      return _buildErrorState(size);
    }

    if (_reportData.isEmpty) {
      return _buildEmptyState(size);
    }

    return _buildDataTable(size);
  }

  Widget _buildDataTable(AppSizes size) {
    final columns = _reportData.isNotEmpty ? _reportData.first.keys.toList() : <String>[];

    return Container(
      margin: EdgeInsets.all(size.padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Tablo başlığı
          Container(
            padding: EdgeInsets.all(size.padding),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.table_chart, color: AppColors.primary, size: 20),
                SizedBox(width: size.smallSpacing),
                Text(
                  'Rapor Verileri',
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_reportData.length} satır',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Tablo içeriği
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 24,
                  horizontalMargin: size.padding,
                  headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                  columns: columns.map((column) => DataColumn(
                    label: Container(
                      constraints: const BoxConstraints(minWidth: 100),
                      child: Text(
                        _formatColumnName(column),
                        style: TextStyle(
                          fontSize: size.textSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )).toList(),
                  rows: _reportData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    
                    return DataRow(
                      color: WidgetStateProperty.all(
                        index % 2 == 0 ? null : Colors.grey.shade50,
                      ),
                      cells: columns.map((column) => DataCell(
                        Container(
                          constraints: const BoxConstraints(minWidth: 100),
                          child: Text(
                            _formatCellValue(row[column]),
                            style: TextStyle(
                              fontSize: size.textSize,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      )).toList(),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          SizedBox(height: size.largeSpacing),
          Text(
            'Rapor yükleniyor...',
            style: TextStyle(
              fontSize: size.mediumText,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          SizedBox(height: size.largeSpacing),
          Text(
            'Rapor yüklenemedi',
            style: TextStyle(
              fontSize: size.mediumText,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(_errorMessage!, textAlign: TextAlign.center),
          SizedBox(height: size.largeSpacing),
          ElevatedButton(
            onPressed: _loadReportData,
            child: const Text('Tekrar Dene'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: AppColors.textTertiary),
          SizedBox(height: size.largeSpacing),
          Text(
            'Bu raporda veri bulunamadı',
            style: TextStyle(
              fontSize: size.mediumText,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Rapor ID: ${widget.reportId}',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatColumnName(String column) {
    switch (column.toLowerCase()) {
      case 'value': return 'Değer';
      case 'defult': return 'Varsayılan';
      case 'tolera': return 'Tolerans';
      case 'id': return 'ID';
      case 'name': return 'Ad';
      case 'firma': return 'Firma';
      case 'amount': return 'Tutar';
      case 'date': return 'Tarih';
      default: return column;
    }
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '-';
    if (value is num) {
      return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
    return value.toString();
  }
}