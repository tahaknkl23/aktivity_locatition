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

  // FIXED DOMAIN SAVING LOGIC
  Future<void> saveDomainAndNavigate() async {
    if (selectedDomain == null || selectedDomain!.trim().isEmpty) {
      _showErrorSnackBar("Lütfen bir domain girin.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(milliseconds: 1000));

      final inputDomain = selectedDomain!.trim();

      // FLEXIBLE SUBDOMAIN EXTRACTION - Fixed Logic
      String subdomain;
      String baseUrl;

      debugPrint("[DOMAIN_SAVE] Input domain: $inputDomain");

      // 1. Full URL provided (http/https)
      if (inputDomain.startsWith('http://') || inputDomain.startsWith('https://')) {
        baseUrl = inputDomain;
        subdomain = _extractSubdomainFromUrl(inputDomain);
      }
      // 2. Domain with port (localhost:8080)
      else if (inputDomain.contains(':') && !inputDomain.contains('://')) {
        baseUrl = 'http://$inputDomain';
        subdomain = inputDomain.split(':')[0];
      }
      // 3. Custom domain (destekcrm.com - NOT veribis)
      else if (inputDomain.contains('.') && !inputDomain.contains('veribiscrm.com')) {
        baseUrl = 'https://$inputDomain';
        subdomain = inputDomain; // KEEP FULL DOMAIN as subdomain
      }
      // 4. Veribis domain (demo.veribiscrm.com)
      else if (inputDomain.contains('.veribiscrm.com')) {
        baseUrl = 'https://$inputDomain';
        subdomain = inputDomain.split('.')[0]; // Extract subdomain part
      }
      // 5. Plain subdomain (demo, destek)
      else {
        baseUrl = 'https://$inputDomain.veribiscrm.com';
        subdomain = inputDomain;
      }

      debugPrint("[DOMAIN_SAVE] Base URL: $baseUrl");
      debugPrint("[DOMAIN_SAVE] Subdomain to save: $subdomain");

      final prefs = await SharedPreferences.getInstance();

      // SAVE BOTH for flexibility
      await prefs.setString('subdomain', subdomain);
      await prefs.setString('base_url', baseUrl);

      debugPrint("[DOMAIN_SAVE] Successfully saved:");
      debugPrint("[DOMAIN_SAVE] - subdomain: $subdomain");
      debugPrint("[DOMAIN_SAVE] - base_url: $baseUrl");

      if (mounted) {
        _showSuccessSnackBar("Domain başarıyla kaydedildi!");
      }

      await Future.delayed(const Duration(milliseconds: 1200));

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      debugPrint('[DOMAIN_SAVE] Error: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar("Domain kaydedilirken hata oluştu.");
      }
    }
  }

  // Helper method to extract subdomain from full URL
  String _extractSubdomainFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host;

      debugPrint("[SUBDOMAIN_EXTRACT] Host: $host");

      // For veribis domains, extract subdomain part
      if (host.contains('veribiscrm.com')) {
        final parts = host.split('.');
        if (parts.length >= 3) {
          return parts[0]; // Return subdomain part
        }
      }

      // For custom domains, return full host
      return host;
    } catch (e) {
      debugPrint("[SUBDOMAIN_EXTRACT] Error: $e");
      return url;
    }
  }

  void onDomainChanged(String domain) {
    setState(() => selectedDomain = domain.trim());
    debugPrint("[DOMAIN_CHANGED] Selected: $domain");
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
