// lib/core/services/hybrid_session_timeout_service.dart - TOKEN-AWARE VERSION
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HybridSessionTimeoutService {
  static final HybridSessionTimeoutService _instance = HybridSessionTimeoutService._internal();
  static HybridSessionTimeoutService get instance => _instance;
  HybridSessionTimeoutService._internal();

  Timer? _sessionTimer;
  Timer? _tokenCheckTimer;
  DateTime? _lastActivity;
  Duration _timeoutDuration = const Duration(minutes: 30);
  VoidCallback? _onTimeout;
  bool _isActive = false;

  bool get isActive => _isActive;
  DateTime? get lastActivity => _lastActivity;
  Duration get timeoutDuration => _timeoutDuration;

  /// Initialize token-aware session timeout - NO WARNING DIALOG
  void initialize({
    Duration timeoutDuration = const Duration(minutes: 30),
    VoidCallback? onTimeout,
  }) {
    _timeoutDuration = timeoutDuration;
    _onTimeout = onTimeout;
    _isActive = true;

    recordActivity();
    _startTokenMonitoring();

    debugPrint('[HybridSessionTimeout] Token-aware initialized: ${timeoutDuration.inMinutes}min timeout');
  }

  /// Record user activity and reset timer
  void recordActivity() {
    if (!_isActive) return;

    _lastActivity = DateTime.now();
    _resetSessionTimer();
    debugPrint('[HybridSessionTimeout] Activity recorded at $_lastActivity');
  }

  /// Reset session timer only
  void _resetSessionTimer() {
    _sessionTimer?.cancel();

    _sessionTimer = Timer(_timeoutDuration, () {
      debugPrint('[HybridSessionTimeout] Session timeout triggered - direct logout');
      _triggerTimeout();
    });
  }

  /// Start token expiration monitoring
  void _startTokenMonitoring() {
    _tokenCheckTimer?.cancel();

    // Check token every 30 seconds
    _tokenCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final tokenExpired = await _checkTokenExpiration();
      if (tokenExpired) {
        debugPrint('[HybridSessionTimeout] Token expired - triggering logout');
        _triggerTimeout();
        timer.cancel();
      }
    });

    debugPrint('[HybridSessionTimeout] Token monitoring started (30s intervals)');
  }

  /// Check if token has expired
  Future<bool> _checkTokenExpiration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final expirationStr = prefs.getString('token_expiration');

      // No token = expired
      if (token == null || token.isEmpty) {
        debugPrint('[HybridSessionTimeout] No token found');
        return true;
      }

      // No expiration data = assume valid (old tokens)
      if (expirationStr == null) {
        debugPrint('[HybridSessionTimeout] No expiration data, assuming valid');
        return false;
      }

      final expiration = DateTime.parse(expirationStr);
      final now = DateTime.now();

      if (now.isAfter(expiration)) {
        debugPrint('[HybridSessionTimeout] Token expired: $expiration vs $now');
        return true;
      }

      // Log remaining time for debugging
      final remaining = expiration.difference(now);
      if (remaining.inMinutes <= 5) {
        debugPrint('[HybridSessionTimeout] Token expires in ${remaining.inMinutes} minutes');
      }

      return false;
    } catch (e) {
      debugPrint('[HybridSessionTimeout] Token check error: $e');
      return true; // Assume expired on error
    }
  }

  /// Trigger timeout - NO DIALOG, direct action
  void _triggerTimeout() {
    if (!_isActive) return;

    debugPrint('[HybridSessionTimeout] Triggering direct logout');

    // Stop all timers first
    stop();

    // Execute timeout callback
    _onTimeout?.call();
  }

  /// Stop all timers and cleanup
  void stop() {
    _sessionTimer?.cancel();
    _tokenCheckTimer?.cancel();
    _sessionTimer = null;
    _tokenCheckTimer = null;
    _lastActivity = null;
    _isActive = false;

    debugPrint('[HybridSessionTimeout] Stopped all timers');
  }

  /// Get remaining time until session timeout
  Duration? get remainingTime {
    if (_lastActivity == null || !_isActive) return null;

    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _timeoutDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining time until token expiration
  Future<Duration?> get remainingTokenTime async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expirationStr = prefs.getString('token_expiration');

      if (expirationStr == null) return null;

      final expiration = DateTime.parse(expirationStr);
      final now = DateTime.now();
      final remaining = expiration.difference(now);

      return remaining.isNegative ? Duration.zero : remaining;
    } catch (e) {
      debugPrint('[HybridSessionTimeout] Token time error: $e');
      return null;
    }
  }

  /// Check if session is about to expire
  bool isAboutToExpire({Duration warningTime = const Duration(minutes: 5)}) {
    final remaining = remainingTime;
    if (remaining == null || !_isActive) return false;

    return remaining <= warningTime && remaining > Duration.zero;
  }

  /// Check if token is about to expire
  Future<bool> isTokenAboutToExpire({Duration warningTime = const Duration(minutes: 5)}) async {
    final remaining = await remainingTokenTime;
    if (remaining == null) return false;

    return remaining <= warningTime && remaining > Duration.zero;
  }

  /// Force timeout for testing or emergency logout
  void forceTimeout() {
    debugPrint('[HybridSessionTimeout] Force timeout triggered');
    _triggerTimeout();
  }

  /// Update timeout duration dynamically
  void updateTimeoutDuration(Duration newDuration) {
    _timeoutDuration = newDuration;
    if (_isActive) {
      _resetSessionTimer();
    }
    debugPrint('[HybridSessionTimeout] Timeout duration updated to ${newDuration.inMinutes} minutes');
  }

  /// Get session info for debugging
  SessionInfo get sessionInfo {
    return SessionInfo(
      isActive: _isActive,
      lastActivity: _lastActivity,
      timeoutDuration: _timeoutDuration,
      remainingTime: remainingTime,
      isAboutToExpire: isAboutToExpire(),
    );
  }

  /// Initialize with token-based duration
  Future<void> initializeWithTokenDuration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expirationStr = prefs.getString('token_expiration');

      if (expirationStr != null) {
        final expiration = DateTime.parse(expirationStr);
        final now = DateTime.now();
        final tokenDuration = expiration.difference(now);

        if (tokenDuration > Duration.zero) {
          // Use 90% of token duration as session timeout
          final sessionDuration = Duration(
            milliseconds: (tokenDuration.inMilliseconds * 0.9).round(),
          );

          initialize(
            timeoutDuration: sessionDuration,
            onTimeout: _onTimeout,
          );

          debugPrint('[HybridSessionTimeout] Initialized with token-based duration: ${sessionDuration.inMinutes}min');
          return;
        }
      }

      // Fallback to default duration
      initialize(onTimeout: _onTimeout);
      debugPrint('[HybridSessionTimeout] Initialized with default duration');
    } catch (e) {
      debugPrint('[HybridSessionTimeout] Token duration init error: $e');
      initialize(onTimeout: _onTimeout);
    }
  }

  /// Extend session manually
  void extendSession() {
    if (_isActive) {
      recordActivity();
      debugPrint('[HybridSessionTimeout] Session extended manually');
    }
  }

  /// Check overall session health
  Future<SessionHealthStatus> checkSessionHealth() async {
    if (!_isActive) {
      return SessionHealthStatus.inactive;
    }

    final tokenExpired = await _checkTokenExpiration();
    if (tokenExpired) {
      return SessionHealthStatus.tokenExpired;
    }

    final remaining = remainingTime;
    if (remaining == null) {
      return SessionHealthStatus.unknown;
    }

    if (remaining <= Duration.zero) {
      return SessionHealthStatus.sessionExpired;
    }

    if (remaining.inMinutes <= 5) {
      return SessionHealthStatus.expiringSoon;
    }

    return SessionHealthStatus.healthy;
  }
}

