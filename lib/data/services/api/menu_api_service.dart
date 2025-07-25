// lib/data/services/api/menu_api_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../data/models/menu/menu_model.dart';
import 'api_client.dart';

class MenuApiService {
  /// Kullanıcı menüsünü getir
  Future<MenuResponse> getUserMenu() async {
    try {
      debugPrint('[MENU_API] 📋 Getting user menu...');

      final response = await ApiClient.post(
        '/api/Layout/GetUserSiteMenu',
        body: {}, // Boş body gönder, token header'da
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;

        debugPrint('[MENU_API] ✅ Menu loaded: ${data.length} main items');

        return MenuResponse.fromJson(data);
      } else {
        throw Exception('Failed to load menu: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[MENU_API] ❌ Load menu error: $e');
      rethrow;
    }
  }
}
