// lib/screens/login/login_screen.dart - RESPONSIVE OPTION 2
import 'package:aktivity_location_app/core/constants/app_colors.dart';
import 'package:aktivity_location_app/core/constants/app_duration.dart';
import 'package:aktivity_location_app/core/constants/app_sizes.dart';
import 'package:aktivity_location_app/core/constants/app_strings.dart';
import 'package:aktivity_location_app/core/extensions/context_extensions.dart';
import 'package:aktivity_location_app/core/helpers/snackbar_helper.dart';
import 'package:aktivity_location_app/core/routes/app_routes.dart';
import 'package:aktivity_location_app/core/widgets/common/app_version_info_widget.dart';
import 'package:aktivity_location_app/data/services/api/auth_service.dart';
import 'package:aktivity_location_app/presentation/screens/auth/widgets/forgot_password.dart';
import 'package:aktivity_location_app/presentation/screens/auth/widgets/login_background.dart';
import 'package:aktivity_location_app/presentation/screens/auth/widgets/login_button.dart';
import 'package:aktivity_location_app/presentation/screens/auth/widgets/login_form.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/session_timeout_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isLoading = false;
  String? _currentDomain;

  @override
  void initState() {
    super.initState();
    _loadCurrentDomain();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // 🎯 Domain'i yükle ve o domain'e özel kullanıcı bilgilerini getir
  Future<void> _loadCurrentDomain() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final subdomain = prefs.getString('subdomain');

      if (subdomain != null && subdomain.isNotEmpty) {
        setState(() {
          _currentDomain = '$subdomain.veribiscrm.com';
        });

        // Bu domain'e özel kullanıcı bilgilerini yükle
        await _loadDomainSpecificCredentials(subdomain);

        debugPrint('[LOGIN] Current domain: $_currentDomain');
      } else {
        setState(() {
          _currentDomain = null;
        });
        debugPrint('[LOGIN] No domain found');
      }
    } catch (e) {
      debugPrint('[LOGIN] Error loading domain: $e');
      setState(() {
        _currentDomain = null;
      });
    }
  }

  // 🎯 Domain'e özel kullanıcı bilgilerini yükle
  Future<void> _loadDomainSpecificCredentials(String subdomain) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Domain bazlı key'ler kullan
      final domainEmailKey = 'saved_email_$subdomain';
      final domainPasswordKey = 'saved_password_$subdomain';

      final savedEmail = prefs.getString(domainEmailKey) ?? '';
      final savedPassword = prefs.getString(domainPasswordKey) ?? '';

      if (savedEmail.isNotEmpty) {
        emailController.text = savedEmail;
        debugPrint('[LOGIN] Loaded saved email for $subdomain: $savedEmail');
      } else {
        emailController.text = '';
      }

      if (savedPassword.isNotEmpty) {
        passwordController.text = savedPassword;
        debugPrint('[LOGIN] Loaded saved password for $subdomain');
      } else {
        passwordController.text = '';
      }
    } catch (e) {
      debugPrint('[LOGIN] Error loading domain-specific credentials: $e');
      emailController.text = '';
      passwordController.text = '';
    }
  }

  // 🎯 Başarılı login sonrası domain'e özel kayıt
  Future<void> _saveSuccessfulLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Domain geçmişine kaydet
      final subdomain = prefs.getString('subdomain');
      if (subdomain != null && subdomain.isNotEmpty) {
        final fullDomain = '$subdomain.veribiscrm.com';
        final loginHistory = prefs.getStringList('login_history') ?? [];

        loginHistory.remove(fullDomain);
        loginHistory.insert(0, fullDomain);

        if (loginHistory.length > 10) {
          loginHistory.removeRange(10, loginHistory.length);
        }

        await prefs.setStringList('login_history', loginHistory);
        debugPrint('[LOGIN] Saved to history: $fullDomain');

        // 🎯 Domain'e özel kullanıcı bilgilerini kaydet
        final domainEmailKey = 'saved_email_$subdomain';
        final domainPasswordKey = 'saved_password_$subdomain';

        await prefs.setString(domainEmailKey, emailController.text.trim());
        await prefs.setString(domainPasswordKey, passwordController.text.trim());
        debugPrint('[LOGIN] Saved credentials for domain: $subdomain');
      }
    } catch (e) {
      debugPrint('[LOGIN] Error saving successful login: $e');
    }
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    final result = await _authService.login(email, password, context);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      await _saveSuccessfulLogin();
      SessionTimeoutService.instance.recordActivity();

      if (mounted) {
        SnackbarHelper.showSuccess(context: context, message: "Giriş başarılı!");
      }

      Future.delayed(AppDurations.yarimSecond, () {
        if (mounted) {
          context.pushReplacementNamed(AppRoutes.main);
        }
      });
    } else {
      if (mounted && result.errorMessage != null) {
        SnackbarHelper.showError(context: context, message: result.errorMessage!);
      }
    }
  }

  // 🎯 Domain değiştirme - form alanlarını temizle
  void _handleDomainChange() async {
    try {
      final shouldChange = await _showDomainChangeDialog();
      if (!shouldChange) return;

      final prefs = await SharedPreferences.getInstance();

      // Session verilerini temizle
      await prefs.remove('subdomain');
      await prefs.remove('token');
      await prefs.remove('full_name');
      await prefs.remove('user_id');
      await prefs.remove('picture_url');

      // 🎯 Form alanlarını da temizle
      emailController.clear();
      passwordController.clear();

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.domainSelection,
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('[LOGIN] Domain change error: $e');
      if (mounted) {
        SnackbarHelper.showError(context: context, message: "Domain değiştirme sırasında hata oluştu.");
      }
    }
  }

  // 🎯 Domain değiştirme onay dialog'u - RESPONSIVE
  Future<bool> _showDomainChangeDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isTablet = screenWidth > 600;

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
              ),
              contentPadding: EdgeInsets.all(isTablet ? 32 : 24),
              icon: Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.swap_horiz,
                  color: AppColors.primaryColor,
                  size: isTablet ? 40 : 32,
                ),
              ),
              title: Text(
                'Domain Değiştir',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 22 : 18,
                ),
              ),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isTablet ? 400 : double.infinity,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Farklı bir domain seçmek istediğinizden emin misiniz?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: isTablet ? 16 : 12),
                    if (_currentDomain != null)
                      Container(
                        padding: EdgeInsets.all(isTablet ? 16 : 12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.domain,
                              color: Colors.blue,
                              size: isTablet ? 24 : 20,
                            ),
                            SizedBox(width: isTablet ? AppDimensions.paddingM : AppDimensions.paddingS),
                            Expanded(
                              child: Text(
                                'Mevcut: $_currentDomain',
                                style: TextStyle(
                                  fontSize: isTablet ? 14 : 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Container(
                      padding: EdgeInsets.all(isTablet ? 16 : 12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.cleaning_services,
                                color: Colors.orange,
                                size: isTablet ? 24 : 20,
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Expanded(
                                child: Text(
                                  'Giriş alanları temizlenecek',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isTablet ? 8 : 4),
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange,
                                size: isTablet ? 24 : 20,
                              ),
                              SizedBox(width: isTablet ? 12 : 8),
                              Expanded(
                                child: Text(
                                  'Mevcut oturumunuz sonlandırılacak',
                                  style: TextStyle(
                                    fontSize: isTablet ? 14 : 12,
                                    color: Colors.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTablet ? 24 : 16,
                      vertical: isTablet ? 12 : 8,
                    ),
                  ),
                  child: Text(
                    'Değiştir',
                    style: TextStyle(fontSize: isTablet ? 16 : 14),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);
    final screenWidth = size.width;

    // 📱 RESPONSIVE CALCULATIONS using your AppSizes
    final isSmallPhone = screenWidth < 360;
    final isTablet = screenWidth > AppDimensions.mobileBreakpoint;

    // Dynamic sizing based on your existing size system
    final logoSize = isTablet
        ? size.titleText * 1.5
        : isSmallPhone
            ? size.titleText * 1.2
            : size.titleText * 1.3;

    final domainFontSize = isTablet
        ? size.mediumText
        : isSmallPhone
            ? size.smallText
            : size.textSize;

    final linkFontSize = isTablet
        ? size.textSize * 1.1
        : isSmallPhone
            ? size.textSmall * 1.2
            : size.textSize;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: LoginBackground(
        child: Stack(
          // 🆕 Stack ekledik
          children: [
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isTablet ? size.padding * 2 : size.padding,
                      right: isTablet ? size.padding * 2 : size.padding,
                      bottom: MediaQuery.of(context).viewInsets.bottom + (isTablet ? 32 : 24),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                        // Tablet için max width using your dimensions
                        maxWidth: isTablet ? 500 : double.infinity,
                      ),
                      child: isTablet
                          ? Center(
                              child: _buildLoginContent(size, logoSize, domainFontSize, linkFontSize, isSmallPhone, isTablet),
                            )
                          : IntrinsicHeight(
                              child: _buildLoginContent(size, logoSize, domainFontSize, linkFontSize, isSmallPhone, isTablet),
                            ),
                    ),
                  );
                },
              ),
            ),

            // 🆕 Version bilgisi - sadece bu satır eklendi
            AppVersionInfoWidget(isFloating: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginContent(AppSizes size, double logoSize, double domainFontSize, double linkFontSize, bool isSmallPhone, bool isTablet) {
    return Column(
      mainAxisAlignment: isTablet ? MainAxisAlignment.center : MainAxisAlignment.center,
      children: [
        // 🎯 DOMAIN BİLGİSİ - RESPONSIVE, SADECE GÖRÜNTÜLEME
        if (_currentDomain != null)
          Container(
            width: double.infinity,
            margin: EdgeInsets.only(
              bottom: isTablet ? size.height * 0.03 : size.height * 0.02,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? AppDimensions.paddingXL : AppDimensions.paddingM,
              vertical: isTablet ? AppDimensions.paddingL : AppDimensions.paddingM,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(
                isTablet ? AppDimensions.radiusL : AppDimensions.radiusM,
              ),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.3),
                width: isTablet ? 2 : 1,
              ),
              boxShadow: isTablet
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.domain,
                  color: AppColors.white.withValues(alpha: 0.8),
                  size: isTablet ? 28 : 20,
                ),
                SizedBox(width: isTablet ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bağlı Domain',
                        style: TextStyle(
                          fontSize: domainFontSize * 0.85,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      if (isTablet) SizedBox(height: AppDimensions.paddingXS),
                      Text(
                        _currentDomain!,
                        style: TextStyle(
                          fontSize: domainFontSize,
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Sadece bilgi ikonu - tıklanamaز
                Icon(
                  Icons.info_outline,
                  color: AppColors.white.withValues(alpha: 0.6),
                  size: isTablet ? 20 : 16,
                ),
              ],
            ),
          ),

        // Ana Logo - RESPONSIVE
        Text(
          AppStrings.appName,
          style: TextStyle(
            fontSize: logoSize,
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            shadows: isTablet
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
        ),

        SizedBox(height: isTablet ? size.formSpacing * 2.5 : size.formSpacing * 2),

        // Login Form - RESPONSIVE CONTAINER using your padding system
        Container(
          width: double.infinity,
          padding: isTablet ? EdgeInsets.all(AppDimensions.paddingXL) : null,
          decoration: isTablet
              ? BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.2),
                  ),
                )
              : null,
          child: Form(
            key: _formKey,
            child: LoginForm(
              emailController: emailController,
              passwordController: passwordController,
            ),
          ),
        ),

        SizedBox(height: isTablet ? size.formSpacing * 2.5 : size.formSpacing * 2),

        // Login Button
        LoginButton(
          onPressed: _handleLogin,
          isLoading: _isLoading,
        ),

        SizedBox(height: isTablet ? size.formSpacing * 1.5 : size.formSpacing),

        // Forgot Password
        ForgotPassword(
          onTap: () => context.pushNamed(AppRoutes.forgotPassword),
        ),

        SizedBox(height: isTablet ? size.formSpacing * 0.1 : size.formSpacing * 0.1),

        // 🎯 DOMAIN DEĞİŞTİRME LİNKİ - Using your AppDimensions
        if (_currentDomain != null)
          GestureDetector(
            onTap: _handleDomainChange,
            child: Container(
              padding: EdgeInsets.symmetric(
                vertical: isTablet ? AppDimensions.paddingM : AppDimensions.paddingS,
                horizontal: isTablet ? AppDimensions.paddingM : AppDimensions.paddingS,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    color: AppColors.white.withValues(alpha: 0.9),
                    size: isTablet ? 20 : 18,
                  ),
                  SizedBox(width: isTablet ? AppDimensions.paddingS : AppDimensions.paddingXS),
                  Text(
                    "Farklı Domain Seç",
                    style: TextStyle(
                      color: AppColors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      fontSize: linkFontSize,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // 🎯 Domain bulunamadıysa göster - RESPONSIVE
        if (_currentDomain == null) ...[
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.domainSelection,
                  (route) => false,
                );
              },
              icon: Icon(
                Icons.domain,
                color: Colors.white,
                size: isTablet ? 20 : 18,
              ),
              label: Text(
                "Domain Seç",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: isTablet ? size.mediumText : size.smallText,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Colors.red.withValues(alpha: 0.5),
                  width: isTablet ? 2 : 1,
                ),
                backgroundColor: Colors.red.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    isTablet ? AppDimensions.radiusL : AppDimensions.radiusM,
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  vertical: isTablet ? AppDimensions.paddingM : AppDimensions.paddingS,
                  horizontal: isTablet ? AppDimensions.paddingL : AppDimensions.paddingM,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
