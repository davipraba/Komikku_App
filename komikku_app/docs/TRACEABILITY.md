# Matriks Ketertelusuran Kebutuhan (Requirements Traceability Matrix)
## Aplikasi KomikKu — Tugas Praktikum Pemrograman Aplikasi Mobile (PAM)

Dokumen ini memetakan setiap Kebutuhan Fungsional (Functional Requirement / FR) pada dokumen Spesifikasi Kebutuhan Perangkat Lunak (`docs/PRD_SRS.md`) ke berkas implementasi dan status penyelesaiannya dalam proyek KomikKu.

---

### Ringkasan Status

| Kategori Kebutuhan | Total FR | Selesai | Sebagian | Belum |
|---|---|---|---|---|
| **FR-AUTH** (Autentikasi & Biometrik) | 16 | 16 | 0 | 0 |
| **FR-HOME** (Beranda & Jelajah) | 4 | 4 | 0 | 0 |
| **FR-SEARCH** (Pencarian & Filter) | 4 | 4 | 0 | 0 |
| **FR-DETAIL** (Detail Komik) | 5 | 5 | 0 | 0 |
| **FR-READER** (Pembaca Chapter) | 6 | 6 | 0 | 0 |
| **FR-LIB** (Perpustakaan & Riwayat) | 6 | 6 | 0 | 0 |
| **FR-SYNC** (Sinkronisasi Cloud) | 5 | 5 | 0 | 0 |
| **FR-REVIEW** (Rating & Ulasan Komunitas) | 5 | 5 | 0 | 0 |
| **FR-NOTIF** (Pengingat Baca / Notifikasi) | 6 | 6 | 0 | 0 |
| **FR-LBS** (Toko Buku & Perpustakaan Terdekat) | 6 | 6 | 0 | 0 |
| **FR-AI** (Asisten AI & LLM) | 9 | 9 | 0 | 0 |
| **FR-SET** (Pengaturan & Profil) | 4 | 4 | 0 | 0 |
| **TOTAL** | **76** | **76** | **0** | **0** |

---

### 1. FR-AUTH — Autentikasi & Biometrik

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-AUTH-01** | Registrasi email, password (min 6 karakter), dan nama tampilan. | `lib/screens/register_screen.dart`<br>`lib/services/supabase_service.dart` | Must | **Selesai** |
| **FR-AUTH-02** | Login email & password via Supabase Auth. | `lib/screens/login_screen.dart`<br>`lib/services/supabase_service.dart` | Must | **Selesai** |
| **FR-AUTH-03** | Validasi input kosong / kredensial salah dengan SnackBar error dan border field merah. | `lib/screens/login_screen.dart`<br>`lib/screens/register_screen.dart` | Must | **Selesai** |
| **FR-AUTH-04** | Simpan flag login di SharedPreferences dan navigasi ke Root dengan `pushReplacement`. | `lib/screens/login_screen.dart`<br>`lib/services/prefs_service.dart` | Must | **Selesai** |
| **FR-AUTH-05** | Periksa sesi Supabase & SharedPreferences saat aplikasi dibuka; jika valid langsung ke Beranda. | `lib/main.dart` (`AuthGate`)<br>`lib/services/supabase_service.dart` | Must | **Selesai** |
| **FR-AUTH-06** | Logout menghapus sesi & flag login, lalu `pushAndRemoveUntil` ke halaman login. | `lib/screens/profile_screen.dart`<br>`lib/services/supabase_service.dart`<br>`lib/services/prefs_service.dart` | Must | **Selesai** |
| **FR-AUTH-07** | Dialog tawaran "Aktifkan login biometrik?" setelah login password pertama berhasil jika perangkat mendukung. | `lib/screens/login_screen.dart`<br>`lib/services/biometric_service.dart` | Should | **Selesai** |
| **FR-AUTH-08** | Verifikasi biometrik sekali (`authenticate`), lalu simpan `biometricEnabled = true` di SharedPreferences. | `lib/screens/login_screen.dart`<br>`lib/services/biometric_service.dart`<br>`lib/services/prefs_service.dart` | Should | **Selesai** |
| **FR-AUTH-09** | Jika biometrik aktif & sesi valid, aplikasi menampilkan Lock Screen dan otomatis prompt biometrik. | `lib/screens/lock_screen.dart`<br>`lib/main.dart` (`AuthGate`) | Should | **Selesai** |
| **FR-AUTH-10** | Aplikasi tidak menyimpan email/password; biometrik hanya kunci lokal atas sesi Supabase. | `lib/services/biometric_service.dart`<br>`lib/services/prefs_service.dart` | Must | **Selesai** |
| **FR-AUTH-11** | Lock Screen menyediakan tombol "Coba lagi" dan "Login dengan password"; setelah 5x gagal paksa login password. | `lib/screens/lock_screen.dart` | Should | **Selesai** |
| **FR-AUTH-12** | Mengizinkan fallback ke PIN/pola/password kunci perangkat (`biometricOnly: false`). | `lib/services/biometric_service.dart` | Should | **Selesai** |
| **FR-AUTH-13** | Sembunyikan opsi biometrik jika perangkat tidak memiliki hardware biometrik atau tidak terdaftar. | `lib/screens/profile_screen.dart`<br>`lib/screens/login_screen.dart` | Should | **Selesai** |
| **FR-AUTH-14** | Jika sesi Supabase kedaluwarsa, lewati biometrik dan arahkan langsung ke login password. | `lib/main.dart` (`AuthGate`)<br>`lib/services/supabase_service.dart` | Must | **Selesai** |
| **FR-AUTH-15** | Saat logout, flag `biometricEnabled` direset ke `false` dan sesi dihapus. | `lib/screens/profile_screen.dart`<br>`lib/services/prefs_service.dart` | Should | **Selesai** |
| **FR-AUTH-16** | Aplikasi kembali dari background > 60 detik memunculkan Lock Screen jika biometrik aktif (`WidgetsBindingObserver`). | `lib/screens/root.dart`<br>`lib/services/prefs_service.dart` | Should | **Selesai** |

