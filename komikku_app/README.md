# KomikKu 📖 — Aplikasi Pembaca Komik Modern

**KomikKu** adalah aplikasi pembaca komik (*manga*, *manhwa*, dan *manhua*) berbasis Android yang dikembangkan sebagai proyek tugas praktikum mata kuliah Pemrograman Aplikasi Mobile (PAM). Aplikasi ini mengintegrasikan katalog komik daring melalui API publik MangaDex, penyimpanan lokal *offline-first* dengan SQLite, otentikasi serta sinkronisasi awan menggunakan Supabase, keamanan biometrik perangkat (*fingerprint/face unlock*), pengingat baca terjadwal via notifikasi lokal, pencarian toko buku terdekat (*Location-Based Services*), dan asisten AI cerdas untuk rekomendasi komik bertenaga Google Gemini 2.5 Flash via Supabase Edge Function.

---

## 📱 Tangkapan Layar (Screenshots)

| Beranda & Jelajah | Detail & Ulasan | Pembaca Chapter (Reader) |
|:---:|:---:|:---:|
| `[📱 Beranda Komik]` | `[📱 Detail & Chapter]` | `[📱 Reader Mode]` |

| Perpustakaan (Offline) | Asisten AI (Chat LLM) | Toko Buku Terdekat (LBS) |
|:---:|:---:|:---:|
| `[📱 Favorit & Riwayat]` | `[📱 AI Recommendations]` | `[📱 Peta LBS]` |

---

## 🚀 Fitur Unggulan

1. **Autentikasi & Gerbang Biometrik (FR-AUTH)**
   - Registrasi dan login akun aman berbasis Supabase Auth.
   - Verifikasi biometrik (*fingerprint/face*) lokal menggunakan `local_auth` (`stickyAuth: true`) sebagai gerbang sesi aplikasi.
   - Layar kunci (*Lock Screen*) otomatis saat membuka aplikasi atau ketika kembali dari *background* setelah lebih dari 60 detik.
   - Mekanisme proteksi: 5 kali gagal verifikasi biometrik otomatis memaksa login dengan password.

2. **Katalog Komik & Pencarian Cepat (FR-HOME & FR-SEARCH)**
   - Integrasi langsung dengan API publik MangaDex (`api.mangadex.org`).
   - Beranda komik populer dengan *pull-to-refresh* dan paginasi gulir tak terbatas (*infinite scroll*).
   - Pencarian instan judul dengan *debounce* 500 ms dan filter multi-genre interaktif.

3. **Detail Komik & Ulasan Komunitas (FR-DETAIL & FR-REVIEW)**
   - Informasi komik komprehensif: sampul, judul, penulis, status, genre, dan sinopsis (*expand/collapse*).
   - Daftar chapter terurut (naik/turun) dengan opsi filter bahasa (Indonesia & Inggris).
   - Rating komunitas (1–5 bintang) menggunakan widget `RatingBar` interaktif dan ulasan teks yang tersimpan di Supabase PostgreSQL.

4. **Pembaca Komik Cerdas (FR-READER)**
   - Pengambilan halaman gambar berkecepatan tinggi dari server *at-home* MangaDex.
   - Pilihan mode baca: Vertikal (*webtoon/manhwa*) atau Horizontal (*manga* konvensional).
   - Opsi mode hemat data (*data-saver*).
   - Penyimpanan posisi chapter dan nomor halaman terakhir secara otomatis ke SQLite saat halaman berganti atau pengguna keluar.
   - Tombol **"Lanjut Baca"** pada halaman detail yang langsung membuka chapter dan halaman terakhir tersimpan.

5. **Penyimpanan Lokal Offline-First (FR-LIB)**
   - Database lokal SQLite (`sqflite`) untuk menyimpan data **Favorit**, **Riwayat Baca**, **Pengingat**, dan **Pesan AI**.
   - Koleksi favorit dan riwayat tetap dapat diakses penuh saat perangkat berada dalam mode *offline* (mode pesawat).

