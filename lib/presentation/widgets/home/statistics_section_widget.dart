// lib/presentation/widgets/home/statistics_section_widget.dart - FIXED VERSION
import 'package:aktivity_location_app/presentation/widgets/home/statistic_detail_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../data/models/dashboard/dashboard_models.dart';
import '../../providers/dashboard_provider.dart';
import 'simple_data_display.dart';

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
          'Dashboard',
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
              '${provider.cards.length} kart • ${provider.charts.length} grafik',
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
    // 401 Authentication error kontrolü
    if (provider.errorMessage != null && provider.errorMessage!.contains('Oturum süresi dolmuş')) {
      return _AuthErrorState(error: provider.errorMessage!);
    }

    if (provider.isLoading && !provider.hasData) {
      return const _LoadingState();
    } else if (provider.errorMessage != null && !provider.hasData) {
      return _ErrorState(error: provider.errorMessage!);
    } else if (provider.isEmpty) {
      return const _EmptyState();
    } else if (provider.hasData) {
      return _DashboardContent(
        cards: provider.cards,
        charts: provider.charts,
      );
    } else {
      return const _LoadingState();
    }
  }
}

class _DashboardContent extends StatelessWidget {
  final List<StatisticCard> cards;
  final List<ChartWidget> charts;

  const _DashboardContent({
    required this.cards,
    required this.charts,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info Cards Grid
        if (cards.isNotEmpty) ...[
          _StatisticsGrid(cards: cards),
          const SizedBox(height: 24),
        ],

        // Charts Section
        if (charts.isNotEmpty) ...[
          _ChartsSection(charts: charts),
        ],
      ],
    );
  }
}

class _ChartsSection extends StatelessWidget {
  final List<ChartWidget> charts;

  const _ChartsSection({required this.charts});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: charts.map((chart) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ChartDisplayWidget(chart: chart),
        );
      }).toList(),
    );
  }
}

class ChartDisplayWidget extends StatelessWidget {
  final ChartWidget chart;

  const ChartDisplayWidget({super.key, required this.chart});

  @override
  Widget build(BuildContext context) {
    return SimpleDataDisplay(chart: chart);
  }
}

// Custom Painters for Charts
class LineChartPainter extends CustomPainter {
  final List<ChartDataPair> data;

  LineChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF667eea)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = const Color(0xFF667eea)
      ..style = PaintingStyle.fill;

    final maxValue = data.fold<double>(0, (max, item) {
      final itemValue = item.actualValue > item.targetValue ? item.actualValue : item.targetValue;
      return itemValue > max ? itemValue : max;
    });

    final padding = const EdgeInsets.all(30);
    final chartWidth = size.width - padding.horizontal;
    final chartHeight = size.height - padding.vertical;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final x = padding.left + (chartWidth / (data.length - 1)) * i;
      final y = padding.top + chartHeight - (data[i].actualValue / maxValue) * chartHeight;

      final point = Offset(x, y);
      points.add(point);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, linePaint);

    // Draw points
    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StatisticsGrid extends StatelessWidget {
  final List<StatisticCard> cards;

  const _StatisticsGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    // FIXED: Responsive design and better aspect ratio
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive column count
        int crossAxisCount = 2;
        if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        }

        // FIXED: Better aspect ratio calculation
        double aspectRatio = 1.3;
        if (constraints.maxWidth < 400) {
          aspectRatio = 1.1; // Daha yüksek kartlar mobilde
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: size.mediumSpacing,
            mainAxisSpacing: size.mediumSpacing,
            childAspectRatio: aspectRatio, // FIXED: Daha uygun oran
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return _StatCard(card: card, index: index);
          },
        );
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
            padding: EdgeInsets.all(size.cardPadding), // FIXED: Padding azaltıldı
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FIXED: Flexible row for better space management
                Flexible(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Icon container - Fixed size
                      Container(
                        padding: const EdgeInsets.all(6), // FIXED: Smaller padding
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          card.icon,
                          color: Colors.white,
                          size: size.mediumIcon * 0.7, // FIXED: Smaller icon
                        ),
                      ),
                      // Value column - Flexible
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _formatNumber(card.value),
                                style: TextStyle(
                                  fontSize: size.mediumText * 1.1, // FIXED: Smaller font
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (card.unit.isNotEmpty) ...[
                              const SizedBox(height: 2), // FIXED: Smaller spacing
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  card.unit,
                                  style: TextStyle(
                                    fontSize: size.smallText * 0.8, // FIXED: Smaller unit
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // FIXED: Spacer instead of fixed height
                const Spacer(),

                // Title - Fixed to bottom
                Text(
                  card.title,
                  style: TextStyle(
                    fontSize: size.textSize * 0.85, // FIXED: Smaller title
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
    String sqlId = '9889';
    int widgetId = 13907;

    if (card.title.toLowerCase().contains('araç') || card.title.toLowerCase().contains('servis')) {
      sqlId = '9889';
      widgetId = 13907;
    } else if (card.title.toLowerCase().contains('müşteri')) {
      sqlId = '9656';
      widgetId = 13908;
    } else if (card.title.toLowerCase().contains('adres')) {
      sqlId = '9892';
      widgetId = 13909;
    } else if (card.title.toLowerCase().contains('ziyaret')) {
      sqlId = '1842';
      widgetId = 13910;
    } else if (card.title.toLowerCase().contains('sipariş')) {
      sqlId = '285';
      widgetId = 13911;
    }

    showStatisticDetailBottomSheet(
      context: context,
      title: card.title,
      sqlId: sqlId,
      widgetId: widgetId,
      color: color,
      icon: card.icon,
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

// FIXED: New authentication error state
class _AuthErrorState extends StatelessWidget {
  final String error;

  const _AuthErrorState({required this.error});

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
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 32,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              'Oturum Süresi Doldu',
              style: TextStyle(
                fontSize: size.textSize,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: size.tinySpacing),
            Text(
              'Lütfen tekrar giriş yapın',
              style: TextStyle(
                fontSize: size.smallText,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to login - implement your navigation logic
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Giriş Yap'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
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
              'Dashboard yükleniyor...',
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
