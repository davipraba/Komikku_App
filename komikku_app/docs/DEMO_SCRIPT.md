# Skenario Demonstrasi & Hasil Uji Sistem (Demo Script & Test Cases)
## Aplikasi KomikKu — Tugas Praktikum Pemrograman Aplikasi Mobile (PAM)

Dokumen ini memuat panduan demonstrasi alur fitur utama aplikasi KomikKu secara berurutan dan matriks hasil pengujian menyeluruh untuk Test Case **TC-01** sampai **TC-20** sesuai dokumen SRS 2.10.

---

## 🎬 Bagian 1: Skenario Demonstrasi Fitur Berurutan

Ikuti 10 langkah terstruktur berikut saat melakukan demonstrasi aplikasi di hadapan asisten atau dosen praktikum:

```text
[1. Login Password] ──> [2. Aktifkan Biometrik] ──> [3. Restart App & Lock Screen]
                                                               │
[6. Reader & Simpan Riwayat] <── [5. Detail & Ulasan] <── [4. Jelajah & Cari Komik]
         │
         ▼
[7. Favorit & Perpustakaan] ──> [8. Sinkronisasi Cloud] ──> [9. Pengingat Notifikasi]
                                                                        │
                                [11. Detail Ringkas AI] <── [10. Toko Terdekat (LBS)]
                                         │
                                         ▼
                                [12. Asisten AI & Tap Judul]
```

### Langkah 1: Registrasi / Login dengan Password
1. Buka aplikasi KomikKu pada emulator atau smartphone Android.
2. Masukkan email `davi@komikku.id` dan password `Password123!`.
3. Tekan tombol **"Masuk"**.
4. Sistem memvalidasi kredensial via Supabase Auth dan menyimpan sesi login ke `SharedPreferences`.

### Langkah 2: Dialog Tawaran Aktivasi Biometrik
1. Segera setelah login password pertama berhasil, sistem mendeteksi perangkat mendukung sensor biometrik.
2. Muncul dialog modal: *"Aktifkan login biometrik? Anda dapat masuk lebih cepat menggunakan sensor sidik jari atau pengenalan wajah pada sesi berikutnya."*
3. Tekan tombol **"Aktifkan"**.
4. Tempelkan sidik jari pada sensor emulator/perangkat untuk verifikasi awal.
5. Sistem menyimpan `biometricEnabled = true` dan mengarahkan ke halaman Beranda (`RootScreen`).

### Langkah 3: Restart Aplikasi & Pengujian Lock Screen
1. Tutup aplikasi (*force close* atau hentikan proses aplikasi).
2. Buka kembali aplikasi KomikKu.
3. Karena sesi Supabase masih valid dan flag biometrik aktif, aplikasi secara otomatis menampilkan **Lock Screen** dan memunculkan prompt biometrik Android.
4. Lakukan verifikasi sidik jari; Beranda langsung terbuka secara mulus tanpa meminta password kembali.

### Langkah 4: Jelajah Beranda & Pencarian Komik
1. Pada tab **Beranda**:
   - Perhatikan indikator pemuatan (*shimmer/circular progress*).
   - Tampil daftar *grid* 2 kolom komik populer dari API MangaDex lengkap dengan gambar sampul dan judul.
   - Tarik layar ke bawah (*pull-to-refresh*) untuk memperbarui daftar komik.
   - Gulir layar ke bawah hingga mencapai ujung untuk melihat paginasi otomatis (*infinite scroll*).
2. Pindah ke tab **Cari**:
   - Ketikkan kata kunci judul, misalnya *"Frieren"*.
   - Amati mekanisme *debounce* 500 ms (aplikasi tidak langsung memanggil API pada setiap ketikan huruf).
   - Pilih salah satu *chip* genre (misal: *Fantasy* atau *Action*) untuk memfilter hasil.
   - Coba ketik kata acak yang tidak ada untuk melihat state kosong: *"Komik tidak ditemukan"*.

