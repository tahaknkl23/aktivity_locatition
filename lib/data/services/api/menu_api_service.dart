// lib/data/services/api/menu_api_service.dart - ENHANCED VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../data/models/menu/menu_model.dart';
import 'api_client.dart';

class MenuApiService {
  /// Kullanıcı menüsünü getir - ENHANCED VERSION
  Future<MenuResponse> getUserMenu() async {
    try {
      debugPrint('[MENU_API] 📋 Getting user menu...');

      final response = await ApiClient.post(
        '/api/Layout/GetUserSiteMenu',
        body: {},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          final menuResponse = MenuResponse.fromJson(data);

          // Menu yüklendikten sonra report mappings'i al
          await _loadReportMappings(menuResponse);

          return menuResponse;
        } else {
          throw Exception('Expected List but got ${data.runtimeType}');
        }
      } else {
        throw Exception('Failed to load menu: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[MENU_API] ❌ Exception: $e');
      rethrow;
    }
  }

  /// 🆕 Rapor grup mappings'lerini yükle
  Future<void> _loadReportMappings(MenuResponse menuResponse) async {
    try {
      debugPrint('[MENU_API] 🔄 Loading report mappings...');

      // Method 1: Rapor gruplarını API'den al
      final mappings = await _getReportGroupMappings();

      // Method 2: Menu items'ları analiz et
      final menuMappings = _extractReportMappingsFromMenu(menuResponse.menuItems);

      // İki kaynağı birleştir
      final combinedMappings = {...mappings, ...menuMappings};

      // Global mapping'e kaydet
      ReportGroupMapper.instance.updateMappings(combinedMappings);

      debugPrint('[MENU_API] ✅ Report mappings loaded: ${combinedMappings.length} items');
    } catch (e) {
      debugPrint('[MENU_API] ❌ Failed to load report mappings: $e');
      // Hata durumunda varsayılan mappings kullan
      ReportGroupMapper.instance.loadDefaultMappings();
    }
  }

  /// API'den rapor grup mappings'lerini al
  Future<Map<String, String>> _getReportGroupMappings() async {
    try {
      // Önce tüm rapor gruplarını dene
      final response = await ApiClient.get('/api/ReportApi/GetReportGroups');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        final mappings = <String, String>{};

        for (final group in data) {
          final id = group['Id']?.toString();
          final name = group['Name'] as String?;

          if (id != null && name != null) {
            mappings[name.toLowerCase()] = id;
          }
        }

        debugPrint('[MENU_API] ✅ API mappings loaded: ${mappings.length}');
        return mappings;
      }
    } catch (e) {
      debugPrint('[MENU_API] ❌ API mappings failed: $e');
    }

    return {};
  }

  /// Menu items'lardan report mappings çıkar
  Map<String, String> _extractReportMappingsFromMenu(List<MenuItem> items) {
    final mappings = <String, String>{};

    void extractFromItem(MenuItem item) {
      // URL'den Group ID çıkarmaya çalış
      if (item.url != null && item.url!.contains('Report')) {
        final groupId = _extractGroupIdFromUrl(item.url!);
        if (groupId != null) {
          mappings[item.cleanTitle.toLowerCase()] = groupId;
          debugPrint('[MENU_API] 📊 Found mapping: ${item.cleanTitle} -> $groupId');
        }
      }

      // Recursive olarak sub-items'ları da kontrol et
      for (final subItem in item.items) {
        extractFromItem(subItem);
      }
    }

    for (final item in items) {
      extractFromItem(item);
    }

    debugPrint('[MENU_API] ✅ Menu mappings extracted: ${mappings.length}');
    return mappings;
  }

  /// URL'den Group ID çıkar - ENHANCED
  String? _extractGroupIdFromUrl(String url) {
    try {
      // Pattern 1: /Report/Group/12 gibi
      final groupPattern = RegExp(r'/Report/Group/(\d+)');
      final groupMatch = groupPattern.firstMatch(url);
      if (groupMatch != null) {
        return groupMatch.group(1);
      }

      // Pattern 2: ?GroupId=12 gibi
      final uri = Uri.parse(url);
      final groupId = uri.queryParameters['GroupId'] ?? uri.queryParameters['groupId'] ?? uri.queryParameters['group'];
      if (groupId != null) {
        return groupId;
      }

      // Pattern 3: MenuTitle'dan çıkar
      final menuTitle = uri.queryParameters['MenuTitle'];
      if (menuTitle != null) {
        return ReportGroupMapper.instance.getGroupIdByTitle(menuTitle);
      }
    } catch (e) {
      debugPrint('[MENU_API] URL parse error: $e');
    }

    return null;
  }

  /// 🆕 Belirli bir rapor grubu için metadata al
  Future<ReportGroupMetadata?> getReportGroupMetadata(String groupId) async {
    try {
      final response = await ApiClient.get('/api/ReportApi/GetGroupInfo/$groupId');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ReportGroupMetadata.fromJson(data);
      }
    } catch (e) {
      debugPrint('[MENU_API] Group metadata error: $e');
    }

    return null;
  }
}

/// 🆕 Report Group Mapper - Singleton
class ReportGroupMapper {
  static final ReportGroupMapper _instance = ReportGroupMapper._internal();
  static ReportGroupMapper get instance => _instance;
  ReportGroupMapper._internal();

  final Map<String, String> _titleToGroupId = {};
  final Map<String, String> _groupIdToTitle = {};

  void updateMappings(Map<String, String> mappings) {
    _titleToGroupId.clear();
    _groupIdToTitle.clear();

    mappings.forEach((title, groupId) {
      _titleToGroupId[title.toLowerCase()] = groupId;
      _groupIdToTitle[groupId] = title;
    });

    debugPrint('[REPORT_MAPPER] Updated with ${mappings.length} mappings');
  }

  String? getGroupIdByTitle(String title) {
    final result = _titleToGroupId[title.toLowerCase()];
    debugPrint('[REPORT_MAPPER] Lookup: "$title" -> $result');
    return result;
  }

  String? getTitleByGroupId(String groupId) {
    return _groupIdToTitle[groupId];
  }

  void loadDefaultMappings() {
    debugPrint('[REPORT_MAPPER] Loading default mappings...');

    final defaultMappings = <String, String>{
      // Varsayılan mappings - gerçek API'den gelecek verilerle güncellenecek
      'aktivite raporları': '5',
      'activity reports': '5',
      'ziyaret raporları': '5',

      'kişi raporları': '11',
      'contact reports': '11',
      'müşteri raporları': '11',

      'firma raporları': '12',
      'company reports': '12',
      'şirket raporları': '12',

      'satış raporları': '66',
      'sales reports': '66',

      // Daha fazla mapping buraya eklenecek
    };

    updateMappings(defaultMappings);
  }

  Map<String, String> get allMappings => Map.unmodifiable(_titleToGroupId);

  bool get hasMappings => _titleToGroupId.isNotEmpty;
}

/// 🆕 Report Group Metadata
class ReportGroupMetadata {
  final String id;
  final String name;
  final String description;
  final int reportCount;

  ReportGroupMetadata({
    required this.id,
    required this.name,
    required this.description,
    required this.reportCount,
  });

  factory ReportGroupMetadata.fromJson(Map<String, dynamic> json) {
    return ReportGroupMetadata(
      id: json['Id']?.toString() ?? '',
      name: json['Name'] as String? ?? '',
      description: json['Description'] as String? ?? '',
      reportCount: json['ReportCount'] as int? ?? 0,
    );
  }
}
