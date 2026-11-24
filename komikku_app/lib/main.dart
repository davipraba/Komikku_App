import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/env.dart';
import 'screens/lock_screen.dart';
import 'screens/login_screen.dart';
import 'screens/root.dart';
import 'services/notification_service.dart';
import 'services/prefs_service.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi SharedPreferences
  await PrefsService.init();

  // Sinkronkan tema yang tersimpan ke ValueNotifier
  themeModeNotifier.value = PrefsService.themeMode == 'dark'
      ? ThemeMode.dark
      : PrefsService.themeMode == 'light'
          ? ThemeMode.light
          : ThemeMode.system;

  // 2. Inisialisasi Supabase
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    debugPrint('Peringatan: Gagal menginisialisasi Supabase: $e');
  }

  // 3. Inisialisasi Notifikasi Lokal & Timezone (FR-NOTIF)
  try {
    await NotificationService.instance.init();
  } catch (e) {
    debugPrint('Peringatan: Gagal menginisialisasi NotificationService: $e');
  }

  runApp(const KomikKuApp());
}

/// ValueNotifier untuk mengelola mode tema secara reaktif sesuai aturan modul 3 & SRS
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

/// Root widget KomikKu dengan Material 3
class KomikKuApp extends StatelessWidget {
  const KomikKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'KomikKu',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepOrange,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorSchemeSeed: Colors.deepOrange,
            brightness: Brightness.dark,
          ),
          themeMode: currentMode,
          home: const AuthGate(),
        );
      },
    );
  }
}

/// Widget gerbang autentikasi sesuai alur navigasi SRS 2.9
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  Widget _destination = const LoginScreen();

  @override
  void initState() {
    super.initState();
    _checkInitialAuth();
  }

  /// Memeriksa status sesi dan preferensi biometrik saat aplikasi dibuka
  Future<void> _checkInitialAuth() async {
    bool isSessionValid = false;
    try {
      isSessionValid = SupabaseService.instance.isSessionValid;
    } catch (_) {
      isSessionValid = false;
    }

    final bool previouslyLoggedIn = PrefsService.isLoggedIn;
    final bool biometricEnabled = PrefsService.biometricEnabled;

    if (isSessionValid) {
      // Sesi Supabase aktif & valid
      if (biometricEnabled) {
        // Sesi valid + biometrik aktif -> Lock Screen (FR-AUTH-09)
        _destination = const LockScreen(isFromBackground: false);
      } else {
        // Sesi valid + biometrik nonaktif -> Langsung ke Beranda (Root)
        _destination = const RootScreen();
      }
    } else {
      // Sesi tidak valid / tidak ada sesi
      if (previouslyLoggedIn) {
        // Sesi sebelumnya tercatat login tapi sekarang kedaluwarsa (FR-AUTH-14)
        await PrefsService.clearSession();
        _destination = const LoginScreen(sessionExpired: true);
      } else {
        // Pengguna belum pernah login
        _destination = const LoginScreen();
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _destination;
  }
}