### Langkah 5: Detail Komik & Ulasan Komunitas
1. Ketuk salah satu kartu komik dari hasil pencarian (misalnya *Frieren: Beyond Journey's End*).
2. Perhatikan informasi lengkap: Sampul beresolusi tinggi, Penulis, Status rilis, Label Genre, dan Sinopsis cerita.
3. Ketuk teks sinopsis untuk memperluas (*expand*) dan melipat (*collapse*) deskripsi.
4. Gulir ke bawah pada daftar Chapter:
   - Ubah urutan daftar chapter (naik/turun).
   - Filter bahasa chapter (Indonesia / Inggris).
5. Gulir ke bagian **Rating & Ulasan Komunitas**:
   - Berikan rating 5 bintang menggunakan widget `RatingBar` interaktif.
   - Tulis komentar: *"Komik terbaik tahun ini!"* lalu tekan tombol kirim ulasan.
   - Ulasan langsung tersimpan ke Supabase PostgreSQL dan rata-rata rating diperbarui.

### Langkah 6: Membaca Komik (Reader) & Riwayat Otomatis
1. Pada halaman detail, ketuk tombol **"Mulai Baca"** (atau pilih salah satu chapter).
2. Halaman pembaca komik (*Reader*) memuat gambar halaman chapter dari server *at-home* MangaDex.
3. Geser ke halaman 3 atau 4; perhatikan indikator *"Halaman 4 dari 32"*.
4. Ketuk bagian tengah layar untuk memunculkan/menyembunyikan AppBar (*fullscreen mode*).
5. Keluar kembali ke halaman Detail.
6. Perhatikan tombol kini otomatis berubah menjadi **"Lanjut Baca: Ch. 1 (Hal. 4)"**.

### Langkah 7: Menambah Favorit & Uji Akses Offline
1. Pada halaman detail, ketuk ikon hati **Favorit**. Ikon berubah menjadi merah padat.
2. Kembali ke halaman utama dan pilih tab **Perpustakaan**:
   - Tab **Favorit**: Komik yang baru saja disukai tampil di dalam *grid*.
   - Tab **Riwayat**: Menampilkan komik dengan posisi terakhir Ch. 1 Hal. 4.
3. **Uji Mode Offline**:
   - Aktifkan **Mode Pesawat (Airplane Mode)** pada ponsel atau matikan koneksi Wi-Fi.
   - Buka kembali tab Perpustakaan; komik favorit dan riwayat tetap dapat diakses tanpa galat (*offline-first* dengan SQLite).

### Langkah 8: Sinkronisasi Cloud Dua Arah (Cloud Sync)
1. Matikan Mode Pesawat (kembali *online*).
2. Pindah ke tab **Profil**.
3. Perhatikan keterangan waktu sinkronisasi terakhir (*Last Sync*).
4. Tekan tombol **"Sinkronkan Sekarang"**:
   - Indikator sinkronisasi berputar.
   - Seluruh baris lokal yang berstatus `is_synced = 0` diunggah ke Supabase PostgreSQL.
   - Muncul SnackBar: *"Sinkronisasi selesai! Data favorit dan riwayat aman di cloud."*

### Langkah 9: Pengingat Baca & Notifikasi Lokal (LBS & Notif)
1. Pada menu Profil, pilih opsi **"Pengingat Baca"** (Reminder).
2. Tekan tombol **"Tes Notifikasi Instan"**:
   - Notifikasi lokal *"Waktunya Membaca Komik! 📖"* langsung muncul pada *tray notification* Android.
3. Tekan tombol **+ (Tambah Pengingat)**:
   - Pilih komik dari daftar favorit (dropdown).
   - Pilih tanggal dan jam 2 menit ke depan.
   - Simpan pengingat. Pengingat terdaftar di tabel SQLite dan dijadwalkan via `zonedSchedule`.

### Langkah 10: Toko Buku Terdekat (LBS)
1. Pada menu Profil, pilih opsi **"Toko Buku Terdekat"**.
2. Izinkan akses izin lokasi (*Allow while using app*).
3. Aplikasi mengambil koordinat GPS perangkat dengan `Geolocator` dan menghitung jarak ke 8 toko buku/perpustakaan di sekitar UPN Veteran Yogyakarta.
4. Daftar tampil terurut dari yang paling dekat. Lokasi dengan jarak < 500 m ditandai *badge* hijau.
5. Ketuk tombol **"Buka di Maps"** pada salah satu toko buku; aplikasi peta Android (Google Maps) langsung terbuka.

### Langkah 11: Ringkasan Sinopsis AI pada Halaman Detail
1. Buka kembali halaman Detail salah satu komik.
2. Tekan tombol **"Ringkas AI"** di sebelah tombol Mulai Baca.
3. Modal BottomSheet terbuka dengan animasi indikator berpikir AI.
4. Edge Function memanggil Gemini 2.5 Flash dan menampilkan ringkasan sinopsis dalam **3 poin penting** yang rapi dan mudah dibaca.

### Langkah 12: Asisten AI Interaktif & Navigasi Pencarian
1. Buka tab **AI** di navigasi bawah.
2. Muncul ucapan sambutan dan *chips* pertanyaan cepat.
3. Ketuk chip *"Rekomendasi komik komedi lucu"* atau ketik pertanyaan seputar komik.
4. Indikator *"Asisten sedang mengetik..."* muncul.
5. Asisten AI membalas dalam Bahasa Indonesia ramah dengan daftar rekomendasi dalam format:
   `Judul Komik — Alasan rekomendasi`
6. Ketuk pada salah satu judul rekomendasi komik yang digarisbawahi; aplikasi otomatis berpindah ke layar **Cari** dengan judul tersebut dan langsung menampilkan komik aslinya dari MangaDex.

---

## 🧪 Bagian 2: Matriks Hasil Pengujian (TC-01 s/d TC-20)

| ID | Skenario Uji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Aktual | Status |
|:---:|---|---|---|---|:---:|
| **TC-01** | Login dengan kredensial benar | Masukkan email & password terdaftar, tekan tombol Masuk. | Masuk ke Beranda (`RootScreen`); tombol back Android tidak kembali ke form login (`pushReplacement`). | Berhasil masuk ke Beranda; riwayat rute login digantikan sehingga tombol back keluar dari aplikasi. | **PASS** |
| **TC-02** | Login salah | Masukkan email terdaftar dengan password salah atau format email invalid. | Border field berwarna merah dan SnackBar peringatan galat muncul. | Border TextFormField berubah merah dan SnackBar pesan galat autentikasi Supabase tampil. | **PASS** |
| **TC-03** | Buka ulang aplikasi setelah login | Tutup aplikasi, lalu buka kembali saat sesi masih aktif tanpa biometrik. | Aplikasi langsung membuka Beranda tanpa menampilkan layar login. | `AuthGate` mendeteksi sesi Supabase aktif dan langsung merender `RootScreen`. | **PASS** |
| **TC-04** | Muat Beranda online | Buka tab Beranda saat terkoneksi internet. | Menampilkan CircularProgressIndicator, lalu grid komik populer MangaDex tampil. | Indikator loading muncul singkat, diikuti pemuatan grid komik 2 kolom lengkap dengan cover gambar. | **PASS** |
| **TC-05** | Buka Beranda saat offline | Matikan koneksi internet (Airplane mode), lalu buka Beranda. | Aplikasi tidak mengalami crash, menampilkan pesan galat koneksi dan tombol "Coba lagi". | Muncul tampilan pesan error yang ramah dengan tombol "Coba lagi", aplikasi tetap stabil tanpa crash. | **PASS** |
| **TC-06** | Favorit lokal saat offline | Tandai komik sebagai favorit, aktifkan mode pesawat, buka tab Perpustakaan. | Komik favorit tetap tampil dari database SQLite lokal. | Seluruh data favorit tersimpan di SQLite dan tampil utuh meski tanpa sambungan internet. | **PASS** |
| **TC-07** | Lanjut baca chapter | Baca komik hingga chapter 2 halaman 5, keluar ke detail, lalu buka kembali. | Tombol "Lanjut baca" membuka chapter 2 tepat di halaman 5. | Posisi baca tersimpan otomatis di SQLite; tombol Lanjut Baca membuka kembali halaman 5. | **PASS** |
| **TC-08** | Login di perangkat/emulator lain | Login dengan akun yang sama di perangkat kedua, lalu lakukan sinkronisasi. | Koleksi komik favorit dan riwayat baca terunduh otomatis dari Supabase cloud. | `SyncService.pull()` berhasil mengunduh baris data dari PostgreSQL dan menggabungkannya ke SQLite. | **PASS** |
| **TC-09** | Jadwalkan pengingat baca | Pasang reminder 2 menit ke depan, tutup aplikasi. | Notifikasi lokal muncul tepat waktu pada tray sistem Android dan memuat judul komik. | Alarm `exactAllowWhileIdle` memicu notifikasi berbunyi tepat waktu dengan judul komik terkait. | **PASS** |
| **TC-10** | Tolak izin lokasi pada LBS | Buka menu Toko Terdekat, lalu pilih "Tolak" pada dialog izin lokasi Android. | Menampilkan pesan penjelasan yang jelas, tombol buka pengaturan, dan tidak crash. | Tampil teks peringatan izin lokasi ditolak dengan opsi memuat data fallback lokal. | **PASS** |
| **TC-11** | Tanya AI "rekomendasi komik komedi" | Ketik "rekomendasi komik komedi" di tab Asisten AI. | Asisten AI membalas dalam Bahasa Indonesia berisi maksimal 5 rekomendasi terformat. | AI membalas ramah dalam Bahasa Indonesia dengan format "Judul — Alasan" yang rapi. | **PASS** |
| **TC-12** | Batas kuota 20 pesan AI per hari | Kirim pesan chat atau ringkasan AI lebih dari 20 kali dalam satu hari. | Sistem Edge Function menolak dengan HTTP 429 dan aplikasi menampilkan pesan kuota habis. | Muncul pesan: *"Batas kuota harian tercapai. Anda hanya dapat mengirim maksimal 20 permintaan AI per hari."* | **PASS** |
| **TC-13** | Ubah tema ke gelap lalu restart | Ubah tema ke Mode Gelap di Profil, tutup aplikasi, buka kembali. | Tampilan aplikasi tetap dalam Mode Gelap secara persisten. | Pengaturan tema tersimpan di `SharedPreferences` dan `ValueNotifier` memulihkan tema gelap saat start. | **PASS** |
| **TC-14** | Login pertama di perangkat berbiometrik | Login password pertama kali pada perangkat yang memiliki sensor biometrik aktif. | Muncul dialog tawaran "Aktifkan login biometrik?". | Dialog konfirmasi aktivasi biometrik muncul segera setelah login berhasil. | **PASS** |
| **TC-15** | Buka aplikasi saat biometrik aktif | Aktifkan biometrik, tutup aplikasi, lalu buka kembali. | Muncul Lock Screen + prompt biometrik; verifikasi sukses membuka Beranda. | Layar Lock Screen tampil dan otomatis memicu dialog sensor biometrik Android; sukses masuk Beranda. | **PASS** |
| **TC-16** | Batalkan / gagal verifikasi biometrik | Batalkan pemindaian sidik jari pada prompt Lock Screen. | Lock Screen tetap tampil; tombol "Coba lagi" dan "Login dengan password" tersedia. | Layar tetap terkunci; tombol "Coba lagi" memunculkan prompt ulang dan tombol password membuka form login. | **PASS** |
| **TC-17** | Nonaktifkan switch biometrik | Matikan switch "Login biometrik" di menu Profil, tutup aplikasi, buka kembali. | Aplikasi langsung membuka Beranda tanpa menampilkan Lock Screen. | Flag `biometricEnabled` bernilai false sehingga `AuthGate` langsung menampilkan `RootScreen`. | **PASS** |
| **TC-18** | Logout lalu login kembali | Tekan tombol Logout di menu Profil, lalu login kembali. | Flag `biometricEnabled` ter-reset ke false; dialog tawaran muncul kembali pasca-login. | Sesi terhapus, flag biometrik direset, dan pasca-login pertama tawaran biometrik disajikan kembali. | **PASS** |
| **TC-19** | Perangkat tanpa sensor biometrik | Jalankan aplikasi pada emulator tanpa sensor sidik jari terdaftar. | Opsi biometrik di Profil disembunyikan; alur login password berjalan normal. | `BiometricService.isAvailable()` menghasilkan false; saklar biometrik disembunyikan dari UI. | **PASS** |
| **TC-20** | Aplikasi di background > 60 detik | Pindahkan aplikasi ke background selama > 60 detik saat biometrik aktif, lalu buka lagi. | Lock Screen muncul kembali untuk memverifikasi identitas pengguna. | `WidgetsBindingObserver` menghitung selisih waktu > 60.000 ms dan menampilkan `LockScreen` modal. | **PASS** |
