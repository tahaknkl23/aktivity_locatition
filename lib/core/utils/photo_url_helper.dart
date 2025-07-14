import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class PhotoUrlHelper {
  static String? _currentSubdomain;

  /// Initialize subdomain from SharedPreferences
  static Future<void> initializeSubdomain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentSubdomain = prefs.getString('subdomain');
      debugPrint('[PhotoUrlHelper] Initialized with subdomain: $_currentSubdomain');
    } catch (e) {
      debugPrint('[PhotoUrlHelper] Error initializing: $e');
      _currentSubdomain = null;
    }
  }

  /// Update current subdomain
  static void updateSubdomain(String subdomain) {
    _currentSubdomain = subdomain;
    debugPrint('[PhotoUrlHelper] Updated subdomain: $subdomain');
  }

  /// Fix photo URL to full URL with current subdomain
  static String? fixPhotoUrl(String? photoPath) {
    if (photoPath == null || photoPath.isEmpty) {
      return null;
    }

    // If already a full URL, return as is
    if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
      return photoPath;
    }

    // Get current subdomain
    if (_currentSubdomain == null || _currentSubdomain!.isEmpty) {
      debugPrint('[PhotoUrlHelper] No subdomain available for photo: $photoPath');
      return null;
    }

    // Clean the path
    String cleanPath = photoPath;
    if (cleanPath.startsWith('./')) {
      cleanPath = cleanPath.substring(2);
    }
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }

    // Build full URL
    final fullUrl = 'https://$_currentSubdomain.veribiscrm.com$cleanPath';
    debugPrint('[PhotoUrlHelper] Fixed photo URL: $photoPath -> $fullUrl');
    
    return fullUrl;
  }

  /// Get current subdomain
  static String? getCurrentSubdomain() {
    return _currentSubdomain;
  }

  /// Check if photo URL helper is initialized
  static bool get isInitialized => _currentSubdomain != null;
}