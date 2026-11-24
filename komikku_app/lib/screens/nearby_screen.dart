import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/bookstore.dart';
import '../services/location_service.dart';
import '../services/supabase_service.dart';

/// Halaman Toko Buku / Perpustakaan Terdekat (FR-LBS)
/// Mengambil posisi pengguna melalui GPS, menghitung jarak ke toko buku,
/// menandai lokasi < 500 m (hijau), dan menyediakan navigasi ke Google Maps.
class NearbyScreen extends StatefulWidget {
  const NearbyScreen({super.key});

  @override
  State<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends State<NearbyScreen> {
  Position? _currentPosition;
  List<Bookstore> _bookstores = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPermanentlyDenied = false;

  /// Data dummy lokal sebagai fallback jika offline atau tabel Supabase belum siap (sekitar UPN Veteran Yogyakarta)
  static final List<Bookstore> _fallbackBookstores = [
    Bookstore(
      id: '1',
      name: 'Perpustakaan UPN "Veteran" Yogyakarta (Kampus 1)',
      lat: -7.76185,
      lng: 110.40915,
      address: 'Jl. SWK 104 (Lingkar Utara), Condongcatur, Sleman',
    ),
    Bookstore(
      id: '2',
      name: 'Toko Buku Togamas Affandi Gejayan',
      lat: -7.77125,
      lng: 110.38920,
      address: 'Jl. Affandi (Gejayan) No. 5, Caturtunggal, Depok, Sleman',
    ),
    Bookstore(
      id: '3',
      name: 'Gramedia Plaza Ambarrukmo',
      lat: -7.78280,
      lng: 110.40110,
      address: 'Plaza Ambarrukmo Lt. 2, Jl. Laksda Adisucipto, Sleman',
    ),
    Bookstore(
      id: '4',
      name: 'Periplus Bookstore Mal Ambarrukmo',
      lat: -7.78275,
      lng: 110.40125,
      address: 'Plaza Ambarrukmo GF-A25, Jl. Laksda Adisucipto, Sleman',
    ),
    Bookstore(
      id: '5',
      name: 'Toko Buku Social Agency Baru (SAB) Kaliurang',
      lat: -7.75380,
      lng: 110.38090,
      address: 'Jl. Kaliurang KM. 5 No. 34, Caturtunggal, Sleman',
    ),
    Bookstore(
      id: '6',
      name: 'Perpustakaan Daerah Grhatama Pustaka DIY',
      lat: -7.79870,
      lng: 110.40790,
      address: 'Jl. Janti No. 238, Wonocatur, Banguntapan, Bantul',
    ),
    Bookstore(
      id: '7',
      name: 'Gramedia Sudirman Yogyakarta',
      lat: -7.78290,
      lng: 110.37520,
      address: 'Jl. Jend. Sudirman No. 54-56, Kotabaru, Yogyakarta',
    ),
    Bookstore(
      id: '8',
      name: 'Perpustakaan Kota Yogyakarta Kotabaru',
      lat: -7.78650,
      lng: 110.37350,
      address: 'Jl. Suroto No. 9, Kotabaru, Gondokusuman, Yogyakarta',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocationAndBookstores();
  }

  /// Mengambil lokasi pengguna dan menghitung jarak ke daftar toko buku (FR-LBS-01, FR-LBS-02, FR-LBS-03)
  Future<void> _fetchLocationAndBookstores() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isPermanentlyDenied = false;
    });

