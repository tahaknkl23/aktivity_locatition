// lib/presentation/providers/menu_provider.dart
import 'package:flutter/material.dart';
import '../../data/models/menu/menu_model.dart';
import '../../data/services/api/menu_api_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuApiService _menuApiService = MenuApiService();

  List<MenuItem> _menuItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<MenuItem> get menuItems => _menuItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMenuItems => _menuItems.isNotEmpty;

  /// Menüyü yükle
  Future<void> loadMenu() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      debugPrint('[MENU_PROVIDER] 📋 Loading user menu...');

      final menuResponse = await _menuApiService.getUserMenu();
      _menuItems = menuResponse.menuItems;

      debugPrint('[MENU_PROVIDER] ✅ Menu loaded: ${_menuItems.length} items');
    } catch (e) {
      _errorMessage = 'Menü yüklenirken hata oluştu: $e';
      debugPrint('[MENU_PROVIDER] ❌ Error loading menu: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Menüyü temizle (logout için)
  void clearMenu() {
    _menuItems.clear();
    _clearError();
    notifyListeners();
  }

  /// Belirli bir menü öğesini bul
  MenuItem? findMenuItemByUrl(String url) {
    return _findMenuItemRecursive(_menuItems, url);
  }

  MenuItem? _findMenuItemRecursive(List<MenuItem> items, String url) {
    for (final item in items) {
      if (item.url == url) return item;

      if (item.hasChildren) {
        final found = _findMenuItemRecursive(item.items, url);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Ana menü kategorilerini getir (parent menüler)
  List<MenuItem> get mainMenuCategories {
    return _menuItems.where((item) => item.hasChildren).toList();
  }

  /// Navigasyon yapılabilir menü öğelerini getir
  List<MenuItem> get navigableMenuItems {
    final List<MenuItem> navigableItems = [];
    _collectNavigableItems(_menuItems, navigableItems);
    return navigableItems;
  }

  void _collectNavigableItems(List<MenuItem> items, List<MenuItem> result) {
    for (final item in items) {
      if (item.isNavigable) {
        result.add(item);
      }
      if (item.hasChildren) {
        _collectNavigableItems(item.items, result);
      }
    }
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
