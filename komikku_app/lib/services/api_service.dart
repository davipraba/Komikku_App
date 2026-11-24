import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/chapter.dart';
import '../models/genre_tag.dart';
import '../models/manga.dart';

/// Service untuk mengambil konten komik dari MangaDex API publik (SRS 2.6.1).
/// Memakai static methods sesuai materi modul 5.
class ApiService {
  static const String _baseUrl = 'https://api.mangadex.org';

  /// Header wajib termasuk User-Agent agar request tidak ditolak/rate-limited
  static const Map<String, String> _headers = {
    'User-Agent': 'KomikKu-App/1.0.0 (praktikum_mobile_student; contact: student@example.com)',
    'Accept': 'application/json',
  };

  /// Durasi batas waktu request
  static const Duration _timeout = Duration(seconds: 15);

  /// Mengambil daftar komik (populer atau berdasarkan pencarian & tag)
  static Future<List<Manga>> getMangaList({
    int offset = 0,
    int limit = 20,
    String? title,
    List<String>? tagIds,
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        'includes[]': ['cover_art', 'author'],
        'order[followedCount]': 'desc',
        'contentRating[]': ['safe', 'suggestive'],
      };

      if (title != null && title.trim().isNotEmpty) {
        queryParameters['title'] = title.trim();
      }

      if (tagIds != null && tagIds.isNotEmpty) {
        queryParameters['includedTags[]'] = tagIds;
      }

      final uri = Uri.parse('$_baseUrl/manga').replace(
        queryParameters: queryParameters,
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> mangaJsonList = data['data'] as List<dynamic>? ?? [];

        return mangaJsonList
            .map((item) => Manga.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 429) {
        throw Exception('Terlalu banyak permintaan ke MangaDex (Rate limit). Tunggu sebentar lalu coba lagi.');
      } else {
        throw Exception('Gagal memuat daftar komik (Kode: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis. Jaringan lambat, silakan coba lagi.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan tidak terduga: $e');
    }
  }

  /// Mengambil detail lengkap sebuah komik berdasarkan ID
  static Future<Manga> getMangaDetail(String mangaId) async {
    try {
      final uri = Uri.parse('$_baseUrl/manga/$mangaId').replace(
        queryParameters: {
          'includes[]': ['cover_art', 'author'],
        },
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final mangaJson = data['data'] as Map<String, dynamic>?;

        if (mangaJson == null) {
          throw Exception('Data komik tidak ditemukan.');
        }

        return Manga.fromJson(mangaJson);
      } else if (response.statusCode == 404) {
        throw Exception('Komik tidak ditemukan di MangaDex.');
      } else {
        throw Exception('Gagal memuat detail komik (Kode: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } on TimeoutException {
      throw Exception('Waktu permintaan habis.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan: $e');
    }
  }

  /// Mengambil daftar chapter untuk komik tertentu
  static Future<List<Chapter>> getChapters(
    String mangaId, {
    String order = 'asc',
    String? language,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': '100',
        'order[chapter]': order,
        'contentRating[]': ['safe', 'suggestive'],
      };

      if (language != null && language.isNotEmpty) {
        queryParams['translatedLanguage[]'] = [language];
      } else {
        // Ambil Bahasa Indonesia dan Bahasa Inggris
        queryParams['translatedLanguage[]'] = ['id', 'en'];
      }

      final uri = Uri.parse('$_baseUrl/manga/$mangaId/feed').replace(
        queryParameters: queryParams,
      );

      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> chaptersJson = data['data'] as List<dynamic>? ?? [];

        return chaptersJson
            .map((item) => Chapter.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Gagal mengambil daftar chapter (Kode: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet.');
    } on TimeoutException {
      throw Exception('Waktu permintaan chapter habis.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan saat memuat chapter: $e');
    }
  }

  /// Mengambil URL gambar-gambar halaman chapter dari endpoint at-home
  static Future<List<String>> getChapterPages(
    String chapterId, {
    bool dataSaver = true,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/at-home/server/$chapterId');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final String baseUrl = body['baseUrl'] as String? ?? '';
        final chapterData = body['chapter'] as Map<String, dynamic>? ?? {};
        final String hash = chapterData['hash'] as String? ?? '';

        final List<dynamic> fileNames = dataSaver
            ? (chapterData['dataSaver'] as List<dynamic>? ?? [])
            : (chapterData['data'] as List<dynamic>? ?? []);

        final qualityPath = dataSaver ? 'data-saver' : 'data';

        return fileNames
            .map((fileName) => '$baseUrl/$qualityPath/$hash/$fileName')
            .toList();
      } else {
        throw Exception('Gagal memuat halaman chapter (Kode: ${response.statusCode}).');
      }
    } on SocketException {
      throw Exception('Tidak ada koneksi internet untuk memuat gambar.');
    } on TimeoutException {
      throw Exception('Waktu memuat server gambar habis.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Terjadi kesalahan server gambar: $e');
    }
  }

  /// Mengambil daftar tag/genre dari MangaDex
  static Future<List<GenreTag>> getTags() async {
    try {
      final uri = Uri.parse('$_baseUrl/manga/tag');
      final response = await http.get(uri, headers: _headers).timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> tagsJson = data['data'] as List<dynamic>? ?? [];

        final allTags = tagsJson
            .map((item) => GenreTag.fromJson(item as Map<String, dynamic>))
            .where((tag) => tag.group == 'genre' || tag.group == 'theme')
            .toList();

        // Urutkan alfabetis
        allTags.sort((a, b) => a.name.compareTo(b.name));
        return allTags;
      } else {
        return [];
      }
    } catch (_) {
      // Kembalikan list kosong jika gagal mengambil tag
      return [];
    }
  }
}
