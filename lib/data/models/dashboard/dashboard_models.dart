// lib/data/models/dashboard/dashboard_models.dart
import 'package:flutter/material.dart';

/// Ana Dashboard Response
class DashboardResponse {
  final List<DashboardGroup> dashboards;
  final bool disableMasterDashboard;

  DashboardResponse({
    required this.dashboards,
    required this.disableMasterDashboard,
  });

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dashboardsList = json['Dashboards'] as List<dynamic>? ?? [];

      return DashboardResponse(
        dashboards: dashboardsList.map((item) => DashboardGroup.fromJson(item as Map<String, dynamic>)).toList(),
        disableMasterDashboard: json['DisableMasterDashboard'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('[DASHBOARD_RESPONSE] Parse error: $e');
      return DashboardResponse.empty();
    }
  }

  factory DashboardResponse.empty() {
    return DashboardResponse(
      dashboards: [],
      disableMasterDashboard: true,
    );
  }

  /// Ana dashboard'ı al (genellikle ilk grup)
  DashboardGroup? get mainDashboard {
    return dashboards.isNotEmpty ? dashboards.first : null;
  }

  /// Tüm widget'ları flat liste olarak al
  List<DashboardWidget> get allWidgets {
    return dashboards.expand((group) => group.widgets).toList();
  }

  /// Info tipindeki widget'ları al (istatistik kartları için)
  List<DashboardWidget> get infoWidgets {
    return allWidgets.where((widget) => widget.widgetType == 'Info').toList();
  }

  /// Chart widget'ları al
  List<DashboardWidget> get chartWidgets {
    return allWidgets.where((widget) => widget.widgetType != 'Info').toList();
  }
}

/// Dashboard Group (bir dashboard sekme grubu)
class DashboardGroup {
  final int dashboardIndex;
  final String dashboardName;
  final int filterSqlId;
  final List<DashboardWidget> widgets;

  DashboardGroup({
    required this.dashboardIndex,
    required this.dashboardName,
    required this.filterSqlId,
    required this.widgets,
  });

  factory DashboardGroup.fromJson(Map<String, dynamic> json) {
    try {
      final dashboardList = json['Dashboard'] as List<dynamic>? ?? [];

      return DashboardGroup(
        dashboardIndex: json['DashboardIndex'] as int? ?? 0,
        dashboardName: json['DashboardName'] as String? ?? '',
        filterSqlId: json['FilterSqlId'] as int? ?? 0,
        widgets: dashboardList.map((item) => DashboardWidget.fromJson(item as Map<String, dynamic>)).toList(),
      );
    } catch (e) {
      debugPrint('[DASHBOARD_GROUP] Parse error: $e');
      return DashboardGroup.empty();
    }
  }

  factory DashboardGroup.empty() {
    return DashboardGroup(
      dashboardIndex: 0,
      dashboardName: '',
      filterSqlId: 0,
      widgets: [],
    );
  }
}

/// Dashboard Widget (her bir kart/grafik)
class DashboardWidget {
  final int id;
  final String uid;
  final String title;
  final int index;
  final String widgetType; // Info, MultiBar, Grid vb.
  final String detailGridSize;
  final String sql;
  final String? detailSql;
  final int width;
  final String? colorText;
  final String? colorBackground;
  final String? unit;
  final int dashboardIndex;

  DashboardWidget({
    required this.id,
    required this.uid,
    required this.title,
    required this.index,
    required this.widgetType,
    required this.detailGridSize,
    required this.sql,
    this.detailSql,
    required this.width,
    this.colorText,
    this.colorBackground,
    this.unit,
    required this.dashboardIndex,
  });

  factory DashboardWidget.fromJson(Map<String, dynamic> json) {
    return DashboardWidget(
      id: json['Id'] as int? ?? 0,
      uid: json['uid'] as String? ?? '',
      title: json['Title'] as String? ?? '',
      index: json['Index'] as int? ?? 0,
      widgetType: json['WidgetType'] as String? ?? 'Info',
      detailGridSize: json['DetailGridSize'] as String? ?? '',
      sql: json['Sql'] as String? ?? '',
      detailSql: json['DetailSql'] as String?,
      width: json['Width'] as int? ?? 12,
      colorText: json['ColorText'] as String?,
      colorBackground: json['ColorBackground'] as String?,
      unit: json['Unit'] as String?,
      dashboardIndex: json['DashboardIndex'] as int? ?? 0,
    );
  }

  /// Widget'ın görsel özelliklerini al
  WidgetDisplayProperties get displayProperties {
    return WidgetDisplayProperties(
      title: title,
      widgetType: widgetType,
      backgroundColor: _parseColor(colorBackground),
      textColor: Colors.black38,
      unit: unit ?? '',
      isChart: widgetType != 'Info',
    );
  }

