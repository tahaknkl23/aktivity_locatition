// lib/presentation/widgets/home/simple_data_display.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/dashboard/dashboard_models.dart';

class SimpleDataDisplay extends StatelessWidget {
  final ChartWidget chart;

  const SimpleDataDisplay({
    super.key,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      margin: EdgeInsets.symmetric(vertical: size.smallSpacing),
      padding: EdgeInsets.all(size.cardPadding * 0.9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(size),
          const SizedBox(height: 12),
          _buildDataList(context, size), // context'i parametre olarak geç
        ],
      ),
    );
  }

  Widget _buildHeader(AppSizes size) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.table_chart,
            color: Color(0xFF667eea),
            size: 16,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _getCleanTitle(chart.title),
            style: TextStyle(
              fontSize: size.smallText,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF667eea).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${chart.data.length} ay',
            style: TextStyle(
              fontSize: size.smallText * 0.8,
              color: const Color(0xFF667eea),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataList(BuildContext context, AppSizes size) {
    if (!chart.hasData) {
      return _buildNoDataState(size);
    }

    return Column(
      children: [
        // Subtitle
        Text(
          'Hedef vs Gerçekleşen',
          style: TextStyle(
            fontSize: size.smallText * 0.9,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Ay',
                  style: TextStyle(
                    fontSize: size.smallText * 0.9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Hedef',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.smallText * 0.9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFf07b69),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Gerçek',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.smallText * 0.9,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6fc7ef),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Durum',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.smallText * 0.9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),

        // Data Rows
        ...chart.data.take(6).map((item) => _buildDataRow(item, size)),

        // Show more button if there are more than 6 items
        if (chart.data.length > 6) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () => _showAllData(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF667eea).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.expand_more,
                    color: Color(0xFF667eea),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tümünü Göster (${chart.data.length - 6} daha)',
                    style: TextStyle(
                      fontSize: size.smallText * 0.9,
                      color: const Color(0xFF667eea),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDataRow(ChartDataPair item, AppSizes size) {
    return _buildDataRowWithSize(item, size);
  }

  Widget _buildDataRowWithSize(ChartDataPair item, AppSizes size) {
    final isSuccess = item.actualValue >= item.targetValue;
    final percentage = item.targetValue > 0 ? (item.actualValue / item.targetValue) * 100 : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(
        children: [
          // Month name
          Expanded(
            flex: 2,
            child: Text(
              _shortenMonthName(item.category),
              style: TextStyle(
                fontSize: size.smallText,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Target value
          Expanded(
            child: Text(
              item.target.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.smallText,
                color: const Color(0xFFf07b69),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Actual value
          Expanded(
            child: Text(
              item.actual.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: size.smallText,
                color: const Color(0xFF6fc7ef),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Status
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  size: 12,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: size.smallText * 0.8,
                    color: isSuccess ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoDataState(AppSizes size) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_chart_outlined,
              size: 24,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 4),
            Text(
              'Veri Bulunamadı',
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAllData(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8, // 0.7 -> 0.8 daha büyük başlasın
        maxChildSize: 0.95, // 0.9 -> 0.95 daha büyük olabilsin
        minChildSize: 0.6, // 0.5 -> 0.6 daha büyük minimum
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // Üst padding azaltıldı: 16 -> 8
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8), // 16 -> 8 spacing azaltıldı

              // Title
              Text(
                _getCleanTitle(chart.title),
                style: const TextStyle(
                  fontSize: 16, // 18 -> 16 daha küçük başlık
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8), // 16 -> 8 spacing azaltıldı

              // Header row - modal içinde de header ekleyelim
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text(
                        'Ay',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Hedef',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFf07b69),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Gerçek',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6fc7ef),
                        ),
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Durum',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // All data
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: chart.data.length,
                  itemBuilder: (context, index) {
                    final item = chart.data[index];
                    return _buildDataRowWithSize(item, AppSizes.of(context));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCleanTitle(String title) {
    if (title.toLowerCase().contains('dummy')) {
      return 'Hedef - Gerçekleşen Ziyaret';
    }
    return title.replaceAll(RegExp(r'dummy\s*', caseSensitive: false), '').trim();
  }

  String _shortenMonthName(String monthName) {
    final monthMap = {
      'Ocak': 'Oca',
      'Şubat': 'Şub',
      'Mart': 'Mar',
      'Nisan': 'Nis',
      'Mayıs': 'May',
      'Haziran': 'Haz',
      'Temmuz': 'Tem',
      'Ağustos': 'Ağu',
      'Eylül': 'Eyl',
      'Ekim': 'Eki',
      'Kasım': 'Kas',
      'Aralık': 'Ara',
    };

    return monthMap[monthName] ?? (monthName.length > 3 ? monthName.substring(0, 3) : monthName);
  }
}
