import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper SharedPreferences untuk menyimpan preferensi ringan dan status sesi.
/// Menggunakan static methods agar mudah diakses di seluruh aplikasi sesuai modul 6.
class PrefsService {
  static late SharedPreferences _prefs;

  // Kunci-kunci SharedPreferences sesuai SRS 2.5.2
  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserId = 'userId';
  static const String _keyDisplayName = 'displayName';
  static const String _keyThemeMode = 'themeMode';
  static const String _keyBiometricEnabled = 'biometricEnabled';
  static const String _keyBiometricPromptShown = 'biometricPromptShown';
  static const String _keyLastBackgroundAt = 'lastBackgroundAt';
  static const String _keyReaderMode = 'readerMode';
  static const String _keyDataSaver = 'dataSaver';
  static const String _keyLastSyncAt = 'lastSyncAt';

  /// Inisialisasi awal SharedPreferences pada saat startup aplikasi
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sesi Login
  static bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;
  static set isLoggedIn(bool value) => _prefs.setBool(_keyIsLoggedIn, value);

  static String? get userId => _prefs.getString(_keyUserId);
  static set userId(String? value) {
    if (value == null) {
      _prefs.remove(_keyUserId);
    } else {
      _prefs.setString(_keyUserId, value);
    }
  }

  static String? get displayName => _prefs.getString(_keyDisplayName);
  static set displayName(String? value) {
    if (value == null) {
      _prefs.remove(_keyDisplayName);
    } else {
      _prefs.setString(_keyDisplayName, value);
    }
  }

  // Biometrik
  static bool get biometricEnabled =>
      _prefs.getBool(_keyBiometricEnabled) ?? false;
  static set biometricEnabled(bool value) =>
      _prefs.setBool(_keyBiometricEnabled, value);

  static bool get biometricPromptShown =>
      _prefs.getBool(_keyBiometricPromptShown) ?? false;
  static set biometricPromptShown(bool value) =>
      _prefs.setBool(_keyBiometricPromptShown, value);

  static int get lastBackgroundAt => _prefs.getInt(_keyLastBackgroundAt) ?? 0;
  static set lastBackgroundAt(int value) =>
      _prefs.setInt(_keyLastBackgroundAt, value);

  // Tampilan & Pengaturan Baca
  static String get themeMode => _prefs.getString(_keyThemeMode) ?? 'system';
  static set themeMode(String value) => _prefs.setString(_keyThemeMode, value);

  static String get readerMode =>
      _prefs.getString(_keyReaderMode) ?? 'vertical';
  static set readerMode(String value) =>
      _prefs.setString(_keyReaderMode, value);

  static bool get dataSaver => _prefs.getBool(_keyDataSaver) ?? true;
  static set dataSaver(bool value) => _prefs.setBool(_keyDataSaver, value);

  // Sinkronisasi
  static String? get lastSyncAt => _prefs.getString(_keyLastSyncAt);
  static set lastSyncAt(String? value) {
    if (value == null) {
      _prefs.remove(_keyLastSyncAt);
    } else {
      _prefs.setString(_keyLastSyncAt, value);
    }
  }

  /// Menghapus seluruh data sesi saat logout
  static Future<void> clearSession() async {
    await _prefs.setBool(_keyIsLoggedIn, false);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyDisplayName);
    await _prefs.setBool(_keyBiometricEnabled, false);
    await _prefs.setBool(_keyBiometricPromptShown, false);
    await _prefs.remove(_keyLastBackgroundAt);
  }
}