/// Session information model
class SessionInfo {
  final bool isActive;
  final DateTime? lastActivity;
  final Duration timeoutDuration;
  final Duration? remainingTime;
  final bool isAboutToExpire;

  SessionInfo({
    required this.isActive,
    required this.lastActivity,
    required this.timeoutDuration,
    required this.remainingTime,
    required this.isAboutToExpire,
  });

  String get formattedRemainingTime {
    if (remainingTime == null) return 'Bilinmiyor';

    final minutes = remainingTime!.inMinutes;
    final seconds = remainingTime!.inSeconds % 60;

    if (minutes > 0) {
      return '${minutes}d ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  @override
  String toString() {
    return 'SessionInfo(active: $isActive, remaining: $formattedRemainingTime, expiring: $isAboutToExpire)';
  }
}

/// Session health status enum
enum SessionHealthStatus {
  healthy,
  expiringSoon,
  sessionExpired,
  tokenExpired,
  inactive,
  unknown,
}

extension SessionHealthStatusExtension on SessionHealthStatus {
  String get description {
    switch (this) {
      case SessionHealthStatus.healthy:
        return 'Oturum sağlıklı';
      case SessionHealthStatus.expiringSoon:
        return 'Oturum yakında sona erecek';
      case SessionHealthStatus.sessionExpired:
        return 'Oturum süresi doldu';
      case SessionHealthStatus.tokenExpired:
        return 'Token süresi doldu';
      case SessionHealthStatus.inactive:
        return 'Oturum aktif değil';
      case SessionHealthStatus.unknown:
        return 'Oturum durumu bilinmiyor';
    }
  }

  bool get requiresAction {
    return this == SessionHealthStatus.sessionExpired || this == SessionHealthStatus.tokenExpired;
  }

  bool get isHealthy {
    return this == SessionHealthStatus.healthy;
  }
}
