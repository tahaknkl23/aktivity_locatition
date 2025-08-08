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

  /// 2. WIDGET DATALARINI TOPLU ÇEK
  Future<List<WidgetDataResponse>> getWidgetDataBulk({
    required List<String> sqlIds,
    required List<int> indexes,
    required List<int> widgetIds,
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting bulk widget data...');
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
        debugPrint('[DASHBOARD_API] ✅ Bulk widget data loaded: ${data.length} items');

        return data.map((item) => WidgetDataResponse.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load bulk widget data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Bulk widget data error: $e');
      rethrow;
    }
  }

  /// 3. CHART DATA ÇEK (MultiBar vb. için)
  Future<WidgetDataResponse> getChartData({
    required String sqlId,
    required int widgetId,
    required int index,
    int pageSize = 0,
    bool useDefaultFilterDate = true,
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting chart data for SQL ID: $sqlId');

      final response = await ApiClient.post(
        '/api/DynamicFormApi/GetDataTypeMultipleReport',
        body: {
          "form_PATH": null,
          "SqlIds": [sqlId],
          "WidgetIds": [widgetId],
          "indexs": [index],
          "dashboardFilterItems": [],
          "pageSize": pageSize,
          "useDefaultFilterDate": useDefaultFilterDate,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        debugPrint('[DASHBOARD_API] ✅ Chart data loaded');

        if (data.isNotEmpty) {
          return WidgetDataResponse.fromJson(data.first as Map<String, dynamic>);
        } else {
          return WidgetDataResponse.empty();
        }
      } else {
        throw Exception('Failed to load chart data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Chart data error: $e');
      rethrow;
    }
  }

  /// 4. DETAIL GRID DATA ÇEK (info box detayları için)
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

  /// 5. FULL DASHBOARD DATA - COMPLETE ÇÖZÜM
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
      final infoWidgets = mainDashboard.widgets.where((w) => w.widgetType == 'Info').toList();

      if (infoWidgets.isEmpty) {
        debugPrint('[DASHBOARD_API] ⚠️ No info widgets found');
        return DashboardStatistics.empty();
      }

      // 2. Info widget'ları için bulk data çek
      final sqlIds = infoWidgets.map((w) => w.sql).toList();
      final indexes = infoWidgets.map((w) => w.index).toList();
      final widgetIds = infoWidgets.map((w) => w.id).toList();

      final widgetDataList = await getWidgetDataBulk(
        sqlIds: sqlIds,
        indexes: indexes,
        widgetIds: widgetIds,
      );

      // 3. Chart widget'ları için ayrı çek (varsa)
      final chartWidgets = mainDashboard.widgets.where((w) => w.widgetType != 'Info').toList();
      final chartDataList = <WidgetDataResponse>[];

      for (final chartWidget in chartWidgets) {
        try {
          final chartData = await getChartData(
            sqlId: chartWidget.sql,
            widgetId: chartWidget.id,
            index: chartWidget.index,
          );
          chartDataList.add(chartData);
        } catch (e) {
          debugPrint('[DASHBOARD_API] ⚠️ Chart widget ${chartWidget.id} failed: $e');
        }
      }

      // 4. Tüm data'yı birleştir
      final allWidgetData = [...widgetDataList, ...chartDataList];

      debugPrint('[DASHBOARD_API] ✅ Full dashboard data loaded: ${allWidgetData.length} widgets');

      return DashboardStatistics.fromWidgetResponses(allWidgetData);
    } catch (e) {
      debugPrint('[DASHBOARD_API] ❌ Full dashboard data error: $e');
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
  }) async {
    try {
      debugPrint('[DASHBOARD_API] 📊 Getting specific widget data: $widgetId');

      final dataList = await getWidgetDataBulk(
        sqlIds: [sqlId],
        indexes: [index],
        widgetIds: [widgetId],
      );

      return dataList.isNotEmpty ? dataList.first : null;
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
