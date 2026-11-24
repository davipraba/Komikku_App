# KomikKu — PRD & SRS
Aplikasi Pembaca Komik dengan Asisten AI, Reminder Rilis, dan Toko Buku Terdekat

Tim: Davi & Syahrul | Mata kuliah: Praktikum Teknologi dan Pemrograman Mobile
Stack: Flutter (Dart) · SQLite (sqflite) · Supabase · LLM (Gemini API via Supabase Edge Function)

---

# BAGIAN 0 — Rekomendasi Tema

**Tema pilihan: aplikasi baca komik (ide kalian sudah tepat).**

Alasannya:
1. Hampir semua materi modul 1–7 dipakai secara natural, tanpa dipaksakan.
2. Data komik tersedia gratis lewat API publik (MangaDex), jadi tidak perlu bikin backend konten sendiri.
3. Mudah dibagi dua orang.
4. Fitur LLM-nya masuk akal (rekomendasi, ringkasan, tanya-jawab sinopsis).

**Alternatif (kalau ingin lebih ringan):** aplikasi catatan keuangan mahasiswa, atau aplikasi pelacak habit dengan reminder. Keduanya lebih mudah, tetapi komik lebih menarik saat demo dan lebih kaya fitur.

**Catatan penting soal legalitas:** jangan scraping situs komik bajakan. Gunakan **MangaDex API** (publik, tanpa API key untuk baca data) dan cantumkan atribusi "Data & gambar dari MangaDex" di halaman About. Ini aman untuk tugas kuliah.

**Pemetaan ke materi praktikum:**

| Modul | Materi | Dipakai di KomikKu |
|---|---|---|
| 1 | Setup Flutter | Setup project, run di emulator/HP |
| 2 | Widget & layout | ListView, GridView, Card, TextField, Stack (cover + badge), SingleChildScrollView |
| 3 | State & data | StatefulWidget, setState, TextEditingController, model class, conditional rendering, error handling form login |
| 4 | Navigation | push, pop, pushReplacement, pushAndRemoveUntil, passing data, BottomNavigationBar |
| 5 | HTTP request | Ambil daftar komik, detail, chapter, halaman gambar dari MangaDex; `fromJson`, async/await, loading indicator, try-catch, static method `ApiService` |
| 6 | Local storage | SharedPreferences (sesi login, tema, mode baca) + SQLite (favorit, riwayat baca, bookmark) |
| 7 | Notification & LBS | Reminder baca/rilis chapter (scheduled notification), toko buku/perpustakaan terdekat (geolocator) |
| Tambahan | Supabase + LLM | Auth, sinkronisasi cloud, rating/ulasan, asisten AI |

---

# BAGIAN 1 — PRD (Product Requirements Document)

## 1.1 Ringkasan Produk
**KomikKu** adalah aplikasi mobile (Android) untuk menemukan, membaca, dan mengelola koleksi komik. Pengguna bisa mencari komik, membaca chapter, menyimpan favorit dan riwayat (tersimpan lokal, tetap bisa dilihat offline), menyinkronkan koleksi ke cloud, mengatur pengingat baca, menemukan toko buku terdekat, dan bertanya kepada asisten AI untuk rekomendasi dan ringkasan.

## 1.2 Latar Belakang & Masalah
- Pembaca komik sering kehilangan jejak: sudah sampai chapter berapa, komik apa saja yang ingin dibaca.
- Berpindah HP berarti kehilangan daftar bacaan.
- Bingung memilih komik baru yang cocok dengan selera.
- Pembaca yang ingin membeli versi cetak tidak tahu toko buku terdekat.

## 1.3 Tujuan Produk
1. Menyediakan pengalaman baca komik yang sederhana dan nyaman.
2. Menyimpan progres baca secara lokal (cepat, tetap tersedia tanpa internet) dan sinkron ke cloud.
3. Membantu pengguna menemukan komik lewat pencarian, filter genre, dan rekomendasi AI.
4. Menerapkan seluruh materi praktikum (modul 1–7) dalam satu aplikasi utuh.

## 1.4 Target Pengguna
- **Persona 1 – Rani (20, mahasiswa):** rutin baca komik di sela kuliah, sering ganti HP/emulator, ingin progres tidak hilang.
- **Persona 2 – Bima (23, pekerja):** waktu baca terbatas, butuh pengingat dan rekomendasi cepat.

## 1.5 Ruang Lingkup

**In scope (MVP):**
- Registrasi/login (Supabase Auth), sesi tersimpan di SharedPreferences
- **Login biometrik** (sidik jari/wajah, fallback PIN/pola perangkat) sebagai kunci akses saat membuka aplikasi
- Jelajah, pencarian, filter genre
- Detail komik, daftar chapter, pembaca chapter
- Favorit dan riwayat baca (SQLite)
- Sinkronisasi favorit/riwayat ke Supabase
- Rating & ulasan komik (Supabase)
- Reminder baca (scheduled notification) + notifikasi langsung
- Toko buku/perpustakaan terdekat (LBS)
- Asisten AI (rekomendasi, ringkasan sinopsis, tanya-jawab)
- Tema gelap/terang

**Out of scope:**
- Upload komik oleh pengguna
- Pembayaran/langganan
- Push notification dari server (FCM)
- Platform iOS (fokus Android)
- Download chapter penuh untuk offline (hanya metadata favorit/riwayat yang offline)

## 1.6 User Stories

