import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/favorite.dart';
import '../models/reading_history.dart';
import 'database_helper.dart';
import 'prefs_service.dart';
import 'supabase_service.dart';

/// Service Singleton untuk menangani sinkronisasi dua arah SQLite ↔ Supabase (FR-SYNC)
/// Resolusi konflik: Data dengan timestamp 'updated_at' terbaru yang menang (FR-SYNC-03).
class SyncService {
  SyncService._internal();
  static final SyncService instance = SyncService._internal();

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Memeriksa ketersediaan koneksi internet
  Future<bool> get isOnline async {
    final List<ConnectivityResult> connectivity =
        await Connectivity().checkConnectivity();
    return !connectivity.contains(ConnectivityResult.none);
  }

  /// Menjalankan siklus sinkronisasi lengkap: PUSH (upload lokal) lalu PULL (unduh remote)
  Future<bool> syncAll({bool silent = true}) async {
    if (_isSyncing) return false;

    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return false;

    final online = await isOnline;
    if (!online) return false;

    _isSyncing = true;

    try {
      final userId = currentUser.id;

      // 1. PUSH: Unggah perubahan lokal yang belum tersinkron (is_synced = 0)
      await push(userId);

      // 2. PULL: Unduh data cloud terbaru milik pengguna dan gabungkan ke SQLite
      await pull(userId);

      // 3. Catat waktu sinkronisasi berhasil
      final nowStr = DateTime.now().toIso8601String();
      PrefsService.lastSyncAt = nowStr;

      _isSyncing = false;
      return true;
    } catch (_) {
      _isSyncing = false;
      if (!silent) rethrow;
      return false; // Silent failure agar tidak mengganggu antarmuka pengguna
    }
  }

  /// PUSH: Mengunggah item lokal dengan flag is_synced = 0 ke Supabase (FR-SYNC-01)
  Future<void> push(String userId) async {
    final client = SupabaseService.instance.client;

    // A. Push Favorit yang belum tersinkron (termasuk soft-deleted)
    final unsyncedFavs =
        await DatabaseHelper.instance.getUnsyncedFavorites(userId);

    for (final fav in unsyncedFavs) {
      await client.from('favorites').upsert(
        {
          'user_id': userId,
          'manga_id': fav.mangaId,
          'title': fav.title,
          'cover_url': fav.coverUrl,
          'updated_at': fav.updatedAt,
          'is_deleted': fav.isDeleted == 1,
        },
        onConflict: 'user_id,manga_id',
      );

      if (fav.id != null) {
        await DatabaseHelper.instance.markFavoriteSynced(fav.id!);
      }
    }

    // B. Push Riwayat Baca yang belum tersinkron
    final unsyncedHistory =
        await DatabaseHelper.instance.getUnsyncedHistory(userId);

    for (final h in unsyncedHistory) {
      await client.from('reading_history').upsert(
        {
          'user_id': userId,
          'manga_id': h.mangaId,
          'manga_title': h.mangaTitle,
          'cover_url': h.coverUrl,
          'chapter_id': h.chapterId,
          'chapter_label': h.chapterLabel,
          'last_page': h.lastPage,
          'updated_at': h.updatedAt,
        },
        onConflict: 'user_id,manga_id',
      );

      if (h.id != null) {
        await DatabaseHelper.instance.markHistorySynced(h.id!);
      }
    }
  }

  /// PULL: Mengunduh data cloud dan menggabungkannya ke SQLite (FR-SYNC-02, FR-SYNC-03)
  Future<void> pull(String userId) async {
    final client = SupabaseService.instance.client;

    // A. Pull Favorit dari Supabase
    final List<dynamic> remoteFavs =
        await client.from('favorites').select().eq('user_id', userId);

    for (final item in remoteFavs) {
      final map = item as Map<String, dynamic>;
      final mangaId = map['manga_id'] as String;
      final remoteUpdatedAtStr = map['updated_at'] as String;
      final isDeleted = map['is_deleted'] as bool? ?? false;
      final remoteUpdatedAt = DateTime.tryParse(remoteUpdatedAtStr) ?? DateTime(2000);

      // Cek data lokal untuk komik ini
      final localFav = await DatabaseHelper.instance.getFavoriteForManga(userId, mangaId);

      bool shouldUpdate = false;
      if (localFav == null) {
        shouldUpdate = true;
      } else {
        final localUpdatedAt = DateTime.tryParse(localFav.updatedAt) ?? DateTime(2000);
        // Aturan: updated_at terbaru menang (FR-SYNC-03)
        if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        if (isDeleted) {
          // Hapus di lokal
          await DatabaseHelper.instance.removeFavorite(userId, mangaId);
        } else {
          // Tambahkan / perbarui di lokal
          final fav = Favorite(
            userId: userId,
            mangaId: mangaId,
            title: map['title'] as String? ?? 'Komik',
            coverUrl: map['cover_url'] as String?,
            createdAt: map['created_at'] as String? ?? remoteUpdatedAtStr,
            updatedAt: remoteUpdatedAtStr,
            isDeleted: 0,
            isSynced: 1,
          );
          await DatabaseHelper.instance.addFavorite(fav);
        }

        // Tandai sebagai tersinkron
        final updatedFav = await DatabaseHelper.instance.getFavoriteForManga(userId, mangaId);
        if (updatedFav?.id != null) {
          await DatabaseHelper.instance.markFavoriteSynced(updatedFav!.id!);
        }
      }
    }

    // B. Pull Riwayat Baca dari Supabase
    final List<dynamic> remoteHistory =
        await client.from('reading_history').select().eq('user_id', userId);

    for (final item in remoteHistory) {
      final map = item as Map<String, dynamic>;
      final mangaId = map['manga_id'] as String;
      final remoteUpdatedAtStr = map['updated_at'] as String;
      final remoteUpdatedAt = DateTime.tryParse(remoteUpdatedAtStr) ?? DateTime(2000);

      final localHistory =
          await DatabaseHelper.instance.getHistoryForManga(userId, mangaId);

      bool shouldUpdate = false;
      if (localHistory == null) {
        shouldUpdate = true;
      } else {
        final localUpdatedAt =
            DateTime.tryParse(localHistory.updatedAt) ?? DateTime(2000);
        if (remoteUpdatedAt.isAfter(localUpdatedAt)) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        final history = ReadingHistory(
          userId: userId,
          mangaId: mangaId,
          mangaTitle: map['manga_title'] as String? ?? 'Komik',
          coverUrl: map['cover_url'] as String?,
          chapterId: map['chapter_id'] as String? ?? '',
          chapterLabel: map['chapter_label'] as String? ?? '',
          lastPage: map['last_page'] as int? ?? 1,
          updatedAt: remoteUpdatedAtStr,
          isSynced: 1,
        );
        await DatabaseHelper.instance.upsertHistory(history);

        final updatedH =
            await DatabaseHelper.instance.getHistoryForManga(userId, mangaId);
        if (updatedH?.id != null) {
          await DatabaseHelper.instance.markHistorySynced(updatedH!.id!);
        }
      }
    }
  }
}
