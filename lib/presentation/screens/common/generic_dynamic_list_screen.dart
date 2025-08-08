// lib/presentation/screens/common/generic_dynamic_list_screen.dart
import 'dart:ui';

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
  int currentPage = 1;
  final int pageSize = 10000;
  bool hasMoreData = true;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadListData();
    //_scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadListData({bool isRefresh = false}) async {
    setState(() {
      currentPage = 1;
      _listData.clear();
      hasMoreData = false;
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[GENERIC_LIST] 🔍 Starting data load...');
      debugPrint('[GENERIC_LIST] 📋 Controller: ${widget.controller}');
      debugPrint('[GENERIC_LIST] 🔗 URL: ${widget.url}');

      // İlk 3 sayfayı test et ve veri karşılaştır
      List<dynamic> allData = [];
      Set<String> uniqueIds = {};

      for (int testPage = 1; testPage <= 3; testPage++) {
        debugPrint('[GENERIC_LIST] 🧪 TEST Page $testPage loading...');

        final response = await _apiService.getFormListData(
          controller: widget.controller,
          params: _extractParams(),
          formPath: widget.url,
          page: testPage,
          pageSize: 100,
        );

        final pageData = _extractDataFromResponse(response);
        debugPrint('[GENERIC_LIST] 📊 TEST Page $testPage: ${pageData.length} items');

        // İlk item'ın ID'sini logla
        if (pageData.isNotEmpty) {
          final firstItem = pageData[0];
          final itemId = firstItem['Id'] ?? firstItem['id'] ?? firstItem['ID'] ?? 'unknown';
          debugPrint('[GENERIC_LIST] 🔍 TEST Page $testPage first item ID: $itemId');

          // Unique ID kontrolü
          for (final item in pageData) {
            final id = item['Id'] ?? item['id'] ?? item['ID'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
            uniqueIds.add(id.toString());
          }

          allData.addAll(pageData);
        } else {
          debugPrint('[GENERIC_LIST] ❌ TEST Page $testPage: No data received');
          break;
        }
      }

      debugPrint('[GENERIC_LIST] 📊 TEST RESULT:');
      debugPrint('[GENERIC_LIST] 📊 Total items loaded: ${allData.length}');
      debugPrint('[GENERIC_LIST] 📊 Unique IDs found: ${uniqueIds.length}');

      if (allData.length > uniqueIds.length) {
        debugPrint('[GENERIC_LIST] ❌ DUPLICATE DATA DETECTED!');
        debugPrint('[GENERIC_LIST] ❌ Server returning same data for different pages');
        debugPrint('[GENERIC_LIST] 🔧 Pagination not working properly');
      } else {
        debugPrint('[GENERIC_LIST] ✅ No duplicates found, pagination working');
      }

      // Sadece unique verileri kullan
      final uniqueData = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (final item in allData) {
        final id = item['Id'] ?? item['id'] ?? item['ID'] ?? 'unknown_${DateTime.now().millisecondsSinceEpoch}';
        if (!seenIds.contains(id.toString())) {
          seenIds.add(id.toString());
          uniqueData.add(item as Map<String, dynamic>);
        }
      }

      setState(() {
        _listData = uniqueData;
        hasMoreData = false;
        _isLoading = false;
      });

      debugPrint('[GENERIC_LIST] ✅ FINAL RESULT: ${_listData.length} unique items loaded');
    } catch (e, stackTrace) {
      debugPrint('[GENERIC_LIST] ❌ Error: $e');

      setState(() {
        _errorMessage = 'Liste yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }


// Gelişmiş response parsing
  List<dynamic> _extractDataFromResponse(Map<String, dynamic> response) {
    debugPrint('[GENERIC_LIST] 🔍 Parsing response...');
    debugPrint('[GENERIC_LIST] 📦 Response structure: ${response.keys.toList()}');

    List<dynamic> data = [];

    // Farklı response formatlarını dene
    if (response['DataSourceResult'] != null) {
      final dsResult = response['DataSourceResult'];
      debugPrint('[GENERIC_LIST] 📦 DataSourceResult keys: ${dsResult.keys.toList()}');

      if (dsResult['Data'] != null && dsResult['Data'] is List) {
        data = dsResult['Data'] as List<dynamic>;
        debugPrint('[GENERIC_LIST] ✅ Found data in DataSourceResult.Data: ${data.length}');
      }

      // Total count varsa göster
      if (dsResult['Total'] != null) {
        debugPrint('[GENERIC_LIST] 📊 Server reports total: ${dsResult['Total']} items');
      }
    } else if (response['Data'] != null && response['Data'] is List) {
      data = response['Data'] as List<dynamic>;
      debugPrint('[GENERIC_LIST] ✅ Found data in Data: ${data.length}');
    } else if (response['data'] != null && response['data'] is List) {
      data = response['data'] as List<dynamic>;
      debugPrint('[GENERIC_LIST] ✅ Found data in data: ${data.length}');
    } else if (response['result'] != null && response['result'] is List) {
      data = response['result'] as List<dynamic>;
      debugPrint('[GENERIC_LIST] ✅ Found data in result: ${data.length}');
    } else if (response['items'] != null && response['items'] is List) {
      data = response['items'] as List<dynamic>;
      debugPrint('[GENERIC_LIST] ✅ Found data in items: ${data.length}');
    } else {
      debugPrint('[GENERIC_LIST] ❌ No recognizable data format found');
      debugPrint('[GENERIC_LIST] 🔍 Full response: $response');
    }

    return data;
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
              color: Colors.blue.withOpacity(0.1),
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
          color: AppColors.border.withOpacity(0.3),
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
                  _getControllerColor().withOpacity(0.7),
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
                                _getControllerColor().withOpacity(0.7),
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
                            color: AppColors.divider.withOpacity(0.5),
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
                                color: AppColors.info.withOpacity(0.1),
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
                                color: AppColors.primary.withOpacity(0.1),
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
  List<Map<String, String?>> _getGridInfo(Map<String, dynamic> item) {
    final List<Map<String, String?>> gridInfo = [
      {'label': null, 'value': null},
      {'label': null, 'value': null},
      {'label': null, 'value': null},
      {'label': null, 'value': null},
    ];

    // Priority order for fields
    final fieldMappings = {
      // Top Left - Company/Firma
      0: [
        {'key': 'CompanyName', 'label': 'Firma'},
        {'key': 'Company', 'label': 'Firma'},
        {'key': 'Firma', 'label': 'Firma'},
      ],
      // Top Right - Person/User
      1: [
        {'key': 'ContactName', 'label': 'Kişi'},
        {'key': 'UserName', 'label': 'Kullanıcı'},
        {'key': 'AssignedUser', 'label': 'Atanan'},
        {'key': 'Kişi', 'label': 'Kişi'},
      ],
      // Bottom Left - Subject/Amount
      2: [
        {'key': 'Subject', 'label': 'Konu'},
        {'key': 'Amount', 'label': 'Tutar'},
        {'key': 'Description', 'label': 'Açıklama'},
        {'key': 'Konu', 'label': 'Konu'},
        {'key': 'Açıklama', 'label': 'Açıklama'},
      ],
      // Bottom Right - Status
      3: [
        {'key': 'Status', 'label': 'Durum'},
        {'key': 'State', 'label': 'Durum'},
        {'key': 'ProcessStep', 'label': 'Adım'},
        {'key': 'IsActive', 'label': 'Durum'},
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
    };

    return fieldTranslations[key] ?? key;
  }

  String _formatFieldValue(dynamic value) {
    if (value == null) return '-';
    if (value is String && value.isEmpty) return '-';

    // Tarih formatı kontrolü
    if (value is String && value.contains('T')) {
      try {
        final date = DateTime.parse(value);
        return '${date.day}.${date.month}.${date.year}';
      } catch (e) {
        // Ignore parsing error
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

  String _getItemTitle(Map<String, dynamic> item) {
    // Başlık için uygun field'ı bul
    const titleFields = ['Name', 'Title', 'Subject', 'Description', 'Adi', 'Baslik', 'Konu'];

    for (final field in titleFields) {
      if (item.containsKey(field) && item[field] != null) {
        return item[field].toString();
      }
    }

    // ID göster
    final id = item['Id'] ?? item['id'] ?? item['ID'] ?? 'Unknown';
    return '${widget.controller} #$id';
  }
}