---

### 2. FR-HOME — Beranda & Jelajah

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-HOME-01** | Beranda menampilkan daftar komik populer dalam GridView 2 kolom (cover, judul). | `lib/screens/home_screen.dart`<br>`lib/widgets/manga_card.dart` | Must | **Selesai** |
| **FR-HOME-02** | Indikator `CircularProgressIndicator` saat data sedang dimuat. | `lib/screens/home_screen.dart` | Must | **Selesai** |
| **FR-HOME-03** | Pesan error dan tombol "Coba lagi" bila koneksi/request gagal. | `lib/screens/home_screen.dart` | Must | **Selesai** |
| **FR-HOME-04** | Paginasi data (muat komik berikutnya saat scroll mencapai batas bawah). | `lib/screens/home_screen.dart`<br>`lib/services/api_service.dart` | Must | **Selesai** |

---

### 3. FR-SEARCH — Pencarian & Filter

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-SEARCH-01** | Pencarian judul komik melalui TextField ke endpoint pencarian MangaDex. | `lib/screens/search_screen.dart`<br>`lib/services/api_service.dart` | Must | **Selesai** |
| **FR-SEARCH-02** | Mekanisme debounce 500 ms menggunakan `Timer` agar hemat panggilan API. | `lib/screens/search_screen.dart` | Must | **Selesai** |
| **FR-SEARCH-03** | Filter multi-genre menggunakan FilterChip interaktif dari API tag MangaDex. | `lib/screens/search_screen.dart`<br>`lib/services/api_service.dart` | Should | **Selesai** |
| **FR-SEARCH-04** | State kosong bertuliskan "Komik tidak ditemukan" jika hasil pencarian nihil. | `lib/screens/search_screen.dart` | Must | **Selesai** |

---

