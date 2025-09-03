// lib/presentation/widgets/home/statistic_detail_bottom_sheet.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/api/dashboard_api_service.dart';

class StatisticDetailBottomSheet extends StatefulWidget {
  final String title;
  final String sqlId;
  final int widgetId;
  final Color color;
  final IconData icon;

  const StatisticDetailBottomSheet({
    super.key,
    required this.title,
    required this.sqlId,
    required this.widgetId,
    required this.color,
    required this.icon,
  });

  @override
  State<StatisticDetailBottomSheet> createState() => _StatisticDetailBottomSheetState();
}

class _StatisticDetailBottomSheetState extends State<StatisticDetailBottomSheet> {
  final DashboardApiService _apiService = DashboardApiService();
  List<Map<String, dynamic>> _detailData = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetailData();
  }

  Future<void> _loadDetailData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      debugPrint('[DETAIL_BOTTOM_SHEET] Loading detail data for SQL ID: ${widget.sqlId}');

      final detailData = await _apiService.getDetailGridData(
        sqlId: widget.sqlId,
        widgetId: widget.widgetId,
        index: 0,
      );

      if (mounted) {
        setState(() {
          _detailData = detailData;
          _isLoading = false;
        });

        debugPrint('[DETAIL_BOTTOM_SHEET] ✅ Detail data loaded: ${_detailData.length} items');
      }
    } catch (e) {
      debugPrint('[DETAIL_BOTTOM_SHEET] ❌ Error loading detail data: $e');

      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildContent(scrollController),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color,
            widget.color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Title section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Detay Bilgileri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading && _detailData.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_detailData.length} kayıt',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_isLoading) {
      return _buildLoadingState();
    } else if (_errorMessage != null) {
      return _buildErrorState();
    } else if (_detailData.isEmpty) {
      return _buildEmptyState();
    } else {
      return _buildDataTable(scrollController);
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detay veriler yükleniyor...',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 32,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Detay veriler yüklenemedi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tekrar deneyin',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadDetailData,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 32,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Detay veri bulunamadı',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bu kategori için henüz detay bilgi mevcut değil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(ScrollController scrollController) {
    // İlk item'dan header'ları belirle
    final headers = _getTableHeaders();

    return Column(
      children: [
        // Table Header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: headers.map((header) {
              return Expanded(
                child: Text(
                  header,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
        ),

        // Data Rows
        Expanded(
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _detailData.length,
            itemBuilder: (context, index) {
              final item = _detailData[index];
              return _buildDataRow(item, index, headers);
            },
          ),
        ),
      ],
    );
  }

  List<String> _getTableHeaders() {
    if (_detailData.isEmpty) return [];

    final firstItem = _detailData.first;
    final allKeys = firstItem.keys.toList();

    debugPrint('[BOTTOM_SHEET] 🔍 All available keys: $allKeys');

    // Sadece null olmayan field'ları al ve ilk 4'ünü kullan
    final nonNullKeys = <String>[];

    for (final key in allKeys) {
      final value = firstItem[key];
      if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
        nonNullKeys.add(key);
        if (nonNullKeys.length >= 4) break; // Max 4 kolon
      }
    }

    // Eğer hiç non-null field yoksa, tüm field'ları al
    if (nonNullKeys.isEmpty) {
      nonNullKeys.addAll(allKeys.take(4));
    }

    debugPrint('[BOTTOM_SHEET] 🎯 Selected keys for headers: $nonNullKeys');

    // Field isimlerini user-friendly yap
    final headers = nonNullKeys.map((key) => _formatDynamicHeaderName(key)).toList();

    debugPrint('[BOTTOM_SHEET] 🎯 Final headers: $headers');
    return headers;
  }

  String _formatDynamicHeaderName(String fieldName) {
    // Dinamik olarak field isimlerini Türkçeleştir
    switch (fieldName.toLowerCase()) {
      case 'id':
        return 'ID';
      case 'plate':
        return 'Plaka';
      case 'currentkm':
        return 'KM';
      case 'marka':
        return 'Marka';
      case 'model':
        return 'Model';
      case 'lastservicedate':
        return 'Son Servis';
      case 'tarih':
      case 'date':
        return 'Tarih';
      case 'firma':
      case 'company':
      case 'name':
        return 'Firma';
      case 'makine':
      case 'machine':
        return 'Makine';
      case 'fiyat':
      case 'price':
      case 'amount':
        return 'Tutar';
      case 'kur':
        return 'Kur';
      default:
        // CamelCase'i boşluklarla ayır ve Türkçeleştir
        String formatted = fieldName;

        // CamelCase'i böl: "LastServiceDate" -> "Last Service Date"
        formatted = formatted.replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        );

        // İlk harfi büyük yap
        if (formatted.isNotEmpty) {
          formatted = formatted[0].toUpperCase() + formatted.substring(1);
        }

        return formatted;
    }
  }

  Widget _buildDataRow(Map<String, dynamic> item, int index, List<String> headers) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showItemDetail(context, item, index),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: headers.map((header) {
            final fieldName = _getFieldNameFromHeader(header);
            final value = _formatFieldValue(item[fieldName]);

            return Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 11,
                  color: _getFieldColor(fieldName, item[fieldName]),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  String _getFieldNameFromHeader(String header) {
    // Dinamik olarak header'dan field name'e geri çevir
    if (_detailData.isNotEmpty) {
      final firstItem = _detailData.first;

      // Header'ı field'a map et
      for (final key in firstItem.keys) {
        if (_formatDynamicHeaderName(key) == header) {
          return key;
        }
      }
    }

    // Fallback: header'ın kendisini döndür
    return header;
  }

  String _formatFieldValue(dynamic value) {
    if (value == null) return '-';

    final stringValue = value.toString();
    if (stringValue.isEmpty || stringValue == 'null') return '-';

    // Sayısal değerler için formatting
    if (value is num) {
      if (stringValue.contains('.') && value > 1000) {
        // Büyük ondalıklı sayılar (fiyat gibi)
        return value.toStringAsFixed(0);
      } else if (value > 1000) {
        // Büyük tam sayılar (KM gibi)
        return value.toStringAsFixed(0);
      }
      return value.toString();
    }

    // Çok uzun text'leri kısalt
    if (stringValue.length > 15) {
      return '${stringValue.substring(0, 12)}...';
    }

    return stringValue;
  }

  Color _getFieldColor(String fieldName, dynamic value) {
    // Dinamik renklendirme
    final lowerFieldName = fieldName.toLowerCase();

    if (lowerFieldName.contains('fiyat') || lowerFieldName.contains('price') || lowerFieldName.contains('amount')) {
      return Colors.green.shade700;
    } else if (lowerFieldName.contains('id')) {
      return widget.color;
    } else if (lowerFieldName.contains('km') && value != null && value is num && value > 50000) {
      return Colors.orange.shade700; // Yüksek KM için turuncu
    } else if (lowerFieldName.contains('plate') || lowerFieldName.contains('plaka')) {
      return Colors.blue.shade700;
    }

    return AppColors.textPrimary;
  }

  void _showItemDetail(BuildContext context, Map<String, dynamic> item, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Detay #${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // All fields
            ...item.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value?.toString() ?? '-',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Kapat'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Function to show the bottom sheet
void showStatisticDetailBottomSheet({
  required BuildContext context,
  required String title,
  required String sqlId,
  required int widgetId,
  required Color color,
  required IconData icon,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatisticDetailBottomSheet(
      title: title,
      sqlId: sqlId,
      widgetId: widgetId,
      color: color,
      icon: icon,
    ),
  );
}
