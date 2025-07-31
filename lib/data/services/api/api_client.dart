// api_client.dart - CRYPTO DEPENDENCY REMOVED
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/session_timeout_service.dart';

class ApiClient {
  static const Duration _timeout = Duration(minutes: 10);

  // 🔥 REQUEST DEDUPLICATION - Aynı request'leri engelle (Simplified)
  static final Map<String, DateTime> _recentRequests = {};
  static const Duration _requestCooldown = Duration(seconds: 2);

  /// ✅ GÜVENLİ HEADER OLUŞTURMA
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
        debugPrint('[API_CLIENT] Token added to headers');
      } else {
        debugPrint('[API_CLIENT] ⚠️ No token found');
      }

      return headers;
    } catch (e) {
      debugPrint('[API_CLIENT] Header error: $e');
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
    }
  }

  /// ✅ GÜVENLİ BASE URL OLUŞTURMA
  static Future<String> _getBaseUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subdomain = prefs.getString('subdomain') ?? '';

      if (subdomain.isEmpty) {
        throw ApiException('Domain bilgisi bulunamadı. Lütfen tekrar giriş yapın.');
      }

      final baseUrl = 'https://$subdomain.veribiscrm.com';
      debugPrint('[API_CLIENT] Base URL: $baseUrl');
      return baseUrl;
    } catch (e) {
      debugPrint('[API_CLIENT] Base URL error: $e');
      if (e is ApiException) {
        rethrow;
      }
      throw ApiException('API URL oluşturulamadı: $e');
    }
  }

  /// 🔥 SIMPLE REQUEST HASH - No crypto dependency
  static String _generateSimpleHash(String url, Map<String, dynamic>? body) {
    final content = '$url${jsonEncode(body ?? {})}';
    // Simple hash using string hashCode
    return content.hashCode.toString();
  }

  /// 🔥 DUPLICATE REQUEST KONTROLÜ
  static bool _isDuplicateRequest(String requestHash) {
    final now = DateTime.now();

    // Eski request'leri temizle
    _recentRequests.removeWhere((hash, time) => now.difference(time) > _requestCooldown);

    if (_recentRequests.containsKey(requestHash)) {
      final lastRequest = _recentRequests[requestHash]!;
      if (now.difference(lastRequest) < _requestCooldown) {
        debugPrint('[API_CLIENT] 🚫 DUPLICATE REQUEST BLOCKED: $requestHash');
        return true;
      }
    }

    _recentRequests[requestHash] = now;
    return false;
  }

  /// ✅ GÜVENLİ POST REQUEST - DUPLICATE PROTECTION
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      // 🔥 DUPLICATE REQUEST CHECK
      final requestHash = _generateSimpleHash(endpoint, body);
      if (_isDuplicateRequest(requestHash)) {
        throw ApiException('Bu işlem çok sık tekrarlandı. Lütfen bekleyin.');
      }

      // 🎯 SESSION REFRESH - Her API call'da
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

      // Response body'yi güvenli yazdır (çok uzunsa kısalt)
      final responsePreview = response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body;
      debugPrint("[API] Response preview: $responsePreview");

      // Status code kontrolü
      await _checkStatusCode(response);

      return response;
    } on SocketException {
      throw ApiException('İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
    } on TimeoutException {
      throw ApiException('İstek zaman aşımına uğradı. Lütfen tekrar deneyin.');
    } on ApiException {
      rethrow; // ApiException'ları direkt fırlat
    } catch (e) {
      debugPrint("[API] POST Error: $e");
      throw ApiException('İstek başarısız oldu: ${e.toString()}');
    }
  }

  /// ✅ GÜVENLİ GET REQUEST - DUPLICATE PROTECTION
  static Future<http.Response> get(String endpoint) async {
    try {
      // 🔥 DUPLICATE REQUEST CHECK
      final requestHash = _generateSimpleHash(endpoint, null);
      if (_isDuplicateRequest(requestHash)) {
        throw ApiException('Bu işlem çok sık tekrarlandı. Lütfen bekleyin.');
      }

      // 🎯 SESSION REFRESH - Her API call'da
      SessionTimeoutService.instance.recordActivity();

      final baseUrl = await _getBaseUrl();
      final headers = await _getHeaders();
      final url = Uri.parse('$baseUrl$endpoint');

      debugPrint("[API] GET: $url");

      final response = await http.get(url, headers: headers).timeout(_timeout);

      debugPrint("[API] Status: ${response.statusCode}");

      final responsePreview = response.body.length > 500 ? '${response.body.substring(0, 500)}...' : response.body;
      debugPrint("[API] Response preview: $responsePreview");

      // Status code kontrolü
      await _checkStatusCode(response);

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

  /// ✅ STATUS CODE KONTROLÜ
  static Future<void> _checkStatusCode(http.Response response) async {
    switch (response.statusCode) {
      case 200:
      case 201:
        // Başarılı - session'ı yenile
        SessionTimeoutService.instance.recordActivity();
        break;
      case 401:
        await _clearAuthData();
        throw ApiException('Oturum süresi dolmuş. Lütfen tekrar giriş yapın.');
      case 403:
        throw ApiException('Bu işlem için yetkiniz bulunmuyor.');
      case 404:
        throw ApiException('İstenen kaynak bulunamadı.');
      case 405:
        throw ApiException('Bu işlem desteklenmiyor.');
      case 409:
        throw ApiException('Bu kayıt başka bir işlemde kullanılıyor.');
      case 422:
        throw ApiException('Gönderilen veriler hatalı. Lütfen kontrol edin.');
      case 429:
        throw ApiException('Çok fazla istek gönderildi. Lütfen bekleyin.');
      case 500:
        throw ApiException('Sunucu hatası. Lütfen daha sonra tekrar deneyin.');
      case 502:
      case 503:
        throw ApiException('Servis geçici olarak kullanılamıyor. Lütfen tekrar deneyin.');
      default:
        throw ApiException('Bilinmeyen hata (${response.statusCode}). Lütfen tekrar deneyin.');
    }
  }

  /// ✅ AUTH VERİLERİNİ TEMİZLE
  static Future<void> _clearAuthData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('user_id');
      await prefs.remove('user_name');
      await prefs.remove('user_email');
      debugPrint('[API_CLIENT] Auth data cleared due to 401');
    } catch (e) {
      debugPrint('[API_CLIENT] Error clearing auth data: $e');
    }
  }

  /// ✅ TOKEN KONTROLÜ
  static Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('[API_CLIENT] Token check error: $e');
      return false;
    }
  }

  /// ✅ SUBDOMAIN KONTROLÜ
  static Future<bool> isSubdomainValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subdomain = prefs.getString('subdomain');
      return subdomain != null && subdomain.isNotEmpty;
    } catch (e) {
      debugPrint('[API_CLIENT] Subdomain check error: $e');
      return false;
    }
  }

  /// 🔧 REQUEST CACHE'İ TEMİZLE (debugging için)
  static void clearRequestCache() {
    _recentRequests.clear();
    debugPrint('[API_CLIENT] Request cache cleared');
  }

  /// 📊 CACHE İSTATİSTİKLERİ
  static Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    final activeRequests = _recentRequests.values.where((time) => now.difference(time) < _requestCooldown).length;

    return {
      'total_cached': _recentRequests.length,
      'active_blocks': activeRequests,
      'cooldown_seconds': _requestCooldown.inSeconds,
    };
  }
}

/// ✅ ÖZEL API EXCEPTION SINIFI
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

/// ✅ TIMEOUT EXCEPTION
class TimeoutException implements Exception {
  final String message;

  TimeoutException(this.message, Duration duration);

  @override
  String toString() => message;
}
