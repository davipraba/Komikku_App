import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../services/biometric_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import 'about_screen.dart';
import 'login_screen.dart';
import 'nearby_screen.dart';
import 'reminder_screen.dart';

/// Halaman Profil dan Pengaturan KomikKu
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isBioAvailable = false;
  bool _isBioEnabled = false;
  bool _isLoading = true;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  /// Memuat status ketersediaan biometrik dan preferensi tersimpan
  Future<void> _loadPreferences() async {
    final available = await BiometricService.instance.isAvailable();
    if (mounted) {
      setState(() {
        _isBioAvailable = available;
        _isBioEnabled = PrefsService.biometricEnabled;
        _isLoading = false;
      });
    }
  }

  /// Menangani perubahan toggle biometrik
  Future<void> _onToggleBiometric(bool value) async {
    if (value) {
      // Aktivasi memerlukan verifikasi biometrik terlebih dahulu (FR-SET-04)
      final success = await BiometricService.instance.authenticate(
        reason: 'Verifikasi biometrik untuk mengaktifkan fitur',
      );

      if (!mounted) return;

      if (success) {
        setState(() => _isBioEnabled = true);
        PrefsService.biometricEnabled = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login biometrik berhasil diaktifkan.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() => _isBioEnabled = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verifikasi gagal. Biometrik tidak diaktifkan.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } else {
      // Nonaktifkan biometrik
      setState(() => _isBioEnabled = false);
      PrefsService.biometricEnabled = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login biometrik dinonaktifkan.'),
        ),
      );
    }
  }

  /// Menjalankan sinkronisasi manual ke Supabase (FR-SYNC-04)
  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    try {
      final success = await SyncService.instance.syncAll(silent: false);
      if (!mounted) return;
      setState(() => _isSyncing = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sinkronisasi cloud berhasil!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan sinkronisasi. Periksa koneksi internet Anda.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan sinkronisasi: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  String _formatLastSync() {
    final lastSync = PrefsService.lastSyncAt;
    if (lastSync == null) return 'Belum pernah disinkronkan';
    try {
      final dt = DateTime.parse(lastSync).toLocal();
      return 'Terakhir: ${DateFormat('dd MMM yyyy, HH:mm').format(dt)}';
    } catch (_) {
      return 'Terakhir: $lastSync';
    }
  }

  /// Menangani proses logout akun
  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun KomikKu?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    // Bersihkan sesi Supabase dan preferensi lokal (FR-AUTH-06 & FR-AUTH-15)
    await SupabaseService.instance.signOut();
    await PrefsService.clearSession();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Dialog pemilihan tema aplikasi (FR-SET-01, TC-13)
  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Tema Aplikasi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Mengikuti Sistem'),
              trailing: PrefsService.themeMode == 'system'
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() => PrefsService.themeMode = 'system');
                themeModeNotifier.value = ThemeMode.system;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Terang'),
              trailing: PrefsService.themeMode == 'light'
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() => PrefsService.themeMode = 'light');
                themeModeNotifier.value = ThemeMode.light;
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Gelap'),
              trailing: PrefsService.themeMode == 'dark'
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() => PrefsService.themeMode = 'dark');
                themeModeNotifier.value = ThemeMode.dark;
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog pemilihan mode baca default
  void _showReaderModeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pilih Mode Baca Default'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Vertikal (Scroll)'),
              subtitle: const Text('Membaca halaman bersambung ke bawah'),
              trailing: PrefsService.readerMode == 'vertical'
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() => PrefsService.readerMode = 'vertical');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Horizontal (Swipe)'),
              subtitle: const Text('Menggeser halaman ke samping'),
              trailing: PrefsService.readerMode == 'horizontal'
                  ? const Icon(Icons.check, color: Colors.deepOrange)
                  : null,
              onTap: () {
                setState(() => PrefsService.readerMode = 'horizontal');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = SupabaseService.instance.currentUser;
    final displayName = PrefsService.displayName ??
        (user?.userMetadata?['display_name'] as String?) ??
        'Pengguna KomikKu';
    final email = user?.email ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil & Pengaturan'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              children: [
                // Header Profil Pengguna
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.person,
                            size: 36,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Bagian Keamanan (Biometrik)
                Text(
                  'Keamanan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SwitchListTile(
                    title: const Text('Login Biometrik'),
                    subtitle: Text(
                      _isBioAvailable
                          ? 'Gunakan sidik jari atau PIN perangkat saat membuka aplikasi'
                          : 'Biometrik tidak didukung atau belum terdaftar di perangkat',
                    ),
                    secondary: const Icon(Icons.fingerprint),
                    value: _isBioEnabled,
                    onChanged: _isBioAvailable ? _onToggleBiometric : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Bagian Fitur & Layanan (Reminder & LBS)
                Text(
                  'Fitur & Layanan',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.alarm_rounded),
                        title: const Text('Pengingat Baca (Reminder)'),
                        subtitle: const Text('Jadwalkan alarm membaca komik favorit'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ReminderScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.near_me_outlined),
                        title: const Text('Toko Buku Terdekat (LBS)'),
                        subtitle: const Text('Cari toko buku dan perpustakaan sekitar'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NearbyScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.cloud_sync_outlined),
                        title: const Text('Sinkronisasi Cloud'),
                        subtitle: Text(_formatLastSync()),
                        trailing: _isSyncing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.sync_rounded),
                        onTap: _isSyncing ? null : _handleManualSync,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bagian Preferensi Baca & Tampilan
                Text(
                  'Preferensi',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: const Text('Tema Aplikasi'),
                        subtitle: Text(
                          PrefsService.themeMode == 'dark'
                              ? 'Gelap'
                              : PrefsService.themeMode == 'light'
                                  ? 'Terang'
                                  : 'Mengikuti Sistem',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showThemeDialog,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.auto_stories_outlined),
                        title: const Text('Mode Baca'),
                        subtitle: Text(
                          PrefsService.readerMode == 'vertical'
                              ? 'Vertikal (Scroll)'
                              : 'Horizontal (Swipe)',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: _showReaderModeDialog,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        secondary: const Icon(Icons.data_saver_on_outlined),
                        title: const Text('Hemat Kuota (Data Saver)'),
                        subtitle: const Text('Gunakan resolusi gambar terkompresi'),
                        value: PrefsService.dataSaver,
                        onChanged: (val) {
                          setState(() {
                            PrefsService.dataSaver = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Bagian Informasi & Atribusi
                Text(
                  'Tentang',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('Tentang KomikKu & Atribusi'),
                    subtitle: const Text('Informasi pengembang & lisensi MangaDex'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 28),

                // Tombol Keluar
                OutlinedButton.icon(
                  onPressed: _handleLogout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'Keluar dari Akun',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}