    try {
      // 1. Dapatkan posisi saat ini via GPS (LocationService)
      final position = await LocationService.instance.getCurrentPosition();

      // 2. Ambil data toko buku dari Supabase (fallback ke lokal jika belum ada koneksi)
      List<Bookstore> stores = [];
      try {
        final res = await SupabaseService.instance.client
            .from('bookstores')
            .select()
            .timeout(const Duration(seconds: 5));

        final listJson = res as List<dynamic>;
        if (listJson.isNotEmpty) {
          stores = listJson
              .map((item) => Bookstore.fromJson(item as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {
        // Gunakan fallback data jika request database cloud gagal
        stores = _fallbackBookstores;
      }

      if (stores.isEmpty) {
        stores = _fallbackBookstores;
      }

      // 3. Hitung jarak (distanceBetween) dari pengguna ke masing-masing toko buku
      for (final store in stores) {
        store.distanceInMeters = LocationService.instance.distanceBetween(
          position.latitude,
          position.longitude,
          store.lat,
          store.lng,
        );
      }

      // 4. Urutkan dari yang terdekat (FR-LBS-04)
      stores.sort((a, b) {
        final distA = a.distanceInMeters ?? double.infinity;
        final distB = b.distanceInMeters ?? double.infinity;
        return distA.compareTo(distB);
      });

      if (!mounted) return;

      setState(() {
        _currentPosition = position;
        _bookstores = stores;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      final isDeniedForever = errorMsg.contains('permanen') ||
          errorMsg.contains('Pengaturan');

      setState(() {
        _errorMessage = errorMsg;
        _isPermanentlyDenied = isDeniedForever;
        _isLoading = false;
      });
    }
  }

  /// Membuka aplikasi peta (Google Maps) dengan koordinat toko buku (FR-LBS-05)
  Future<void> _openInMaps(Bookstore store) async {
    final queryUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${store.lat},${store.lng}',
    );

    try {
      if (await canLaunchUrl(queryUrl)) {
        await launchUrl(queryUrl, mode: LaunchMode.externalApplication);
      } else {
        throw 'Tidak dapat membuka peta';
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuka aplikasi peta.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Buku Terdekat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Perbarui Lokasi',
            onPressed: _isLoading ? null : _fetchLocationAndBookstores,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mendeteksi lokasi GPS Anda...'),
                ],
              ),
            )
          : _errorMessage != null
              ? _buildErrorView(theme)
              : _buildContentView(theme),
    );
  }

  /// Tampilan jika GPS mati atau izin lokasi ditolak (TC-10)
  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_rounded,
              size: 72,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Akses Lokasi Bermasalah',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            if (_isPermanentlyDenied)
              ElevatedButton.icon(
                icon: const Icon(Icons.settings),
                label: const Text('Buka Pengaturan Aplikasi'),
                onPressed: () => LocationService.instance.openAppSettings(),
              )
            else
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                onPressed: _fetchLocationAndBookstores,
              ),
          ],
        ),
      ),
    );
  }

  /// Tampilan daftar toko buku dengan penanda jarak hijau < 500 m (FR-LBS-04)
  Widget _buildContentView(ThemeData theme) {
    return Column(
      children: [
        // Bar info koordinat posisi pengguna
        if (_currentPosition != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(Icons.person_pin_circle, color: Colors.deepOrange, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Koordinat Anda: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),

        // List Toko Buku
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _bookstores.length,
            itemBuilder: (context, index) {
              final store = _bookstores[index];
              final isVeryClose = store.isVeryClose;

              return Card(
                elevation: isVeryClose ? 2.5 : 1.0,
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: isVeryClose
                        ? Colors.green
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    width: isVeryClose ? 1.5 : 0.8,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.storefront_rounded,
                            color: isVeryClose ? Colors.green[700] : theme.colorScheme.primary,
                            size: 26,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              store.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          // Badge Jarak
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVeryClose
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              store.formattedDistance,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isVeryClose ? Colors.green[800] : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Alamat
                      Text(
                        store.address,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tag khusus jika < 500 m
                      if (isVeryClose) ...[
                        Row(
                          children: [
                            const Icon(Icons.check_circle, color: Colors.green, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Sangat dekat dengan Anda (< 500 m)',
                              style: TextStyle(
                                color: Colors.green[800],
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Tombol Buka di Maps (FR-LBS-05)
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _openInMaps(store),
                          icon: const Icon(Icons.map_outlined, size: 16),
                          label: const Text('Buka di Maps'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
