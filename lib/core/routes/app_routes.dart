// lib/core/routes/app_routes.dart - GÜNCELLENMİŞ
import 'package:aktivity_location_app/presentation/screens/activity/activity_list_screen.dart';
import 'package:aktivity_location_app/presentation/screens/common/generic_dynamic_form_screen.dart';
import 'package:aktivity_location_app/presentation/screens/common/generic_dynamic_list_screen.dart';
import 'package:aktivity_location_app/presentation/screens/company/company_list_screen.dart';
import 'package:flutter/material.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/onboarding/domain_selection_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/main/main_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/company/add_company_screen.dart';
import '../../presentation/screens/activity/add_activity_screen.dart';

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

  // 🆕 Generic dynamic routes
  static const String dynamicForm = '/dynamic-form';
  static const String dynamicList = '/dynamic-list';

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

      // 🔧 Mevcut specific routes
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
            activityId: args?['activityId'] as int?,
            preSelectedCompanyId: args?['companyId'] as int?,
          ),
        );

      case companyList:
        return MaterialPageRoute(
          builder: (_) => const CompanyListScreen(), // Mevcut company list screen
        );

      case activityList:
        return MaterialPageRoute(
          builder: (_) => const ActivityListScreen(), // Mevcut activity list screen
        );

      // 🆕 Generic dynamic form route
      case dynamicForm:
        final args = settings.arguments as Map<String, dynamic>?;
        final controller = args?['controller'] as String? ?? '';
        // final url = args?['url'] as String? ?? '';
        final title = args?['title'] as String? ?? 'Form';

        // Controller'a göre uygun sayfaya yönlendir
        return _buildDynamicFormRoute(controller, args, title);

      // 🆕 Generic dynamic list route
      case dynamicList:
        final args = settings.arguments as Map<String, dynamic>?;
        final controller = args?['controller'] as String? ?? '';
        final title = args?['title'] as String? ?? 'Liste';

        // Controller'a göre uygun liste sayfasına yönlendir
        return _buildDynamicListRoute(controller, args, title);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text('Sayfa Bulunamadı'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Route "${settings.name}" not found',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(_).pop(),
                    child: Text('Geri Dön'),
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  // 🆕 Dynamic form route builder
  static MaterialPageRoute _buildDynamicFormRoute(String controller, Map<String, dynamic>? args, String title) {
    switch (controller.toLowerCase()) {
      case 'companyadd':
        // Firma için mevcut sayfayı kullan
        return MaterialPageRoute(
          builder: (_) => AddCompanyScreen(
            companyId: args?['id'] as int?,
          ),
        );

      case 'aktiviteadd':
      case 'aktivitebranchadd':
        // Aktivite için mevcut sayfayı kullan
        return MaterialPageRoute(
          builder: (_) => AddActivityScreen(
            activityId: args?['id'] as int?,
          ),
        );

      default:
        // Diğer formlar için gerçek dynamic form
        return MaterialPageRoute(
          builder: (_) => GenericDynamicFormScreen(
            controller: controller,
            title: title,
            url: args?['url'] as String? ?? '',
            id: args?['id'] as int?,
          ),
        );
    }
  }

  // 🆕 Dynamic list route builder
  static MaterialPageRoute _buildDynamicListRoute(String controller, Map<String, dynamic>? args, String title) {
    switch (controller.toLowerCase()) {
      case 'companyadd':
        // Firma listesi için mevcut sayfayı kullan (eğer varsa)
        return MaterialPageRoute(
          builder: (_) => GenericListPlaceholderScreen(
            controller: controller,
            title: title,
            url: args?['url'] as String? ?? '',
            listType: 'company',
          ),
        );

      case 'aktiviteadd':
      case 'aktivitebranchadd':
        // Aktivite listesi için mevcut sayfayı kullan (eğer varsa)
        return MaterialPageRoute(
          builder: (_) => GenericListPlaceholderScreen(
            controller: controller,
            title: title,
            url: args?['url'] as String? ?? '',
            listType: 'activity',
          ),
        );

      default:
        // Diğer listeler için gerçek dynamic list
        return MaterialPageRoute(
          builder: (_) => GenericDynamicListScreen(
            controller: controller,
            title: title,
            url: args?['url'] as String? ?? '',
            listType: 'generic',
          ),
        );
    }
  }
}

// 🆕 Generic Form Placeholder Screen
class GenericFormPlaceholderScreen extends StatelessWidget {
  final String controller;
  final String title;
  final String url;

  const GenericFormPlaceholderScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.construction,
                  size: 64,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bu form sayfası yakında hazır olacak',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Controller: $controller', style: const TextStyle(fontFamily: 'monospace')),
                    Text('URL: $url', style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🆕 Generic List Placeholder Screen
class GenericListPlaceholderScreen extends StatelessWidget {
  final String controller;
  final String title;
  final String url;
  final String listType;

  const GenericListPlaceholderScreen({
    super.key,
    required this.controller,
    required this.title,
    required this.url,
    required this.listType,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.list_alt,
                  size: 64,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Bu liste sayfası yakında hazır olacak',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Controller: $controller', style: const TextStyle(fontFamily: 'monospace')),
                    Text('URL: $url', style: const TextStyle(fontFamily: 'monospace')),
                    Text('Type: $listType', style: const TextStyle(fontFamily: 'monospace')),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Geri Dön'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
