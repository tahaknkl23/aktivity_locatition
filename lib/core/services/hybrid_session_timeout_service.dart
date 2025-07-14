import 'dart:async';
import 'package:flutter/material.dart';

class HybridSessionTimeoutService {
  static final HybridSessionTimeoutService _instance = HybridSessionTimeoutService._internal();
  static HybridSessionTimeoutService get instance => _instance;
  HybridSessionTimeoutService._internal();

  Timer? _sessionTimer;
  Timer? _warningTimer;
  DateTime? _lastActivity;
  Duration _timeoutDuration = const Duration(minutes: 30);
  Duration _warningDuration = const Duration(minutes: 25);
  VoidCallback? _onTimeout;
  VoidCallback? _onWarning;
  bool _warningShown = false;

  bool get isActive => _sessionTimer?.isActive ?? false;
  DateTime? get lastActivity => _lastActivity;
  Duration get timeoutDuration => _timeoutDuration;

  /// Initialize hybrid session timeout with warning
  void initialize({
    Duration timeoutDuration = const Duration(minutes: 30),
    Duration warningDuration = const Duration(minutes: 25),
    VoidCallback? onTimeout,
    VoidCallback? onWarning,
  }) {
    _timeoutDuration = timeoutDuration;
    _warningDuration = warningDuration;
    _onTimeout = onTimeout;
    _onWarning = onWarning;
    recordActivity();
    debugPrint('[HybridSessionTimeout] Initialized: ${timeoutDuration.inMinutes}min timeout, ${warningDuration.inMinutes}min warning');
  }

  /// Record user activity and reset timers
  void recordActivity() {
    _lastActivity = DateTime.now();
    _warningShown = false;
    _resetTimers();
    debugPrint('[HybridSessionTimeout] Activity recorded at $_lastActivity');
  }

  /// Reset both session and warning timers
  void _resetTimers() {
    // Cancel existing timers
    _sessionTimer?.cancel();
    _warningTimer?.cancel();

    // Start warning timer
    _warningTimer = Timer(_warningDuration, () {
      if (!_warningShown) {
        _warningShown = true;
        debugPrint('[HybridSessionTimeout] Warning triggered');
        _onWarning?.call();
      }
    });

    // Start session timeout timer
    _sessionTimer = Timer(_timeoutDuration, () {
      debugPrint('[HybridSessionTimeout] Session timeout triggered');
      _onTimeout?.call();
    });
  }

  /// Dismiss warning and extend session
  void dismissWarning() {
    _warningShown = false;
    recordActivity();
    debugPrint('[HybridSessionTimeout] Warning dismissed, session extended');
  }

  /// Stop all timers
  void stop() {
    _sessionTimer?.cancel();
    _warningTimer?.cancel();
    _sessionTimer = null;
    _warningTimer = null;
    _lastActivity = null;
    _warningShown = false;
    debugPrint('[HybridSessionTimeout] Stopped');
  }

  /// Get remaining time until timeout
  Duration? get remainingTime {
    if (_lastActivity == null) return null;

    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _timeoutDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Get remaining time until warning
  Duration? get remainingTimeUntilWarning {
    if (_lastActivity == null) return null;

    final elapsed = DateTime.now().difference(_lastActivity!);
    final remaining = _warningDuration - elapsed;

    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// Check if warning has been shown
  bool get isWarningShown => _warningShown;

  /// Check if session is in warning state
  bool get isInWarningState {
    final remaining = remainingTimeUntilWarning;
    return remaining != null && remaining <= Duration.zero && !_warningShown;
  }
}
