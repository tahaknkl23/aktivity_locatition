import 'package:aktivity_location_app/core/routes/app_routes.dart';
import 'package:aktivity_location_app/presentation/screens/onboarding/widgets/domain_continue_button.dart';
import 'package:aktivity_location_app/presentation/screens/onboarding/widgets/domain_selection_form.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_assets.dart';

class DomainSelectionScreen extends StatefulWidget {
  const DomainSelectionScreen({super.key});

  @override
  State<DomainSelectionScreen> createState() => _DomainSelectionScreenState();
}

class _DomainSelectionScreenState extends State<DomainSelectionScreen> with TickerProviderStateMixin {
  final Map<String, String> domainMap = {
    'destek.veribiscrm.com': 'destek',
    'demo.veribiscrm.com': 'demo',
    'bogazici.veribiscrm.com': 'bogazici',
  };

  String? selectedDomain;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> saveDomainAndNavigate() async {
    if (selectedDomain == null || selectedDomain!.trim().isEmpty) {
      _showErrorSnackBar("Lütfen bir domain girin.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      // Custom domain için subdomain çıkarma
      String subdomain;
      if (domainMap.containsKey(selectedDomain!)) {
        subdomain = domainMap[selectedDomain!]!.trim();
      } else {
        // Custom domain için subdomain çıkar (domain.veribiscrm.com -> domain)
        final parts = selectedDomain!.split('.');
        if (parts.length >= 3 && parts[1] == 'veribiscrm' && parts[2] == 'com') {
          subdomain = parts[0];
        } else {
          subdomain = selectedDomain!.trim();
        }
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('subdomain', subdomain);

      debugPrint("[Domain Seçildi] $selectedDomain -> Subdomain: $subdomain");

      if (mounted) {
        _showSuccessSnackBar("Domain başarıyla kaydedildi!");
      }

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('Domain kaydetme hatası: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Domain kaydedilirken hata oluştu.");
      }
    }
  }

  void onDomainChanged(String domain) {
    setState(() => selectedDomain = domain.trim());
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.redColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.greenColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = AppSizes.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.background),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                children: [
                  // Fixed header section
                  Padding(
                    padding: EdgeInsets.all(size.padding),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.02),

                        // Header with Logo
                        Text(
                          "Veribis Crm",
                          style: TextStyle(
                            fontSize: size.largeText * 2.5,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: size.height * 0.02),

                        Text(
                          "Domain Seçimi",
                          style: TextStyle(
                            fontSize: size.mediumText,
                            color: AppColors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expandable content section
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(
                        horizontal: size.padding,
                        vertical: size.padding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: size.height * 0.05),

                          // Domain Selection Form
                          DomainSelectionForm(
                            size: size,
                            domainMap: domainMap,
                            selectedDomain: selectedDomain,
                            onDomainChanged: onDomainChanged,
                          ),

                          SizedBox(height: size.height * 0.04),

                          // Continue Button
                          DomainContinueButton(
                            size: size,
                            isLoading: _isLoading,
                            selectedDomain: selectedDomain,
                            onPressed: saveDomainAndNavigate,
                          ),

                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
