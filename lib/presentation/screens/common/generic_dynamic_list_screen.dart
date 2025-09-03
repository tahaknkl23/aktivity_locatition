import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/base_api_service.dart';

class GenericDynamicListScreen extends StatefulWidget {
  final String controller;
  final String title;
  final String url;
  final String listType;

  const GenericDynamicListScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.url,
    required this.listType,
  });

  @override
  State<GenericDynamicListScreen> createState() => _GenericDynamicListScreenState();
}

class _GenericDynamicListScreenState extends State<GenericDynamicListScreen> {
  final BaseApiService _apiService = BaseApiService();

  List<Map<String, dynamic>> _listData = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _totalCount = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadListData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadListData({bool isRefresh = false}) async {
    setState(() {
      _listData.clear();
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[GENERIC_LIST] 🔍 Loading all data...');
      debugPrint('[GENERIC_LIST] 📋 Controller: ${widget.controller}');
      debugPrint('[GENERIC_LIST] 🔗 URL: ${widget.url}');

      // ✅ SINGLE REQUEST - Load all data at once
      final response = await _apiService.getFormListData(
        controller: widget.controller,
        params: _extractParams(),
        formPath: widget.url,
        page: 1,
        pageSize: 999999, // Very large number to get all data
      );

      final allData = _extractDataFromResponse(response);
      final total = _extractTotalFromResponse(response);

      debugPrint('[GENERIC_LIST] ✅ ALL DATA LOADED: ${allData.length} items, total: $total');

      if (mounted) {
        setState(() {
          _listData = allData.cast<Map<String, dynamic>>();
          _totalCount = total;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[GENERIC_LIST] ❌ Error: $e');

      if (mounted) {
        setState(() {
          _errorMessage = 'Liste yüklenirken hata oluştu: $e';
          _isLoading = false;
        });
      }
    }
  }

  // Extract data from response - Support both new and old formats
  List<dynamic> _extractDataFromResponse(Map<String, dynamic> response) {
    debugPrint('[GENERIC_LIST] 🔍 Parsing response...');
    debugPrint('[GENERIC_LIST] 📦 Response structure: ${response.keys.toList()}');

    // ✅ NEW FORMAT: Direct "Data" array (from GetFormListData)
    if (response['Data'] != null && response['Data'] is List) {
      final data = response['Data'] as List<dynamic>;
      debugPrint('[GENERIC_LIST] ✅ Found data in Data: ${data.length}');
      return data;
    }

    // ✅ OLD FORMAT: DataSourceResult.Data (from GetFormListDataType)
    if (response['DataSourceResult'] != null) {
      final dsResult = response['DataSourceResult'];
      if (dsResult['Data'] != null && dsResult['Data'] is List) {
        final data = dsResult['Data'] as List<dynamic>;
        debugPrint('[GENERIC_LIST] ✅ Found data in DataSourceResult.Data: ${data.length}');
        return data;
      }
    }

    debugPrint('[GENERIC_LIST] ❌ No recognizable data format found');
    return [];
  }

  // Extract total count from response
  int _extractTotalFromResponse(Map<String, dynamic> response) {
    // NEW FORMAT: Direct "Total"
    if (response['Total'] != null) {
      return response['Total'] as int? ?? 0;
    }

    // OLD FORMAT: DataSourceResult.Total
    if (response['DataSourceResult'] != null && response['DataSourceResult']['Total'] != null) {
      return response['DataSourceResult']['Total'] as int? ?? 0;
    }

    // Fallback: Count data array
    return _extractDataFromResponse(response).length;
  }

  String _extractParams() {
    // URL'den params çıkar: /Dyn/AddExpense/List/List -> List
    final urlParts = widget.url.split('/');
    return urlParts.length >= 4 ? urlParts[3] : 'List';
  }

  void _navigateToAddForm() {
    // Yeni kayıt eklemek için form sayfasına git
    final addUrl = widget.url.replaceAll('/List', '/Detail').replaceAll('/list', '/detail');

    Navigator.pushNamed(
      context,
      '/dynamic-form',
      arguments: {
        'controller': widget.controller,
        'url': addUrl,
        'title': widget.title.replaceAll('Listesi', 'Ekle'),
        'isAdd': true,
      },
    ).then((result) {
      // Form'dan geri dönünce listeyi yenile
      if (result == true) {
        _loadListData(isRefresh: true);
      }
    });
  }

  void _navigateToEditForm(Map<String, dynamic> item) {
    final id = item['Id'] ?? item['id'] ?? item['ID'];
    if (id == null) return;

    final editUrl = widget.url.replaceAll('/List', '/Detail').replaceAll('/list', '/detail');

    Navigator.pushNamed(
      context,
      '/dynamic-form',
      arguments: {
        'controller': widget.controller,
        'url': editUrl,
        'title': widget.title.replaceAll('Listesi', 'Düzenle'),
        'id': id,
        'isAdd': false,
      },
    ).then((result) {
      // Form'dan geri dönünce listeyi yenile
      if (result == true) {
        _loadListData(isRefresh: true);
      }
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
          // Stats in AppBar
          if (_totalCount > 0 && !_isLoading)
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
                    '${_listData.length} / $_totalCount',
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
            onPressed: () => _loadListData(isRefresh: true),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddForm,
        backgroundColor: AppColors.primary,
        tooltip: widget.title.replaceAll('Listesi', 'Ekle'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody(AppSizes size) {
    if (_isLoading && _listData.isEmpty) {
      return _buildLoadingState(size);
    }

    if (_errorMessage != null && _listData.isEmpty) {
      return _buildErrorState(size);
    }

    if (_listData.isEmpty) {
      return _buildEmptyState(size);
    }

    return _buildListContent(size);
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
              'Liste Yüklenemedi',
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
              onPressed: () => _loadListData(isRefresh: true),
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
              Icons.inbox_outlined,
              size: 64,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: size.largeSpacing),
          Text(
            'Liste Boş',
            style: TextStyle(
              fontSize: size.mediumText,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Henüz kayıt bulunmuyor',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: size.largeSpacing),
          ElevatedButton.icon(
            onPressed: _navigateToAddForm,
            icon: const Icon(Icons.add),
            label: Text(widget.title.replaceAll('Listesi', 'Ekle')),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(AppSizes size) {
    return RefreshIndicator(
      onRefresh: () => _loadListData(isRefresh: true),
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(size.padding),
        itemCount: _listData.length,
        itemBuilder: (context, index) {
          final item = _listData[index];
          return _buildListItem(item, size);
        },
      ),
    );
  }

  Widget _buildListItem(Map<String, dynamic> item, AppSizes size) {
    final itemTitle = _getItemTitle(item);
    final itemId = item['Id'] ?? item['id'] ?? item['ID'] ?? '';
    final dateInfo = _getDateInfo(item);

    // 2x2 Grid için 4 ana bilgi
    final gridInfo = _getGridInfo(item);

    return Container(
      margin: EdgeInsets.only(bottom: size.mediumSpacing),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 🌈 Top colored border
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getControllerColor(),
                  _getControllerColor().withValues(alpha: 0.7),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),

          // Card content
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              onTap: () => _navigateToEditForm(item),
              child: Padding(
                padding: EdgeInsets.all(size.cardPadding),
                child: Column(
                  children: [
                    // 🎯 HEADER ROW
                    Row(
                      children: [
                        // Compact Icon
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _getControllerColor(),
                                _getControllerColor().withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getControllerIcon(),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: size.smallSpacing),

                        // Title
                        Expanded(
                          child: Text(
                            itemTitle,
                            style: TextStyle(
                              fontSize: size.textSize,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        // Arrow
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),

                    SizedBox(height: size.mediumSpacing),

                    // 📊 2x2 INFO GRID
                    Row(
                      children: [
                        // Left Column
                        Expanded(
                          child: Column(
                            children: [
                              // Top Left
                              _buildGridItem(
                                label: gridInfo[0]['label'],
                                value: gridInfo[0]['value'],
                                size: size,
                              ),
                              SizedBox(height: size.smallSpacing),
                              // Bottom Left
                              _buildGridItem(
                                label: gridInfo[2]['label'],
                                value: gridInfo[2]['value'],
                                size: size,
                              ),
                            ],
                          ),
                        ),

                        SizedBox(width: size.mediumSpacing),

                        // Right Column
                        Expanded(
                          child: Column(
                            children: [
                              // Top Right
                              _buildGridItem(
                                label: gridInfo[1]['label'],
                                value: gridInfo[1]['value'],
                                size: size,
                              ),
                              SizedBox(height: size.smallSpacing),
                              // Bottom Right
                              _buildGridItem(
                                label: gridInfo[3]['label'],
                                value: gridInfo[3]['value'],
                                size: size,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: size.mediumSpacing),

                    // 📅 BOTTOM ROW
                    Container(
                      padding: EdgeInsets.only(top: size.smallSpacing),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.divider.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Date Badge
                          if (dateInfo != null)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.info.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: AppColors.info,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    dateInfo,
                                    style: TextStyle(
                                      fontSize: size.smallText * 0.9,
                                      color: AppColors.info,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          const Spacer(),

                          // ID Badge
                          if (itemId.toString().isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'ID: $itemId',
                                style: TextStyle(
                                  fontSize: size.smallText * 0.9,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Grid item builder
  Widget _buildGridItem({
    required String? label,
    required String? value,
    required AppSizes size,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          style: TextStyle(
            fontSize: size.smallText * 0.9,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2),
        Text(
          value ?? '-',
          style: TextStyle(
            fontSize: size.smallText,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Helper method to get 2x2 grid info
  // Helper method to get 2x2 grid info - UPDATED FOR DOCUMENTS
  List<Map<String, String?>> _getGridInfo(Map<String, dynamic> item) {
    final List<Map<String, String?>> gridInfo = [
      {'label': null, 'value': null},
      {'label': null, 'value': null},
      {'label': null, 'value': null},
      {'label': null, 'value': null},
    ];

    // Document-specific field mappings
    if (widget.controller.toLowerCase().contains('document')) {
      // DOCUMENT SPECIFIC LAYOUT
      gridInfo[0] = {
        'label': 'Firma',
        'value': _formatFieldValue(item['Firma']),
      };

      gridInfo[1] = {
        'label': 'Seri No',
        'value': _formatFieldValue(item['Seri']),
      };

      gridInfo[2] = {
        'label': 'Son Geçerlilik',
        'value': _formatDocumentDate(item['ExpirationDate']),
      };

      gridInfo[3] = {
        'label': 'Gönderim',
        'value': item['Gonderi'] != null ? 'Gönderildi' : 'Beklemede',
      };

      return gridInfo;
    }

    // Generic field mappings (existing code)
    final fieldMappings = {
      // Top Left - Company/Firma
      0: [
        {'key': 'Firma', 'label': 'Firma'},
        {'key': 'CompanyName', 'label': 'Firma'},
        {'key': 'Company', 'label': 'Firma'},
      ],
      // Top Right - Person/User
      1: [
        {'key': 'Seri', 'label': 'Seri No'},
        {'key': 'ContactName', 'label': 'Kişi'},
        {'key': 'UserName', 'label': 'Kullanıcı'},
        {'key': 'AssignedUser', 'label': 'Atanan'},
        {'key': 'Kişi', 'label': 'Kişi'},
        {'key': 'AdiSoyadi', 'label': 'Ad Soyad'},
      ],
      // Bottom Left - Subject/Amount
      2: [
        {'key': 'ExpirationDate', 'label': 'Son Geçerlilik'},
        {'key': 'Subject', 'label': 'Konu'},
        {'key': 'Amount', 'label': 'Tutar'},
        {'key': 'Description', 'label': 'Açıklama'},
        {'key': 'Konu', 'label': 'Konu'},
        {'key': 'Açıklama', 'label': 'Açıklama'},
        {'key': 'Telefon', 'label': 'Telefon'},
      ],
      // Bottom Right - Status
      3: [
        {'key': 'Gonderi', 'label': 'Durum'},
        {'key': 'Status', 'label': 'Durum'},
        {'key': 'State', 'label': 'Durum'},
        {'key': 'ProcessStep', 'label': 'Adım'},
        {'key': 'IsActive', 'label': 'Durum'},
        {'key': 'Mail', 'label': 'E-posta'},
        {'key': 'Unvani', 'label': 'Ünvan'},
        {'key': 'Departman', 'label': 'Departman'},
      ],
    };

    // Fill grid with available data
    fieldMappings.forEach((index, mappings) {
      for (final mapping in mappings) {
        if (item.containsKey(mapping['key']) && item[mapping['key']] != null) {
          final value = item[mapping['key']].toString();
          if (value.isNotEmpty && value != 'null') {
            gridInfo[index] = {
              'label': mapping['label']!,
              'value': _formatFieldValue(item[mapping['key']]),
            };
            break;
          }
        }
      }
    });

    // Fill empty slots with other available data
    final usedKeys = <String>{};
    for (final info in gridInfo) {
      if (info['label'] != null) {
        for (final mappingList in fieldMappings.values) {
          for (final mapping in mappingList) {
            if (mapping['label'] == info['label']) {
              usedKeys.add(mapping['key']!);
              break;
            }
          }
        }
      }
    }

    final remainingKeys = item.keys
        .where((key) =>
            !usedKeys.contains(key) &&
            !['Id', 'id', 'ID', 'CreatedDate', 'UpdatedDate'].contains(key) &&
            item[key] != null &&
            item[key].toString().isNotEmpty)
        .take(4 - gridInfo.where((info) => info['value'] != null).length);

    int emptyIndex = 0;
    for (final key in remainingKeys) {
      while (emptyIndex < 4 && gridInfo[emptyIndex]['value'] != null) {
        emptyIndex++;
      }
      if (emptyIndex < 4) {
        gridInfo[emptyIndex] = {
          'label': _formatFieldName(key),
          'value': _formatFieldValue(item[key]),
        };
      }
    }

    return gridInfo;
  }

  /// Format document date specifically
  String _formatDocumentDate(dynamic dateValue) {
    if (dateValue == null) return '-';

    try {
      final dateStr = dateValue.toString();
      if (dateStr.contains(' ')) {
        // "20.06.2025 00:00:00" format
        return dateStr.split(' ')[0]; // Just take date part
      }
      return dateStr;
    } catch (e) {
      return dateValue.toString();
    }
  }

  String _getItemTitle(Map<String, dynamic> item) {
    // Document-specific title logic
    if (widget.controller.toLowerCase().contains('document')) {
      final title = item['Title'] as String?;
      if (title != null && title.isNotEmpty) {
        return title;
      }
    }

    // Generic title fields
    const titleFields = ['Title', 'Name', 'Subject', 'Description', 'Adi', 'Baslik', 'Konu', 'AdiSoyadi'];

    for (final field in titleFields) {
      if (item.containsKey(field) && item[field] != null) {
        final value = item[field].toString();
        if (value.isNotEmpty && value != 'null') {
          return value;
        }
      }
    }

    // ID göster
    final id = item['Id'] ?? item['id'] ?? item['ID'] ?? 'Unknown';
    return '${widget.controller} #$id';
  }

  // Helper methods for better UI
  Color _getControllerColor() {
    switch (widget.controller.toLowerCase()) {
      case 'addexpense':
        return Colors.red;
      case 'vehiclerentadd':
        return Colors.teal;
      case 'companyadd':
        return Colors.blue;
      case 'aktiviteadd':
      case 'aktivitebranchadd':
        return Colors.orange;
      case 'contactadd':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  IconData _getControllerIcon() {
    switch (widget.controller.toLowerCase()) {
      case 'addexpense':
        return Icons.receipt_long;
      case 'vehiclerentadd':
        return Icons.directions_car;
      case 'companyadd':
        return Icons.business;
      case 'aktiviteadd':
      case 'aktivitebranchadd':
        return Icons.assignment;
      case 'contactadd':
        return Icons.person;
      default:
        return Icons.folder;
    }
  }

  String _formatFieldName(String key) {
    // Field isimlerini Türkçeleştir
    const fieldTranslations = {
      'Name': 'Ad',
      'Title': 'Başlık',
      'Subject': 'Konu',
      'Description': 'Açıklama',
      'Amount': 'Tutar',
      'Date': 'Tarih',
      'Status': 'Durum',
      'Company': 'Firma',
      'Contact': 'Kişi',
      'Phone': 'Telefon',
      'Email': 'Email',
      'Address': 'Adres',
      'AdiSoyadi': 'Ad Soyad',
      'Telefon': 'Telefon',
      'Mail': 'E-posta',
      'Unvani': 'Ünvan',
      'Departman': 'Departman',
    };

    return fieldTranslations[key] ?? key;
  }

  String _formatFieldValue(dynamic value) {
    if (value == null) return '-';
    if (value is String && value.isEmpty) return '-';

    // Tarih formatı kontrolü - SADECE TARİH GÖSTER
    if (value is String && (value.contains('T') || value.contains(' '))) {
      try {
        DateTime date;
        if (value.contains('T')) {
          // ISO format: 2025-08-29T10:40:00
          date = DateTime.parse(value);
        } else if (value.contains(' ')) {
          // Turkish format: 29.08.2025 10:40:00
          final parts = value.split(' ');
          if (parts.isNotEmpty) {
            final datePart = parts[0]; // Sadece tarih kısmını al
            final dateParts = datePart.split('.');
            if (dateParts.length == 3) {
              date = DateTime(
                int.parse(dateParts[2]), // yıl
                int.parse(dateParts[1]), // ay
                int.parse(dateParts[0]), // gün
              );
            } else {
              return value.toString();
            }
          } else {
            return value.toString();
          }
        } else {
          return value.toString();
        }

        // Sadece tarih döndür - saat yok
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      } catch (e) {
        // Parse edilemezse orijinal değeri döndür
        return value.toString();
      }
    }

    return value.toString();
  }

  String? _getDateInfo(Map<String, dynamic> item) {
    const dateFields = ['CreatedDate', 'UpdatedDate', 'Date', 'StartDate', 'EndDate'];

    for (final field in dateFields) {
      if (item.containsKey(field) && item[field] != null) {
        return _formatFieldValue(item[field]);
      }
    }

    return null;
  }

  String getItemTitle(Map<String, dynamic> item) {
    // Başlık için uygun field'ı bul
    const titleFields = ['Name', 'Title', 'Subject', 'Description', 'Adi', 'Baslik', 'Konu', 'AdiSoyadi'];

    for (final field in titleFields) {
      if (item.containsKey(field) && item[field] != null) {
        final value = item[field].toString();
        if (value.isNotEmpty && value != 'null') {
          return value;
        }
      }
    }

    // ID göster
    final id = item['Id'] ?? item['id'] ?? item['ID'] ?? 'Unknown';
    return '${widget.controller} #$id';
  }
}
