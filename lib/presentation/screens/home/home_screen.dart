import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/services/api/auth_service.dart';

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

      debugPrint('[HOME] Loaded user: $name, domain: $_userDomain');
    } catch (e) {
      debugPrint('[HOME] Error loading user info: $e');
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout,
                color: Colors.orange,
                size: 32,
              ),
            ),
            title: const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Oturumunuzu sonlandırmak istediğinizden emin misiniz?',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
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
        title: const Text(
          'Veribis CRM',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Card
            _buildWelcomeCard(size),

            SizedBox(height: size.largeSpacing),

            // Quick Actions
            _buildQuickActions(size),

            SizedBox(height: size.largeSpacing),

            // Statistics Cards
            _buildStatisticsCards(size),

            SizedBox(height: size.largeSpacing),

            // Recent Activities
            //_buildRecentActivities(size),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(AppSizes size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: size.mediumSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldiniz',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: size.smallText,
                      ),
                    ),
                    Text(
                      _userName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.mediumText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_userDomain.isNotEmpty) ...[
                      SizedBox(height: size.tinySpacing),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _userDomain,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: size.smallText * 0.9,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(AppSizes size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: size.mediumText,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.mediumSpacing),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_business,
                title: 'Firma Ekle',
                color: AppColors.primary,
                onTap: () {
                  // Navigate to add company screen
                  Navigator.pushNamed(context, AppRoutes.addCompany);
                },
                size: size,
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              child: _buildActionCard(
                icon: Icons.assignment_add,
                title: 'Aktivite Ekle',
                color: AppColors.secondary,
                onTap: () {
                  Navigator.pushNamed(context, AppRoutes.addActivity);
                },
                size: size,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
    required AppSizes size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(size.cardPadding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(size.cardBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
            ),
            SizedBox(height: size.smallSpacing),
            Text(
              title,
              style: TextStyle(
                fontSize: size.smallText,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCards(AppSizes size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'İstatistikler',
          style: TextStyle(
            fontSize: size.mediumText,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: size.mediumSpacing),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Bugün Toplam Aktivite',
                value: '2',
                icon: Icons.business,
                color: AppColors.info,
                size: size,
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              child: _buildStatCard(
                title: 'Bugün Kalan Aktivite',
                value: '1',
                icon: Icons.assignment,
                color: AppColors.success,
                size: size,
              ),
            ),
          ],
        ),
        SizedBox(height: size.smallIcon),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Yarın Toplam Aktivite',
                value: '4',
                icon: Icons.business,
                color: AppColors.hardalColor,
                size: size,
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              child: _buildStatCard(
                title: 'Yarın Kalan Aktivite',
                value: '4',
                icon: Icons.assignment,
                color: Colors.purple,
                size: size,
              ),
            ),
          ],
        ),
        SizedBox(height: size.smallIcon),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                title: 'Bu Hafta Toplam Aktivite',
                value: '10',
                icon: Icons.business,
                color: AppColors.primaryDark,
                size: size,
              ),
            ),
            SizedBox(width: size.mediumSpacing),
            Expanded(
              child: _buildStatCard(
                title: 'Bu Hafta Kalan Aktivite',
                value: '9',
                icon: Icons.assignment,
                color: AppColors.redColor,
                size: size,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required AppSizes size,
  }) {
    return Container(
      padding: EdgeInsets.all(size.cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: size.largeText,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: size.smallSpacing),
          Text(
            title,
            style: TextStyle(
              fontSize: size.smallText,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
