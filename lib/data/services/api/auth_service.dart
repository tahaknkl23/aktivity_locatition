// lib/data/services/api/auth_service.dart - ENHANCED VERSION
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/current_user.dart';
import '../../../core/services/session_timeout_service.dart';
import '../../../core/utils/photo_url_helper.dart';

class AuthService {
  Future<LoginResult> login(String email, String password, BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('subdomain')?.trim() ?? '';

    debugPrint("[LOGIN] Raw Domain: $domain");

    if (domain.isEmpty) {
      return LoginResult(
        success: false,
        errorMessage: "Domain bilgisi bulunamadı. Lütfen domain seçin.",
      );
    }

    // 🆕 FLEXIBLE URL BUILDING - HTTP/HTTPS & Custom Domain Support
    final urlParts = _buildLoginUrl(domain);
    final baseUrl = urlParts.baseUrl;
    final subdomain = urlParts.subdomain;

    final url = Uri.parse('$baseUrl/token');
    debugPrint("[LOGIN] Login URL: $url");
    debugPrint("[LOGIN] Subdomain for storage: $subdomain");

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'password',
          'username': email,
          'password': password,
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Bağlantı zaman aşımına uğradı');
        },
      );

      debugPrint("[LOGIN] Status Code: ${response.statusCode}");
      debugPrint("[LOGIN] Response received");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token']?.toString() ?? '';
        final fullName = data['FullName']?.toString() ?? '';
        final userId = data['UserId']?.toString() ?? '';
        final rawPicture = data['PictureUrl']?.toString() ?? '';

        // 🆕 TOKEN EXPIRATION TIME
        final expiresIn = data['expires_in'] as int? ?? 3600; // Default 1 hour
        final expirationTime = DateTime.now().add(Duration(seconds: expiresIn));

        // 🆕 FLEXIBLE PICTURE URL BUILDING
        String picture = '';
        if (rawPicture.isNotEmpty) {
          picture = _buildPictureUrl(rawPicture, baseUrl);
        }

        if (accessToken.isEmpty) {
          return LoginResult(
            success: false,
            errorMessage: "Giriş başarısız: Token alınamadı.",
          );
        }

        // 🆕 ENHANCED STORAGE - Token expiration time dahil
        await prefs.setString('token', accessToken);
        await prefs.setString('full_name', fullName);
        await prefs.setString('user_id', userId);
        await prefs.setString('picture_url', picture);
        await prefs.setString('subdomain', subdomain);
        await prefs.setString('base_url', baseUrl);
        await prefs.setString('token_expiration', expirationTime.toIso8601String());

        CurrentUser.accessToken = accessToken;
        CurrentUser.name = fullName;
        CurrentUser.userId = int.tryParse(userId);
        CurrentUser.subdomain = subdomain;

        PhotoUrlHelper.updateSubdomain(subdomain);

        // 🆕 TOKEN-AWARE SESSION TRACKING
        _startTokenAwareSessionTracking(expirationTime);

        debugPrint("[LOGIN] ✅ Başarılı giriş. Kullanıcı: $fullName - ID: $userId");
        debugPrint("[LOGIN] ✅ Base URL: $baseUrl");
        debugPrint("[LOGIN] ✅ Token expires at: $expirationTime");
        return LoginResult(success: true);
      }

      String errorMessage;
      switch (response.statusCode) {
        case 401:
          errorMessage = "Kullanıcı adı veya şifre hatalı.";
          break;
        case 403:
          errorMessage = "Erişim reddedildi. Hesabınız engellenmiş olabilir.";
          break;
        case 400:
          errorMessage = "Geçersiz bilgiler. Lütfen kontrol edin.";
          break;
        case 404:
          errorMessage = "Domain bulunamadı. Domain adresini kontrol edin.";
          break;
        case 500:
          errorMessage = "Sunucu hatası. Lütfen daha sonra tekrar deneyin.";
          break;
        default:
          errorMessage = "Bilinmeyen hata: ${response.statusCode}";
          break;
      }

      return LoginResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      debugPrint("[LOGIN] ❌ Exception: $e");

      String errorMessage;
      if (e.toString().contains('timeout')) {
        errorMessage = "Bağlantı zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.";
      } else if (e.toString().contains('SocketException')) {
        errorMessage = "İnternet bağlantısı yok. Bağlantınızı kontrol edin.";
      } else if (e.toString().contains('HandshakeException')) {
        errorMessage = "SSL/TLS bağlantı hatası. Domain adresini kontrol edin.";
      } else {
        errorMessage = "Bağlantı hatası: ${e.toString()}";
      }

      return LoginResult(
        success: false,
        errorMessage: errorMessage,
      );
    }
  }

  // 🆕 FLEXIBLE URL BUILDING METHOD
  LoginUrlParts _buildLoginUrl(String domain) {
    String baseUrl;
    String subdomain;

    // 1. Full URL provided (http:// veya https://)
    if (domain.startsWith('http://') || domain.startsWith('https://')) {
      baseUrl = domain;
      subdomain = _extractSubdomainFromUrl(domain);
      debugPrint("[URL_BUILD] Full URL provided: $baseUrl -> Subdomain: $subdomain");
      return LoginUrlParts(baseUrl: baseUrl, subdomain: subdomain);
    }

    // 2. Domain with port (localhost:8080, 192.168.1.100:3000)
    if (domain.contains(':') && !domain.contains('://')) {
      baseUrl = 'http://$domain'; // Port varsa HTTP kullan
      subdomain = domain.split(':')[0]; // Port'u çıkar
      debugPrint("[URL_BUILD] Domain with port: $baseUrl -> Subdomain: $subdomain");
      return LoginUrlParts(baseUrl: baseUrl, subdomain: subdomain);
    }

    // 3. Custom domain (destekcrm.com, mycompany.com)
    if (domain.contains('.') && !domain.contains('veribiscrm.com')) {
      baseUrl = 'https://$domain'; // Custom domain için HTTPS
      subdomain = domain;
      debugPrint("[URL_BUILD] Custom domain: $baseUrl -> Subdomain: $subdomain");
      return LoginUrlParts(baseUrl: baseUrl, subdomain: subdomain);
    }

    // 4. Veribis subdomain (demo.veribiscrm.com)
    if (domain.contains('.veribiscrm.com')) {
      baseUrl = 'https://$domain';
      subdomain = domain.split('.')[0];
      debugPrint("[URL_BUILD] Veribis subdomain: $baseUrl -> Subdomain: $subdomain");
      return LoginUrlParts(baseUrl: baseUrl, subdomain: subdomain);
    }

    // 5. Plain subdomain (demo, destek)
    baseUrl = 'https://$domain.veribiscrm.com';
    subdomain = domain;
    debugPrint("[URL_BUILD] Plain subdomain: $baseUrl -> Subdomain: $subdomain");
    return LoginUrlParts(baseUrl: baseUrl, subdomain: subdomain);
  }

  // 🆕 EXTRACT SUBDOMAIN FROM FULL URL
  String _extractSubdomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;

      // veribiscrm.com domain'i için subdomain çıkar
      if (host.contains('veribiscrm.com')) {
        return host.split('.')[0];
      }

      // Custom domain için tüm host'u subdomain olarak kullan
      return host;
    } catch (e) {
      debugPrint("[SUBDOMAIN_EXTRACT] Error: $e");
      return url;
    }
  }

  // 🆕 FLEXIBLE PICTURE URL BUILDING
  String _buildPictureUrl(String rawPicture, String baseUrl) {
    if (rawPicture.startsWith('http')) {
      return rawPicture; // Already full URL
    }

    // Relative path'i baseUrl ile birleştir
    final cleanPath = rawPicture.startsWith('./')
        ? rawPicture.substring(2)
        : rawPicture.startsWith('/')
            ? rawPicture.substring(1)
            : rawPicture;

    return '$baseUrl/$cleanPath';
  }

  // 🆕 TOKEN-AWARE SESSION TRACKING
  void _startTokenAwareSessionTracking(DateTime tokenExpiration) {
    // Token süresinin %90'ını session timeout olarak kullan
    final tokenDuration = tokenExpiration.difference(DateTime.now());
    final sessionDuration = Duration(
      milliseconds: (tokenDuration.inMilliseconds * 0.9).round(),
    );

    SessionTimeoutService.instance.initialize(
      timeoutDuration: sessionDuration,
      onTimeout: () async {
        debugPrint('[AUTH] Token-aware session timeout triggered');
        await logout();
      },
    );

    debugPrint('[AUTH] Token-aware session tracking started: ${sessionDuration.inMinutes} minutes');
  }

  // 🆕 ENHANCED TOKEN VALIDATION
  Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final expirationStr = prefs.getString('token_expiration');

      if (token == null || token.isEmpty) {
        debugPrint('[AUTH] No token found');
        return false;
      }

      if (expirationStr != null) {
        final expiration = DateTime.parse(expirationStr);
        final now = DateTime.now();

        if (now.isAfter(expiration)) {
          debugPrint('[AUTH] Token expired at $expiration, now is $now');
          await logout(); // Auto logout on expired token
          return false;
        }

        // Token'in %10'u kaldıysa warning
        final remaining = expiration.difference(now);
        final total = expiration.difference(DateTime.now().subtract(Duration(seconds: 3600))); // Assume 1h total
        if (remaining.inMilliseconds < (total.inMilliseconds * 0.1)) {
          debugPrint('[AUTH] Token expiring soon: ${remaining.inMinutes} minutes left');
        }
      }

      debugPrint('[AUTH] Token is valid');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Token validation error: $e');
      return false;
    }
  }

  // 🆕 ENHANCED LOGOUT
  Future<void> logout() async {
    try {
      debugPrint('[AUTH] Logout started');

      SessionTimeoutService.instance.stop();
      await _clearUserData();

      CurrentUser.accessToken = null;
      CurrentUser.name = null;
      CurrentUser.userId = null;

      debugPrint('[AUTH] ✅ Logout completed');
    } catch (e) {
      debugPrint('[AUTH] ❌ Logout error: $e');
    }
  }

  // 🆕 CLEAR USER DATA (subdomain preserved)
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('full_name');
    await prefs.remove('user_id');
    await prefs.remove('picture_url');
    await prefs.remove('token_expiration');

    debugPrint('[AUTH] User data cleared (subdomain preserved)');
  }

  // 🆕 REFRESH SESSION MANUALLY
  Future<void> refreshSession() async {
    if (await isTokenValid()) {
      SessionTimeoutService.instance.recordActivity();
      debugPrint('[AUTH] Session refreshed manually');
    } else {
      debugPrint('[AUTH] Cannot refresh - invalid token');
      await logout();
    }
  }

  // 🆕 GET TOKEN EXPIRATION INFO
  Future<TokenExpirationInfo?> getTokenExpirationInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expirationStr = prefs.getString('token_expiration');

      if (expirationStr == null) return null;

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
      debugPrint('[AUTH] Get expiration info error: $e');
      return null;
    }
  }
}

// 🆕 HELPER CLASSES
class LoginResult {
  final bool success;
  final String? errorMessage;

  LoginResult({
    required this.success,
    this.errorMessage,
  });
}

class LoginUrlParts {
  final String baseUrl;
  final String subdomain;

  LoginUrlParts({
    required this.baseUrl,
    required this.subdomain,
  });
}

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

    if (minutes > 0) {
      return '${minutes}d ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