### 4. FR-DETAIL — Detail Komik

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-DETAIL-01** | Menerima ID komik via constructor parameter (passing data) dan fetch detail dari API. | `lib/screens/detail_screen.dart`<br>`lib/services/api_service.dart` | Must | **Selesai** |
| **FR-DETAIL-02** | Menampilkan cover, judul, author, status rilis, genre tags, sinopsis expand/collapse, dan rating. | `lib/screens/detail_screen.dart`<br>`lib/models/manga.dart` | Must | **Selesai** |
| **FR-DETAIL-03** | Menampilkan feed daftar chapter (filter bahasa ID/EN, urut naik/turun). | `lib/screens/detail_screen.dart`<br>`lib/widgets/chapter_tile.dart` | Must | **Selesai** |
| **FR-DETAIL-04** | Tombol Favorit (toggle icon) dan tombol "Lanjut baca" ke posisi terakhir baca. | `lib/screens/detail_screen.dart`<br>`lib/services/database_helper.dart` | Must | **Selesai** |
| **FR-DETAIL-05** | Tombol "Ringkas AI" membuka Modal BottomSheet ringkasan sinopsis 3 poin via LLM. | `lib/screens/detail_screen.dart`<br>`lib/services/ai_service.dart` | Should | **Selesai** |

---

### 5. FR-READER — Pembaca Chapter

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-READER-01** | Mengambil URL halaman dari endpoint at-home MangaDex. | `lib/screens/reader_screen.dart`<br>`lib/services/api_service.dart` | Must | **Selesai** |
| **FR-READER-02** | Tampilan pembaca gambar komik (PageView horizontal atau ListView vertikal sesuai pengaturan). | `lib/screens/reader_screen.dart` | Must | **Selesai** |
| **FR-READER-03** | Indikator nomor halaman aktif "Halaman x dari y". | `lib/screens/reader_screen.dart` | Must | **Selesai** |
| **FR-READER-04** | Menyimpan riwayat baca (komik, chapter, halaman terakhir) ke SQLite saat halaman berganti & keluar. | `lib/screens/reader_screen.dart`<br>`lib/services/database_helper.dart` | Must | **Selesai** |
| **FR-READER-05** | Opsi hemat data (kualitas gambar data-saver vs normal). | `lib/screens/reader_screen.dart`<br>`lib/services/prefs_service.dart`<br>`lib/services/api_service.dart` | Should | **Selesai** |
| **FR-READER-06** | Kontrol ketukan layar untuk menyembunyikan/menampilkan AppBar dan navigasi (fullscreen mode). | `lib/screens/reader_screen.dart` | Should | **Selesai** |

---

### 6. FR-LIB — Perpustakaan & Riwayat Lokal

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-LIB-01** | Tab "Favorit" menampilkan koleksi komik favorit dari database SQLite. | `lib/screens/library_screen.dart`<br>`lib/services/database_helper.dart` | Must | **Selesai** |
| **FR-LIB-02** | Menghapus komik dari favorit (soft-delete untuk sinkronisasi cloud). | `lib/screens/library_screen.dart`<br>`lib/screens/detail_screen.dart` | Must | **Selesai** |
| **FR-LIB-03** | Tab "Riwayat" menampilkan komik yang pernah dibaca beserta chapter dan halaman terakhir. | `lib/screens/library_screen.dart`<br>`lib/models/reading_history.dart` | Must | **Selesai** |
| **FR-LIB-04** | Mengetuk item riwayat langsung membuka Reader pada chapter dan halaman tersimpan. | `lib/screens/library_screen.dart`<br>`lib/screens/reader_screen.dart` | Must | **Selesai** |
| **FR-LIB-05** | Seluruh data favorit dan riwayat difilter berdasarkan `user_id` yang sedang login dan dapat diakses offline. | `lib/services/database_helper.dart`<br>`lib/screens/library_screen.dart` | Must | **Selesai** |
| **FR-LIB-06** | Tombol "Hapus Semua Riwayat" dengan dialog konfirmasi. | `lib/screens/library_screen.dart`<br>`lib/services/database_helper.dart` | Should | **Selesai** |

---

