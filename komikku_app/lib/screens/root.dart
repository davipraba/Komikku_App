import 'package:flutter/material.dart';
import '../services/prefs_service.dart';
import 'ai_screen.dart';
import 'home_screen.dart';
import 'library_screen.dart';
import 'lock_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';

/// Halaman Root sebagai kerangka navigasi utama (BottomNavigationBar 5 tab).
/// Mengimplementasikan WidgetsBindingObserver untuk mendeteksi status background aplikasi (FR-AUTH-16).
class RootScreen extends StatefulWidget {
  const RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLockScreenShowing = false;

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
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused) {
      // Simpan waktu saat aplikasi ditinggalkan ke background
      PrefsService.lastBackgroundAt = DateTime.now().millisecondsSinceEpoch;
    } else if (state == AppLifecycleState.resumed) {
      // Saat aplikasi kembali dari background setelah > 60 detik dan biometrik aktif, munculkan Lock Screen (FR-AUTH-16)
      final lastBg = PrefsService.lastBackgroundAt;
      if (lastBg > 0 && PrefsService.biometricEnabled && !_isLockScreenShowing) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - lastBg;
        if (elapsed > 60000) { // 60 detik
          _isLockScreenShowing = true;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const LockScreen(isFromBackground: true),
            ),
          ).then((_) {
            _isLockScreenShowing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      const AiScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Cari',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark),
            label: 'Perpustakaan',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
