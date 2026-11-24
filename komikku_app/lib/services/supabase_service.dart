import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk menangani autentikasi dan interaksi Supabase Auth.
/// Menggunakan singleton pattern sesuai standar praktikum.
class SupabaseService {
  SupabaseService._internal();
  static final SupabaseService instance = SupabaseService._internal();

  /// Mengakses SupabaseClient dari instance global
  SupabaseClient get client => Supabase.instance.client;

  /// Mengambil sesi aktif saat ini
  Session? get currentSession => client.auth.currentSession;

  /// Mengambil user aktif saat ini
  User? get currentUser => client.auth.currentUser;

  /// Memeriksa apakah sesi saat ini masih ada dan belum kedaluwarsa
  bool get isSessionValid {
    final session = client.auth.currentSession;
    if (session == null) return false;
    return !session.isExpired;
  }

  /// Pendaftaran akun baru dengan email, password, dan nama tampilan
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'display_name': displayName.trim()},
    );
  }

  /// Masuk dengan email dan password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Keluar dari sesi Supabase
  Future<void> signOut() async {
    await client.auth.signOut();
  }
}
