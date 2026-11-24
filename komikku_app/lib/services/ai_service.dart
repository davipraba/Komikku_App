import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_helper.dart';
import 'supabase_service.dart';

/// Service untuk berkomunikasi dengan Supabase Edge Function `ai-assistant`
/// Sesuai SRS 2.6.3, FR-AI, dan TC-11 & TC-12
class AiService {
  AiService._internal();
  static final AiService instance = AiService._internal();

  /// Mengambil konteks preferensi pengguna dari SQLite:
  /// - 5 komik terakhir yang dibaca (reading_history)
  /// - Judul komik favorit teratas (favorites)
  Future<Map<String, dynamic>> buildUserContext() async {
    final userId = SupabaseService.instance.currentUser?.id;
    if (userId == null) return {};

    try {
      // 1. Ambil 5 riwayat baca terakhir
      final historyList = await DatabaseHelper.instance.getHistory(userId);
      final recentTitles = historyList.take(5).map((h) => h.mangaTitle).toList();

      // 2. Ambil komik favorit untuk preferensi
      final favList = await DatabaseHelper.instance.getFavorites(userId);
      final favTitles = favList.take(5).map((f) => f.title).toList();

      return {
        'recent': recentTitles,
        'favorite_genres': favTitles,
      };
    } catch (e) {
      // Jika terjadi kesalahan akses database lokal, kembalikan konteks kosong
      return {};
    }
  }

  /// Mengirim pesan percakapan ke asisten AI dengan konteks preferensi pengguna (FR-AI-01, FR-AI-04)
  Future<String> chat(String message, {Map<String, dynamic>? customContext}) async {
    final context = customContext ?? await buildUserContext();
    return await _invokeAi(mode: 'chat', message: message, context: context);
  }

  /// Meminta ringkasan sinopsis komik menjadi 3 poin penting (FR-AI-05, FR-DETAIL-05)
  Future<String> summarize(String synopsis) async {
    return await _invokeAi(mode: 'summarize', message: synopsis);
  }

  /// Memanggil Supabase Edge Function `ai-assistant` dengan timeout 30 detik
  /// Menangani status 429 (kuota habis) dan error jaringan
  Future<String> _invokeAi({
    required String mode,
    required String message,
    Map<String, dynamic>? context,
  }) async {
    if (!SupabaseService.instance.isSessionValid) {
      throw Exception('Sesi tidak valid atau telah kedaluwarsa. Silakan login kembali.');
    }

    try {
      final body = <String, dynamic>{
        'mode': mode,
        'message': message,
      };
      if (context != null) {
        body['context'] = context;
      }

      final response = await SupabaseService.instance.client.functions
          .invoke(
            'ai-assistant',
            body: body,
          )
          .timeout(const Duration(seconds: 30));

      final status = response.status;
      final data = response.data;

      if (status == 200) {
        if (data is Map<String, dynamic>) {
          return data['reply'] as String? ?? 'Tidak ada jawaban dari asisten AI.';
        }
        return data.toString();
      } else if (status == 429) {
        throw Exception(
          'Batas kuota harian tercapai. Anda hanya dapat mengirim maksimal 20 permintaan AI per hari.',
        );
      } else {
        String errorMsg = 'Gagal memproses permintaan AI (Status $status).';
        if (data is Map<String, dynamic> && data['error'] != null) {
          errorMsg = data['error'].toString();
        }
        throw Exception(errorMsg);
      }
    } on FunctionException catch (e) {
      if (e.status == 429) {
        throw Exception(
          'Batas kuota harian tercapai. Anda hanya dapat mengirim maksimal 20 permintaan AI per hari.',
        );
      }
      if (e.details is Map && (e.details as Map)['error'] != null) {
        throw Exception((e.details as Map)['error'].toString());
      }
      throw Exception('Gagal menghubungi asisten AI: ${e.reasonPhrase ?? e.toString()}');
    } on TimeoutException {
      throw Exception('Permintaan waktu habis (timeout). Silakan periksa koneksi internet Anda dan coba lagi.');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa koneksi Anda dan coba lagi.');
    } catch (e) {
      final str = e.toString();
      if (str.contains('429')) {
        throw Exception(
          'Batas kuota harian tercapai. Anda hanya dapat mengirim maksimal 20 permintaan AI per hari.',
        );
      }
      rethrow;
    }
  }
}
