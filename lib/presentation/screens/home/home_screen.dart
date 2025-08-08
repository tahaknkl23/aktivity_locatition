// lib/presentation/screens/home/home_screen.dart - CLEAN VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/api/auth_service.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/menu/menu_drawer.dart';
import '../../widgets/home/welcome_card_widget.dart';
import '../../widgets/home/quick_actions_widget.dart';
import '../../widgets/home/statistics_section_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userDomain = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardDataSafely();
    });
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('full_name') ?? 'Kullanıcı';
      final subdomain = prefs.getString('subdomain') ?? '';

      setState(() {
        _userName = name;
        _userDomain = subdomain.isNotEmpty ? '$subdomain.veribiscrm.com' : '';
      });
    } catch (e) {
      debugPrint('[HOME] Error loading user info: $e');
    }
  }

  void _loadDashboardDataSafely() {
    try {
      if (mounted) {
        context.read<DashboardProvider>().loadDashboardData();
      }
    } catch (e) {
      debugPrint('[HOME] ❌ Error loading dashboard: $e');
    }
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await _showLogoutDialog();
    if (!shouldLogout) return;

    try {
      await _authService.logout();
      if (mounted) {
        context.showSuccessSnackBar('Başarıyla çıkış yapıldı');
        context.pushNamedAndRemoveUntil(AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackBar('Çıkış işlemi sırasında hata oluştu');
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Çıkış Yap'),
            content: const Text('Oturumunuzu sonlandırmak istediğinizden emin misiniz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Çıkış Yap'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Veribis CRM', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Consumer<DashboardProvider>(
            builder: (context, provider, child) {
              return IconButton(
                onPressed: provider.isLoading ? null : () => provider.loadDashboardData(forceRefresh: true),
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Yenile',
              );
            },
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      drawer: const MenuDrawer(),
      body: RefreshIndicator(
        onRefresh: () => context.read<DashboardProvider>().loadDashboardData(forceRefresh: true),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(size.padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Card
              WelcomeCardWidget(
                userName: _userName,
                userDomain: _userDomain,
              ),
              SizedBox(height: size.largeSpacing),

              // Quick Actions
              QuickActionsWidget(
                onFirmaEkle: () => Navigator.pushNamed(context, AppRoutes.addCompany),
                onAktiviteEkle: () => Navigator.pushNamed(context, AppRoutes.addActivity),
              ),
              SizedBox(height: size.largeSpacing),

              // Statistics Section
              const StatisticsSectionWidget(),
              SizedBox(height: size.largeSpacing),
            ],
          ),
        ),
      ),
    );
  }
}
