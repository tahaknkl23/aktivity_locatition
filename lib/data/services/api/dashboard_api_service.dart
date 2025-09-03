// lib/data/services/api/dashboard_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../data/models/dashboard/dashboard_models.dart';
import 'api_client.dart';

class DashboardApiService {
  /// 1. DASHBOARD CONFIGURATION GETIR
  Future<DashboardResponse> getDashboardConfiguration() async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting dashboard configuration...');

      final response = await ApiClient.post(
        '/api/Dashboard/GetDashBoardUser',
        body: {}, // Boş body, token header'da
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('[DASHBOARD_API] ✅ Dashboard configuration loaded');

        return DashboardResponse.fromJson(data);
      } else {
        throw Exception('Failed to load dashboard configuration: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Dashboard configuration error: $e');
      rethrow;
    }
  }

  /// 2. INFO WIDGET DATALARINI TOPLU ÇEK
  Future<List<WidgetDataResponse>> getInfoWidgetDataBulk({
    required List<String> sqlIds,
    required List<int> indexes,
    required List<int> widgetIds,
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting bulk INFO widget data...');
      debugPrint('[DASHBOARD_API] SQL IDs: $sqlIds');
      debugPrint('[DASHBOARD_API] Indexes: $indexes');
      debugPrint('[DASHBOARD_API] Widget IDs: $widgetIds');

      final response = await ApiClient.post(
        '/api/DynamicFormApi/GetDataTypeMultipleReport',
        body: {
          "form_PATH": null,
          "SqlIds": sqlIds,
          "indexs": indexes,
          "WidgetIds": widgetIds,
          "dashboardFilterItems": [],
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        debugPrint('[DASHBOARD_API] ✅ Bulk INFO widget data loaded: ${data.length} items');

        return data.map((item) => WidgetDataResponse.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load bulk widget data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Bulk INFO widget data error: $e');
      rethrow;
    }
  }

  /// 3. CHART WIDGET DATALARINI TOPLU ÇEK (MULTIBAR, LINE VB.)
  Future<List<WidgetDataResponse>> getChartWidgetDataBulk({
    required List<String> sqlIds,
    required List<int> indexes,
    required List<int> widgetIds,
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting bulk CHART widget data...');
      debugPrint('[DASHBOARD_API] Chart SQL IDs: $sqlIds');
      debugPrint('[DASHBOARD_API] Chart Indexes: $indexes');
      debugPrint('[DASHBOARD_API] Chart Widget IDs: $widgetIds');

      final response = await ApiClient.post(
        '/api/DynamicFormApi/GetDataTypeMultipleReport',
        body: {
          "form_PATH": null,
          "SqlIds": sqlIds,
          "WidgetIds": widgetIds,
          "indexs": indexes,
          "dashboardFilterItems": [],
          "pageSize": 0, // ✅ CHART için pageSize 0
          "useDefaultFilterDate": true, // ✅ CHART için default filter
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        debugPrint('[DASHBOARD_API] ✅ Bulk CHART widget data loaded: ${data.length} items');

        return data.map((item) => WidgetDataResponse.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load chart widget data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Bulk CHART widget data error: $e');
      rethrow;
    }
  }

  /// 4. FULL DASHBOARD DATA - INFO + CHART COMBINED
  Future<DashboardStatistics> getFullDashboardData() async {
    try {
      debugPrint('[DASHBOARD_API] 🚀 Loading full dashboard data...');

      // 1. Dashboard config al
      final dashboardConfig = await getDashboardConfiguration();

      if (dashboardConfig.dashboards.isEmpty) {
        debugPrint('[DASHBOARD_API] ⚠️ No dashboard configuration found');
        return DashboardStatistics.empty();
      }

      final mainDashboard = dashboardConfig.mainDashboard!;
      debugPrint('[DASHBOARD_API] 📋 Main dashboard: ${mainDashboard.dashboardName}');
      debugPrint('[DASHBOARD_API] 📊 Total widgets: ${mainDashboard.widgets.length}');

      // 2. Widget'ları tipine göre ayır
      final infoWidgets = mainDashboard.widgets.where((w) => w.widgetType == 'Info').toList();
      final chartWidgets = mainDashboard.widgets.where((w) => w.widgetType != 'Info').toList();

      debugPrint('[DASHBOARD_API] 📊 Info widgets: ${infoWidgets.length}');
      debugPrint('[DASHBOARD_API] 📈 Chart widgets: ${chartWidgets.length}');

      List<WidgetDataResponse> allWidgetData = [];

      // 3. INFO widget'ları için bulk data çek
      if (infoWidgets.isNotEmpty) {
        final infoSqlIds = infoWidgets.map((w) => w.sql).toList();
        final infoIndexes = infoWidgets.map((w) => w.index).toList();
        final infoWidgetIds = infoWidgets.map((w) => w.id).toList();

        debugPrint('[DASHBOARD_API] 🔄 Loading INFO widgets...');
        final infoDataList = await getInfoWidgetDataBulk(
          sqlIds: infoSqlIds,
          indexes: infoIndexes,
          widgetIds: infoWidgetIds,
        );

        allWidgetData.addAll(infoDataList);
        debugPrint('[DASHBOARD_API] ✅ INFO widgets loaded: ${infoDataList.length}');
      }

      // 4. CHART widget'ları için bulk data çek
      if (chartWidgets.isNotEmpty) {
        final chartSqlIds = chartWidgets.map((w) => w.sql).toList();
        final chartIndexes = chartWidgets.map((w) => w.index).toList();
        final chartWidgetIds = chartWidgets.map((w) => w.id).toList();

        debugPrint('[DASHBOARD_API] 🔄 Loading CHART widgets...');
        final chartDataList = await getChartWidgetDataBulk(
          sqlIds: chartSqlIds,
          indexes: chartIndexes,
          widgetIds: chartWidgetIds,
        );

        allWidgetData.addAll(chartDataList);
        debugPrint('[DASHBOARD_API] ✅ CHART widgets loaded: ${chartDataList.length}');
      }

      debugPrint('[DASHBOARD_API] 🎯 Total widget data loaded: ${allWidgetData.length}');

      // 5. Widget data'larını istatistiklere çevir
      final statistics = DashboardStatistics.fromWidgetResponses(allWidgetData);

      debugPrint('[DASHBOARD_API] ✅ Dashboard statistics created:');
      debugPrint('[DASHBOARD_API] 📊 Cards: ${statistics.cards.length}');
      debugPrint('[DASHBOARD_API] 📈 Charts: ${statistics.charts.length}');

      return statistics;
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Full dashboard data error: $e');
      rethrow;
    }
  }

  /// 5. DETAIL GRID DATA ÇEK (info box detayları için)
  Future<List<Map<String, dynamic>>> getDetailGridData({
    required String sqlId,
    required int widgetId,
    required int index,
    String gridType = "InfoBoxGrid",
    String url = "/",
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting detail grid data for SQL ID: $sqlId');

      final response = await ApiClient.post(
        '/api/DynamicFormApi/GetDataTypeMultipleReport',
        body: {
          "form_PATH": null,
          "SqlIds": [sqlId],
          "WidgetIds": [widgetId],
          "indexs": [index],
          "kendoGridAttribute": "InfoBoxGrid_$widgetId",
          "GridType": gridType,
          "url": url,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        debugPrint('[DASHBOARD_API] ✅ Detail grid data loaded: ${data.length} items');

        if (data.isNotEmpty) {
          final firstItem = data.first as Map<String, dynamic>;
          final dataSourceResult = firstItem['DataSourceResult'] as Map<String, dynamic>? ?? {};
          final gridData = dataSourceResult['Data'] as List<dynamic>? ?? [];

          return gridData.cast<Map<String, dynamic>>();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load detail grid data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Detail grid data error: $e');
      rethrow;
    }
  }

  /// 6. REFRESH DASHBOARD DATA (cache'li versiyon)
  Future<DashboardStatistics> refreshDashboardData({
    bool forceRefresh = false,
  }) async {
    try {
      // Cache logic buraya eklenebilir
      if (forceRefresh) {
        debugPrint('[DASHBOARD_API] 🔄 Force refreshing dashboard data...');
      }

      return await getFullDashboardData();
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Refresh dashboard error: $e');
      rethrow;
    }
  }

  /// 7. SPECIFIC WIDGET DATA ÇEK
  Future<WidgetDataResponse?> getSpecificWidgetData({
    required int widgetId,
    required String sqlId,
    required int index,
    bool isChart = false,
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting specific widget data: $widgetId (isChart: $isChart)');

      Map<String, dynamic> requestBody = {
        "form_PATH": null,
        "SqlIds": [sqlId],
        "indexs": [index],
        "WidgetIds": [widgetId],
        "dashboardFilterItems": [],
      };

      // Chart widget için extra parametreler
      if (isChart) {
        requestBody["pageSize"] = 0;
        requestBody["useDefaultFilterDate"] = true;
      }

      final response = await ApiClient.post(
        '/api/DynamicFormApi/GetDataTypeMultipleReport',
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data.isNotEmpty ? WidgetDataResponse.fromJson(data.first as Map<String, dynamic>) : null;
      } else {
        throw Exception('Failed to load specific widget data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Specific widget data error: $e');
      return null;
    }
  }

  /// 8. DASHBOARD HEALTH CHECK
  Future<bool> isDashboardHealthy() async {
    try {
      final config = await getDashboardConfiguration();
      return config.dashboards.isNotEmpty;
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Dashboard health check failed: $e');
      return false;
    }
  }
}