| ID | Sebagai… | Saya ingin… | Supaya… | Prioritas |
|---|---|---|---|---|
| US-01 | Pengguna baru | mendaftar dan login | akun dan data saya aman | Must |
| US-02 | Pengguna | tetap login saat membuka ulang aplikasi | tidak login berulang | Must |
| US-03 | Pengguna | melihat daftar komik populer | menemukan bacaan | Must |
| US-04 | Pengguna | mencari komik berdasarkan judul | cepat menemukan komik tertentu | Must |
| US-05 | Pengguna | memfilter berdasarkan genre | mempersempit pilihan | Should |
| US-06 | Pengguna | melihat detail dan daftar chapter | memilih chapter | Must |
| US-07 | Pengguna | membaca chapter halaman demi halaman | menikmati komik | Must |
| US-08 | Pengguna | menandai komik favorit | mengaksesnya cepat | Must |
| US-09 | Pengguna | melihat riwayat baca dan lanjut dari chapter terakhir | tidak kehilangan progres | Must |
| US-10 | Pengguna | favorit/riwayat tersinkron ke cloud | data aman saat ganti HP | Should |
| US-11 | Pengguna | memberi rating dan ulasan | berbagi pendapat | Should |
| US-12 | Pengguna | mengatur pengingat baca | rutin membaca | Should |
| US-13 | Pengguna | melihat toko buku terdekat | membeli komik cetak | Could |
| US-14 | Pengguna | bertanya ke asisten AI tentang rekomendasi | menemukan komik cocok selera | Should |
| US-15 | Pengguna | meringkas sinopsis dengan AI | memahami cerita cepat | Could |
| US-16 | Pengguna | mengganti tema gelap/terang | nyaman membaca malam hari | Could |
| US-17 | Pengguna | membuka aplikasi dengan sidik jari/wajah | login cepat tanpa mengetik password dan akun lebih aman | Should |
| US-18 | Pengguna | mengaktifkan/menonaktifkan biometrik di pengaturan | saya yang mengontrol keamanannya | Should |

## 1.7 Daftar Fitur & Prioritas

| Kode | Fitur | Prioritas | Modul terkait |
|---|---|---|---|
| F1 | Autentikasi, sesi & **login biometrik** | Must (email) / Should (biometrik) | 3, 4, 6, Supabase, `local_auth` |
| F2 | Beranda & jelajah komik | Must | 2, 5 |
| F3 | Pencarian & filter genre | Must | 3, 5 |
| F4 | Detail komik & daftar chapter | Must | 4, 5 |
| F5 | Pembaca chapter | Must | 2, 5 |
| F6 | Favorit & riwayat (offline) | Must | 6 (SQLite) |
| F7 | Sinkronisasi cloud | Should | Supabase |
| F8 | Rating & ulasan | Should | Supabase |
| F9 | Reminder baca & notifikasi | Should | 7 |
| F10 | Toko buku terdekat (LBS) | Could | 7 |
| F11 | Asisten AI | Should | LLM |
| F12 | Pengaturan (tema, mode baca, logout) | Could | 6 |

## 1.8 Metrik Keberhasilan (untuk penilaian praktikum)
- Semua fitur Must berjalan tanpa crash di emulator/HP fisik.
- Minimal 1 fitur dari tiap modul 2–7 terdemonstrasi.
- Waktu muat daftar komik < 3 detik pada koneksi normal.
- Favorit dan riwayat tetap tampil saat mode pesawat.
- Respons AI < 10 detik.

## 1.9 Risiko & Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| MangaDex API lambat/rate limit | Daftar tidak tampil | Caching ringan di SQLite, loading & retry, batasi request |
| Gambar halaman besar | Lambat/boros kuota | Gunakan kualitas `data-saver`, `cached_network_image` |
| API key LLM bocor | Penyalahgunaan | Simpan key di Supabase Edge Function, bukan di aplikasi |
| Kuota LLM gratis habis | Fitur AI mati | Pesan fallback, batasi panjang prompt & jumlah request per hari |
| Scheduled notification tidak muncul di emulator | Gagal demo | Demo di HP fisik, izin exact alarm |
| Waktu pengerjaan terbatas | Fitur belum selesai | Kerjakan berdasarkan prioritas Must → Should → Could |
| Emulator tidak punya biometrik terdaftar / perangkat tidak mendukung | Biometrik tidak bisa didemokan | Daftarkan fingerprint di emulator (Settings → Security) atau uji di HP fisik; sistem otomatis fallback ke password |
| Sesi Supabase kedaluwarsa saat biometrik aktif | Pengguna tertahan di lock screen | Jika sesi tidak valid, arahkan ke login password dan beri pesan jelas |

## 1.10 Pembagian Tugas (2 orang)

| Area | Davi | Syahrul |
|---|---|---|
| UI | Login/register, beranda, detail, pembaca | Favorit, riwayat, profil, pengaturan, asisten AI |
| Data | ApiService MangaDex, model, Supabase Auth | SQLite (DatabaseHelper), sinkronisasi Supabase |
| Fitur lanjutan | Rating/ulasan, notifikasi | LBS, LLM (Edge Function + UI chat) |
| Dokumen | PRD, SRS | Laporan, video demo |

(Silakan tukar sesuai kemampuan; yang penting tiap orang menyentuh data layer dan UI.)

## 1.11 Timeline Usulan (6 minggu)

| Minggu | Target |
|---|---|
| 1 | Setup project, struktur folder, Supabase project, UI login/register, navigasi dasar |
| 2 | ApiService MangaDex, beranda, pencarian, detail |
| 3 | Pembaca chapter, SQLite favorit & riwayat |
| 4 | Sinkronisasi Supabase, rating/ulasan, pengaturan & tema |
| 5 | Notifikasi, LBS, asisten AI |
| 6 | Testing, perbaikan bug, polishing UI, laporan, demo |

---

# BAGIAN 2 — SRS (Software Requirements Specification)

## 2.1 Pendahuluan

### 2.1.1 Tujuan
Dokumen ini menjelaskan kebutuhan fungsional dan non-fungsional aplikasi KomikKu sebagai acuan implementasi dan pengujian.

