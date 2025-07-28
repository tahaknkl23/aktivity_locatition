// lib/presentation/widgets/menu/menu_drawer.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/menu/menu_model.dart';
import '../../../data/services/api/auth_service.dart';
import '../../../presentation/screens/auth/login_screen.dart'; // ✅ LoginScreen import
import '../../providers/menu_provider.dart';

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  String _userName = '';
  String _userDomain = '';
  String _userEmail = '';
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('full_name') ?? 'Kullanıcı';
        _userDomain = prefs.getString('subdomain') ?? '';
        _userEmail = prefs.getString('email') ?? '';
      });
    } catch (e) {
      debugPrint('[MENU_DRAWER] Error loading user info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(size),
          Expanded(
            child: _buildMenuList(size),
          ),
          _buildDrawerFooter(size),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(AppSizes size) {
    return Container(
      height: size.isMobile ? 200 : 240, // ✅ Responsive height
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(size.horizontalPadding), // ✅ Responsive padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: size.isMobile ? 25 : 30, // ✅ Responsive avatar
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: size.isMobile ? 25 : 30, // ✅ Responsive icon
                  color: Colors.white,
                ),
              ),
              SizedBox(height: size.smallSpacing),
              Text(
                _userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.mediumText, // ✅ Responsive text
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_userEmail.isNotEmpty) ...[
                SizedBox(height: size.tinySpacing),
                Text(
                  _userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: size.smallText, // ✅ Responsive text
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_userDomain.isNotEmpty) ...[
                SizedBox(height: size.tinySpacing),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.isMobile ? 6 : 8, // ✅ Responsive padding
                    vertical: size.isMobile ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(size.isMobile ? 8 : 12), // ✅ Responsive radius
                  ),
                  child: Text(
                    '$_userDomain.veribiscrm.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.textSmall, // ✅ Responsive text
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(AppSizes size) {
    return Consumer<MenuProvider>(
      builder: (context, menuProvider, child) {
        if (menuProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (menuProvider.errorMessage != null) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(size.padding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  SizedBox(height: size.mediumSpacing),
                  Text(
                    'Menü yüklenemedi',
                    style: TextStyle(
                      fontSize: size.mediumText,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: size.smallSpacing),
                  Text(
                    menuProvider.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: size.smallText,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: size.largeSpacing),
                  ElevatedButton(
                    onPressed: () => menuProvider.loadMenu(),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          );
        }

        if (!menuProvider.hasMenuItems) {
          return Center(
            child: Text(
              'Menü bulunamadı',
              style: TextStyle(
                fontSize: size.mediumText,
                color: AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            // ✅ Ana Sayfa kaldırıldı - sadece dynamic menüler
            ...menuProvider.menuItems.map(
              (menuItem) => _buildMenuItemWithChildren(menuItem, size),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuItemWithChildren(MenuItem menuItem, AppSizes size) {
    if (!menuItem.hasChildren) {
      return _buildMenuItem(menuItem, size);
    }

    return ExpansionTile(
      leading: Icon(
        menuItem.icon,
        color: menuItem.color,
        size: size.isMobile ? 22 : 26, // ✅ İkon boyutu artırıldı
      ),
      title: Text(
        menuItem.cleanTitle,
        style: TextStyle(
          fontSize: size.mediumText, // ✅ Yazı boyutu artırıldı
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      iconColor: AppColors.primaryColor,
      collapsedIconColor: AppColors.textSecondary,
      tilePadding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: 8, // ✅ Dikey padding artırıldı
      ),
      children: menuItem.items.map((subItem) {
        return Padding(
          padding: EdgeInsets.only(left: size.horizontalPadding), // ✅ Responsive padding
          child: _buildMenuItem(subItem, size, isSubItem: true),
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(
    MenuItem menuItem,
    AppSizes size, {
    bool isSubItem = false,
    bool isHome = false,
  }) {
    return ListTile(
      leading: isSubItem
          ? Container(
              width: size.isMobile ? 24 : 28, // ✅ Sub-item ikon boyutu artırıldı
              height: size.isMobile ? 24 : 28,
              decoration: BoxDecoration(
                color: menuItem.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                menuItem.icon,
                color: menuItem.color,
                size: size.isMobile ? 16 : 18, // ✅ İç ikon boyutu artırıldı
              ),
            )
          : Icon(
              isHome ? Icons.home : menuItem.icon,
              color: isHome ? AppColors.primaryColor : menuItem.color,
              size: size.isMobile ? 22 : 26, // ✅ Ana ikon boyutu artırıldı
            ),
      title: Text(
        isHome ? 'Ana Sayfa' : menuItem.cleanTitle,
        style: TextStyle(
          fontSize: isSubItem ? size.textSize : size.mediumText, // ✅ Yazı boyutları artırıldı
          fontWeight: isSubItem ? FontWeight.w500 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () => _handleMenuTap(menuItem, isHome),
      dense: false, // ✅ Dense kapatıldı, daha geniş alan
      contentPadding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding * 0.8,
        vertical: size.isMobile ? 8 : 12, // ✅ Dikey padding artırıldı
      ),
    );
  }

  void _handleMenuTap(MenuItem menuItem, [bool isHome = false]) {
    Navigator.pop(context); // Drawer'ı kapat

    if (isHome) {
      // Ana sayfaya git
      return;
    }

    if (!menuItem.isNavigable) {
      context.showInfoSnackBar('Bu menü öğesi henüz aktif değil');
      return;
    }

    // URL'e göre navigasyon yap
    _navigateByUrl(menuItem.url!);
  }

  void _navigateByUrl(String url) {
    debugPrint('[MENU_DRAWER] Navigating to: $url');

    // ✅ Taha kullanıcısının menü URL'lerine göre düzeltilmiş navigasyon
    if (url.contains('CompanyAdd/Detail')) {
      Navigator.pushNamed(context, AppRoutes.addCompany);
    } else if (url.contains('CompanyAdd/List')) {
      Navigator.pushNamed(context, AppRoutes.companyList);
    } else if (url.contains('AktiviteAdd/Detail')) {
      // ✅ Taha'da farklı URL
      Navigator.pushNamed(context, AppRoutes.addActivity);
    } else if (url.contains('AktiviteAdd/List')) {
      // ✅ Taha'da farklı URL
      Navigator.pushNamed(context, AppRoutes.activityList);
    } else if (url.contains('ContactAdd/Detail')) {
      // Kişi ekleme sayfası - henüz yok
      context.showInfoSnackBar('Kişi ekleme sayfası hazırlanıyor');
    } else if (url.contains('ContactAdd/List')) {
      // Kişi listesi sayfası - henüz yok
      context.showInfoSnackBar('Kişi listesi sayfası hazırlanıyor');
    } else {
      // Genel web view veya başka bir navigasyon
      context.showInfoSnackBar('Bu sayfa henüz hazırlanıyor: ${url.split('/').last}');
    }
  }

  Widget _buildDrawerFooter(AppSizes size) {
    return Container(
      height: size.isMobile ? 60 : 70, // ✅ Footer yüksekliği küçültüldü
      padding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: 8, // ✅ Dikey padding küçültüldü
      ),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.logout,
          color: AppColors.redColor,
          size: size.isMobile ? 22 : 26, // ✅ İkon boyutu artırıldı
        ),
        title: Text(
          'Çıkış Yap',
          style: TextStyle(
            fontSize: size.mediumText, // ✅ Yazı boyutu artırıldı
            color: AppColors.redColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () {
          debugPrint('[MENU_DRAWER] 🚪 Logout ListTile tapped!');
          _handleLogout();
        },
        contentPadding: EdgeInsets.symmetric(
          horizontal: size.horizontalPadding * 0.3, // ✅ Padding küçültüldü
          vertical: 0,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    // ✅ Context'i önceden al
    final navigatorContext = Navigator.of(context);
    final scaffoldContext = ScaffoldMessenger.of(context);

    Navigator.pop(context); // Drawer'ı kapat

    // Debug log ekleyelim
    debugPrint('[MENU_DRAWER] 🚪 Logout button tapped');

    try {
      final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
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
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
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

      debugPrint('[MENU_DRAWER] 🚪 Confirmation result: $shouldLogout');

      if (!shouldLogout) return;

      debugPrint('[MENU_DRAWER] 🚪 Starting logout process...');

      await _authService.logout();

      debugPrint('[MENU_DRAWER] 🚪 Logout successful, clearing menu...');

      // ✅ Success message göster
      scaffoldContext.showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Başarıyla çıkış yapıldı',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // ✅ Navigation - context'e bağımlı olmadan
      debugPrint('[MENU_DRAWER] 🚪 Navigating to login...');
      navigatorContext.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
      debugPrint('[MENU_DRAWER] ✅ Navigation completed!');
    } catch (e) {
      debugPrint('[MENU_DRAWER] ❌ Logout error: $e');

      // ✅ Hata durumunda da navigation yap
      try {
        navigatorContext.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
        debugPrint('[MENU_DRAWER] ✅ Error navigation completed!');
      } catch (navError) {
        debugPrint('[MENU_DRAWER] ❌ Navigation also failed: $navError');
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
}
