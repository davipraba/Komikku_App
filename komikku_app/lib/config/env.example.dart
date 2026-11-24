// Contoh file konfigurasi environment KomikKu.
// Salin file ini menjadi 'env.dart' dan isi dengan URL serta anon key dari dashboard Supabase Anda.

class Env {
  // Ganti dengan URL project Supabase Anda (misal: https://xyzcompany.supabase.co)
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_SUPABASE_PROJECT_ID.supabase.co',
  );

  // Ganti dengan anon public key dari Supabase Settings -> API
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_SUPABASE_ANON_KEY',
  );
}