### 2.1.2 Definisi
| Istilah | Arti |
|---|---|
| Manga/Komik | Judul komik dari MangaDex |
| Chapter | Satu bab komik |
| Edge Function | Fungsi server kecil di Supabase untuk memanggil LLM secara aman |
| RLS | Row Level Security Supabase, membatasi akses data per pengguna |
| LBS | Location-Based Services |

### 2.1.3 Referensi
- MangaDex API: https://api.mangadex.org/docs/
- Dokumentasi Supabase, Flutter, sqflite, geolocator, flutter_local_notifications
- Modul Praktikum 1–7

## 2.2 Deskripsi Umum

### 2.2.1 Perspektif Produk
Aplikasi klien mobile (Flutter) yang berkomunikasi dengan tiga layanan eksternal: MangaDex (konten), Supabase (auth, database cloud, edge function), dan LLM provider (melalui Edge Function).

### 2.2.2 Arsitektur

```
┌──────────────────────── Flutter App (Android) ────────────────────────┐
│ Presentation: screens/ + widgets/                                     │
│ State: StatefulWidget + setState (+ ValueNotifier bila perlu)         │
│ Data layer:                                                           │
│   ApiService (MangaDex)   SupabaseService   DatabaseHelper (SQLite)   │
│   PrefsService (SharedPreferences)   NotificationService   LocationSvc│
└──────────┬──────────────────┬─────────────────────────────────────────┘
           │ HTTP             │ supabase_flutter
           ▼                  ▼
     MangaDex API        Supabase: Auth · Postgres · Edge Function ──► LLM API
```

### 2.2.3 Karakteristik Pengguna
Pengguna umum tanpa keahlian teknis; aplikasi berbahasa Indonesia.

### 2.2.4 Lingkungan Operasi
- Android 8.0 (API 26) atau lebih baru
- Flutter stable, Dart 3.x
- Koneksi internet untuk konten online; mode terbatas offline

### 2.2.5 Asumsi & Ketergantungan
- MangaDex API tersedia dan tidak berubah drastis.
- Pengguna memberi izin notifikasi dan lokasi untuk fitur terkait.
- Supabase free tier dan kuota LLM gratis mencukupi untuk demo.

## 2.3 Kebutuhan Fungsional

### FR-AUTH — Autentikasi
| ID | Kebutuhan |
|---|---|
| FR-AUTH-01 | Sistem menyediakan registrasi dengan email, password (min. 6 karakter), dan nama tampilan. |
| FR-AUTH-02 | Sistem menyediakan login dengan email dan password via Supabase Auth. |
| FR-AUTH-03 | Jika input kosong atau kredensial salah, sistem menampilkan SnackBar error dan border field merah. |
| FR-AUTH-04 | Setelah login, sistem menyimpan flag login di SharedPreferences dan menavigasi ke Root dengan `pushReplacement`. |
| FR-AUTH-05 | Saat aplikasi dibuka, sistem memeriksa SharedPreferences dan sesi Supabase; jika valid langsung ke Beranda. |
| FR-AUTH-06 | Logout menghapus sesi dan flag login, lalu `pushAndRemoveUntil` ke halaman login. |
| FR-AUTH-07 | Setelah login password pertama berhasil, jika perangkat mendukung biometrik dan sudah ada biometrik terdaftar, sistem menawarkan dialog "Aktifkan login biometrik?". |
| FR-AUTH-08 | Jika pengguna setuju, sistem memverifikasi biometrik sekali (`authenticate`) lalu menyimpan `biometricEnabled = true` di SharedPreferences. |
| FR-AUTH-09 | Jika `biometricEnabled = true` dan sesi Supabase masih valid, saat aplikasi dibuka sistem menampilkan **Lock Screen** dan otomatis memunculkan prompt biometrik; Beranda hanya terbuka setelah autentikasi berhasil. |
| FR-AUTH-10 | Sistem tidak menyimpan email/password pengguna. Biometrik hanya berfungsi sebagai "kunci" atas sesi Supabase yang sudah ada di perangkat. |
| FR-AUTH-11 | Jika biometrik gagal/dibatalkan, Lock Screen menyediakan tombol "Coba lagi" dan "Login dengan password". Setelah 5 kali gagal beruntun (atau sistem mengunci sementara), sistem memaksa login password. |
| FR-AUTH-12 | Sistem mengizinkan fallback ke PIN/pola/password layar kunci perangkat (`biometricOnly: false`). |
| FR-AUTH-13 | Jika perangkat tidak mendukung biometrik, belum ada biometrik terdaftar, atau izin dicabut, opsi biometrik disembunyikan/dinonaktifkan dan sistem memakai alur login password biasa. |
| FR-AUTH-14 | Jika sesi Supabase sudah kedaluwarsa/tidak valid, flag biometrik dilewati dan pengguna diarahkan ke login password. |
| FR-AUTH-15 | Saat logout, `biometricEnabled` direset ke `false` dan sesi dihapus. |
| FR-AUTH-16 | Aplikasi yang kembali dari background setelah > 60 detik menampilkan Lock Screen lagi bila biometrik aktif (via `WidgetsBindingObserver`). |

### FR-HOME — Beranda & Jelajah
| ID | Kebutuhan |
|---|---|
| FR-HOME-01 | Beranda menampilkan komik populer dalam GridView (cover, judul). |
| FR-HOME-02 | Saat data dimuat, sistem menampilkan CircularProgressIndicator. |
| FR-HOME-03 | Jika request gagal, sistem menampilkan pesan error dan tombol "Coba lagi". |
| FR-HOME-04 | Daftar mendukung paginasi (muat lebih banyak saat scroll ke bawah atau tombol "Muat lagi"). |

### FR-SEARCH — Pencarian & Filter
| ID | Kebutuhan |
|---|---|
| FR-SEARCH-01 | Pengguna dapat mengetik judul pada TextField; hasil diambil dari endpoint pencarian MangaDex. |
| FR-SEARCH-02 | Pencarian memakai debounce ±500 ms agar tidak membebani API. |
| FR-SEARCH-03 | Pengguna dapat memilih genre (chip) untuk memfilter hasil. |
| FR-SEARCH-04 | Jika hasil kosong, sistem menampilkan "Komik tidak ditemukan". |

