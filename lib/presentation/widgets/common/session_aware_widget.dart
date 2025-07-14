import 'package:flutter/material.dart';
import '../../../core/services/hybrid_session_timeout_service.dart';

class SessionAwareWidget extends StatefulWidget {
  final Widget child;

  const SessionAwareWidget({
    super.key,
    required this.child,
  });

  @override
  State<SessionAwareWidget> createState() => _SessionAwareWidgetState();
}

class _SessionAwareWidgetState extends State<SessionAwareWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // App geri geldiğinde session'ı yenile
        if (HybridSessionTimeoutService.instance.isActive) {
          HybridSessionTimeoutService.instance.recordActivity();
          debugPrint('[SessionAware] App resumed - session refreshed');
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App arka plana geçtiğinde özel bir şey yapma
        // Session timeout zaten çalışmaya devam edecek
        debugPrint('[SessionAware] App paused/inactive');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}