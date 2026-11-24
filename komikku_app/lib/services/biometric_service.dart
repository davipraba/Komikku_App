import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Service untuk menangani autentikasi biometrik (sidik jari, wajah, dan PIN perangkat).
/// Menggunakan singleton pattern.
class BiometricService {
  BiometricService._internal();
  static final BiometricService instance = BiometricService._internal();

  final LocalAuthentication _auth = LocalAuthentication();

  /// Memeriksa apakah perangkat mendukung biometrik DAN sudah memiliki biometrik terdaftar
  Future<bool> isAvailable() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return false;

      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) return false;

      final availableBiometrics = await _auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Meminta autentikasi biometrik dengan fallback ke PIN/pola perangkat
  Future<bool> authenticate({
    String reason = 'Verifikasi biometrik untuk membuka KomikKu',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Membolehkan fallback ke PIN/pola/password perangkat
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