### FR-DETAIL — Detail Komik
| ID | Kebutuhan |
|---|---|
| FR-DETAIL-01 | Menerima ID komik melalui constructor (passing data) dan mengambil detail dari API. |
| FR-DETAIL-02 | Menampilkan cover, judul, penulis, status, genre, sinopsis, rata-rata rating. |
| FR-DETAIL-03 | Menampilkan daftar chapter (bahasa Indonesia/Inggris, urut naik/turun). |
| FR-DETAIL-04 | Tersedia tombol favorit (toggle) dan tombol "Lanjut baca" bila ada riwayat. |
| FR-DETAIL-05 | Tersedia tombol "Ringkas dengan AI" (lihat FR-AI). |

### FR-READER — Pembaca Chapter
| ID | Kebutuhan |
|---|---|
| FR-READER-01 | Mengambil daftar URL halaman dari endpoint at-home MangaDex. |
| FR-READER-02 | Menampilkan halaman secara vertikal (scroll) atau horizontal (swipe) sesuai pengaturan. |
| FR-READER-03 | Menampilkan indikator "Halaman x/y". |
| FR-READER-04 | Menyediakan tombol chapter sebelumnya/berikutnya. |
| FR-READER-05 | Saat chapter dibuka/ditutup, sistem menyimpan riwayat (komik, chapter, halaman terakhir) ke SQLite. |

### FR-LIB — Favorit & Riwayat (SQLite)
| ID | Kebutuhan |
|---|---|
| FR-LIB-01 | Pengguna dapat menambah/menghapus komik dari favorit; tersimpan di SQLite (operasi CRUD). |
| FR-LIB-02 | Halaman Favorit menampilkan daftar dari SQLite dan tetap tampil tanpa internet. |
| FR-LIB-03 | Halaman Riwayat menampilkan komik terakhir dibaca beserta chapter dan waktu. |
| FR-LIB-04 | Pengguna dapat menghapus satu item atau seluruh riwayat. |
| FR-LIB-05 | Data difilter berdasarkan `user_id` agar akun berbeda di satu HP tidak bercampur. |

### FR-SYNC — Sinkronisasi Cloud (Supabase)
| ID | Kebutuhan |
|---|---|
| FR-SYNC-01 | Sistem mengunggah favorit dan riwayat ke Supabase saat ada perubahan dan koneksi tersedia. |
| FR-SYNC-02 | Setelah login di perangkat baru, sistem mengunduh favorit/riwayat dari Supabase ke SQLite. |
| FR-SYNC-03 | Konflik diselesaikan dengan aturan "data dengan `updated_at` terbaru menang". |
| FR-SYNC-04 | Tersedia tombol "Sinkronkan sekarang" dan penanda waktu sinkron terakhir. |
| FR-SYNC-05 | Item yang belum tersinkron ditandai `is_synced = 0` dan dicoba ulang saat online. |

### FR-REVIEW — Rating & Ulasan
| ID | Kebutuhan |
|---|---|
| FR-REVIEW-01 | Pengguna dapat memberi rating 1–5 dan ulasan teks pada sebuah komik. |
| FR-REVIEW-02 | Ulasan disimpan di tabel Supabase dan tampil ke semua pengguna di halaman detail. |
| FR-REVIEW-03 | Satu pengguna hanya punya satu ulasan per komik (dapat diedit/dihapus). |
| FR-REVIEW-04 | Sistem menampilkan rata-rata rating dari komunitas KomikKu. |

### FR-NOTIF — Notifikasi & Reminder
| ID | Kebutuhan |
|---|---|
| FR-NOTIF-01 | Sistem meminta izin notifikasi pada peluncuran pertama. |
| FR-NOTIF-02 | Pengguna dapat mengirim notifikasi uji langsung (immediate notification). |
| FR-NOTIF-03 | Pengguna dapat menjadwalkan reminder: memilih komik (dari favorit), tanggal, dan jam. |
| FR-NOTIF-04 | Notifikasi terjadwal muncul walau aplikasi ditutup dan berisi judul komik. |
| FR-NOTIF-05 | Reminder dapat dilihat dan dibatalkan dari halaman Reminder. |
| FR-NOTIF-06 | Opsi reminder harian berulang pada jam tertentu ("Waktunya membaca!"). |

### FR-LBS — Toko Buku Terdekat
| ID | Kebutuhan |
|---|---|
| FR-LBS-01 | Sistem meminta izin lokasi dan memeriksa GPS aktif. |
| FR-LBS-02 | Sistem mengambil posisi pengguna dengan `Geolocator.getCurrentPosition`. |
| FR-LBS-03 | Sistem menghitung jarak ke daftar toko buku/perpustakaan (data dummy di JSON/tabel Supabase) dengan `Geolocator.distanceBetween`. |
| FR-LBS-04 | Daftar diurutkan dari terdekat; lokasi < 500 m ditandai hijau. |
| FR-LBS-05 | Tombol "Buka di Maps" membuka aplikasi peta (`url_launcher`, URL `geo:` atau Google Maps). |
| FR-LBS-06 | Jika izin ditolak/GPS mati, sistem menampilkan pesan yang jelas. |

