import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const PlaceholderScreen(title: 'Aktiviteler'),
    const PlaceholderScreen(title: 'Firmalar'),
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
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
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
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
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '$title Ekranı',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu ekran yakında gelecek',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}