import 'package:flutter/material.dart';
import '../services/biometric_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import 'login_screen.dart';
import 'root.dart';

/// Halaman Kunci (Lock Screen) biometrik KomikKu.
/// Berfungsi sebagai gerbang keamanan atas sesi Supabase yang tersimpan.
class LockScreen extends StatefulWidget {
  final bool isFromBackground;

  const LockScreen({
    super.key,
    this.isFromBackground = false,
  });

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  int _failedAttempts = 0;
  bool _isAuthenticating = false;
  String _statusMessage = 'Aplikasi terkunci. Sentuh sensor untuk membuka.';

  @override
  void initState() {
    super.initState();
    // Otomatis memunculkan prompt biometrik setelah frame pertama selesai dirender (FR-AUTH-09)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startBiometricAuth();
    });
  }

  /// Memulai proses autentikasi biometrik
  Future<void> _startBiometricAuth() async {
    if (_isAuthenticating) return;

    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Memverifikasi identitas Anda...';
    });

    final success = await BiometricService.instance.authenticate(
      reason: 'Buka kunci KomikKu dengan biometrik atau PIN',
    );

    if (!mounted) return;

    if (success) {
      _onAuthSuccess();
    } else {
      _onAuthFailure();
    }
  }

  /// Penanganan jika verifikasi biometrik berhasil
  void _onAuthSuccess() {
    setState(() {
      _isAuthenticating = false;
      _statusMessage = 'Verifikasi berhasil!';
    });

    if (widget.isFromBackground) {
      // Jika dipanggil saat aplikasi kembali dari background, cukup pop screen lock
      Navigator.pop(context);
    } else {
      // Jika saat pertama kali aplikasi dibuka
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootScreen()),
      );
    }
  }

  /// Penanganan jika verifikasi biometrik gagal atau dibatalkan
  void _onAuthFailure() {
    _failedAttempts++;

    setState(() {
      _isAuthenticating = false;
      _statusMessage = 'Verifikasi gagal. Percobaan ke-$_failedAttempts dari 5.';
    });

    // Setelah 5 kali gagal beruntun, paksa login dengan password (FR-AUTH-11)
    if (_failedAttempts >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terlalu banyak percobaan gagal. Silakan masuk menggunakan password.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      _forcePasswordLogin();
    }
  }

  /// Mengarahkan pengguna untuk masuk dengan password dan mereset sesi
  Future<void> _forcePasswordLogin() async {
    await SupabaseService.instance.signOut();
    await PrefsService.clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = PrefsService.displayName ?? 'Pengguna';

    return PopScope(
      // Mencegah tombol back menutup aplikasi tanpa verifikasi
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(),

                // Ikon Biometrik
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.fingerprint,
                    size: 80,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // Nama Pengguna & Status
                Text(
                  'Halo, $displayName',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _failedAttempts > 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),

                const Spacer(),

                // Tombol Coba Lagi
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isAuthenticating ? null : _startBiometricAuth,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ),
                const SizedBox(height: 12),

                // Tombol Login dengan Password
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _forcePasswordLogin,
                    icon: const Icon(Icons.password),
                    label: const Text('Login dengan Password'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
