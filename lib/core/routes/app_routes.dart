// lib/core/routes/app_routes.dart - GÜNCELLENMİŞ
import 'package:flutter/material.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/domain_selection_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/company/add_company_screen.dart';
import '../../presentation/screens/activity/add_activity_screen.dart'; // ✅ Düzeltilmiş import

class AppRoutes {
  static const String onboarding = '/';
  static const String domainSelection = '/domain-selection';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String main = '/main';
  static const String home = '/home';
  static const String addCompany = '/add-company';
  static const String addActivity = '/add-activity';
  static const String activityList = '/activity-list';
  static const String companyList = '/company-list';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());

      case domainSelection:
        return MaterialPageRoute(builder: (_) => const DomainSelectionScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());

      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());

      case addCompany:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddCompanyScreen(
            companyId: args?['companyId'] as int?,
          ),
        );

      case addActivity:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => AddActivityScreen(
            // ✅ Düzeltilmiş class ismi
            activityId: args?['activityId'] as int?,
            preSelectedCompanyId: args?['companyId'] as int?,
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route "${settings.name}" not found'),
            ),
          ),
        );
    }
  }
}
