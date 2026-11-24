import 'package:flutter/material.dart';

/// Halaman Tentang KomikKu dengan Atribusi Resmi MangaDex (SRS 2.6.1 & NFR-10)
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang KomikKu'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // Logo & Nama Aplikasi
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'KomikKu',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Versi 1.0.0 (Tugas Praktikum Mobile)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Deskripsi Aplikasi
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang Aplikasi',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'KomikKu adalah aplikasi pembaca komik modern yang dibangun menggunakan Flutter dan Material 3 '
                    'untuk memenuhi tugas mata kuliah Praktikum Teknologi dan Pemrograman Mobile.\n'
                    'Aplikasi ini dirancang untuk membaca komik, menyimpan favorit dan riwayat secara offline, '
                    'sinkronisasi cloud, pengingat rilis, pencarian toko buku terdekat, dan integrasi asisten AI.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // PENGHARGAAN & ATRIBUSI MANGADEX (WAJIB SESUAI SRS)
          Card(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Atribusi & Sumber Konten',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Data komik, sinopsis, metadata pengarang, serta berkas gambar cover dan halaman '
                    'sepenuhnya bersumber secara legal melalui API publik MangaDex (https://api.mangadex.org).\n\n'
                    'Aplikasi ini tidak meng-host file komik dan tidak melakukan scraping ilegal. '
                    'Hak cipta seluruh manga, karya seni, dan terjemahan sepenuhnya adalah milik pengarang, '
                    'penerbit, dan kelompok scanlation asli.',
                    style: TextStyle(height: 1.4, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Info Tim Pengembang
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tim Pengembang',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('• Davi & Syahrul'),
                  Text('• Praktikum Teknologi dan Pemrograman Mobile'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
