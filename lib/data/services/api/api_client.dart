import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/session_timeout_service.dart';

class ApiClient {
  static const Duration _timeout = Duration(minutes: 10);

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

  /// ✅ GÜVENLİ POST REQUEST
  static Future<http.Response> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
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

  /// ✅ GÜVENLİ GET REQUEST
  static Future<http.Response> get(String endpoint) async {
    try {
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

  TimeoutException(this.message);

  @override
  String toString() => message;
}
