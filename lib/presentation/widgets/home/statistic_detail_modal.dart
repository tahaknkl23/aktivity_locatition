// lib/presentation/widgets/home/statistic_detail_modal.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/services/api/dashboard_api_service.dart';

class StatisticDetailModal extends StatefulWidget {
  final String title;
  final String sqlId;
  final int widgetId;
  final Color color;
  final IconData icon;

  const StatisticDetailModal({
    super.key,
    required this.title,
    required this.sqlId,
    required this.widgetId,
    required this.color,
    required this.icon,
  });

  @override
  State<StatisticDetailModal> createState() => _StatisticDetailModalState();
}

class _StatisticDetailModalState extends State<StatisticDetailModal> {
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

      debugPrint('[DETAIL_MODAL] Loading detail data for SQL ID: ${widget.sqlId}');

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

        debugPrint('[DETAIL_MODAL] ✅ Detail data loaded: ${_detailData.length} items');
      }
    } catch (e) {
      debugPrint('[DETAIL_MODAL] ❌ Error loading detail data: $e');

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
    final size = AppSizes.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: size.width * 0.9,
        height: size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(size),

            // Content
            Expanded(
              child: _buildContent(size),
            ),

            // Footer
            _buildFooter(size),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.color,
            widget.color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: size.mediumSpacing),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: size.mediumText,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Detay Bilgileri',
                  style: TextStyle(
                    fontSize: size.smallText,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AppSizes size) {
    if (_isLoading) {
      return _buildLoadingState(size);
    } else if (_errorMessage != null) {
      return _buildErrorState(size);
    } else if (_detailData.isEmpty) {
      return _buildEmptyState(size);
    } else {
      return _buildDataList(size);
    }
  }

  Widget _buildLoadingState(AppSizes size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(widget.color),
            ),
          ),
          SizedBox(height: size.largeSpacing),
          Text(
            'Detay veriler yükleniyor...',
            style: TextStyle(
              fontSize: size.textSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.cardPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
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
              'Detay veriler yüklenemedi',
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
                fontSize: size.smallText,
                color: AppColors.textSecondary,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: size.largeSpacing),
            ElevatedButton.icon(
              onPressed: _loadDetailData,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: size.largeSpacing),
          Text(
            'Detay veri bulunamadı',
            style: TextStyle(
              fontSize: size.mediumText,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            'Bu kategori için henüz detay bilgi mevcut değil',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataList(AppSizes size) {
    return Column(
      children: [
        // Summary info
        Container(
          padding: EdgeInsets.all(size.cardPadding),
          color: Colors.grey.shade50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Toplam ${_detailData.length} kayıt',
                style: TextStyle(
                  fontSize: size.textSize,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_detailData.length}',
                  style: TextStyle(
                    fontSize: size.smallText,
                    fontWeight: FontWeight.bold,
                    color: widget.color,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Data list
        Expanded(
          child: ListView.builder(
            itemCount: _detailData.length,
            itemBuilder: (context, index) {
              final item = _detailData[index];
              return _buildDetailItem(item, index, size);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(Map<String, dynamic> item, int index, AppSizes size) {
    // Ana field'ları belirle (her API'ye göre farklı olabilir)
    final mainField = _getMainField(item);
    final secondaryField = _getSecondaryField(item);
    final extraFields = _getExtraFields(item);

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: size.cardPadding,
        vertical: size.smallSpacing / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(size.cardPadding * 0.8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: size.smallText,
                fontWeight: FontWeight.bold,
                color: widget.color,
              ),
            ),
          ),
        ),
        title: Text(
          mainField,
          style: TextStyle(
            fontSize: size.textSize,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (secondaryField.isNotEmpty) ...[
              SizedBox(height: 4),
              Text(
                secondaryField,
                style: TextStyle(
                  fontSize: size.smallText,
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (extraFields.isNotEmpty) ...[
              SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: extraFields.take(3).map((field) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      field,
                      style: TextStyle(
                        fontSize: size.smallText * 0.85,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
          size: 20,
        ),
        onTap: () {
          _showItemDetail(context, item, index);
        },
      ),
    );
  }

  // Ana field'ı belirle (plaka, isim, vs.)
  String _getMainField(Map<String, dynamic> item) {
    if (item.containsKey('Plate') && item['Plate'] != null) {
      return item['Plate'].toString();
    }
    if (item.containsKey('Name') && item['Name'] != null) {
      return item['Name'].toString();
    }
    if (item.containsKey('Firma') && item['Firma'] != null) {
      return item['Firma'].toString();
    }
    if (item.containsKey('Id')) {
      return 'ID: ${item['Id']}';
    }
    return 'Kayıt ${item.hashCode}';
  }

  // İkincil field (marka, model, vs.)
  String _getSecondaryField(Map<String, dynamic> item) {
    final parts = <String>[];

    if (item.containsKey('Marka') && item['Marka'] != null) {
      parts.add(item['Marka'].toString());
    }
    if (item.containsKey('Model') && item['Model'] != null) {
      parts.add(item['Model'].toString());
    }
    if (item.containsKey('Type') && item['Type'] != null) {
      parts.add(item['Type'].toString());
    }

    return parts.join(' - ');
  }

  // Extra field'lar (km, tarih, vs.)
  List<String> _getExtraFields(Map<String, dynamic> item) {
    final fields = <String>[];

    if (item.containsKey('CurrentKm') && item['CurrentKm'] != null) {
      fields.add('${item['CurrentKm']} km');
    }
    if (item.containsKey('LastServiceDate') && item['LastServiceDate'] != null) {
      fields.add('Servis: ${item['LastServiceDate']}');
    }
    if (item.containsKey('Status') && item['Status'] != null) {
      fields.add('Durum: ${item['Status']}');
    }

    return fields;
  }

  void _showItemDetail(BuildContext context, Map<String, dynamic> item, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detay #${index + 1}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: item.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${entry.key}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        entry.value?.toString() ?? '-',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppSizes size) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SQL ID: ${widget.sqlId}',
            style: TextStyle(
              fontSize: size.smallText * 0.9,
              color: AppColors.textTertiary,
            ),
          ),
          TextButton.icon(
            onPressed: _loadDetailData,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Yenile'),
            style: TextButton.styleFrom(
              foregroundColor: widget.color,
            ),
          ),
        ],
      ),
    );
  }
}
