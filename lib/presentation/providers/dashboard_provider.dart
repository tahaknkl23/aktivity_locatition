// lib/presentation/providers/dashboard_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/dashboard/dashboard_models.dart';
import '../../data/services/api/dashboard_api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardApiService _dashboardApiService = DashboardApiService();

  // State variables
  DashboardStatistics? _statistics;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastUpdated;

  // Getters
  DashboardStatistics? get statistics => _statistics;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastUpdated => _lastUpdated;
  bool get hasData => _statistics != null && (_statistics!.cards.isNotEmpty || _statistics!.charts.isNotEmpty);
  bool get isEmpty => _statistics?.cards.isEmpty == true && _statistics?.charts.isEmpty == true;

  // Chart specific getters
  bool get hasCharts => _statistics?.charts.isNotEmpty == true;
  List<ChartWidget> get charts => _statistics?.charts ?? [];
  List<StatisticCard> get cards => _statistics?.cards ?? [];

  /// Dashboard verilerini yükle
  Future<void> loadDashboardData({bool forceRefresh = false}) async {
    if (_isLoading) return; // Duplicate loading engelle

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[DASHBOARD_PROVIDER] 📊 Loading dashboard data (forceRefresh: $forceRefresh)...');

      final statistics = await _dashboardApiService.refreshDashboardData(
        forceRefresh: forceRefresh,
      );

      _statistics = statistics;
      _lastUpdated = DateTime.now();

      debugPrint('[DASHBOARD_PROVIDER] ✅ Dashboard data loaded:');
      debugPrint('[DASHBOARD_PROVIDER] 📊 Cards: ${statistics.cards.length}');
      debugPrint('[DASHBOARD_PROVIDER] 📈 Charts: ${statistics.charts.length}');

      // Chart detaylarını log'la
      for (int i = 0; i < statistics.charts.length; i++) {
        final chart = statistics.charts[i];
        debugPrint('[DASHBOARD_PROVIDER] 📈 Chart $i: ${chart.title} (${chart.chartType}) - ${chart.data.length} data points');

        // İlk birkaç data point'i de göster
        for (int j = 0; j < chart.data.take(3).length; j++) {
          final dataPoint = chart.data[j];
          debugPrint('[DASHBOARD_PROVIDER] 📊   Data $j: ${dataPoint.category} - Target: ${dataPoint.target}, Actual: ${dataPoint.actual}');
        }
      }
    } catch (e) {
      _errorMessage = 'Dashboard verileri yüklenirken hata oluştu: $e';
      debugPrint('[DASHBOARD_PROVIDER] ❌ Error loading dashboard data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Belirli bir widget'ı yenile
  Future<void> refreshSpecificWidget({
    required int widgetId,
    required String sqlId,
    required int index,
    bool isChart = false,
  }) async {
    try {
      debugPrint('[DASHBOARD_PROVIDER] 🔄 Refreshing widget: $widgetId (isChart: $isChart)');

      final widgetData = await _dashboardApiService.getSpecificWidgetData(
        widgetId: widgetId,
        sqlId: sqlId,
        index: index,
        isChart: isChart,
      );

      if (widgetData != null && _statistics != null) {
        if (isChart) {
          // Chart widget'ı güncelle
          final updatedCharts = List<ChartWidget>.from(_statistics!.charts);
          final chartIndex = updatedCharts.indexWhere((chart) => chart.title.contains(widgetData.reportInfo.name));

          if (chartIndex >= 0 && widgetData.chartData.isNotEmpty) {
            updatedCharts[chartIndex] = ChartWidget.fromWidgetData(widgetData);

            _statistics = DashboardStatistics(
              cards: _statistics!.cards,
              charts: updatedCharts,
              lastUpdated: DateTime.now().toIso8601String(),
            );

            notifyListeners();
            debugPrint('[DASHBOARD_PROVIDER] ✅ Chart widget $widgetId refreshed');
          }
        } else {
          // Info widget'ı güncelle
          final updatedCards = List<StatisticCard>.from(_statistics!.cards);
          final cardIndex = updatedCards.indexWhere((card) => card.title.contains(widgetData.reportInfo.name));

          if (cardIndex >= 0 && widgetData.singleValue != null) {
            updatedCards[cardIndex] = StatisticCard.fromWidgetData(widgetData);

            _statistics = DashboardStatistics(
              cards: updatedCards,
              charts: _statistics!.charts,
              lastUpdated: DateTime.now().toIso8601String(),
            );

            notifyListeners();
            debugPrint('[DASHBOARD_PROVIDER] ✅ Info widget $widgetId refreshed');
          }
        }
      }
    } catch (e) {
      debugPrint('[DASHBOARD_PROVIDER] ❌ Error refreshing widget $widgetId: $e');
    }
  }

  /// Dashboard sağlık durumunu kontrol et
  Future<bool> checkDashboardHealth() async {
    try {
      return await _dashboardApiService.isDashboardHealthy();
    } catch (e) {
      debugPrint('[DASHBOARD_PROVIDER] ❌ Dashboard health check error: $e');
      return false;
    }
  }

  /// Belirli kategorideki kartları getir
  List<StatisticCard> getCardsByCategory(String category) {
    if (_statistics == null) return [];

    return _statistics!.cards.where((card) {
      final title = card.title.toLowerCase();
      final cat = category.toLowerCase();

      switch (cat) {
        case 'activity':
        case 'aktivite':
          return title.contains('ziyaret') || title.contains('aktivite');
        case 'company':
        case 'firma':
          return title.contains('müşteri') || title.contains('firma') || title.contains('adres');
        case 'order':
        case 'sipariş':
          return title.contains('sipariş') || title.contains('tutar');
        case 'vehicle':
        case 'araç':
          return title.contains('araç') || title.contains('servis');
        default:
          return true;
      }
    }).toList();
  }

  /// Belirli türdeki chart'ları getir
  List<ChartWidget> getChartsByType(String chartType) {
    if (_statistics == null) return [];

    return _statistics!.charts.where((chart) {
      return chart.chartType.toLowerCase() == chartType.toLowerCase();
    }).toList();
  }

  /// MultiBar chart'ları getir
  List<ChartWidget> get multiBarCharts {
    return getChartsByType('MultiBar');
  }

  /// Line chart'ları getir
  List<ChartWidget> get lineCharts {
    return getChartsByType('Line');
  }

  /// Pie chart'ları getir
  List<ChartWidget> get pieCharts {
    return getChartsByType('Pie');
  }

  /// En önemli kartları getir (değere göre)
  List<StatisticCard> getTopCards({int limit = 4}) {
    if (_statistics == null) return [];

    // Kartları değere göre sırala (sayısal değerleri parse et)
    final sortedCards = List<StatisticCard>.from(_statistics!.cards);
    sortedCards.sort((a, b) {
      final aValue = _parseNumericValue(a.value);
      final bValue = _parseNumericValue(b.value);
      return bValue.compareTo(aValue);
    });

    return sortedCards.take(limit).toList();
  }

  /// En yüksek performanslı chart'ları getir
  List<ChartWidget> getTopPerformingCharts({int limit = 2}) {
    if (_statistics == null) return [];

    // Chart'ları data point sayısına göre sırala
    final sortedCharts = List<ChartWidget>.from(_statistics!.charts);
    sortedCharts.sort((a, b) => b.data.length.compareTo(a.data.length));

    return sortedCharts.take(limit).toList();
  }

  /// String değeri sayısal değere çevir
  double _parseNumericValue(String value) {
    try {
      // Binlik ayıracını kaldır ve sayıya çevir
      final cleanValue = value.replaceAll(',', '').replaceAll('.', '');
      return double.tryParse(cleanValue) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Cache'i temizle
  void clearCache() {
    _statistics = null;
    _lastUpdated = null;
    _clearError();
    notifyListeners();
    debugPrint('[DASHBOARD_PROVIDER] 🧹 Cache cleared');
  }

  /// Verinin ne kadar eski olduğunu kontrol et
  bool get isDataStale {
    if (_lastUpdated == null) return true;

    final now = DateTime.now();
    final difference = now.difference(_lastUpdated!);

    // 10 dakikadan eski ise stale
    return difference.inMinutes > 10;
  }

  /// Otomatik yenileme gerekip gerekmediğini kontrol et
  bool get needsAutoRefresh {
    return isDataStale || isEmpty;
  }

  /// Dashboard özetini al
  DashboardSummary get summary {
    if (_statistics == null) {
      return DashboardSummary.empty();
    }

    return DashboardSummary(
      totalCards: _statistics!.cards.length,
      totalCharts: _statistics!.charts.length,
      lastUpdated: _lastUpdated,
      isHealthy: _errorMessage == null,
      categories: _getCategoryBreakdown(),
    );
  }

  /// Kategori dağılımını al
  Map<String, int> _getCategoryBreakdown() {
    if (_statistics == null) return {};

    final breakdown = <String, int>{};

    for (final card in _statistics!.cards) {
      final title = card.title.toLowerCase();

      if (title.contains('müşteri') || title.contains('firma')) {
        breakdown['Firmalar'] = (breakdown['Firmalar'] ?? 0) + 1;
      } else if (title.contains('ziyaret') || title.contains('aktivite')) {
        breakdown['Aktiviteler'] = (breakdown['Aktiviteler'] ?? 0) + 1;
      } else if (title.contains('sipariş') || title.contains('tutar')) {
        breakdown['Siparişler'] = (breakdown['Siparişler'] ?? 0) + 1;
      } else if (title.contains('araç') || title.contains('servis')) {
        breakdown['Araçlar'] = (breakdown['Araçlar'] ?? 0) + 1;
      } else {
        breakdown['Diğer'] = (breakdown['Diğer'] ?? 0) + 1;
      }
    }

    return breakdown;
  }

  /// Chart türlerinin dağılımını al
  Map<String, int> get chartTypeBreakdown {
    if (_statistics == null) return {};

    final breakdown = <String, int>{};

    for (final chart in _statistics!.charts) {
      final type = chart.chartType;
      breakdown[type] = (breakdown[type] ?? 0) + 1;
    }

    return breakdown;
  }

  /// Toplam chart data point sayısı
  int get totalChartDataPoints {
    if (_statistics == null) return 0;

    return _statistics!.charts.fold(0, (total, chart) => total + chart.data.length);
  }

  /// Belirli bir chart'ı ID ile bul
  ChartWidget? getChartById(String chartTitle) {
    if (_statistics == null) return null;

    try {
      return _statistics!.charts.firstWhere(
        (chart) => chart.title.toLowerCase().contains(chartTitle.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Belirli bir card'ı ID ile bul
  StatisticCard? getCardById(String cardTitle) {
    if (_statistics == null) return null;

    try {
      return _statistics!.cards.firstWhere(
        (card) => card.title.toLowerCase().contains(cardTitle.toLowerCase()),
      );
    } catch (e) {
      return null;
    }
  }

  /// Dashboard'da arama yap
  DashboardSearchResult searchDashboard(String query) {
    if (_statistics == null || query.isEmpty) {
      return DashboardSearchResult.empty();
    }

    final lowerQuery = query.toLowerCase();

    // Kartlarda ara
    final matchingCards = _statistics!.cards.where((card) {
      return card.title.toLowerCase().contains(lowerQuery) ||
          card.value.toLowerCase().contains(lowerQuery) ||
          card.unit.toLowerCase().contains(lowerQuery);
    }).toList();

    // Chart'larda ara
    final matchingCharts = _statistics!.charts.where((chart) {
      return chart.title.toLowerCase().contains(lowerQuery) || chart.chartType.toLowerCase().contains(lowerQuery);
    }).toList();

    return DashboardSearchResult(
      query: query,
      cards: matchingCards,
      charts: matchingCharts,
    );
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    debugPrint('[DASHBOARD_PROVIDER] 🗑️ Disposing');
    super.dispose();
  }
}

/// Dashboard özet bilgileri
class DashboardSummary {
  final int totalCards;
  final int totalCharts;
  final DateTime? lastUpdated;
  final bool isHealthy;
  final Map<String, int> categories;

  DashboardSummary({
    required this.totalCards,
    required this.totalCharts,
    this.lastUpdated,
    required this.isHealthy,
    required this.categories,
  });

  factory DashboardSummary.empty() {
    return DashboardSummary(
      totalCards: 0,
      totalCharts: 0,
      isHealthy: false,
      categories: {},
    );
  }

  /// Son güncelleme zamanını formatla
  String get formattedLastUpdated {
    if (lastUpdated == null) return 'Henüz yüklenmedi';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated!);

    if (difference.inMinutes < 1) {
      return 'Az önce güncellendi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce güncellendi';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} saat önce güncellendi';
    } else {
      return '${difference.inDays} gün önce güncellendi';
    }
  }

  /// Toplam widget sayısı
  int get totalWidgets => totalCards + totalCharts;

  /// En popüler kategori
  String get topCategory {
    if (categories.isEmpty) return 'Belirsiz';

    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.key;
  }
}

/// Dashboard arama sonucu
class DashboardSearchResult {
  final String query;
  final List<StatisticCard> cards;
  final List<ChartWidget> charts;

  DashboardSearchResult({
    required this.query,
    required this.cards,
    required this.charts,
  });

  factory DashboardSearchResult.empty() {
    return DashboardSearchResult(
      query: '',
      cards: [],
      charts: [],
    );
  }

  bool get hasResults => cards.isNotEmpty || charts.isNotEmpty;
  int get totalResults => cards.length + charts.length;
}
