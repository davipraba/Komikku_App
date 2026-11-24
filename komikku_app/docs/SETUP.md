# Panduan Setup Backend & Aplikasi KomikKu

Dokumen ini berisi panduan konfigurasi Supabase (Database, Auth, Row Level Security, Edge Functions) dan aplikasi Flutter KomikKu.

---

## 1. Persyaratan Awal (Prerequisites)

1. **Flutter SDK** (versi 3.32+ atau kompatibel dengan Dart 3)
2. **Node.js / npm** (untuk Supabase CLI atau install via winget/scoop/brew)
3. **Supabase CLI**:
   - Windows (via Scoop/Winget): `scoop bucket add supabase https://github.com/supabase/scoop-bucket.git && scoop install supabase` atau `winget install Supabase.CLI`
   - Linux / macOS: `brew install supabase/tap/supabase` atau `npm install -g supabase`
4. **Google Gemini API Key**: Dapatkan gratis dari [Google AI Studio](https://aistudio.google.com/).

---

## 2. Setup Database Supabase

1. Buka dashboard proyek Supabase Anda di [https://supabase.com](https://supabase.com).
2. Masuk ke menu **SQL Editor**.
3. Buka file `supabase/schema.sql` pada repository ini, salin seluruh kodenya, dan tempelkan ke SQL Editor Supabase.
4. Klik **Run** untuk mengeksekusi skrip.
5. Skrip akan otomatis membuat:
   - Tabel `public.profiles` + Trigger `on_auth_user_created` untuk registrasi otomatis.
   - Tabel `public.bookstores` + RLS publik read-only + data dummy toko buku & perpustakaan sekitar kampus UPN Veteran Yogyakarta.
   - Tabel `public.favorites` + RLS pengguna (`auth.uid() = user_id`) untuk sinkronisasi cloud.
   - Tabel `public.reading_history` + RLS pengguna (`auth.uid() = user_id`).
   - Tabel `public.reviews` + RLS (publik read untuk semua authenticated user; write hanya untuk ulasan milik sendiri) dengan constraint rating 1..5.
   - Tabel `public.ai_usage` + RLS pengguna untuk pembatasan kuota 20 pesan AI per hari (FR-AI-08).

---

## 3. Setup & Deploy Supabase Edge Function (`ai-assistant`)

Edge Function bertindak sebagai backend aman untuk memanggil Google Gemini API tanpa pernah mengekspos API Key ke sisi client Android.

### Langkah-langkah Deployment:

1. **Login ke Supabase CLI:**
   ```bash
   supabase login
   ```
   Ikuti instruksi browser untuk membuat token akses CLI.

2. **Hubungkan (Link) ke Project Supabase Anda:**
   Dapatkan Project Reference ID dari URL project dashboard Anda (`https://supabase.com/dashboard/project/<project-ref>`).
   ```bash
   cd komikku_app
   supabase link --project-ref <project-ref>
   ```

3. **Konfigurasi Secret API Key Gemini:**
   Simpan kunci API Gemini Anda ke dalam Supabase Secrets:
   ```bash
   supabase secrets set GEMINI_API_KEY=AIzaSyYourGeminiApiKeyHere
   ```
   *(Opsional: Anda dapat memverifikasi secret yang tersimpan dengan perintah `supabase secrets list`)*

4. **Deploy Edge Function:**
   Deploy fungsi `ai-assistant`:
   ```bash
   supabase functions deploy ai-assistant
   ```

5. **Verifikasi Edge Function:**
   Setelah proses deploy selesai, fungsi akan tersedia di:
   `https://<project-ref>.supabase.co/functions/v1/ai-assistant`

---

## 4. Konfigurasi Client Flutter

1. Masuk ke folder proyek Flutter `komikku_app`:
   ```bash
   cd komikku_app
   ```

2. Buat file konfigurasi environment `lib/config/env.dart` dari template `lib/config/env.example.dart`:
   ```dart
   // lib/config/env.dart
   class Env {
     static const String supabaseUrl = 'https://your-project-ref.supabase.co';
     static const String supabaseAnonKey = 'eyJhbGciOi...your-anon-key';
   }
   ```
   *(Catatan: `lib/config/env.dart` sudah terdaftar di `.gitignore` agar kredensial tidak bocor ke git repository)*

3. Pasang dependency Flutter:
   ```bash
   flutter pub get
   ```

4. Jalankan aplikasi pada emulator atau perangkat Android:
   ```bash
   flutter run
   ```

---

## 5. Pengujian Skenario Khusus (Test Cases)

### TC-11: Tanya AI "rekomendasi komik komedi"
1. Masuk ke tab **AI** di navigasi bawah.
2. Ketik *"rekomendasi komik komedi"* atau ketuk salah satu chip rekomendasi awal.
3. Asisten AI akan membalas dalam Bahasa Indonesia dengan maksimal 5 judul dalam format:
   `Judul Komik — Alasan rekomendasi`
4. Setiap judul rekomendasi bergaris bawah atau berikon pencarian dapat diketuk untuk langsung membuka layar Pencarian dengan kata kunci tersebut.

### TC-12: Pembatasan Kuota 20 Pesan AI per Hari
1. Kirim pesan chat atau gunakan ringkas sinopsis hingga mencapai 20 kali dalam satu hari yang sama.
2. Pada permintaan ke-21, Edge Function akan mengembalikan HTTP Status `429 Too Many Requests`.
3. Aplikasi akan menampilkan pesan:
   *"Batas kuota harian tercapai. Anda hanya dapat mengirim maksimal 20 permintaan AI per hari."*
4. Kuota akan otomatis direset pada pergantian hari UTC (atau dapat diuji dengan mengubah kolom `count` di tabel `ai_usage` pada Supabase Table Editor).
