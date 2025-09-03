// lib/main.dart - NO DIALOG VERSION
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
    _initializeDirectSessionTimeout();
  }

  /// DIRECT Session timeout sistemini başlatır - NO DIALOG
  void _initializeDirectSessionTimeout() {
    HybridSessionTimeoutService.instance.initialize(
      timeoutDuration: const Duration(minutes: 30), // 30 DAKİKA
      onTimeout: _handleDirectSessionTimeout, // DIRECT LOGOUT
    );
    debugPrint('[MAIN] Direct session timeout initialized (30min - no dialog)');
  }

  /// DIRECT Session timeout - NO WARNING DIALOG
  void _handleDirectSessionTimeout() async {
    debugPrint('[MAIN] Direct session timeout detected - performing immediate logout');

    try {
      // Logout işlemi
      await _authService.logout();

      // Provider'ları temizle
      final context = _navigatorKey.currentContext;
      if (context != null && mounted) {
        context.read<MenuProvider>().clearMenu();
        context.read<DashboardProvider>().clearCache();
      }

      // DIRECT REDIRECT - NO DIALOG
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final context = _navigatorKey.currentContext;
        if (context != null && mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );

          // Simple info snackbar - NOT blocking dialog
          _showTimeoutNotification(context);
        }
      });
    } catch (e) {
      debugPrint('[MAIN] Session timeout error: $e');

      // Emergency redirect on error
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

  /// Simple notification - NOT blocking dialog
  void _showTimeoutNotification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.timer_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Oturum süresi doldu. Güvenlik için çıkış yapıldı.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
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

// Session debugging widget - Development only
class SessionDebugWidget extends StatefulWidget {
  final Widget child;

  const SessionDebugWidget({super.key, required this.child});

  @override
  State<SessionDebugWidget> createState() => _SessionDebugWidgetState();
}

class _SessionDebugWidgetState extends State<SessionDebugWidget> {
  Timer? _debugTimer;
  String _sessionStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _startSessionDebugging();
  }

  void _startSessionDebugging() {
    _debugTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      final healthStatus = await HybridSessionTimeoutService.instance.checkSessionHealth();
      final sessionInfo = HybridSessionTimeoutService.instance.sessionInfo;

      setState(() {
        _sessionStatus = '${healthStatus.description} | ${sessionInfo.formattedRemainingTime}';
      });

      debugPrint('[SESSION_DEBUG] $healthStatus - ${sessionInfo.formattedRemainingTime}');
    });
  }

  @override
  void dispose() {
    _debugTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Debug overlay - only in debug mode
        if (kDebugMode)
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _sessionStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// Development flag check
bool get kDebugMode {
  bool inDebugMode = false;
  assert(inDebugMode = true);
  return inDebugMode;
}