  /// String renk kodunu Color'a çevir
  Color? _parseColor(String? colorCode, {Color? defaultColor}) {
    if (colorCode == null || colorCode.isEmpty) return defaultColor;

    try {
      if (colorCode.startsWith('#')) {
        return Color(int.parse(colorCode.substring(1), radix: 16) + 0xFF000000);
      } else if (colorCode == 'green') {
        return Colors.green;
      } else if (colorCode == 'red') {
        return Colors.red;
      } else {
        return defaultColor;
      }
    } catch (e) {
      return defaultColor;
    }
  }

  /// Widget boyutu hesapla (responsive)
  int getResponsiveWidth(double screenWidth) {
    if (screenWidth < 600) {
      // Mobile: her widget full width
      return 12;
    } else if (screenWidth < 900) {
      // Tablet: 2'li satır
      return width >= 6 ? 12 : 6;
    } else {
      // Desktop: orijinal width
      return width;
    }
  }
}

/// Widget görsel özellikleri
class WidgetDisplayProperties {
  final String title;
  final String widgetType;
  final Color? backgroundColor;
  final Color textColor;
  final String unit;
  final bool isChart;

  WidgetDisplayProperties({
    required this.title,
    required this.widgetType,
    this.backgroundColor,
    required this.textColor,
    required this.unit,
    required this.isChart,
  });
}

/// Widget veri response'u - UPDATED VERSION
class WidgetDataResponse {
  final List<WidgetDataItem> data;
  final WidgetReportInfo reportInfo;
  final int index;

  WidgetDataResponse({
    required this.data,
    required this.reportInfo,
    required this.index,
  });