### FR-AI — Asisten AI (LLM)
| ID | Kebutuhan |
|---|---|
| FR-AI-01 | Halaman "Asisten AI" berbentuk chat; pengguna mengetik pertanyaan (mis. "komik aksi mirip One Piece"). |
| FR-AI-02 | Aplikasi mengirim pesan ke Supabase Edge Function; Edge Function memanggil LLM dan mengembalikan jawaban. |
| FR-AI-03 | Prompt sistem membatasi AI pada topik komik/manga dan menjawab dalam bahasa Indonesia. |
| FR-AI-04 | Konteks disertai genre favorit dan 5 komik terakhir dibaca agar rekomendasi personal. |
| FR-AI-05 | Tombol "Ringkas sinopsis" pada detail mengirim sinopsis ke LLM dan menampilkan ringkasan 3 poin. |
| FR-AI-06 | Rekomendasi AI yang berupa judul dapat diketuk untuk mencari judul tersebut di MangaDex. |
| FR-AI-07 | Saat menunggu, tampil indikator mengetik; jika gagal/timeout, tampil pesan error dan tombol ulangi. |
| FR-AI-08 | Edge Function membatasi 20 permintaan/hari/pengguna (rate limit sederhana). |
| FR-AI-09 | Riwayat chat disimpan di SQLite (opsional, 50 pesan terakhir). |

### FR-SET — Pengaturan
| ID | Kebutuhan |
|---|---|
| FR-SET-01 | Tema gelap/terang disimpan di SharedPreferences dan diterapkan saat aplikasi dibuka. |
| FR-SET-02 | Mode baca (vertikal/horizontal) dan kualitas gambar (hemat data/normal) tersimpan di SharedPreferences. |
| FR-SET-04 | Terdapat switch "Login biometrik" yang mengaktifkan/menonaktifkan fitur (aktivasi memerlukan verifikasi biometrik terlebih dahulu); status disimpan di SharedPreferences. |
| FR-SET-03 | Menu profil menampilkan nama, email, tombol Logout, dan halaman About (atribusi MangaDex). |

## 2.4 Kebutuhan Non-Fungsional

| ID | Kategori | Kebutuhan |
|---|---|---|
| NFR-01 | Performa | Daftar komik tampil ≤ 3 detik (koneksi 4G); antarmuka tidak freeze (semua I/O async). |
| NFR-02 | Keandalan | Semua request dibungkus try-catch; aplikasi tidak crash saat offline/timeout. |
| NFR-03 | Offline | Favorit, riwayat, dan pengaturan dapat diakses tanpa internet. |
| NFR-04 | Keamanan | Password dikelola Supabase Auth (tidak disimpan di aplikasi); API key LLM hanya di Edge Function; RLS aktif di semua tabel cloud; hanya anon key di klien. |
| NFR-04b | Keamanan biometrik | Data biometrik (sidik jari/wajah) dikelola sepenuhnya oleh sistem Android dan tidak pernah dibaca, disimpan, atau dikirim oleh aplikasi; aplikasi hanya menerima hasil sukses/gagal. Gunakan `local_auth` dan `stickyAuth: true`. |
| NFR-05 | Privasi | Lokasi hanya dibaca saat fitur dipakai, tidak disimpan/dikirim ke server. |
| NFR-06 | Kegunaan | UI konsisten (Material 3), navigasi maksimal 3 ketukan ke fitur utama, teks Bahasa Indonesia. |
| NFR-07 | Kompatibilitas | Android API 26+; layar 5"–7". |
| NFR-08 | Pemeliharaan | Struktur folder berlapis (models, services, screens, widgets); komentar pada fungsi penting; satu `ApiService` dengan static method. |
| NFR-09 | Hemat data | Gambar dicache (`cached_network_image`); mode data-saver tersedia. |
| NFR-10 | Kepatuhan | Menampilkan atribusi MangaDex; tidak memakai sumber komik ilegal. |

## 2.5 Kebutuhan Data

### 2.5.1 SQLite (lokal) — `komikku.db`

**Tabel `favorites`**
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK AUTOINCREMENT | |
| user_id | TEXT | UUID dari Supabase |
| manga_id | TEXT | ID MangaDex |
| title | TEXT | |
| cover_url | TEXT | |
| created_at | TEXT (ISO8601) | |
| updated_at | TEXT | untuk resolusi konflik |
| is_deleted | INTEGER (0/1) | soft delete agar bisa disinkron |
| is_synced | INTEGER (0/1) | |
| UNIQUE(user_id, manga_id) | | |

**Tabel `reading_history`**
| Kolom | Tipe | Keterangan |
|---|---|---|
| id | INTEGER PK | |
| user_id | TEXT | |
| manga_id | TEXT | |
| manga_title | TEXT | |
| cover_url | TEXT | |
| chapter_id | TEXT | |
| chapter_label | TEXT | mis. "Chapter 12" |
| last_page | INTEGER | |
| updated_at | TEXT | |
| is_synced | INTEGER | |
| UNIQUE(user_id, manga_id) | | satu baris per komik (progres terakhir) |

**Tabel `reminders`**
| Kolom | Tipe |
|---|---|
| id | INTEGER PK (juga dipakai sebagai id notifikasi) |
| manga_id, manga_title | TEXT |
| scheduled_at | TEXT |
| repeat_daily | INTEGER |

**Tabel `ai_messages`** (opsional)
| Kolom | Tipe |
|---|---|
| id | INTEGER PK |
| user_id | TEXT |
| role | TEXT ('user'/'assistant') |
| content | TEXT |
| created_at | TEXT |

### 2.5.2 SharedPreferences
| Key | Tipe | Fungsi |
|---|---|---|
| `isLoggedIn` | bool | cek sesi cepat saat start |
| `biometricEnabled` | bool | apakah Lock Screen biometrik aktif |
| `biometricPromptShown` | bool | agar dialog tawaran biometrik tidak muncul berulang |
| `lastBackgroundAt` | int (epoch ms) | menentukan perlu Lock Screen lagi atau tidak |
| `userId`, `displayName` | String | info pengguna |
| `themeMode` | String | light/dark |
| `readerMode` | String | vertical/horizontal |
| `dataSaver` | bool | kualitas gambar |
| `lastSyncAt` | String | waktu sinkron terakhir |
| `aiQuotaDate`, `aiQuotaCount` | String/int | penghitung kuota AI lokal |