6. **Sinkronisasi Cloud Dua Arah (FR-SYNC)**
   - Mengunggah perubahan lokal (`is_synced = 0`) ke Supabase Postgres dengan *Row Level Security* (RLS).
   - Mengunduh koleksi komik saat pengguna login di perangkat baru.
   - Resolusi konflik data dengan aturan timestamp `updated_at` terbaru yang menang.
   - Tombol manual sinkronisasi di layar profil dengan penunjuk waktu terakhir sinkron.

7. **Notifikasi Pengingat Baca Terjadwal (FR-NOTIF)**
   - Menjadwalkan pengingat baca komik pada tanggal dan jam tertentu menggunakan `flutter_local_notifications` dan `timezone`.
   - Menggunakan mode alarm presisi Android (`AndroidScheduleMode.exactAllowWhileIdle`).
   - Opsi pengingat harian berulang ("Waktunya membaca!").
   - Fitur uji notifikasi instan langsung dari aplikasi.

8. **Toko Buku & Perpustakaan Terdekat (FR-LBS)**
   - Mengakses GPS perangkat menggunakan `geolocator`.
   - Menghitung jarak relatif pengguna ke toko buku dan perpustakaan di sekitar kampus UPN "Veteran" Yogyakarta (Gramedia, Togamas, Periplus, Perpustakaan Pusat UPN, Grhatama Pustaka DIY, dll.).
   - Menampilkan jarak terurut; penanda hijau untuk lokasi < 500 meter.
   - Tombol integrasi "Buka di Maps" yang langsung membuka aplikasi navigasi via `url_launcher`.

9. **Asisten AI Cerdas (FR-AI)**
   - Percakapan interaktif (*chat*) seputar rekomendasi komik bertenaga **Google Gemini 2.5 Flash**.
   - Arsitektur aman: Kunci API Gemini disimpan di Supabase Edge Function Secrets dan **tidak pernah** diekspos ke kode aplikasi Android.
   - Rekomendasi personal berdasarkan komik yang baru-baru ini dibaca dan komik favorit di SQLite.
   - Rekomendasi judul komik dapat diketuk langsung untuk mencari komik tersebut di MangaDex.
   - Fitur **"Ringkas AI"** pada halaman detail komik yang menyajikan 3 poin ringkasan sinopsis secara padat.
   - Pembatasan kuota (*rate limiting*) 20 permintaan per hari per pengguna yang dikontrol oleh tabel `ai_usage` di database Supabase.

10. **Personalisasi & Pengaturan (FR-SET)**
    - Dukungan Tema Terang (*Light Mode*) dan Tema Gelap (*Dark Mode*) yang tersimpan persisten di `SharedPreferences`.

---

## 🛠️ Tech Stack & Arsitektur

- **Framework**: Flutter (Target Android API 26+, Material 3)
- **Bahasa Pemrograman**: Dart 3
- **State Management**: `StatefulWidget` + `setState` dan `ValueNotifier` (sesuai standar materi praktikum tanpa library eksternal)
- **Networking & API**: `package:http` (MangaDex REST API)
- **Database Lokal**: `sqflite` + `path`
- **Preferensi Ringan**: `shared_preferences`
- **Backend & Cloud Database**: Supabase (`supabase_flutter`):
  - Supabase Auth
  - PostgreSQL Database + Row Level Security (RLS)
  - Supabase Edge Functions (Deno TypeScript)
- **Otentikasi Biometrik**: `local_auth`
- **Notifikasi**: `flutter_local_notifications` + `timezone`
- **Lokasi & Pemetaan**: `geolocator` + `url_launcher`
- **Penyedia AI / LLM**: Google Gemini API (`gemini-2.5-flash`) melalui Edge Function

Struktur Folder Arsitektur:
```text
lib/
├── config/             # Konfigurasi environment (Supabase URL & Anon Key)
├── models/             # Data models (Manga, Chapter, Favorite, Review, Reminder, dll.)
├── screens/            # UI Layar (Home, Search, Detail, Reader, Library, AI, Profile, dll.)
├── services/           # Service singleton (ApiService, SupabaseService, DatabaseHelper, dll.)
└── widgets/            # Reusable UI widgets (MangaCard, ChatBubble, RatingBar, ChapterTile, dll.)
supabase/
├── functions/          # Deno Edge Functions (ai-assistant)
└── schema.sql          # DDL Database, RLS Policies, dan Data Dummy LBS
docs/
├── DEMO_SCRIPT.md      # Skenario demonstrasi berurutan & hasil uji TC-01..TC-20
├── PRD_SRS.md          # Dokumen spesifikasi kebutuhan perangkat lunak resmi
├── SETUP.md            # Panduan setup CLI Supabase & Edge Function
└── TRACEABILITY.md     # Matriks ketertelusuran kebutuhan (FR Traceability)
```

