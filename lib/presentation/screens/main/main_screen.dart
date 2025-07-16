import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        backgroundColor: AppColors.surface,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: 'Aktiviteler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business),
            label: 'Firmalar',
          ),
        ],
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
          ],
        ),
      ),
    );
  }
}
