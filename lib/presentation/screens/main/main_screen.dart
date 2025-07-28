import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ Provider import
import '../../../core/constants/app_colors.dart';
import '../../providers/menu_provider.dart'; // ✅ Menu provider import
import '../home/home_screen.dart';
import '../activity/activity_list_screen.dart';
import '../company/company_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const ActivityListScreen(),
    const CompanyListScreen(),
    const PlaceholderScreen(title: 'Profil'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // ✅ Ana ekran yüklendiğinde menüyü yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMenuSafely();
    });
  }

  /// Güvenli menu yükleme
  void _loadMenuSafely() {
    try {
      if (mounted) {
        context.read<MenuProvider>().loadMenu();
        debugPrint('[MAIN_SCREEN] 📋 Menu loading initiated');
      }
    } catch (e) {
      debugPrint('[MAIN_SCREEN] ❌ Error loading menu: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        debugPrint('[MAIN_SCREEN] 🟢 App resumed');
        // Uygulama geri geldiğinde menüyü yenile
        if (mounted) {
          _loadMenuSafely();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        debugPrint('[MAIN_SCREEN] 🔴 App paused/inactive');
        break;
      case AppLifecycleState.detached:
        debugPrint('[MAIN_SCREEN] 🔴 App detached');
        break;
      case AppLifecycleState.hidden:
        debugPrint('[MAIN_SCREEN] 🔴 App hidden');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Consumer<MenuProvider>(
        builder: (context, menuProvider, child) {
          // Menü yüklenene kadar basit bottom nav göster
          return BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() => _currentIndex = index);

              // Menü yüklü değilse ve home tab'a tıklandıysa menüyü yükle
              if (index == 0 && !menuProvider.hasMenuItems && !menuProvider.isLoading) {
                _loadMenuSafely();
              }
            },
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textTertiary,
            backgroundColor: AppColors.surface,
            elevation: 8,
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Ana Sayfa',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.assignment),
                    if (menuProvider.isLoading && _currentIndex == 1)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Aktiviteler',
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  children: [
                    const Icon(Icons.business),
                    if (menuProvider.isLoading && _currentIndex == 2)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                label: 'Firmalar',
              ),
            ],
          );
        },
      ),
    );
  }
}

// Geçici placeholder ekranı
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Ekranı',
              style: TextStyle(
                fontSize: 24,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ekran yakında gelecek',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title özelliği geliştiriliyor...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              child: const Text('Yakında'),
            ),
          ],
        ),
      ),
    );
  }
}
