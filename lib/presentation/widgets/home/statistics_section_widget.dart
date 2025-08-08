// lib/presentation/widgets/home/statistics_section_widget.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/dashboard/dashboard_models.dart';
import '../../providers/dashboard_provider.dart';
import 'statistic_detail_modal.dart';

class StatisticsSectionWidget extends StatelessWidget {
  const StatisticsSectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, provider),
            const SizedBox(height: 16),
            _buildContent(context, provider),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, DashboardProvider provider) {
    final size = AppSizes.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'İstatistikler',
          style: TextStyle(
            fontSize: size.mediumText * 1.1,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        if (provider.hasData)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${provider.statistics!.cards.length} kart',
              style: TextStyle(
                fontSize: size.smallText * 0.9,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, DashboardProvider provider) {
    if (provider.isLoading && !provider.hasData) {
      return const _LoadingState();
    } else if (provider.errorMessage != null && !provider.hasData) {
      return _ErrorState(error: provider.errorMessage!);
    } else if (provider.isEmpty) {
      return const _EmptyState();
    } else if (provider.hasData) {
      return _StatisticsGrid(cards: provider.statistics!.cards);
    } else {
      return const _LoadingState();
    }
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      height: 180,
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            ),
            SizedBox(height: size.mediumSpacing),
            Text(
              'İstatistikler yükleniyor...',
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      height: 180,
      padding: EdgeInsets.all(size.cardPadding),
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
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 32,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              'Veriler yüklenemedi',
              style: TextStyle(
                fontSize: size.textSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.tinySpacing),
            Text(
              'Tekrar deneyin',
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            ElevatedButton.icon(
              onPressed: () => context.read<DashboardProvider>().loadDashboardData(forceRefresh: true),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Yenile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Container(
      height: 180,
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
      child: Center(
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
                Icons.analytics_outlined,
                size: 32,
                color: AppColors.textTertiary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              'Henüz veri yok',
              style: TextStyle(
                fontSize: size.textSize,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatisticsGrid extends StatelessWidget {
  final List<StatisticCard> cards;

  const _StatisticsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: size.mediumSpacing,
        mainAxisSpacing: size.mediumSpacing,
        childAspectRatio: 1.15,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return _StatCard(card: card, index: index);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final StatisticCard card;
  final int index;

  const _StatCard({required this.card, required this.index});

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final color = _getColorForIndex(index);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.cardBorderRadius * 1.3),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showDetailModal(context, color),
          borderRadius: BorderRadius.circular(size.cardBorderRadius * 1.3),
          child: Padding(
            padding: EdgeInsets.all(size.cardPadding * 1.1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        card.icon,
                        color: Colors.white,
                        size: size.mediumIcon * 0.8,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatNumber(card.value),
                          style: TextStyle(
                            fontSize: size.mediumText * 1.2,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (card.unit.isNotEmpty) ...[
                          Text(
                            card.unit,
                            style: TextStyle(
                              fontSize: size.smallText * 0.85,
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                SizedBox(height: size.smallSpacing),
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: size.textSize * 0.9,
                    color: Colors.white.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailModal(BuildContext context, Color color) {
    // Widget'ın SQL ID'sini ve detay bilgilerini determine et
    String sqlId = '9889'; // Default - gerçekte card'dan gelecek
    int widgetId = 13907; // Default - gerçekte card'dan gelecek

    // Card title'a göre SQL ID'yi belirle (API response'unuza göre mapping)
    if (card.title.toLowerCase().contains('araç') || card.title.toLowerCase().contains('servis')) {
      sqlId = '9889'; // Araç servisi için
      widgetId = 13907;
    } else if (card.title.toLowerCase().contains('müşteri')) {
      sqlId = '9656'; // Müşteri için
      widgetId = 13908;
    } else if (card.title.toLowerCase().contains('adres')) {
      sqlId = '9892'; // Adres için
      widgetId = 13909;
    } else if (card.title.toLowerCase().contains('ziyaret')) {
      sqlId = '1842'; // Ziyaret için
      widgetId = 13910;
    } else if (card.title.toLowerCase().contains('sipariş')) {
      sqlId = '285'; // Sipariş için
      widgetId = 13911;
    }

    showDialog(
      context: context,
      builder: (context) => StatisticDetailModal(
        title: card.title,
        sqlId: sqlId,
        widgetId: widgetId,
        color: color,
        icon: card.icon,
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      const Color(0xFF667eea), // Blue
      const Color(0xFF5cb85c), // Green
      const Color(0xFFf0ad4e), // Orange
      const Color(0xFFd9534f), // Red
      const Color(0xFF5bc0de), // Light blue
      const Color(0xFF9b59b6), // Purple
      const Color(0xFF1abc9c), // Teal
      const Color(0xFFe67e22), // Dark orange
    ];

    return colors[index % colors.length];
  }

  String _formatNumber(String value) {
    try {
      final number = double.tryParse(value.replaceAll(',', ''));
      if (number == null) return value;

      if (number >= 1000000) {
        return '${(number / 1000000).toStringAsFixed(1)}M';
      } else if (number >= 1000) {
        return '${(number / 1000).toStringAsFixed(1)}K';
      } else {
        return number.toStringAsFixed(0);
      }
    } catch (e) {
      return value;
    }
  }
}
