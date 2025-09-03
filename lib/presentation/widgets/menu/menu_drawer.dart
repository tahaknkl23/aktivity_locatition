// lib/presentation/widgets/menu/menu_drawer.dart - ENHANCED VERSION
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/routes/app_routes.dart';
import '../../../data/models/menu/menu_model.dart';
import '../../../data/services/api/auth_service.dart';
import '../../../data/services/api/menu_api_service.dart';
import '../../providers/menu_provider.dart';
import '../../screens/attachment/attachment_list_screen.dart';
import '../../screens/report/dynamic_report_screen.dart';

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
    _initializeReportMapper();
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

  /// Report mapper'ı başlat
  Future<void> _initializeReportMapper() async {
    try {
      // Eğer mappings boşsa, varsayılan değerleri yükle
      if (!ReportGroupMapper.instance.hasMappings) {
        ReportGroupMapper.instance.loadDefaultMappings();
      }
    } catch (e) {
      debugPrint('[MENU_DRAWER] Report mapper init error: $e');
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
      height: size.isMobile ? 200 : 240,
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
          padding: EdgeInsets.all(size.horizontalPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: size.isMobile ? 25 : 30,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                child: Icon(
                  Icons.person,
                  size: size.isMobile ? 25 : 30,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: size.smallSpacing),
              Text(
                _userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: size.mediumText,
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
                    fontSize: size.smallText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (_userDomain.isNotEmpty) ...[
                SizedBox(height: size.tinySpacing),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: size.isMobile ? 6 : 8,
                    vertical: size.isMobile ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(size.isMobile ? 8 : 12),
                  ),
                  child: Text(
                    '$_userDomain.veribiscrm.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size.textSmall,
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
          return const Center(child: CircularProgressIndicator());
        }

        if (menuProvider.errorMessage != null) {
          return _buildErrorState(menuProvider, size);
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
            // Menu items
            ...menuProvider.menuItems.map(
              (menuItem) => _buildMenuItemWithChildren(menuItem, size),
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorState(MenuProvider menuProvider, AppSizes size) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(size.padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
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

  Widget _buildMenuItemWithChildren(MenuItem menuItem, AppSizes size) {
    if (!menuItem.hasChildren) {
      return _buildMenuItem(menuItem, size);
    }

    return ExpansionTile(
      leading: Icon(
        menuItem.icon,
        color: menuItem.color,
        size: size.isMobile ? 22 : 26,
      ),
      title: Text(
        menuItem.cleanTitle,
        style: TextStyle(
          fontSize: size.mediumText,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      iconColor: AppColors.primaryColor,
      collapsedIconColor: AppColors.textSecondary,
      tilePadding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: 8,
      ),
      children: menuItem.items.map((subItem) {
        return Padding(
          padding: EdgeInsets.only(left: size.horizontalPadding),
          child: _buildMenuItemWithChildren(subItem, size),
        );
      }).toList(),
    );
  }

  Widget _buildMenuItem(MenuItem menuItem, AppSizes size, {bool isSubItem = false}) {
    return ListTile(
      leading: isSubItem
          ? Container(
              width: size.isMobile ? 24 : 28,
              height: size.isMobile ? 24 : 28,
              decoration: BoxDecoration(
                color: menuItem.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                menuItem.icon,
                color: menuItem.color,
                size: size.isMobile ? 16 : 18,
              ),
            )
          : Icon(
              menuItem.icon,
              color: menuItem.color,
              size: size.isMobile ? 22 : 26,
            ),
      title: Text(
        menuItem.cleanTitle,
        style: TextStyle(
          fontSize: isSubItem ? size.textSize : size.mediumText,
          fontWeight: isSubItem ? FontWeight.w500 : FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: () => _handleMenuTap(menuItem),
      dense: false,
      contentPadding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding * 0.8,
        vertical: size.isMobile ? 8 : 12,
      ),
    );
  }

  void _handleMenuTap(MenuItem menuItem) {
    debugPrint('[MENU_DRAWER] =====================================');
    debugPrint('[MENU_DRAWER] Menu tapped: ${menuItem.cleanTitle}');
    debugPrint('[MENU_DRAWER] Menu URL: ${menuItem.url}');
    debugPrint('[MENU_DRAWER] =====================================');

    Navigator.pop(context);

    // NULL URL CHECK: Web'deki davranışı taklit et
    if (menuItem.url == null || menuItem.url!.isEmpty) {
      debugPrint('[MENU_DRAWER] NULL URL - MenuItem disabled: ${menuItem.cleanTitle}');

      context.showInfoSnackBar('${menuItem.cleanTitle} henüz aktif değil');
      return;
    }

    if (!menuItem.isNavigable) {
      context.showInfoSnackBar('Bu menü öğesi henüz aktif değil');
      return;
    }

    final url = menuItem.url!;
    final urlParts = url.split('/').where((part) => part.isNotEmpty).toList();

    if (urlParts.isEmpty) {
      _showUrlError(url, 'URL parçaları boş');
      return;
    }

    final firstPart = urlParts[0].toLowerCase();

    switch (firstPart) {
      case 'dyn':
        _handleDynUrl(urlParts, url, menuItem.cleanTitle);
        break;
      case 'report':
        _handleReportUrl(urlParts, url, menuItem.cleanTitle);
        break;
      case 'attachment':
        _handleAttachmentUrl(urlParts, url, menuItem.cleanTitle);
        break;
      default:
        _handleUnknownUrl(urlParts, url, menuItem.cleanTitle);
        break;
    }
  }

  void _handleDynUrl(List<String> urlParts, String fullUrl, String title) {
    if (urlParts.length < 3) {
      _showUrlError(fullUrl, 'URL çok kısa - en az /Dyn/Controller/Action gerekli');
      return;
    }

    final controller = urlParts[1];
    final action = urlParts[2];
    final params = urlParts.length > 3 ? urlParts.sublist(3) : <String>[];

    try {
      _navigateByAnalysis(controller, action, params, fullUrl, title);
    } catch (e) {
      _showUrlError(fullUrl, 'Navigation hatası: $e');
    }
  }

  /// ENHANCED Report URL Handler - Dynamic Group ID lookup
  void _handleReportUrl(List<String> urlParts, String fullUrl, String title) {
    debugPrint('[MENU_DRAWER] Handling report URL...');
    debugPrint('[MENU_DRAWER] URL Parts: $urlParts');
    debugPrint('[MENU_DRAWER] Title: $title');

    // SPECIAL CASE: Dinamik Rapor
    if (urlParts.length >= 2 && urlParts[1].toLowerCase() == 'dynamicreport') {
      debugPrint('[MENU_DRAWER] Dynamic Report detected - showing placeholder');
      _showDynamicReportPlaceholder(title);
      return;
    }

    // 1. URL'den Group ID çıkarmaya çalış
    String? groupId = _extractGroupIdFromUrl(fullUrl, title);

    // 2. Eğer URL'den çıkaramazsan, title'dan bul
    if (groupId == null) {
      groupId = ReportGroupMapper.instance.getGroupIdByTitle(title);
      debugPrint('[MENU_DRAWER] Group ID from title mapping: $groupId');
    }

    // 3. Hala bulamazsan varsayılan mapping dene
    if (groupId == null) {
      groupId = _getFallbackGroupId(title);
      debugPrint('[MENU_DRAWER] Fallback Group ID: $groupId');
    }

    if (groupId == null) {
      debugPrint('[MENU_DRAWER] Group ID could not be determined');
      _showUrlError(fullUrl, 'Rapor grup ID\'si belirlenemedi');
      return;
    }

    try {
      _navigateToReportGroup(groupId, title, fullUrl);
    } catch (e) {
      _showUrlError(fullUrl, 'Rapor açılamadı: $e');
    }
  }

  /// Dinamik Rapor için placeholder göster
  void _showDynamicReportPlaceholder(String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.dynamic_form,
            color: Colors.blue,
            size: 32,
          ),
        ),
        title: Text(title),
        content: const Text(
          'Dinamik Rapor sistemi yakında mobil uygulamaya eklenecek.\n\nŞu anda sadece web versiyonunda kullanılabilir.',
          textAlign: TextAlign.center,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _handleAttachmentUrl(List<String> urlParts, String fullUrl, String title) {
    Map<String, dynamic> parameters = {};

    if (fullUrl.contains('?')) {
      final queryString = fullUrl.split('?')[1];
      final queryParams = queryString.split('&');

      for (final param in queryParams) {
        if (param.contains('=')) {
          final keyValue = param.split('=');
          final key = Uri.decodeComponent(keyValue[0]);
          final value = Uri.decodeComponent(keyValue[1]);

          if (key == 'MenuTitle') {
            parameters['MenuTitle'] = [value, title];
          } else {
            parameters[key] = value;
          }
        }
      }
    }

    if (parameters.isEmpty) {
      parameters['MenuTitle'] = ['Listele', title];
    }

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttachmentListScreen(
            title: title,
            specialName: 'AttachmentListQuery',
            parameters: parameters,
          ),
        ),
      );
    } catch (e) {
      _showUrlError(fullUrl, 'Dosyalar sayfası açılamadı: $e');
    }
  }

  void _handleUnknownUrl(List<String> urlParts, String fullUrl, String title) {
    final firstPart = urlParts[0];
    final action = urlParts.length > 1 ? urlParts[1] : 'List';
    final controller = '${firstPart.substring(0, 1).toUpperCase()}${firstPart.substring(1).toLowerCase()}Add';

    try {
      if (action.toLowerCase().contains('list')) {
        _navigateToGenericList(controller, fullUrl, title);
      } else {
        _navigateToGenericForm(controller, fullUrl, title);
      }
    } catch (e) {
      _showUrlError(fullUrl, 'Bu URL formatı henüz desteklenmiyor');
    }
  }

  /// Enhanced Group ID extraction - SIMPLIFIED
  String? _extractGroupIdFromUrl(String fullUrl, String title) {
    try {
      // Pattern: Report/Detail/123 → Extract 123
      final reportPattern = RegExp(r'Report/Detail/(\d+)');
      final match = reportPattern.firstMatch(fullUrl);
      if (match != null) {
        debugPrint('[MENU_DRAWER] Group ID from URL: ${match.group(1)}');
        return match.group(1);
      }
    } catch (e) {
      debugPrint('[MENU_DRAWER] URL parsing error: $e');
    }

    return null;
  }

  /// Fallback group ID mapping for unknown titles
  String? _getFallbackGroupId(String title) {
    final lowerTitle = title.toLowerCase();

    // Temel kategorilere göre varsayılan mapping
    if (lowerTitle.contains('aktivite') || lowerTitle.contains('ziyaret')) return '5';
    if (lowerTitle.contains('kişi') || lowerTitle.contains('müşteri')) return '11';
    if (lowerTitle.contains('firma') || lowerTitle.contains('şirket')) return '12';
    if (lowerTitle.contains('satış')) return '66';

    // Varsayılan
    return '1';
  }

  void _navigateToReportGroup(String groupId, String title, String fullUrl) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DynamicReportScreen(
            reportId: groupId,
            title: title,
            url: fullUrl,
          ),
        ),
      );
      debugPrint('[MENU_DRAWER] Report group navigation successful');
    } catch (e) {
      _showUrlError(fullUrl, 'Rapor grubu açılamadı: $e');
    }
  }

  void _navigateByAnalysis(String controller, String action, List<String> params, String fullUrl, String title) {
    if (_tryDirectRouting(controller, action, params)) {
      return;
    }

    final actionLower = action.toLowerCase();
    final hasParams = params.isNotEmpty;
    final paramString = hasParams ? params.join('/') : '';

    if (actionLower == 'detail') {
      _navigateToGenericForm(controller, fullUrl, title);
    } else if (actionLower == 'list') {
      _navigateToGenericList(controller, fullUrl, title);
    } else if (hasParams) {
      final paramLower = paramString.toLowerCase();
      if (paramLower.contains('list') || paramLower.contains('rapor') || paramLower.contains('report')) {
        _navigateToGenericList(controller, fullUrl, title);
      } else {
        _navigateToGenericForm(controller, fullUrl, title);
      }
    } else {
      _showUrlError(fullUrl, 'Bilinmeyen action: $action');
    }
  }

  bool _tryDirectRouting(String controller, String action, List<String> params) {
    final controllerLower = controller.toLowerCase();
    final actionLower = action.toLowerCase();

    if (controllerLower == 'companyadd') {
      if (actionLower == 'detail') {
        Navigator.pushNamed(context, AppRoutes.addCompany);
        return true;
      } else if (actionLower == 'list') {
        Navigator.pushNamed(context, AppRoutes.companyList);
        return true;
      }
    }

    if (controllerLower == 'aktiviteadd' || controllerLower == 'aktivitebranchadd') {
      if (actionLower == 'detail') {
        Navigator.pushNamed(context, AppRoutes.addActivity);
        return true;
      } else if (actionLower == 'list') {
        Navigator.pushNamed(context, AppRoutes.activityList);
        return true;
      }
    }

    return false;
  }

  void _navigateToGenericForm(String controller, String url, String title) {
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
    } catch (e) {
      _showUrlError(url, 'Form sayfası açılamadı: $e');
    }
  }

  void _navigateToGenericList(String controller, String url, String title) {
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
    } catch (e) {
      _showUrlError(url, 'Liste sayfası açılamadı: $e');
    }
  }

  void _showUrlError(String url, String reason) {
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
      ),
    );
  }

  Widget _buildDrawerFooter(AppSizes size) {
    return Container(
      height: size.isMobile ? 60 : 70,
      padding: EdgeInsets.symmetric(
        horizontal: size.horizontalPadding,
        vertical: 8,
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
          size: size.isMobile ? 22 : 26,
        ),
        title: Text(
          'Çıkış Yap',
          style: TextStyle(
            fontSize: size.mediumText,
            color: AppColors.redColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: _handleLogout,
        contentPadding: EdgeInsets.symmetric(
          horizontal: size.horizontalPadding * 0.3,
          vertical: 0,
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final navigatorContext = Navigator.of(context);
    final scaffoldContext = ScaffoldMessenger.of(context);

    Navigator.pop(context);

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

      if (!shouldLogout) return;

      await _authService.logout();

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

      navigatorContext.pushNamedAndRemoveUntil(
        AppRoutes.login,
        (route) => false,
      );
    } catch (e) {
      try {
        navigatorContext.pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      } catch (navError) {
        debugPrint('[MENU_DRAWER] Navigation also failed: $navError');
      }
    }
  }
}
