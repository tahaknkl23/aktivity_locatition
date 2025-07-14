import 'dart:async';
import 'package:flutter/material.dart';

class SessionTimeoutService {
  static final SessionTimeoutService _instance = SessionTimeoutService._internal();
  static SessionTimeoutService get instance => _instance;
  SessionTimeoutService._internal();

  Timer? _sessionTimer;
  DateTime? _lastActivity;
  Duration _timeoutDuration = const Duration(minutes: 30);
  VoidCallback? _onTimeout;

  bool get isActive => _sessionTimer?.isActive ?? false;
  DateTime? get lastActivity => _lastActivity;
  Duration get timeoutDuration => _timeoutDuration;

  /// Initialize session timeout
  void initialize({
    Duration timeoutDuration = const Duration(minutes: 30),
    VoidCallback? onTimeout,
  }) {
    _timeoutDuration = timeoutDuration;
    _onTimeout = onTimeout;
    recordActivity();
    debugPrint('[SessionTimeout] Initialized with ${timeoutDuration.inMinutes} minutes timeout');
  }

  /// Record user activity and reset timer
  void recordActivity() {
    _lastActivity = DateTime.now();
    _resetTimer();
    debugPrint('[SessionTimeout] Activity recorded at ${_lastActivity}');
  }

  /// Reset the session timer
  void _resetTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_timeoutDuration, () {
      debugPrint('[SessionTimeout] Session timeout triggered');
      _onTimeout?.call();
    });
  }

  /// Stop session timeout
  void stop() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
    _lastActivity = null;
    debugPrint('[SessionTimeout] Stopped');
  }

  /// Get remaining time until timeout
  Duration? get remainingTime {
    if (_lastActivity == null) return null;
    
    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _timeoutDuration - elapsed;
    
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if session is about to expire (within warning time)
  bool isAboutToExpire({Duration warningTime = const Duration(minutes: 5)}) {
    final remaining = remainingTime;
    if (remaining == null) return false;
    
    return remaining <= warningTime;
  }
}