// lib/data/services/api/api_client.dart - ENHANCED TOKEN HANDLING
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/session_timeout_service.dart';

class ApiClient {
  static const Duration _timeout = Duration(minutes: 10);
  static DateTime? _lastTokenCheck;
  static const Duration _tokenCheckInterval = Duration(minutes: 1);

  // Global navigation context for auto-logout
  static BuildContext? _navigatorContext;

  // Set navigator context for auto-logout
  static void setNavigatorContext(BuildContext context) {
    _navigatorContext = context;
    debugPrint('[API_CLIENT] Navigator context set for auto-logout');
  }

  /// ENHANCED HEADER GENERATION
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token.isNotEmpty) {
        // ENHANCED: Check token validity before using
        final isValid = await _validateTokenExpiration();
        if (!isValid) {
          debugPrint('[API_CLIENT] Token expired during header generation');
          // Clear expired token immediately
          await _clearAuthData();
          // Trigger logout navigation
          _navigateToLogin();
          throw ApiException('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
        }

        headers['Authorization'] = 'Bearer $token';
        debugPrint('[API_CLIENT] Valid token added to headers');
      } else {
        debugPrint('[API_CLIENT] No token found - user needs to login');
        _navigateToLogin();
        throw ApiException('Oturum bulunamadı. Lütfen giriş yapın.');
      }

      return headers;
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      debugPrint('[API_CLIENT] Header generation error: $e');
      throw ApiException('İstek hazırlanırken hata oluştu: $e');
    }
  }

  /// ENHANCED TOKEN VALIDATION
  static Future<bool> _validateTokenExpiration() async {
    try {
      final now = DateTime.now();

      // Rate limiting check
      if (_lastTokenCheck != null && now.difference(_lastTokenCheck!) < _tokenCheckInterval) {
        return true; // Skip frequent checks
      }

      _lastTokenCheck = now;

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final expirationStr = prefs.getString('token_expiration');

      if (token == null || token.isEmpty) {
        debugPrint('[API_CLIENT] No token found during validation');
        return false;
      }

      if (expirationStr != null && expirationStr.isNotEmpty) {
        try {
          final expiration = DateTime.parse(expirationStr);

          if (now.isAfter(expiration)) {
            debugPrint('[API_CLIENT] Token expired: $expiration vs $now');
            return false;
          }

          // Warning for tokens expiring soon (5 minutes)
          final remaining = expiration.difference(now);
          if (remaining.inMinutes <= 5) {
            debugPrint('[API_CLIENT] Token expiring soon: ${remaining.inMinutes}m');
          }

          return true;
        } catch (e) {
          debugPrint('[API_CLIENT] Token expiration parse error: $e');
          return false;
        }
      }

      // No expiration data - token might be valid but risky
      debugPrint('[API_CLIENT] No expiration data found');
      return true;
    } catch (e) {
      debugPrint('[API_CLIENT] Token validation error: $e');
      return false;
    }
  }

  /// BASE URL GENERATION
  static Future<String> _getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Try stored base URL first
      String? baseUrl = prefs.getString('base_url');
      if (baseUrl != null && baseUrl.isNotEmpty) {
        debugPrint('[API_CLIENT] Using stored base URL: $baseUrl');
        return baseUrl;
      }

      // Fallback to subdomain
      final subdomain = prefs.getString('subdomain') ?? '';
      if (subdomain.isEmpty) {
        throw ApiException('Domain bilgisi bulunamadı. Lütfen giriş ekranından tekrar başlayın.');
      }

      baseUrl = _buildBaseUrlFromSubdomain(subdomain);
      debugPrint('[API_CLIENT] Built base URL from subdomain: $baseUrl');
      return baseUrl;
    } catch (e) {
      debugPrint('[API_CLIENT] Base URL error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('API URL oluşturulamadı: $e');
    }
  }

  static String _buildBaseUrlFromSubdomain(String subdomain) {
    if (subdomain.startsWith('http://') || subdomain.startsWith('https://')) {
      return subdomain;
    }
    if (subdomain.contains(':') && !subdomain.contains('://')) {
      return 'http://$subdomain';
    }
    if (subdomain.contains('.') && !subdomain.contains('veribiscrm.com')) {
      return 'https://$subdomain';
    }
    if (subdomain.contains('.veribiscrm.com')) {
      return 'https://$subdomain';
    }
    return 'https://$subdomain.veribiscrm.com';
  }

  /// ENHANCED POST REQUEST
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      SessionTimeoutService.instance.recordActivity();

      final baseUrl = await _getBaseUrl();
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');

      debugPrint("[API] POST: $url");
      debugPrint("[API] Body keys: ${body?.keys.toList() ?? 'empty'}");

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body ?? {}),
          )
          .timeout(_timeout);

      debugPrint("[API] Status: ${response.statusCode}");

      // Log response preview
      final responsePreview = response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body;
      debugPrint("[API] Response preview: $responsePreview");

      // ENHANCED status handling
      await _handleResponseStatus(response);

      return response;
    } on SocketException {
      throw ApiException('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException {
      throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint("[API] POST Error: $e");
      throw ApiException('İstek başarısız oldu: ${e.toString()}');
    }
  }

  /// ENHANCED GET REQUEST
  static Future<http.Response> get(String endpoint) async {
    try {
      SessionTimeoutService.instance.recordActivity();

      final baseUrl = await _getBaseUrl();
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');

      debugPrint("[API] GET: $url");

      final response = await http.get(url, headers: headers).timeout(_timeout);

      debugPrint("[API] Status: ${response.statusCode}");

      final responsePreview = response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body;
      debugPrint("[API] Response preview: $responsePreview");

      await _handleResponseStatus(response);

      return response;
    } on SocketException {
      throw ApiException('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException {
      throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } on ApiException {
      rethrow;
    } catch (e) {
      debugPrint("[API] GET Error: $e");
      throw ApiException('İstek başarısız oldu: ${e.toString()}');
    }
  }

  /// ENHANCED RESPONSE STATUS HANDLING
  static Future<void> _handleResponseStatus(http.Response response) async {
    switch (response.statusCode) {
      case 200:
      case 201:
        SessionTimeoutService.instance.recordActivity();
        break;

      case 401:
        debugPrint('[API_CLIENT] 401 Unauthorized - Handling token expiration');
        await _handleTokenExpiration();
        throw ApiException('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');

      case 403:
        throw ApiException('Bu işlem için yetkiniz bulunmuyor.');

      case 404:
        throw ApiException('İstenen kaynak bulunamadı.');

      case 408:
        throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');

      case 429:
        throw ApiException('Çok fazla istek gönderildi. Lütfen bekleyin.');

      case 500:
        throw ApiException('Sunucu hatası. Lütfen daha sonra tekrar deneyin.');

      case 502:
      case 503:
      case 504:
        throw ApiException('Servis geçici olarak kullanılamıyor. Lütfen tekrar deneyin.');

      default:
        String errorDetail = '';
        try {
          final errorBody = jsonDecode(response.body);
          errorDetail = errorBody['message'] ?? errorBody['error'] ?? '';
        } catch (e) {
          // Ignore parsing error
        }

        final errorMessage = errorDetail.isNotEmpty
            ? 'Hata (${response.statusCode}): $errorDetail'
            : 'Bilinmeyen hata (${response.statusCode}). Lütfen tekrar deneyin.';

        throw ApiException(errorMessage);
    }
  }

  /// ENHANCED TOKEN EXPIRATION HANDLER
  static Future<void> _handleTokenExpiration() async {
    try {
      debugPrint('[API_CLIENT] Handling token expiration - clearing all auth data');

      // Clear all auth data
      await _clearAuthData();

      // Stop session timeout service
      SessionTimeoutService.instance.stop();

      // Navigate to login
      _navigateToLogin();
    } catch (e) {
      debugPrint('[API_CLIENT] Error handling token expiration: $e');
    }
  }

  /// CLEAR AUTH DATA
  static Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('token_expiration');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      await prefs.remove('full_name');
      await prefs.remove('picture_url');

      _lastTokenCheck = null;
      debugPrint('[API_CLIENT] All auth data cleared');
    } catch (e) {
      debugPrint('[API_CLIENT] Error clearing auth data: $e');
    }
  }

  /// NAVIGATE TO LOGIN
  static void _navigateToLogin() {
    if (_navigatorContext != null) {
      try {
        debugPrint('[API_CLIENT] Navigating to login screen');

        // Navigate and clear all previous routes
        Navigator.of(_navigatorContext!).pushNamedAndRemoveUntil(
          '/login', // Adjust this route name to match your login route
          (route) => false,
        );
      } catch (e) {
        debugPrint('[API_CLIENT] Navigation error: $e');
      }
    } else {
      debugPrint('[API_CLIENT] Cannot navigate - no navigator context set');
    }
  }

  /// TOKEN VALIDATION (PUBLIC)
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final expirationStr = prefs.getString('token_expiration');

      if (token == null || token.isEmpty) {
        return false;
      }

      if (expirationStr != null && expirationStr.isNotEmpty) {
        try {
          final expiration = DateTime.parse(expirationStr);
          final now = DateTime.now();

          if (now.isAfter(expiration)) {
            debugPrint('[API_CLIENT] Token expired during public validation');
            await _clearAuthData();
            return false;
          }
        } catch (e) {
          debugPrint('[API_CLIENT] Token expiration parse error: $e');
          return false;
        }
      }

      return true;
    } catch (e) {
      debugPrint('[API_CLIENT] Token validation error: $e');
      return false;
    }
  }

  /// DOMAIN VALIDATION
  static Future<bool> isDomainValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('base_url');
      final subdomain = prefs.getString('subdomain');

      return (baseUrl != null && baseUrl.isNotEmpty) || (subdomain != null && subdomain.isNotEmpty);
    } catch (e) {
      debugPrint('[API_CLIENT] Domain validation error: $e');
      return false;
    }
  }

  /// TOKEN INFO
  static Future<TokenExpirationInfo?> getTokenExpirationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expirationStr = prefs.getString('token_expiration');

      if (expirationStr == null || expirationStr.isEmpty) return null;

      final expiration = DateTime.parse(expirationStr);
      final now = DateTime.now();
      final remaining = expiration.difference(now);

      return TokenExpirationInfo(
        expirationTime: expiration,
        remainingTime: remaining,
        isExpired: remaining.isNegative,
        isExpiringSoon: remaining.inMinutes < 5,
      );
    } catch (e) {
      debugPrint('[API_CLIENT] Get expiration info error: $e');
      return null;
    }
  }

  /// FORCE LOGOUT
  static Future<void> forceLogout() async {
    try {
      debugPrint('[API_CLIENT] Force logout initiated');
      await _handleTokenExpiration();
    } catch (e) {
      debugPrint('[API_CLIENT] Force logout error: $e');
    }
  }
}

/// API EXCEPTION
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;

  bool get isNetworkError => message.contains('bağlantı') || message.contains('internet') || message.contains('timeout');

  bool get isAuthError => statusCode == 401 || message.contains('oturum') || message.contains('giriş');

  bool get isServerError => statusCode != null && statusCode! >= 500;
}

/// TIMEOUT EXCEPTION
class TimeoutException implements Exception {
  final String message;
  final Duration duration;

  TimeoutException(this.message, this.duration);

  @override
  String toString() => message;
}

/// TOKEN EXPIRATION INFO
class TokenExpirationInfo {
  final DateTime expirationTime;
  final Duration remainingTime;
  final bool isExpired;
  final bool isExpiringSoon;

  TokenExpirationInfo({
    required this.expirationTime,
    required this.remainingTime,
    required this.isExpired,
    required this.isExpiringSoon,
  });

  String get formattedRemainingTime {
    if (isExpired) return 'Süresi dolmuş';

    final minutes = remainingTime.inMinutes;
    final seconds = remainingTime.inSeconds % 60;

    if (minutes > 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}s ${remainingMinutes}d';
    } else if (minutes > 0) {
      return '${minutes}d ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
