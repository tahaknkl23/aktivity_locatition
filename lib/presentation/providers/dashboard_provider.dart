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
  bool get hasData => _statistics != null && _statistics!.cards.isNotEmpty;
  bool get isEmpty => _statistics?.cards.isEmpty ?? true;

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

      debugPrint('[DASHBOARD_PROVIDER] ✅ Dashboard data loaded: ${statistics.cards.length} cards, ${statistics.charts.length} charts');
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
  }) async {
    try {
      debugPrint('[DASHBOARD_PROVIDER] 🔄 Refreshing widget: $widgetId');

      final widgetData = await _dashboardApiService.getSpecificWidgetData(
        widgetId: widgetId,
        sqlId: sqlId,
        index: index,
      );

      if (widgetData != null && _statistics != null) {
        // Mevcut istatistikleri güncelle
        final updatedCards = List<StatisticCard>.from(_statistics!.cards);

        // İlgili kartı bul ve güncelle
        final cardIndex = updatedCards.indexWhere((card) => card.title.contains(widgetData.reportInfo.name));

        if (cardIndex >= 0 && widgetData.singleValue != null) {
          updatedCards[cardIndex] = StatisticCard.fromWidgetData(widgetData);

          _statistics = DashboardStatistics(
            cards: updatedCards,
            charts: _statistics!.charts,
            lastUpdated: DateTime.now().toIso8601String(),
          );

          notifyListeners();
          debugPrint('[DASHBOARD_PROVIDER] ✅ Widget $widgetId refreshed');
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
