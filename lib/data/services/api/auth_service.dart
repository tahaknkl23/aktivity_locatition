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
    final subdomain = prefs.getString('subdomain')?.trim() ?? '';

    debugPrint("[LOGIN] Subdomain: $subdomain");

    // ❌ Subdomain hatalıysa çık
    if (subdomain.isEmpty || subdomain.contains('http') || subdomain.contains('/')) {
      return LoginResult(
        success: false,
        errorMessage: "Domain bilgisi hatalı. Lütfen tekrar seçin.",
      );
    }

    final url = Uri.parse('https://$subdomain.veribiscrm.com/token');
    debugPrint("[LOGIN] URL: $url");

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
      );

      debugPrint("[LOGIN] Status Code: ${response.statusCode}");
      debugPrint("[LOGIN] Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token']?.toString() ?? '';
        final fullName = data['FullName']?.toString() ?? '';
        final userId = data['UserId']?.toString() ?? '';
        final rawPicture = data['PictureUrl']?.toString() ?? '';
        final picture = rawPicture.startsWith('http')
            ? rawPicture
            : 'https://$subdomain.veribiscrm.com${rawPicture.replaceFirst('./', '/')}'.replaceAll(RegExp(r'\.*$'), '');

        await prefs.setString('picture_url', picture);

        if (accessToken.isEmpty) {
          return LoginResult(
            success: false,
            errorMessage: "Giriş başarısız: Token alınamadı.",
          );
        }

        await prefs.setString('token', accessToken);
        await prefs.setString('full_name', fullName);
        await prefs.setString('user_id', userId);
        await prefs.setString('picture_url', picture);

        CurrentUser.accessToken = accessToken;
        CurrentUser.name = fullName;
        CurrentUser.userId = int.tryParse(userId);
        CurrentUser.subdomain = subdomain;

        // 🎯 PHOTO URL HELPER'I INITIALIZE ET
        PhotoUrlHelper.updateSubdomain(subdomain);

        // 🎯 SESSION TIMEOUT'U BAŞLAT
        _startSessionTracking();

        debugPrint("[LOGIN] ✅ Başarılı giriş. Kullanıcı: $fullName - ID: $userId");
        return LoginResult(success: true);
      }

      // Hatalı durumlar
      String errorMessage;
      switch (response.statusCode) {
        case 401:
          errorMessage = "Yetkisiz erişim. Lütfen bilgilerinizi kontrol edin.";
          break;
        case 403:
          errorMessage = "Erişim reddedildi. Yetkiniz olmayabilir.";
          break;
        case 400:
          errorMessage = "Kullanıcı adı veya şifre hatalı.";
          break;
        default:
          errorMessage = "Sunucu hatası: ${response.statusCode}";
          break;
      }

      return LoginResult(success: false, errorMessage: errorMessage);
    } catch (e) {
      debugPrint("[LOGIN] ❌ Exception: $e");
      return LoginResult(
        success: false,
        errorMessage: "Bağlantı hatası: $e",
      );
    }
  }

  // 🎯 YENİ METHOD - Session tracking'i başlat
  void _startSessionTracking() {
    SessionTimeoutService.instance.recordActivity();
    debugPrint('[AUTH] Session tracking started');
  }

  // 🎯 YENİ METHOD - Logout işlemi
  Future<void> logout() async {
    try {
      debugPrint('[AUTH] Logout started');

      // Session timeout'u durdur
      SessionTimeoutService.instance.stop();

      // Kullanıcı verilerini temizle
      await _clearUserData();

      // CurrentUser'ı temizle
      CurrentUser.accessToken = null;
      CurrentUser.name = null;
      CurrentUser.userId = null;
      // CurrentUser.subdomain'i sakla - domain değiştirmek için ayrı buton var

      debugPrint('[AUTH] ✅ Logout completed');
    } catch (e) {
      debugPrint('[AUTH] ❌ Logout error: $e');
    }
  }

  // 🎯 YENİ METHOD - Kullanıcı verilerini temizle (subdomain hariç)
  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();

    // Sadece auth ile ilgili verileri temizle
    await prefs.remove('token');
    await prefs.remove('full_name');
    await prefs.remove('user_id');
    await prefs.remove('picture_url');

    // Subdomain'i sakla - domain değiştirmek için ayrı buton var
    debugPrint('[AUTH] User data cleared (subdomain preserved)');
  }

  // 🎯 YENİ METHOD - Session'ı manuel olarak yenile
  Future<void> refreshSession() async {
    SessionTimeoutService.instance.recordActivity();
    debugPrint('[AUTH] Session refreshed manually');
  }

  // 🎯 YENİ METHOD - Token'ın geçerli olup olmadığını kontrol et
  Future<bool> isTokenValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        debugPrint('[AUTH] No token found');
        return false;
      }

      debugPrint('[AUTH] Token exists');
      return true;
    } catch (e) {
      debugPrint('[AUTH] Token validation error: $e');
      return false;
    }
  }
}

// 🎯 YENİ CLASS - Login sonucu için
class LoginResult {
  final bool success;
  final String? errorMessage;

  LoginResult({
    required this.success,
    this.errorMessage,
  });
}