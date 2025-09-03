// lib/presentation/providers/menu_provider.dart - ENHANCED VERSION
import 'package:flutter/foundation.dart';
import '../../data/models/menu/menu_model.dart';
import '../../data/services/api/menu_api_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuApiService _menuApiService = MenuApiService();

  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _reportMappingsLoaded = false;

  // Getters
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMenuItems => _menuItems.isNotEmpty;
  bool get reportMappingsLoaded => _reportMappingsLoaded;

  /// Load menu with enhanced report mapping
  Future<void> loadMenu() async {
    debugPrint('[MENU_PROVIDER] 🔄 Starting enhanced menu load...');

    _setLoading(true);
    _setError(null);

    try {
      // Load menu items (API will also initialize report mappings)
      final menuResponse = await _menuApiService.getUserMenu();

      debugPrint('[MENU_PROVIDER] ✅ Menu loaded: ${menuResponse.menuItems.length} items');
      debugPrint('[MENU_PROVIDER] ✅ Report mappings loaded: ${ReportGroupMapper.instance.hasMappings}');

      _menuItems = menuResponse.menuItems;
      _reportMappingsLoaded = ReportGroupMapper.instance.hasMappings;

      // Debug: Log all report-related menu items
      _debugLogReportMenus();
    } catch (error) {
      debugPrint('[MENU_PROVIDER] ❌ Menu load failed: $error');
      _setError('Menü yüklenirken hata oluştu: $error');
    } finally {
      _setLoading(false);
    }
  }

  /// Debug: Rapor menülerini logla
  void _debugLogReportMenus() {
    debugPrint('[MENU_PROVIDER] ===== REPORT MENUS DEBUG =====');

    final reportMenus = _findReportMenus(_menuItems);

    for (final menu in reportMenus) {
      final groupId = ReportGroupMapper.instance.getGroupIdByTitle(menu.cleanTitle);
      debugPrint('[MENU_PROVIDER] 📊 Report Menu: "${menu.cleanTitle}" -> Group ID: $groupId');
      debugPrint('[MENU_PROVIDER]     URL: ${menu.url}');
    }

    debugPrint('[MENU_PROVIDER] Total report menus found: ${reportMenus.length}');
    debugPrint('[MENU_PROVIDER] ================================');
  }

  /// Rapor menülerini recursive olarak bul
  List<MenuItem> _findReportMenus(List<MenuItem> items) {
    final reportMenus = <MenuItem>[];

    void findReports(MenuItem item) {
      // URL'de 'Report' geçiyorsa rapor menüsüdür
      if (item.url != null && item.url!.toLowerCase().contains('report')) {
        reportMenus.add(item);
      }

      // Title'da rapor kelimesi geçiyorsa da kontrol et
      if (item.cleanTitle.toLowerCase().contains('rapor')) {
        reportMenus.add(item);
      }

      // Recursive olarak alt menüleri kontrol et
      for (final subItem in item.items) {
        findReports(subItem);
      }
    }

    for (final item in items) {
      findReports(item);
    }

    return reportMenus;
  }

  /// Force reload report mappings
  Future<void> reloadReportMappings() async {
    try {
      debugPrint('[MENU_PROVIDER] 🔄 Reloading report mappings...');

      // Clear current mappings
      ReportGroupMapper.instance.updateMappings({});

      // Reload menu (will also reload report mappings)
      await loadMenu();

      debugPrint('[MENU_PROVIDER] ✅ Report mappings reloaded');
    } catch (error) {
      debugPrint('[MENU_PROVIDER] ❌ Report mappings reload failed: $error');
    }
  }

  /// Get report menu items only
  List<MenuItem> getReportMenuItems() {
    return _findReportMenus(_menuItems);
  }

  /// Get menu item by title (case insensitive)
  MenuItem? findMenuItemByTitle(String title) {
    MenuItem? findRecursive(List<MenuItem> items, String searchTitle) {
      for (final item in items) {
        if (item.cleanTitle.toLowerCase() == searchTitle.toLowerCase()) {
          return item;
        }

        final found = findRecursive(item.items, searchTitle);
        if (found != null) return found;
      }
      return null;
    }

    return findRecursive(_menuItems, title);
  }

  /// Get menu item by URL pattern
  MenuItem? findMenuItemByUrl(String urlPattern) {
    MenuItem? findRecursive(List<MenuItem> items, String pattern) {
      for (final item in items) {
        if (item.url != null && item.url!.contains(pattern)) {
          return item;
        }

        final found = findRecursive(item.items, pattern);
        if (found != null) return found;
      }
      return null;
    }

    return findRecursive(_menuItems, urlPattern);
  }

  /// Search menu items by keyword
  List<MenuItem> searchMenuItems(String keyword) {
    final results = <MenuItem>[];
    final lowerKeyword = keyword.toLowerCase();

    void searchRecursive(List<MenuItem> items) {
      for (final item in items) {
        if (item.cleanTitle.toLowerCase().contains(lowerKeyword)) {
          results.add(item);
        }
        searchRecursive(item.items);
      }
    }

    searchRecursive(_menuItems);
    return results;
  }

  /// Get menu statistics
  MenuStatistics getStatistics() {
    int totalItems = 0;
    int reportItems = 0;
    int formItems = 0;
    int listItems = 0;
    int attachmentItems = 0;

    void countRecursive(List<MenuItem> items) {
      for (final item in items) {
        totalItems++;

        if (item.url != null) {
          final url = item.url!.toLowerCase();
          if (url.contains('report')) reportItems++;
          if (url.contains('detail')) formItems++;
          if (url.contains('list')) listItems++;
          if (url.contains('attachment')) attachmentItems++;
        }

        countRecursive(item.items);
      }
    }

    countRecursive(_menuItems);

    return MenuStatistics(
      totalItems: totalItems,
      reportItems: reportItems,
      formItems: formItems,
      listItems: listItems,
      attachmentItems: attachmentItems,
      reportMappingsCount: ReportGroupMapper.instance.allMappings.length,
    );
  }

  /// Clear menu data
  void clearMenu() {
    _menuItems.clear();
    _reportMappingsLoaded = false;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }
}

/// Menu statistics model
class MenuStatistics {
  final int totalItems;
  final int reportItems;
  final int formItems;
  final int listItems;
  final int attachmentItems;
  final int reportMappingsCount;

  MenuStatistics({
    required this.totalItems,
    required this.reportItems,
    required this.formItems,
    required this.listItems,
    required this.attachmentItems,
    required this.reportMappingsCount,
  });

  @override
  String toString() {
    return '''MenuStatistics:
  Total Items: $totalItems
  Report Items: $reportItems
  Form Items: $formItems
  List Items: $listItems
  Attachment Items: $attachmentItems
  Report Mappings: $reportMappingsCount''';
  }
}
