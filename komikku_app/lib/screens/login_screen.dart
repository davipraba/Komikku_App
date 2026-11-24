import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/biometric_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';
import 'root.dart';

/// Halaman Login KomikKu
class LoginScreen extends StatefulWidget {
  final bool sessionExpired;

  const LoginScreen({
    super.key,
    this.sessionExpired = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  @override
  void initState() {
    super.initState();
    if (widget.sessionExpired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi Anda telah berakhir. Silakan masuk kembali.'),
            backgroundColor: Colors.orange,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Memvalidasi input pengguna sebelum memanggil API
  bool _validateInputs() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    bool isValid = true;

    if (email.isEmpty) {
      _emailError = 'Email tidak boleh kosong';
      isValid = false;
    } else if (!email.contains('@') || !email.contains('.')) {
      _emailError = 'Format email tidak valid';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Password tidak boleh kosong';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password minimal 6 karakter';
      isValid = false;
    }

    if (!isValid) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon periksa kembali input Anda'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }

    return isValid;
  }

  /// Menangani proses masuk dengan Supabase Auth
  Future<void> _handleLogin() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    try {
      final response = await SupabaseService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthException('Gagal mendapatkan data pengguna.');
      }

      // Simpan flag login dan data profil dasar ke SharedPreferences
      PrefsService.isLoggedIn = true;
      PrefsService.userId = user.id;
      final rawName = user.userMetadata?['display_name'] as String?;
      PrefsService.displayName = rawName ?? user.email?.split('@').first ?? 'Pengguna';

      if (!mounted) return;

      // Cek apakah perangkat mendukung biometrik dan belum pernah ditawarkan (FR-AUTH-07)
      final canBiometric = await BiometricService.instance.isAvailable();
      if (canBiometric && !PrefsService.biometricPromptShown && mounted) {
        final shouldEnable = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Aktifkan Login Biometrik?'),
            content: const Text(
              'Gunakan sidik jari atau PIN perangkat untuk membuka aplikasi dengan lebih cepat dan aman.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Nanti Saja'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Aktifkan'),
              ),
            ],
          ),
        );

        PrefsService.biometricPromptShown = true;

        if (shouldEnable == true) {
          final authSuccess = await BiometricService.instance.authenticate(
            reason: 'Verifikasi biometrik untuk mengaktifkan',
          );
          if (authSuccess) {
            PrefsService.biometricEnabled = true;
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Login biometrik berhasil diaktifkan!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }

      // Unduh dan sinkronkan data cloud pengguna ke SQLite lokal (FR-SYNC-02, TC-08)
      SyncService.instance.syncAll();

      if (!mounted) return;

      // Navigasi ke halaman Root utama
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootScreen()),
      );
    } on AuthException catch (e) {
      setState(() {
        _emailError = 'Periksa email atau password Anda';
        _passwordError = 'Periksa email atau password Anda';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Judul Aplikasi
                Icon(
                  Icons.menu_book_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'KomikKu',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Selamat datang kembali! Silakan masuk ke akun Anda.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Form Email
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'nama@email.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),

                // Form Password
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Minimal 6 karakter',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  isPasswordVisible: _isPasswordVisible,
                  onTogglePassword: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 24),

                // Tombol Masuk
                PrimaryButton(
                  text: 'Masuk',
                  isLoading: _isLoading,
                  icon: Icons.login,
                  onPressed: _handleLogin,
                ),
                const SizedBox(height: 20),

                // Navigasi ke Pendaftaran
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Belum punya akun?'),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text('Daftar di sini'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
