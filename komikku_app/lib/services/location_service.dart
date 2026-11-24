import 'package:geolocator/geolocator.dart';

/// Service Singleton untuk menangani GPS dan Location-Based Services (LBS) sesuai Modul 7 dan FR-LBS
class LocationService {
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  /// Memeriksa apakah sensor GPS / Location Services pada perangkat aktif (FR-LBS-01)
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Memeriksa dan meminta izin akses lokasi ke pengguna (FR-LBS-01)
  Future<LocationPermission> checkAndRequestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  /// Mengambil posisi koordinat pengguna saat ini (FR-LBS-02)
  Future<Position> getCurrentPosition() async {
    // 1. Cek apakah GPS aktif
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('GPS tidak aktif. Mohon aktifkan layanan lokasi pada perangkat Anda.');
    }

    // 2. Cek izin lokasi
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Izin lokasi ditolak secara permanen. Silakan izinkan melalui Pengaturan Aplikasi.');
    }

    // 3. Dapatkan koordinat akurasi tinggi
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  /// Menghitung jarak lurus (Great Circle) antara dua titik koordinat dalam meter (FR-LBS-03)
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Membuka halaman pengaturan aplikasi sistem jika izin ditolak permanen
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Membuka halaman pengaturan lokasi sistem
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