### 7. FR-SYNC — Sinkronisasi Cloud

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-SYNC-01** | Push unggah baris lokal `is_synced = 0` (termasuk soft-delete `is_deleted = 1`) ke Supabase Postgres. | `lib/services/sync_service.dart` | Should | **Selesai** |
| **FR-SYNC-02** | Pull unduh semua data cloud milik pengguna saat login di perangkat baru. | `lib/services/sync_service.dart` | Should | **Selesai** |
| **FR-SYNC-03** | Resolusi konflik: baris dengan timestamp `updated_at` terbaru yang menang. | `lib/services/sync_service.dart` | Should | **Selesai** |
| **FR-SYNC-04** | Tombol manual "Sinkronkan sekarang" di Profil menampilkan status dan timestamp `lastSyncAt`. | `lib/screens/profile_screen.dart`<br>`lib/services/sync_service.dart` | Should | **Selesai** |
| **FR-SYNC-05** | Kegagalan sinkronisasi saat offline tidak mengganggu antarmuka pengguna (silent background retry). | `lib/services/sync_service.dart` | Should | **Selesai** |

---

### 8. FR-REVIEW — Rating & Ulasan Komunitas

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-REVIEW-01** | Pengguna dapat memberikan rating 1-5 bintang dan komentar teks pada komik. | `lib/screens/detail_screen.dart`<br>`lib/services/review_service.dart` | Should | **Selesai** |
| **FR-REVIEW-02** | Rating dan ulasan disimpan di tabel `reviews` Supabase dengan UNIQUE(`user_id`, `manga_id`). | `supabase/schema.sql`<br>`lib/services/review_service.dart` | Should | **Selesai** |
| **FR-REVIEW-03** | Halaman detail menampilkan rata-rata rating dan daftar ulasan pengguna lain. | `lib/screens/detail_screen.dart`<br>`lib/models/review.dart` | Should | **Selesai** |
| **FR-REVIEW-04** | Pengguna dapat mengubah atau menghapus ulasan miliknya sendiri. | `lib/screens/detail_screen.dart`<br>`lib/services/review_service.dart` | Should | **Selesai** |
| **FR-REVIEW-05** | Widget interaktif `RatingBar` reusable untuk memilih bintang rating (1-5). | `lib/widgets/rating_bar.dart` | Should | **Selesai** |

---

### 9. FR-NOTIF — Pengingat Baca & Rilis (Notifikasi Lokal)

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-NOTIF-01** | Pengguna dapat menjadwalkan notifikasi pengingat untuk komik favorit pada tanggal dan jam tertentu. | `lib/screens/reminder_screen.dart`<br>`lib/services/notification_service.dart` | Must | **Selesai** |
| **FR-NOTIF-02** | Meminta izin notifikasi Android 13+ (`POST_NOTIFICATIONS`) saat pertama kali digunakan. | `lib/services/notification_service.dart` | Must | **Selesai** |
| **FR-NOTIF-03** | Form penjadwalan menyediakan pemilihan komik, tanggal (`showDatePicker`), dan jam (`showTimePicker`). | `lib/screens/reminder_screen.dart` | Must | **Selesai** |
| **FR-NOTIF-04** | Notifikasi muncul tepat waktu meskipun aplikasi ditutup (`exactAllowWhileIdle`). | `lib/services/notification_service.dart` | Must | **Selesai** |
| **FR-NOTIF-05** | Daftar reminder dapat dilihat dan dibatalkan dari halaman Reminder (id notifikasi = id baris SQLite). | `lib/screens/reminder_screen.dart`<br>`lib/services/database_helper.dart` | Must | **Selesai** |
| **FR-NOTIF-06** | Opsi reminder harian berulang pada jam tertentu ("Waktunya membaca!"). | `lib/screens/reminder_screen.dart`<br>`lib/services/notification_service.dart` | Should | **Selesai** |

---

### 10. FR-LBS — Toko Buku & Perpustakaan Terdekat

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-LBS-01** | Sistem meminta izin lokasi dan memeriksa status GPS aktif. | `lib/services/location_service.dart`<br>`lib/screens/nearby_screen.dart` | Must | **Selesai** |
| **FR-LBS-02** | Mengambil posisi koordinat pengguna dengan `Geolocator.getCurrentPosition`. | `lib/services/location_service.dart` | Must | **Selesai** |
| **FR-LBS-03** | Menghitung jarak ke daftar lokasi di sekitar kampus UPN Veteran Yogyakarta dengan `distanceBetween`. | `lib/services/location_service.dart`<br>`lib/screens/nearby_screen.dart` | Must | **Selesai** |
| **FR-LBS-04** | Daftar diurutkan dari yang terdekat; lokasi berjarak < 500 m ditandai badge hijau. | `lib/screens/nearby_screen.dart` | Must | **Selesai** |
| **FR-LBS-05** | Tombol "Buka di Maps" membuka navigasi Google Maps via `url_launcher`. | `lib/screens/nearby_screen.dart` | Must | **Selesai** |
| **FR-LBS-06** | Menampilkan pesan yang jelas bila izin lokasi ditolak atau GPS nonaktif tanpa crash. | `lib/screens/nearby_screen.dart` | Must | **Selesai** |

