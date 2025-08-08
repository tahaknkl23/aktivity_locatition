// lib/presentation/widgets/menu/menu_drawer.dart
import 'package:aktivity_location_app/presentation/screens/report/report_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/menu/menu_model.dart';
import '../../../data/services/api/auth_service.dart';
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
    // 🔍 ENHANCED DEBUG LOGS
    debugPrint('[MENU_DRAWER] =====================================');
    debugPrint('[MENU_DRAWER] 🎯 Menu tapped: ${menuItem.cleanTitle}');
    debugPrint('[MENU_DRAWER] 🎯 Menu URL: ${menuItem.url}');
    debugPrint('[MENU_DRAWER] 🎯 Is navigable: ${menuItem.isNavigable}');
    debugPrint('[MENU_DRAWER] 🎯 Has children: ${menuItem.hasChildren}');
    debugPrint('[MENU_DRAWER] 🎯 Dashboard: ${menuItem.dashboard}');
    debugPrint('[MENU_DRAWER] 🎯 ID: ${menuItem.id}');
    debugPrint('[MENU_DRAWER] =====================================');

    Navigator.pop(context); // Drawer'ı kapat

    if (isHome) {
      return;
    }

    // 🔍 URL kontrolü
    if (menuItem.url == null || menuItem.url!.isEmpty) {
      debugPrint('[MENU_DRAWER] ❌ URL is null or empty!');
      context.showInfoSnackBar('Bu menü öğesinin URL\'si yok');
      return;
    }

    if (!menuItem.isNavigable) {
      debugPrint('[MENU_DRAWER] ❌ Menu item is not navigable!');
      context.showInfoSnackBar('Bu menü öğesi henüz aktif değil');
      return;
    }

    // 🔍 URL ANALYSIS
    final url = menuItem.url!;
    final urlParts = url.split('/').where((part) => part.isNotEmpty).toList();

    debugPrint('[MENU_DRAWER] 🔍 URL Parts: $urlParts');
    debugPrint('[MENU_DRAWER] 🔍 URL Length: ${urlParts.length}');

    // URL formatını analiz et
    if (urlParts.isEmpty) {
      debugPrint('[MENU_DRAWER] ❌ Empty URL parts!');
      _showUrlError(url, 'URL parçaları boş');
      return;
    }

    // 🆕 REPORT URL HANDLING - Report/Detail/ID formatı
    if (urlParts[0].toLowerCase() == 'report') {
      debugPrint('[MENU_DRAWER] 📊 REPORT URL detected!');
      _handleReportUrl(urlParts, url, menuItem.cleanTitle);
      return;
    }

    // Dyn kontrolü (eski format)
    if (urlParts[0].toLowerCase() != 'dyn') {
      debugPrint('[MENU_DRAWER] ❌ URL does not start with Dyn or Report!');
      _showUrlError(url, 'URL formatı tanınmıyor (Dyn veya Report ile başlamalı)');
      return;
    }

    if (urlParts.length < 3) {
      debugPrint('[MENU_DRAWER] ❌ URL too short (need at least /Dyn/Controller/Action)');
      _showUrlError(url, 'URL çok kısa - en az /Dyn/Controller/Action gerekli');
      return;
    }

    final controller = urlParts[1];
    final action = urlParts[2];
    final params = urlParts.length > 3 ? urlParts.sublist(3) : <String>[];

    debugPrint('[MENU_DRAWER] 🔍 Controller: $controller');
    debugPrint('[MENU_DRAWER] 🔍 Action: $action');
    debugPrint('[MENU_DRAWER] 🔍 Params: $params');

    // Navigation stratejisini belirle
    try {
      _navigateByAnalysis(controller, action, params, url, menuItem.cleanTitle);
    } catch (e) {
      debugPrint('[MENU_DRAWER] ❌ Navigation error: $e');
      _showUrlError(url, 'Navigation hatası: $e');
    }
  }

  /// 🆕 REPORT URL HANDLER
  void _handleReportUrl(List<String> urlParts, String fullUrl, String title) {
    debugPrint('[MENU_DRAWER] 📊 Handling report URL...');
    debugPrint('[MENU_DRAWER] 📊 URL Parts: $urlParts');
    debugPrint('[MENU_DRAWER] 📊 Full URL: $fullUrl');
    debugPrint('[MENU_DRAWER] 📊 Title: $title');

    if (urlParts.length < 3) {
      debugPrint('[MENU_DRAWER] ❌ Report URL too short (need Report/Detail/ID)');
      _showUrlError(fullUrl, 'Report URL çok kısa - Report/Detail/ID formatı gerekli');
      return;
    }

    final reportAction = urlParts[1]; // Detail
    final reportId = urlParts[2]; // 12, 2, vs.

    debugPrint('[MENU_DRAWER] 📊 Report Action: $reportAction');
    debugPrint('[MENU_DRAWER] 📊 Report ID: $reportId');

    // Report için özel navigation
    try {
      _navigateToReport(reportId, title, fullUrl);
    } catch (e) {
      debugPrint('[MENU_DRAWER] ❌ Report navigation error: $e');
      _showUrlError(fullUrl, 'Rapor açılamadı: $e');
    }
  }

  /// 🆕 REPORT NAVIGATION
  void _navigateToReport(String reportId, String title, String fullUrl) {
    debugPrint('[MENU_DRAWER] 📊 Navigating to report...');
    debugPrint('[MENU_DRAWER] 📊 Report ID: $reportId');
    debugPrint('[MENU_DRAWER] 📊 Title: $title');

    try {
      // Report Screen'e git
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DynamicReportScreen(
            reportId: reportId,
            title: title,
            url: fullUrl,
          ),
        ),
      );
      debugPrint('[MENU_DRAWER] ✅ Report navigation successful');
    } catch (e) {
      debugPrint('[MENU_DRAWER] ❌ Report navigation failed: $e');
      _showUrlError(fullUrl, 'Rapor açılamadı: $e');
    }
  }

  /// URL analizi ile navigation yap
  void _navigateByAnalysis(String controller, String action, List<String> params, String fullUrl, String title) {
    debugPrint('[MENU_DRAWER] 🚀 Starting navigation analysis...');

    // Action'a göre strateji belirle
    final actionLower = action.toLowerCase();
    final hasParams = params.isNotEmpty;
    final paramString = hasParams ? params.join('/') : '';

    debugPrint('[MENU_DRAWER] 🔍 Action (lower): $actionLower');
    debugPrint('[MENU_DRAWER] 🔍 Has params: $hasParams');
    debugPrint('[MENU_DRAWER] 🔍 Param string: $paramString');

    // 1. BILINEN CONTROLLER'LAR IÇIN DIRECT ROUTING
    if (_tryDirectRouting(controller, action, params)) {
      debugPrint('[MENU_DRAWER] ✅ Direct routing successful');
      return;
    }

    // 2. ACTION BAZLI ROUTING
    if (actionLower == 'detail') {
      debugPrint('[MENU_DRAWER] 📝 Detected FORM action');
      _navigateToGenericForm(controller, fullUrl, title);
    } else if (actionLower == 'list') {
      debugPrint('[MENU_DRAWER] 📋 Detected LIST action');
      _navigateToGenericList(controller, fullUrl, title);
    } else if (hasParams) {
      // Parametreli durumlar için analiz
      final paramLower = paramString.toLowerCase();
      debugPrint('[MENU_DRAWER] 🔍 Analyzing params: $paramLower');

      if (paramLower.contains('list') || paramLower.contains('rapor') || paramLower.contains('report')) {
        debugPrint('[MENU_DRAWER] 📋 Detected LIST in params');
        _navigateToGenericList(controller, fullUrl, title);
      } else {
        debugPrint('[MENU_DRAWER] 📝 Defaulting to FORM for params');
        _navigateToGenericForm(controller, fullUrl, title);
      }
    } else {
      debugPrint('[MENU_DRAWER] ❓ Unknown action, showing info');
      _showUrlError(fullUrl, 'Bilinmeyen action: $action');
    }
  }

  /// Bilinen controller'lar için direct routing dene
  bool _tryDirectRouting(String controller, String action, List<String> params) {
    final controllerLower = controller.toLowerCase();
    final actionLower = action.toLowerCase();

    debugPrint('[MENU_DRAWER] 🔍 Trying direct routing for: $controllerLower/$actionLower');

    // Company routes
    if (controllerLower == 'companyadd') {
      if (actionLower == 'detail') {
        debugPrint('[MENU_DRAWER] ➡️ Direct route: Company Add');
        Navigator.pushNamed(context, AppRoutes.addCompany);
        return true;
      } else if (actionLower == 'list') {
        debugPrint('[MENU_DRAWER] ➡️ Direct route: Company List');
        Navigator.pushNamed(context, AppRoutes.companyList);
        return true;
      }
    }

    // Activity routes
    if (controllerLower == 'aktiviteadd' || controllerLower == 'aktivitebranchadd') {
      if (actionLower == 'detail') {
        debugPrint('[MENU_DRAWER] ➡️ Direct route: Activity Add');
        Navigator.pushNamed(context, AppRoutes.addActivity);
        return true;
      } else if (actionLower == 'list') {
        debugPrint('[MENU_DRAWER] ➡️ Direct route: Activity List');
        Navigator.pushNamed(context, AppRoutes.activityList);
        return true;
      }
    }

    debugPrint('[MENU_DRAWER] ❌ No direct route found');
    return false;
  }

  /// Generic form sayfasına git - ENHANCED
  void _navigateToGenericForm(String controller, String url, String title) {
    debugPrint('[MENU_DRAWER] 📝 Navigating to generic form...');
    debugPrint('[MENU_DRAWER] 📝 Controller: $controller');
    debugPrint('[MENU_DRAWER] 📝 URL: $url');
    debugPrint('[MENU_DRAWER] 📝 Title: $title');

    try {
      Navigator.pushNamed(
        context,
        AppRoutes.dynamicForm,
        arguments: {
          'controller': controller,
          'url': url,
          'title': title,
          'isAdd': true,
        },
      );
      debugPrint('[MENU_DRAWER] ✅ Generic form navigation successful');
    } catch (e) {
      debugPrint('[MENU_DRAWER] ❌ Generic form navigation failed: $e');
      _showUrlError(url, 'Form sayfası açılamadı: $e');
    }
  }

  /// Generic liste sayfasına git - ENHANCED
  void _navigateToGenericList(String controller, String url, String title) {
    debugPrint('[MENU_DRAWER] 📋 Navigating to generic list...');
    debugPrint('[MENU_DRAWER] 📋 Controller: $controller');
    debugPrint('[MENU_DRAWER] 📋 URL: $url');
    debugPrint('[MENU_DRAWER] 📋 Title: $title');

    try {
      Navigator.pushNamed(
        context,
        AppRoutes.dynamicList,
        arguments: {
          'controller': controller,
          'url': url,
          'title': title,
          'listType': 'generic',
        },
      );
      debugPrint('[MENU_DRAWER] ✅ Generic list navigation successful');
    } catch (e) {
      debugPrint('[MENU_DRAWER] ❌ Generic list navigation failed: $e');
      _showUrlError(url, 'Liste sayfası açılamadı: $e');
    }
  }

  /// URL hata mesajı göster - ENHANCED
  void _showUrlError(String url, String reason) {
    debugPrint('[MENU_DRAWER] ❌ URL Error: $reason');
    debugPrint('[MENU_DRAWER] ❌ Failed URL: $url');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sayfa açılamadı',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Sebep: $reason'),
            Text('URL: $url', style: TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Kopyala',
          textColor: Colors.white,
          onPressed: () {
            // URL'yi kopyalama işlemi buraya eklenebilir
            debugPrint('[MENU_DRAWER] 📋 URL copied to debug: $url');
          },
        ),
      ),
    );
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
}
