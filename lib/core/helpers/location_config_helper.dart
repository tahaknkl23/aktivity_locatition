// lib/core/helpers/location_config_helper.dart
import 'package:flutter/material.dart';

/// 🎯 LOCATION FEATURES CONTROLLER
/// Form URL'sine ve Controller'a göre konum özelliklerini kontrol eder
/// Mevcut sistemi bozmadan modüler yapı sağlar

class LocationConfigHelper {
  /// Form URL'sine göre konum özelliklerinin aktif olup olmadığını kontrol et
  static bool shouldShowLocationFeatures(String? formUrl, String? controller) {
    if (formUrl == null && controller == null) return false;

    // 🎯 AUTOMATIC DETECTION: URL ve Controller bazında otomatik karar

    // 🔧 KONUM ÖZELLİKLERİ AKTİF OLAN FORM URL'LERİ (Branch aktiviteler)
    final locationEnabledUrls = [
      '/Dyn/AktiviteBranchAdd/Detail', // ✅ Branch aktiviteler - Konum aktif
      // Normal aktiviteler için URL yok - otomatik kapalı
    ];

    // 🔧 KONUM ÖZELLİKLERİ AKTİF OLAN CONTROLLER'LAR (Branch aktiviteler)
    final locationEnabledControllers = [
      'AktiviteBranchAdd', // ✅ Branch aktiviteler - Konum aktif
      // 'AktiviteAdd' - Normal aktiviteler kapalı
    ];

    // URL kontrolü (öncelikli)
    if (formUrl != null) {
      final urlMatch = locationEnabledUrls.any((url) => formUrl.contains(url));
      if (urlMatch) {
        debugPrint('[LOCATION_CONFIG] ✅ Location enabled for URL: $formUrl (BRANCH ACTIVITY)');
        return true;
      }

      // Normal aktivite URL'si kontrolü
      if (formUrl.contains('/Dyn/AktiviteAdd/Detail')) {
        debugPrint('[LOCATION_CONFIG] ❌ Location disabled for URL: $formUrl (NORMAL ACTIVITY)');
        return false;
      }
    }

    // Controller kontrolü (ikincil)
    if (controller != null) {
      final controllerMatch = locationEnabledControllers.any((ctrl) => controller.contains(ctrl));
      if (controllerMatch) {
        debugPrint('[LOCATION_CONFIG] ✅ Location enabled for Controller: $controller (BRANCH ACTIVITY)');
        return true;
      }

      // Normal aktivite controller kontrolü
      if (controller.contains('AktiviteAdd') && !controller.contains('AktiviteBranchAdd')) {
        debugPrint('[LOCATION_CONFIG] ❌ Location disabled for Controller: $controller (NORMAL ACTIVITY)');
        return false;
      }
    }

    debugPrint('[LOCATION_CONFIG] ❌ Location disabled - no match for URL: $formUrl, Controller: $controller');
    return false;
  }

  /// Adres enrichment özelliğinin aktif olup olmadığını kontrol et
  static bool shouldEnrichWithAddress(String? controller) {
    if (controller == null) return false;

    final addressEnrichmentControllers = [
      'AktiviteAdd',
      'AktiviteBranchAdd',
    ];

    final shouldEnrich = addressEnrichmentControllers.any((ctrl) => controller.toLowerCase().contains(ctrl.toLowerCase()));

    debugPrint('[LOCATION_CONFIG] Address enrichment for $controller: $shouldEnrich');
    return shouldEnrich;
  }

  /// Branch comparison özelliğinin aktif olup olmadığını kontrol et
  static bool shouldCompareBranchLocation(String? controller) {
    if (controller == null) return false;

    final branchComparisonControllers = [
      'AktiviteBranchAdd', // Branch kelimesi olan aktiviteler için aktif
    ];

    final shouldCompare = branchComparisonControllers.any((ctrl) => controller.toLowerCase().contains(ctrl.toLowerCase()));

    debugPrint('[LOCATION_CONFIG] Branch comparison for $controller: $shouldCompare');
    return shouldCompare;
  }

  /// Konum takibi gerektiren action'lar
  static bool requiresLocationForAction(String? controller, String? action) {
    if (controller == null) return false;

    // Sadece aktivite ekleme/düzenleme formlarında konum gerekli
    if (!shouldShowLocationFeatures(null, controller)) return false;

    // Detail action'ında (form sayfasında) konum gerekli
    return action?.toLowerCase() == 'detail';
  }

  /// Debug: Tüm location ayarlarını logla
  static void debugLocationSettings(String? formUrl, String? controller, String? action) {
    debugPrint('[LOCATION_CONFIG] ===== LOCATION SETTINGS DEBUG =====');
    debugPrint('[LOCATION_CONFIG] Form URL: $formUrl');
    debugPrint('[LOCATION_CONFIG] Controller: $controller');
    debugPrint('[LOCATION_CONFIG] Action: $action');
    debugPrint('[LOCATION_CONFIG] Show Location Features: ${shouldShowLocationFeatures(formUrl, controller)}');
    debugPrint('[LOCATION_CONFIG] Enrich Address: ${shouldEnrichWithAddress(controller)}');
    debugPrint('[LOCATION_CONFIG] Compare Branch: ${shouldCompareBranchLocation(controller)}');
    debugPrint('[LOCATION_CONFIG] Requires Location: ${requiresLocationForAction(controller, action)}');
    debugPrint('[LOCATION_CONFIG] =========================================');
  }

  /// Backend'e göndermek için ayarları al
  static Map<String, bool> getLocationSettingsForBackend(String? controller, String? formUrl) {
    return {
      'hasLocationFeatures': shouldShowLocationFeatures(formUrl, controller),
      'hasAddressEnrichment': shouldEnrichWithAddress(controller),
      'hasBranchComparison': shouldCompareBranchLocation(controller),
    };
  }
}
