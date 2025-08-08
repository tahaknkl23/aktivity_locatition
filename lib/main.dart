// lib/main.dart - UPDATED VERSION
import 'dart:async';
import 'package:aktivity_location_app/presentation/providers/dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Enhanced session timeout imports
import 'core/services/hybrid_session_timeout_service.dart';
import 'presentation/widgets/common/session_aware_widget.dart';
import 'data/services/api/auth_service.dart';
import 'core/routes/app_routes.dart';
import 'core/utils/photo_url_helper.dart';
import 'core/constants/app_colors.dart';
import 'presentation/providers/menu_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize PhotoUrlHelper
  await PhotoUrlHelper.initializeSubdomain();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _initializeHybridSessionTimeout();
  }

  /// 🚀 HYBRID Session timeout sistemini başlatır
  void _initializeHybridSessionTimeout() {
    HybridSessionTimeoutService.instance.initialize(
      timeoutDuration: const Duration(minutes: 30), // 🎯 30 DAKİKA
      warningDuration: const Duration(minutes: 25), // 🎯 25 DAKİKADA UYARI
      onTimeout: _handleSessionTimeout,
      onWarning: _handleSessionWarning,
    );
    debugPrint('[MAIN] Hybrid session timeout initialized (30min timeout, 25min warning)');
  }

  /// 🔔 Session warning olduğunda çağrılır
  void _handleSessionWarning() async {
    debugPrint('[MAIN] 🔔 Session warning triggered');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _navigatorKey.currentContext;
      if (context != null && mounted) {
        _showSessionWarningDialog(context);
      }
    });
  }

  /// 🔔 Session warning dialog'unu göster
  void _showSessionWarningDialog(BuildContext context) {
    final remainingTime = HybridSessionTimeoutService.instance.remainingTime;
    if (remainingTime == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SessionWarningDialog(
        remainingTime: remainingTime,
        onExtendSession: () {
          Navigator.pop(context);
          HybridSessionTimeoutService.instance.dismissWarning();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text(
                    'Oturumunuz uzatıldı',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
        onLogout: () {
          Navigator.pop(context);
          _handleSessionTimeout();
        },
      ),
    );
  }

  /// ⏰ Session timeout olduğunda çağrılır
  void _handleSessionTimeout() async {
    debugPrint('[MAIN] 🔔 Session timeout detected - performing logout');

    try {
      await _authService.logout();

      // Provider'ları temizle
      final context = _navigatorKey.currentContext;
      if (context != null) {
        context.read<MenuProvider>().clearMenu();
        context.read<DashboardProvider>().clearCache(); // ✅ YENİ EKLENEN
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _navigatorKey.currentContext;
        if (context != null && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.timer_off, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Güvenlik nedeniyle oturumunuz sonlandırıldı. (30 dakika)',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 6),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Tamam',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
            ),
          );
        }
      });
    } catch (e) {
      debugPrint('[MAIN] Session timeout error: $e');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _navigatorKey.currentContext;
        if (context != null && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    HybridSessionTimeoutService.instance.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()), // ✅ YENİ EKLENEN
        // Diğer provider'lar buraya eklenebilir
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);

          return SessionAwareWidget(
            child: MediaQuery(
              data: mediaQuery.copyWith(
                textScaler: TextScaler.linear(
                  mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.0),
                ),
              ),
              child: child!,
            ),
          );
        },
        title: 'Veribis Crm',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          cardTheme: CardTheme(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            margin: const EdgeInsets.all(8),
          ),
        ),
        initialRoute: AppRoutes.onboarding,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

/// 🔔 Session Warning Dialog Widget
class SessionWarningDialog extends StatefulWidget {
  final Duration remainingTime;
  final VoidCallback onExtendSession;
  final VoidCallback onLogout;

  const SessionWarningDialog({
    super.key,
    required this.remainingTime,
    required this.onExtendSession,
    required this.onLogout,
  });

  @override
  State<SessionWarningDialog> createState() => _SessionWarningDialogState();
}

class _SessionWarningDialogState extends State<SessionWarningDialog> with TickerProviderStateMixin {
  late Timer _countdownTimer;
  late Duration _timeLeft;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.remainingTime;

    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft.inSeconds <= 0) {
        timer.cancel();
        widget.onLogout();
        return;
      }

      setState(() {
        _timeLeft = Duration(seconds: _timeLeft.inSeconds - 1);
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.timer_outlined,
                    size: 48,
                    color: Colors.orange,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Oturum Zaman Aşımı',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Oturumunuz ${_timeLeft.inMinutes} dakika ${_timeLeft.inSeconds % 60} saniye sonra otomatik olarak sonlandırılacak.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Text(
              '${_timeLeft.inMinutes.toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.red,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onLogout,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Çıkış Yap'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onExtendSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Devam Et'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