---

## ⚙️ Panduan Instalasi & Menjalankan Aplikasi

### 1. Prasyarat Sistem
- Flutter SDK versi 3.32 atau lebih baru
- Android Studio / Android SDK (minSdk 26)
- Akun Supabase ([supabase.com](https://supabase.com))
- Kunci API Google Gemini ([Google AI Studio](https://aistudio.google.com/))

### 2. Setup Database Supabase
1. Buka dashboard proyek Supabase Anda dan masuk ke menu **SQL Editor**.
2. Buka file `supabase/schema.sql`, salin seluruh isinya, tempelkan ke SQL Editor, lalu jalankan (**Run**).
3. Skrip ini akan membuat tabel `profiles`, `bookstores`, `favorites`, `reading_history`, `reviews`, `ai_usage` serta seluruh aturan RLS yang diperlukan.

### 3. Setup & Deploy Supabase Edge Function (`ai-assistant`)
Jalankan perintah berikut di terminal:
```bash
# 1. Login ke Supabase CLI
supabase login

# 2. Hubungkan ke proyek Anda
cd komikku_app
supabase link --project-ref <PROJECT_REFERENCE_ID>

# 3. Daftarkan secret API Key Gemini
supabase secrets set GEMINI_API_KEY=AIzaSyYourGeminiApiKeyHere

# 4. Deploy fungsi asisten AI
supabase functions deploy ai-assistant
```

### 4. Konfigurasi Environment Klien Flutter
Buat file `lib/config/env.dart` dari berkas percontohan `lib/config/env.example.dart`:
```dart
// lib/config/env.dart
class Env {
  static const String supabaseUrl = 'https://YOUR_PROJECT_ID.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOi...YOUR_ANON_KEY';
}
```
*(Catatan: File `lib/config/env.dart` sudah terdaftar di `.gitignore` sehingga aman dari kebocoran git repository)*.

### 5. Menjalankan Aplikasi
```bash
# Mengunduh dependensi package
flutter pub get

# Memeriksa analisis kode (Harus 0 issues)
flutter analyze

# Menjalankan pada emulator atau perangkat fisik Android
flutter run
```

---

## 👥 Akun & Data Uji Demo (Demo Accounts)

Untuk mempermudah pengujian alur autentikasi dan sinkronisasi cloud multi-perangkat:

| Nama Pengguna | Email | Password | Keterangan |
|---|---|---|---|
| **Davi Pratama** | `davi@komikku.id` | `Password123!` | Akun Demo Utama (Favorit & Riwayat Baca) |
| **Syahrul Hidayat** | `syahrul@komikku.id` | `Password123!` | Akun Demo Kedua (Untuk Uji Sinkronisasi & Ulasan) |

---

## 📜 Atribusi API & Lisensi

- **Konten Komik**: Seluruh data judul, bab, sampul, dan halaman komik disediakan oleh **[MangaDex](https://mangadex.org/)** melalui API publik mereka (`https://api.mangadex.org/`) sesuai dengan *MangaDex API Acceptable Use Policy*. KomikKu tidak menyimpan berkas gambar berhak cipta di server sendiri.
- **Peta & Lokasi**: Koordinat lokasi toko buku di sekitar kampus UPN Veteran Yogyakarta dirujuk dari data publik OpenStreetMap / Google Maps.
- **Kecerdasan Buatan**: Didukung oleh model **Google Gemini 2.5 Flash**.

---

## 👨‍💻 Kontributor Pengembang

Proyek ini dikembangkan oleh tim mahasiswa untuk memenuhi tugas praktikum Pemrograman Aplikasi Mobile (PAM):
1. **Davi** — Mahasiswa 1
2. **Syahrul** — Mahasiswa 2