### 2.5.3 Supabase (PostgreSQL)

**`profiles`** — `id uuid PK (= auth.users.id)`, `display_name text`, `created_at timestamptz`

**`favorites`** — `id uuid PK`, `user_id uuid FK`, `manga_id text`, `title text`, `cover_url text`, `updated_at timestamptz`, `is_deleted bool`, `UNIQUE(user_id, manga_id)`

**`reading_history`** — `id uuid PK`, `user_id uuid FK`, `manga_id text`, `manga_title text`, `cover_url text`, `chapter_id text`, `chapter_label text`, `last_page int`, `updated_at timestamptz`, `UNIQUE(user_id, manga_id)`

**`reviews`** — `id uuid PK`, `user_id uuid FK`, `manga_id text`, `rating int CHECK (1..5)`, `comment text`, `created_at`, `updated_at`, `UNIQUE(user_id, manga_id)`

**`bookstores`** — `id uuid PK`, `name text`, `lat double`, `lng double`, `address text` (data toko buku/perpustakaan sekitar kampus)

**`ai_usage`** — `user_id uuid`, `date date`, `count int`, `PRIMARY KEY(user_id, date)` (rate limit Edge Function)

**Kebijakan RLS:**
- `favorites`, `reading_history`, `ai_usage`, `profiles`: pengguna hanya bisa SELECT/INSERT/UPDATE/DELETE baris dengan `user_id = auth.uid()`.
- `reviews`: SELECT untuk semua pengguna terautentikasi; INSERT/UPDATE/DELETE hanya milik sendiri.
- `bookstores`: SELECT untuk semua, tanpa tulis dari klien.

## 2.6 Antarmuka Eksternal

### 2.6.1 MangaDex API (HTTP GET, tanpa API key)
| Fungsi | Endpoint |
|---|---|
| Daftar/cari komik | `GET https://api.mangadex.org/manga?limit=20&offset=0&title={q}&includes[]=cover_art&includes[]=author&includedTags[]={tagId}&order[followedCount]=desc` |
| Detail komik | `GET /manga/{id}?includes[]=cover_art&includes[]=author` |
| Daftar chapter | `GET /manga/{id}/feed?translatedLanguage[]=id&translatedLanguage[]=en&order[chapter]=asc&limit=100` |
| Halaman chapter | `GET /at-home/server/{chapterId}` → `baseUrl`, `chapter.hash`, `chapter.dataSaver[]` |
| URL cover | `https://uploads.mangadex.org/covers/{mangaId}/{fileName}.256.jpg` |
| Daftar genre | `GET /manga/tag` |

Catatan: batasi request (± 5/detik), kirim header `User-Agent` yang jelas, dan gunakan `data-saver` untuk hemat kuota. Struktur respons berupa `data` (List/Map) dan `relationships`; parsing dilakukan dengan factory `Manga.fromJson()`.

### 2.6.2 Supabase
- SDK: `supabase_flutter` (Auth, Postgres, Functions).
- Inisialisasi di `main.dart` dengan `Supabase.initialize(url, anonKey)`.

### 2.6.3 LLM melalui Edge Function
- Endpoint: `POST {SUPABASE_URL}/functions/v1/ai-assistant` dengan header Authorization (JWT pengguna).
- Request: `{ "mode": "chat" | "summarize", "message": "...", "context": { "favorite_genres": [...], "recent": [...] } }`
- Response: `{ "reply": "..." }`
- Di dalam Edge Function: verifikasi JWT → cek/perbarui `ai_usage` → susun prompt sistem → panggil LLM → kembalikan jawaban.
- **Rekomendasi provider LLM:** Google Gemini API (`gemini-2.5-flash`, ada free tier) atau Groq (cepat, free tier). Cek batas kuota terbaru sebelum dipakai karena bisa berubah.

**Contoh prompt sistem:**
> Kamu adalah asisten KomikKu, ahli komik/manga/manhwa. Jawab dalam Bahasa Indonesia, singkat dan ramah. Hanya bahas topik komik. Beri maksimal 5 rekomendasi dalam format daftar: "Judul — alasan singkat". Jangan mengarang judul; jika tidak yakin, katakan tidak yakin.

**Contoh kerangka Edge Function (Deno/TypeScript):**
```ts
import { serve } from "https://deno.land/std/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: req.headers.get("Authorization")! } } }
  );
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) return new Response("Unauthorized", { status: 401 });

  const { mode, message, context } = await req.json();
  // TODO: cek & update tabel ai_usage (maks 20/hari)

  const system = "Kamu adalah asisten KomikKu ...";
  const res = await fetch(
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${Deno.env.get("GEMINI_API_KEY")}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: system }] },
        contents: [{ role: "user", parts: [{ text: message }] }],
      }),
    }
  );
  const json = await res.json();
  const reply = json.candidates?.[0]?.content?.parts?.[0]?.text ?? "Maaf, tidak ada jawaban.";
  return new Response(JSON.stringify({ reply }), {
    headers: { "Content-Type": "application/json" },
  });
});
```
(Kerangka ini perlu disesuaikan dengan dokumentasi provider terbaru; API key disimpan lewat `supabase secrets set GEMINI_API_KEY=...`.)

### 2.6.4 Perangkat Keras/Sistem
GPS (izin `ACCESS_FINE_LOCATION`), notifikasi (`POST_NOTIFICATIONS`, `SCHEDULE_EXACT_ALARM`), internet (`INTERNET`).

## 2.7 Daftar Package Flutter