---

### 11. FR-AI — Asisten AI (LLM via Edge Function)

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-AI-01** | Halaman "Asisten AI" berbentuk antarmuka chat dengan input pesan pengguna. | `lib/screens/ai_screen.dart`<br>`lib/widgets/chat_bubble.dart` | Should | **Selesai** |
| **FR-AI-02** | Klien memanggil Supabase Edge Function `ai-assistant` yang mengeksekusi LLM dan mengembalikan respons. | `lib/services/ai_service.dart`<br>`supabase/functions/ai-assistant/index.ts` | Should | **Selesai** |
| **FR-AI-03** | System prompt membatasi topik pembicaraan hanya seputar komik dan dalam Bahasa Indonesia. | `supabase/functions/ai-assistant/index.ts` | Should | **Selesai** |
| **FR-AI-04** | Konteks permintaan menyertakan komik favorit dan 5 komik terakhir dibaca dari SQLite. | `lib/services/ai_service.dart`<br>`supabase/functions/ai-assistant/index.ts` | Should | **Selesai** |
| **FR-AI-05** | Fitur "Ringkas AI" pada detail menghasilkan rangkuman sinopsis 3 poin penting. | `lib/screens/detail_screen.dart`<br>`lib/services/ai_service.dart` | Should | **Selesai** |
| **FR-AI-06** | Judul rekomendasi pada balasan AI dapat diketuk untuk mencari komik tersebut di MangaDex. | `lib/widgets/chat_bubble.dart`<br>`lib/screens/search_screen.dart` | Should | **Selesai** |
| **FR-AI-07** | Indikator sedang mengetik saat menunggu balasan; kartu error dan tombol ulangi saat gagal/timeout. | `lib/screens/ai_screen.dart` | Should | **Selesai** |
| **FR-AI-08** | Edge Function membatasi pemakaian maksimal 20 permintaan/hari/pengguna (rate limit). | `supabase/functions/ai-assistant/index.ts`<br>`supabase/schema.sql` (`ai_usage`) | Should | **Selesai** |
| **FR-AI-09** | Riwayat pesan chat disimpan di SQLite (hingga 50 pesan terakhir per pengguna). | `lib/services/database_helper.dart`<br>`lib/models/chat_message.dart`<br>`lib/screens/ai_screen.dart` | Should | **Selesai** |

---

### 12. FR-SET — Pengaturan & Profil

| ID | Deskripsi Kebutuhan | File Implementasi | Prioritas | Status |
|---|---|---|---|---|
| **FR-SET-01** | Pilihan tema terang/gelap disimpan di SharedPreferences dan diterapkan secara reaktif. | `lib/services/prefs_service.dart`<br>`lib/screens/profile_screen.dart`<br>`lib/main.dart` | Must | **Selesai** |
| **FR-SET-02** | Pengaturan mode baca (vertikal/horizontal) dan kualitas gambar (hemat data/normal). | `lib/services/prefs_service.dart`<br>`lib/screens/profile_screen.dart` | Must | **Selesai** |
| **FR-SET-03** | Profil menampilkan nama tampilan, email pengguna, tombol Logout, dan navigasi Tentang (Atribusi MangaDex). | `lib/screens/profile_screen.dart`<br>`lib/screens/about_screen.dart` | Must | **Selesai** |
| **FR-SET-04** | Switch toggle "Login biometrik" yang memerlukan verifikasi biometrik untuk aktivasi. | `lib/screens/profile_screen.dart`<br>`lib/services/biometric_service.dart` | Should | **Selesai** |