  factory WidgetDataResponse.fromJson(Map<String, dynamic> json) {
    try {
      final dataSourceResult = json['DataSourceResult'] as Map<String, dynamic>? ?? {};
      final dataList = dataSourceResult['Data'] as List<dynamic>? ?? [];

      debugPrint('[WIDGET_DATA_RESPONSE] 📊 Parsing response for: ${json['reportInf']?['Name'] ?? 'Unknown'}');
      debugPrint('[WIDGET_DATA_RESPONSE] 📋 Data items: ${dataList.length}');

      return WidgetDataResponse(
        data: dataList.map((item) => WidgetDataItem.fromJson(item as Map<String, dynamic>)).toList(),
        reportInfo: WidgetReportInfo.fromJson(json['reportInf'] ?? {}),
        index: json['Index'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('[WIDGET_DATA_RESPONSE] ❌ Parse error: $e');
      return WidgetDataResponse.empty();
    }
  }

  factory WidgetDataResponse.empty() {
    return WidgetDataResponse(
      data: [],
      reportInfo: WidgetReportInfo.empty(),
      index: 0,
    );
  }

  /// Info widget için tek değer al
  WidgetDataItem? get singleValue {
    return data.isNotEmpty ? data.first : null;
  }

  /// Chart için tüm değerleri al
  List<WidgetDataItem> get chartData => data;

  /// Widget'ın boş olup olmadığını kontrol et
  bool get isEmpty => data.isEmpty;

  /// Widget'ın hata durumunu kontrol et
  bool get hasError => reportInfo.errors?.isNotEmpty == true;

  /// Chart için özel getter'lar
  bool get isChart => reportInfo.chartType != 'Info';
  bool get isInfo => reportInfo.chartType == 'Info';
}

/// Widget veri öğesi - UPDATED VERSION
class WidgetDataItem {
  final dynamic value;
  final String? name;
  final String? category;
  final dynamic hedef;
  final dynamic gerceklesen;
  final String? colorHtml;
  final dynamic defult;
  final dynamic tolera;

  WidgetDataItem({
    this.value,
    this.name,
    this.category,
    this.hedef,
    this.gerceklesen,
    this.colorHtml,
    this.defult,
    this.tolera,
  });

  factory WidgetDataItem.fromJson(Map<String, dynamic> json) {
    return WidgetDataItem(
      value: json['Value'] ?? json['value'],
      name: json['Name'] as String? ?? json['name'] as String?,
      category: json['Category'] as String?,
      hedef: json['Hedef'],
      gerceklesen: json['Gerceklesen'],
      colorHtml: json['ColorHtmlHedef'] as String? ?? json['ColorHtmlGerceklesen'] as String?,
      defult: json['defult'],
      tolera: json['tolera'],
    );
  }

  /// Değeri string olarak formatla
  String get formattedValue {
    if (value == null) return '0';

    if (value is num) {
      if (value % 1 == 0) {
        // Tam sayı
        return value.toStringAsFixed(0);
      } else {
        // Ondalıklı sayı
        return value.toStringAsFixed(2);
      }
    }

    return value.toString();
  }

  /// Renk kodunu Color'a çevir
  Color? get color {
    if (colorHtml == null) return null;

    try {
      if (colorHtml!.startsWith('#')) {
        return Color(int.parse(colorHtml!.substring(1), radix: 16) + 0xFF000000);
      }
    } catch (e) {
      return null;
    }

    return null;
  }

  /// Chart veri çifti (hedef vs gerçekleşen)
  ChartDataPair? get chartPair {
    if (hedef != null && gerceklesen != null) {
      return ChartDataPair(
        category: category ?? name ?? '',
        target: hedef,
        actual: gerceklesen,
      );
    }
    return null;
  }

  /// Chart için flex değer alma
  dynamic get chartValue {
    if (gerceklesen != null) return gerceklesen;
    if (hedef != null) return hedef;
    if (value != null) return value;
    return 0;
  }
}

/// Chart veri çifti - UPDATED VERSION
class ChartDataPair {
  final String category;
  final dynamic target;
  final dynamic actual;

  ChartDataPair({
    required this.category,
    required this.target,
    required this.actual,
  });

  double get targetValue => (target is num) ? target.toDouble() : 0.0;
  double get actualValue => (actual is num) ? actual.toDouble() : 0.0;
}

/// Widget rapor bilgileri
class WidgetReportInfo {
  final String chartType;
  final String name;
  final String sql;
  final List<String>? errors;

  WidgetReportInfo({
    required this.chartType,
    required this.name,
    required this.sql,
    this.errors,
  });

  factory WidgetReportInfo.fromJson(Map<String, dynamic> json) {
    return WidgetReportInfo(
      chartType: json['ChartType'] as String? ?? 'Info',
      name: json['Name'] as String? ?? '',
      sql: json['Sql'] as String? ?? '',
      errors: json['Errors'] as List<String>?,
    );
  }

  factory WidgetReportInfo.empty() {
    return WidgetReportInfo(
      chartType: 'Info',
      name: '',
      sql: '',
    );
  }
}

/// Dashboard istatistikleri için helper model - UPDATED VERSION
class DashboardStatistics {
  final List<StatisticCard> cards;
  final List<ChartWidget> charts;
  final String lastUpdated;

  DashboardStatistics({
    required this.cards,
    required this.charts,
    required this.lastUpdated,
  });

  factory DashboardStatistics.fromWidgetResponses(List<WidgetDataResponse> responses) {
    final cards = <StatisticCard>[];
    final charts = <ChartWidget>[];

    debugPrint('[DASHBOARD_STATISTICS] 🔄 Processing ${responses.length} widget responses...');

    for (int i = 0; i < responses.length; i++) {
      final response = responses[i];
      final chartType = response.reportInfo.chartType;

      debugPrint('[DASHBOARD_STATISTICS] 📊 Widget $i: ${response.reportInfo.name} ($chartType)');

      try {
        if (chartType == 'Info' && response.singleValue != null) {
          // Info widget - Statistic Card olarak işle
          final card = StatisticCard.fromWidgetData(response);
          cards.add(card);
          debugPrint('[DASHBOARD_STATISTICS] ✅ Added Info card: ${card.title}');
        } else if (chartType != 'Info' && response.chartData.isNotEmpty) {
          // Chart widget - Chart Widget olarak işle
          final chart = ChartWidget.fromWidgetData(response);
          charts.add(chart);
          debugPrint('[DASHBOARD_STATISTICS] ✅ Added Chart: ${chart.title} (${chart.chartType}) - ${chart.data.length} data points');
        } else {
          debugPrint('[DASHBOARD_STATISTICS] ⚠️ Skipped widget $i: No valid data');
        }
      } catch (e) {
        debugPrint('[DASHBOARD_STATISTICS] ❌ Error processing widget $i: $e');
      }
    }

    debugPrint('[DASHBOARD_STATISTICS] 🎯 Final result: ${cards.length} cards, ${charts.length} charts');

    return DashboardStatistics(
      cards: cards,
      charts: charts,
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }

  factory DashboardStatistics.empty() {
    return DashboardStatistics(
      cards: [],
      charts: [],
      lastUpdated: DateTime.now().toIso8601String(),
    );
  }
}

/// İstatistik kartı
class StatisticCard {
  final String title;
  final String value;
  final String unit;
  final Color? backgroundColor;
  final Color textColor;
  final IconData icon;

  StatisticCard({
    required this.title,
    required this.value,
    required this.unit,
    this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  factory StatisticCard.fromWidgetData(WidgetDataResponse response) {
    final data = response.singleValue!;
    final title = data.name ?? response.reportInfo.name;

    return StatisticCard(
      title: title,
      value: data.formattedValue,
      unit: _extractUnit(title),
      backgroundColor: data.color,
      textColor: Colors.black87,
      icon: _getIconForTitle(title),
    );
  }

  static String _extractUnit(String title) {
    if (title.toLowerCase().contains('tutar')) return 'TL';
    if (title.toLowerCase().contains('adet')) return 'Adet';
    if (title.toLowerCase().contains('müşteri')) return 'Adet';
    if (title.toLowerCase().contains('ziyaret')) return 'Adet';
    if (title.toLowerCase().contains('sipariş')) return 'Adet';
    if (title.toLowerCase().contains('adres')) return 'Adet';
    return '';
  }

  static IconData _getIconForTitle(String title) {
    final lowerTitle = title.toLowerCase();

    if (lowerTitle.contains('müşteri') || lowerTitle.contains('customer')) return Icons.people;
    if (lowerTitle.contains('sipariş') || lowerTitle.contains('order')) return Icons.shopping_cart;
    if (lowerTitle.contains('ziyaret') || lowerTitle.contains('visit')) return Icons.location_on;
    if (lowerTitle.contains('tutar') || lowerTitle.contains('amount')) return Icons.attach_money;
    if (lowerTitle.contains('adres') || lowerTitle.contains('address')) return Icons.location_city;
    if (lowerTitle.contains('araç') || lowerTitle.contains('vehicle')) return Icons.directions_car;
    if (lowerTitle.contains('servis') || lowerTitle.contains('service')) return Icons.build;

    return Icons.analytics;
  }
}

/// Chart widget - COMPLETELY UPDATED VERSION
class ChartWidget {
  final String title;
  final String chartType;
  final List<ChartDataPair> data;

  ChartWidget({
    required this.title,
    required this.chartType,
    required this.data,
  });

  factory ChartWidget.fromWidgetData(WidgetDataResponse response) {
    debugPrint('[CHART_WIDGET] 🔄 Processing chart: ${response.reportInfo.name}');
    debugPrint('[CHART_WIDGET] 📊 Chart type: ${response.reportInfo.chartType}');
    debugPrint('[CHART_WIDGET] 📋 Data count: ${response.chartData.length}');

    final chartData = <ChartDataPair>[];

    for (int i = 0; i < response.chartData.length; i++) {
      final item = response.chartData[i];
      debugPrint('[CHART_WIDGET] 🔍 Item $i: ${item.name} / ${item.category}');

      // MultiBar için Hedef-Gerçekleşen data pair'i
      if (item.hedef != null && item.gerceklesen != null) {
        final pair = ChartDataPair(
          category: item.category ?? item.name ?? 'Kategori ${i + 1}',
          target: item.hedef,
          actual: item.gerceklesen,
        );
        chartData.add(pair);
        debugPrint('[CHART_WIDGET] ✅ Added pair: ${pair.category} - Target: ${pair.target}, Actual: ${pair.actual}');
      }
      // Single value chart için
      else if (item.value != null) {
        final pair = ChartDataPair(
          category: item.category ?? item.name ?? 'Kategori ${i + 1}',
          target: 0,
          actual: item.value,
        );
        chartData.add(pair);
        debugPrint('[CHART_WIDGET] ✅ Added single value: ${pair.category} = ${pair.actual}');
      }
    }

    return ChartWidget(
      title: response.reportInfo.name,
      chartType: response.reportInfo.chartType,
      data: chartData,
    );
  }

  /// Chart widget için özel methodlar
  bool get hasData => data.isNotEmpty;
  bool get isMultiBar => chartType == 'MultiBar';
  bool get isLine => chartType == 'Line';
  bool get isPie => chartType == 'Pie';

  /// Maximum değerleri al
  double get maxTarget => data.isEmpty ? 0 : data.map((d) => d.targetValue).reduce((a, b) => a > b ? a : b);
  double get maxActual => data.isEmpty ? 0 : data.map((d) => d.actualValue).reduce((a, b) => a > b ? a : b);
  double get maxValue => [maxTarget, maxActual].reduce((a, b) => a > b ? a : b);

  /// Chart için formatted title
  String get formattedTitle {
    if (title.length > 25) {
      return '${title.substring(0, 25)}...';
    }
    return title;
  }

  /// Chart'da kullanılacak renkler
  List<Color> get chartColors {
    return [
      const Color(0xFF667eea), // Blue
      const Color(0xFF5cb85c), // Green
      const Color(0xFFf0ad4e), // Orange
      const Color(0xFFd9534f), // Red
      const Color(0xFF5bc0de), // Light blue
      const Color(0xFF9b59b6), // Purple
      const Color(0xFF1abc9c), // Teal
      const Color(0xFFe67e22), // Dark orange
    ];
  }

  /// Hedef ve gerçekleşen için farklı renkler
  Color get targetColor => const Color(0xFFf07b69);
  Color get actualColor => const Color(0xFF6fc7ef);
}