| Package | Fungsi |
|---|---|
| `http` | Request ke MangaDex (modul 5) |
| `supabase_flutter` | Auth, DB cloud, Edge Function |
| `sqflite`, `path` | Database lokal SQLite |
| `shared_preferences` | Sesi, tema, pengaturan |
| `flutter_local_notifications`, `timezone` | Immediate & scheduled notification |
| `geolocator` | Lokasi & jarak |
| `url_launcher` | Buka Google Maps |
| `cached_network_image` | Cache gambar cover/halaman |
| `connectivity_plus` | Cek koneksi untuk sinkronisasi |
| `intl` | Format tanggal |
| `local_auth` | Autentikasi biometrik (sidik jari/wajah) & fallback PIN perangkat |

### Konfigurasi Android untuk Biometrik
1. `AndroidManifest.xml`: tambahkan `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.
2. `MainActivity.kt`: ubah superclass menjadi `FlutterFragmentActivity` (bukan `FlutterActivity`), karena `local_auth` memerlukannya.
3. `styles.xml` (LaunchTheme & NormalTheme): parent theme harus `Theme.AppCompat` / `Theme.MaterialComponents` turunan agar dialog biometrik tampil.
4. Emulator: Settings → Security → daftarkan PIN lalu fingerprint; saat prompt muncul, gunakan Extended controls → Fingerprint → "Touch sensor".

### Kerangka `BiometricService`
```dart
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    final supported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    return supported && canCheck;
  }

  Future<bool> authenticate({String reason = 'Verifikasi untuk membuka KomikKu'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // fallback PIN/pola perangkat
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
```
(Sesuaikan dengan versi `local_auth` yang dipakai; pada versi baru parameter `options` bisa berubah, cek dokumentasi.)

## 2.8 Struktur Folder Proyek

```
lib/
├─ main.dart
├─ models/        manga.dart · chapter.dart · review.dart · bookstore.dart · chat_message.dart
├─ services/      api_service.dart · supabase_service.dart · database_helper.dart
│                 prefs_service.dart · notification_service.dart · location_service.dart
│                 ai_service.dart · sync_service.dart · biometric_service.dart
├─ screens/       login_screen.dart · register_screen.dart · lock_screen.dart · root.dart
│                 home_screen.dart · search_screen.dart · detail_screen.dart
│                 reader_screen.dart · library_screen.dart (favorit + riwayat)
│                 reminder_screen.dart · nearby_screen.dart · ai_screen.dart
│                 profile_screen.dart
└─ widgets/       manga_card.dart · chapter_tile.dart · rating_bar.dart · chat_bubble.dart
```

## 2.9 Alur Navigasi

```
Splash/cek sesi ─┬─ sesi valid & biometrik aktif ──► Lock Screen ─(sukses)─► Root
                 │                                      └─(gagal/pilih password)─► Login
                 ├─ sesi valid & biometrik nonaktif ──► Root
                 └─ tidak ada sesi ──► Login ──(pushReplacement)──► Root (BottomNavigationBar)
                                         └─► Register                ├─ Beranda ─► Detail ─► Reader
                                                  ├─ Cari    ─► Detail
                                                  ├─ Perpustakaan (Favorit | Riwayat) ─► Detail/Reader
                                                  ├─ Asisten AI ─► (ketuk judul) Detail
                                                  └─ Profil ─► Reminder · Terdekat · Pengaturan · Logout
                                                                     (Logout: pushAndRemoveUntil ke Login)
```

## 2.10 Use Case Utama (ringkas)

**UC-06 Login biometrik**
- Aktor: Pengguna
- Prasyarat: Pernah login password, biometrik sudah diaktifkan di KomikKu, sesi Supabase valid
- Alur: Buka aplikasi → cek `biometricEnabled` + sesi → Lock Screen → prompt biometrik otomatis → sukses → `pushReplacement` ke Root.
- Alternatif: Gagal/batal → tombol "Coba lagi" atau "Login dengan password"; sesi tidak valid → langsung ke Login password; perangkat tidak mendukung → alur biasa.

**UC-01 Membaca komik**
- Aktor: Pengguna
- Prasyarat: Sudah login, online
- Alur: Beranda → pilih komik → Detail → pilih chapter → Reader memuat halaman → riwayat otomatis tersimpan di SQLite → (online) sinkron ke Supabase.
- Alternatif: Request gagal → pesan error + tombol coba lagi.

**UC-02 Menambah favorit**
- Alur: Detail → tekan ikon hati → INSERT/UPDATE ke SQLite (`is_synced=0`) → SyncService mengunggah ke Supabase saat online → `is_synced=1`.

**UC-03 Mengatur reminder**
- Alur: Profil → Reminder → pilih komik favorit → pilih tanggal & jam → `zonedSchedule` → simpan ke tabel `reminders` → notifikasi muncul saat waktunya.

**UC-04 Bertanya ke AI**
- Alur: Tab Asisten AI → ketik pertanyaan → `AiService` kirim ke Edge Function (disertai genre favorit) → tampil jawaban → ketuk judul rekomendasi → pencarian MangaDex.

**UC-05 Cari toko buku terdekat**
- Alur: Profil → Terdekat → izin lokasi → ambil posisi → hitung jarak ke tabel `bookstores` → tampil list terurut → "Buka di Maps".

## 2.11 Rencana Pengujian

| ID | Skenario | Hasil yang diharapkan |
|---|---|---|
| TC-01 | Login dengan kredensial benar | Masuk ke Beranda; tombol back tidak kembali ke login |
| TC-02 | Login salah | SnackBar error, border merah |
| TC-03 | Buka ulang aplikasi setelah login | Langsung ke Beranda |
| TC-04 | Muat Beranda online | Grid komik tampil, ada loading |
| TC-05 | Matikan internet lalu buka Beranda | Pesan error + tombol coba lagi, tidak crash |
| TC-06 | Tambah favorit lalu mode pesawat | Favorit tetap tampil |
| TC-07 | Baca chapter lalu tutup, buka lagi | Tombol "Lanjut baca" tepat di halaman terakhir |
| TC-08 | Login di emulator lain | Favorit/riwayat terunduh dari Supabase |
| TC-09 | Set reminder 2 menit ke depan, tutup app | Notifikasi muncul memuat judul komik |
| TC-10 | Tolak izin lokasi | Pesan jelas, aplikasi tidak crash |
| TC-11 | Tanya AI "rekomendasi komik komedi" | Jawaban Bahasa Indonesia berisi daftar rekomendasi |
| TC-12 | Kirim 21 pesan AI dalam sehari | Pesan "kuota harian habis" |
| TC-13 | Ubah tema ke gelap, restart | Tema tetap gelap |
| TC-14 | Login pertama di perangkat yang punya biometrik | Muncul dialog tawaran aktifkan biometrik |
| TC-15 | Aktifkan biometrik, tutup lalu buka aplikasi | Lock Screen + prompt biometrik; sukses → Beranda |
| TC-16 | Batalkan/gagal biometrik | Lock Screen tetap, tombol "Coba lagi" dan "Login dengan password" tersedia |
| TC-17 | Matikan switch biometrik di Pengaturan, buka ulang | Langsung ke Beranda tanpa Lock Screen |
| TC-18 | Logout lalu login lagi | `biometricEnabled` ter-reset; dialog tawaran muncul lagi |
| TC-19 | Perangkat tanpa biometrik terdaftar | Opsi biometrik tidak muncul; login password normal |
| TC-20 | Aplikasi di background > 60 detik lalu dibuka | Lock Screen muncul kembali |

---

# BAGIAN 3 — Penjelasan Teknis Per Fitur

| Fitur | Teknologi | Cara kerja singkat |
|---|---|---|
| **Login/Register** | Supabase Auth, SharedPreferences, `TextEditingController`, `pushReplacement` | Form validasi → `supabase.auth.signInWithPassword` → simpan `isLoggedIn` → navigasi. |
| **Beranda & Pencarian** | `http`, model `Manga.fromJson`, GridView.builder, `async/await`, `initState`, `isLoading` | `ApiService.getManga()` memanggil MangaDex, di-parse ke `List<Manga>`, ditampilkan sebagai grid. Pencarian dengan debounce `Timer`. |
| **Detail & Chapter** | Passing ID via constructor, `ApiService.getMangaDetail/getChapters`, FutureBuilder atau setState | Mengambil detail dan feed chapter berdasarkan ID. |
| **Reader** | `at-home/server` API, `Image.network`/`cached_network_image`, `PageView` atau `ListView` | URL halaman = `baseUrl/data-saver/{hash}/{file}`. Posisi halaman disimpan ke SQLite. |
| **Favorit & Riwayat** | **SQLite (sqflite)** | CRUD lewat `DatabaseHelper` (singleton). Alasan memilih SQLite: relasional, query filter per `user_id`, cocok untuk daftar yang bertambah banyak. |
| **Sesi & Pengaturan** | **SharedPreferences** | Data ringan key-value: login flag, tema, mode baca. |
| **Login Biometrik** | `local_auth`, `BiometricService`, `LockScreen`, `WidgetsBindingObserver`, SharedPreferences | Biometrik tidak menggantikan Supabase Auth, melainkan "gerbang" di atas sesi Supabase yang tersimpan. Hasil verifikasi hanya benar/salah dari sistem Android. Jika sesi habis, pengguna wajib login password. |
| **Sinkronisasi** | **Supabase Postgres + RLS**, `connectivity_plus` | Upsert item `is_synced=0` ke Supabase; saat login baru, tarik data dan gabungkan dengan aturan `updated_at`. |
| **Rating & Ulasan** | Supabase Postgres | Tabel `reviews` dengan constraint unik per pengguna/komik; rata-rata dihitung via query/aggregate. |
| **Reminder** | `flutter_local_notifications`, `timezone`, Singleton `NotificationService` | Memakai `zonedSchedule` seperti modul 7; id notifikasi = id baris `reminders` agar bisa dibatalkan. |
| **Toko buku terdekat** | `geolocator`, `url_launcher`, tabel `bookstores` | Cek GPS → izin → posisi → `distanceBetween` → urut → tampil, hijau jika < 500 m. |
| **Asisten AI** | Supabase Edge Function + Gemini/Groq, `ai_service.dart`, ChatBubble | Klien tak pernah memegang API key. Edge Function memverifikasi JWT, membatasi kuota, memanggil LLM. |
| **Navigasi** | `Navigator.push/pop/pushReplacement/pushAndRemoveUntil`, `BottomNavigationBar` di `Root` | Sama seperti modul 4. |

## Checklist Kesiapan Demo
- [ ] Project Supabase dibuat; tabel + RLS aktif; `bookstores` terisi 5–10 lokasi sekitar kampus
- [ ] Edge Function ter-deploy; secret LLM terpasang
- [ ] Izin Android: INTERNET, lokasi, notifikasi, exact alarm, **USE_BIOMETRIC**
- [ ] `MainActivity` memakai `FlutterFragmentActivity`; fingerprint/PIN sudah terdaftar di perangkat/emulator demo
- [ ] Desugaring diaktifkan di `build.gradle.kts` (sesuai modul 7)
- [ ] Uji di HP fisik (notifikasi terjadwal & GPS)
- [ ] Halaman About memuat atribusi MangaDex
- [ ] Siapkan akun demo dan skenario demo berurutan: login password → aktifkan biometrik → restart app (Lock Screen) → jelajah → baca → favorit → sinkron → reminder → toko terdekat → tanya AI

## Saran Urutan Pengerjaan
1. Bangun fondasi dulu: login, navigasi, `ApiService`, Beranda → Detail → Reader (ini inti penilaian modul 2–5).
2. Lanjut SQLite + SharedPreferences (modul 6).
3. Tambah notifikasi + LBS (modul 7).
4. Terakhir Supabase sync, ulasan, dan AI (nilai plus). Jika waktu mepet, AI cukup mode "ringkas sinopsis" + chat sederhana.
