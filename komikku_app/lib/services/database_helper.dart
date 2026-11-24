import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/chat_message.dart';
import '../models/favorite.dart';
import '../models/reading_history.dart';
import '../models/reminder.dart';

/// Helper singleton untuk database lokal SQLite (komikku.db) sesuai modul 6 dan SRS 2.5.1
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('komikku.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// Membuat tabel-tabel SQLite sesuai skema SRS 2.5.1
  Future<void> _createDB(Database db, int version) async {
    // 1. Tabel Favorit (dengan soft delete untuk sinkronisasi cloud)
    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        manga_id TEXT NOT NULL,
        title TEXT NOT NULL,
        cover_url TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        is_synced INTEGER DEFAULT 0,
        UNIQUE(user_id, manga_id)
      )
    ''');

    // 2. Tabel Riwayat Baca (satu baris per komik, menyimpan posisi terakhir)
    await db.execute('''
      CREATE TABLE reading_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        manga_id TEXT NOT NULL,
        manga_title TEXT NOT NULL,
        cover_url TEXT,
        chapter_id TEXT NOT NULL,
        chapter_label TEXT NOT NULL,
        last_page INTEGER DEFAULT 1,
        updated_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        UNIQUE(user_id, manga_id)
      )
    ''');

    // 3. Tabel Reminders (Pengingat Baca / Rilis)
    await db.execute('''
      CREATE TABLE reminders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        manga_id TEXT NOT NULL,
        manga_title TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        repeat_daily INTEGER DEFAULT 0
      )
    ''');

    // 4. Tabel Riwayat Chat Asisten AI (opsional)
    await db.execute('''
      CREATE TABLE ai_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    // Penanganan upgrade skema database bila ada versi baru
  }

  // ====================================================================
  // OPERASI TABEL FAVORITES (FR-LIB-01, FR-LIB-02, FR-LIB-05)
  // ====================================================================

  /// Menambah atau mengaktifkan kembali komik favorit (is_deleted = 0)
  Future<int> addFavorite(Favorite favorite) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    return await db.rawInsert('''
      INSERT INTO favorites (user_id, manga_id, title, cover_url, created_at, updated_at, is_deleted, is_synced)
      VALUES (?, ?, ?, ?, ?, ?, 0, 0)
      ON CONFLICT(user_id, manga_id) DO UPDATE SET
        title = excluded.title,
        cover_url = excluded.cover_url,
        updated_at = excluded.updated_at,
        is_deleted = 0,
        is_synced = 0
    ''', [
      favorite.userId,
      favorite.mangaId,
      favorite.title,
      favorite.coverUrl,
      favorite.createdAt.isNotEmpty ? favorite.createdAt : now,
      now,
    ]);
  }

  /// Menghapus komik dari favorit menggunakan soft delete (is_deleted = 1) agar bisa disinkronkan ke cloud
  Future<int> removeFavorite(String userId, String mangaId) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    return await db.update(
      'favorites',
      {
        'is_deleted': 1,
        'is_synced': 0,
        'updated_at': now,
      },
      where: 'user_id = ? AND manga_id = ?',
      whereArgs: [userId, mangaId],
    );
  }

  /// Memeriksa apakah komik tertentu saat ini difavoritkan oleh pengguna
  Future<bool> isFavorite(String userId, String mangaId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND manga_id = ? AND is_deleted = 0',
      whereArgs: [userId, mangaId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// Mengambil seluruh komik favorit pengguna yang aktif (FR-LIB-02)
  Future<List<Favorite>> getFavorites(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND is_deleted = 0',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return result.map((json) => Favorite.fromMap(json)).toList();
  }

  /// Mengambil komik favorit yang belum tersinkronkan ke Supabase (FR-SYNC-05)
  Future<List<Favorite>> getUnsyncedFavorites(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    return result.map((json) => Favorite.fromMap(json)).toList();
  }

  /// Mengambil data favorit tertentu (termasuk yang soft-deleted) untuk perbandingan saat sinkronisasi
  Future<Favorite?> getFavoriteForManga(String userId, String mangaId) async {
    final db = await instance.database;
    final result = await db.query(
      'favorites',
      where: 'user_id = ? AND manga_id = ?',
      whereArgs: [userId, mangaId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return Favorite.fromMap(result.first);
    }
    return null;
  }

  /// Menandai baris favorit telah berhasil disinkronkan ke cloud
  Future<int> markFavoriteSynced(int id) async {
    final db = await instance.database;
    return await db.update(
      'favorites',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================================================================
  // OPERASI TABEL READING_HISTORY (FR-LIB-03, FR-LIB-04, FR-LIB-05)
  // ====================================================================

  /// Menyimpan atau memperbarui riwayat baca komik (upsert)
  Future<int> upsertHistory(ReadingHistory history) async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String();

    return await db.rawInsert('''
      INSERT INTO reading_history (user_id, manga_id, manga_title, cover_url, chapter_id, chapter_label, last_page, updated_at, is_synced)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0)
      ON CONFLICT(user_id, manga_id) DO UPDATE SET
        manga_title = excluded.manga_title,
        cover_url = excluded.cover_url,
        chapter_id = excluded.chapter_id,
        chapter_label = excluded.chapter_label,
        last_page = excluded.last_page,
        updated_at = excluded.updated_at,
        is_synced = 0
    ''', [
      history.userId,
      history.mangaId,
      history.mangaTitle,
      history.coverUrl,
      history.chapterId,
      history.chapterLabel,
      history.lastPage,
      now,
    ]);
  }

  /// Mengambil daftar seluruh riwayat baca pengguna (FR-LIB-03)
  Future<List<ReadingHistory>> getHistory(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'reading_history',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return result.map((json) => ReadingHistory.fromMap(json)).toList();
  }

  /// Mengambil riwayat baca terakhir untuk komik tertentu (untuk tombol "Lanjut Baca")
  Future<ReadingHistory?> getHistoryForManga(String userId, String mangaId) async {
    final db = await instance.database;
    final result = await db.query(
      'reading_history',
      where: 'user_id = ? AND manga_id = ?',
      whereArgs: [userId, mangaId],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return ReadingHistory.fromMap(result.first);
    }
    return null;
  }

  /// Menghapus satu item riwayat baca (FR-LIB-04)
  Future<int> deleteHistoryOne(String userId, String mangaId) async {
    final db = await instance.database;
    return await db.delete(
      'reading_history',
      where: 'user_id = ? AND manga_id = ?',
      whereArgs: [userId, mangaId],
    );
  }

  /// Menghapus seluruh riwayat baca pengguna (FR-LIB-04)
  Future<int> deleteHistoryAll(String userId) async {
    final db = await instance.database;
    return await db.delete(
      'reading_history',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Mengambil riwayat baca yang belum tersinkron ke cloud
  Future<List<ReadingHistory>> getUnsyncedHistory(String userId) async {
    final db = await instance.database;
    final result = await db.query(
      'reading_history',
      where: 'user_id = ? AND is_synced = 0',
      whereArgs: [userId],
    );
    return result.map((json) => ReadingHistory.fromMap(json)).toList();
  }

  /// Menandai riwayat telah tersinkron ke cloud
  Future<int> markHistorySynced(int id) async {
    final db = await instance.database;
    return await db.update(
      'reading_history',
      {'is_synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================================================================
  // OPERASI TABEL REMINDERS (FR-NOTIF-03, FR-NOTIF-05)
  // ====================================================================

  /// Menambahkan reminder baru, mengembalikan ID autoincrement yang digunakan sebagai ID notifikasi
  Future<int> addReminder(Reminder reminder) async {
    final db = await instance.database;
    return await db.insert('reminders', reminder.toMap());
  }

  /// Mengambil seluruh reminder yang terdaftar
  Future<List<Reminder>> getReminders() async {
    final db = await instance.database;
    final result = await db.query(
      'reminders',
      orderBy: 'scheduled_at ASC',
    );
    return result.map((json) => Reminder.fromMap(json)).toList();
  }

  /// Menghapus reminder berdasarkan ID
  Future<int> deleteReminder(int id) async {
    final db = await instance.database;
    return await db.delete(
      'reminders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ====================================================================
  // OPERASI TABEL AI_MESSAGES (FR-AI-09)
  // ====================================================================

  /// Menyimpan pesan chat ke tabel lokal SQLite
  Future<int> addChatMessage(ChatMessage message) async {
    final db = await instance.database;
    return await db.insert('ai_messages', message.toMap());
  }

  /// Mengambil hingga 50 riwayat pesan chat terakhir untuk user_id tertentu
  /// Mengembalikan daftar terurut secara kronologis (pesan lama ke baru)
  Future<List<ChatMessage>> getRecentChatMessages(String userId, {int limit = 50}) async {
    final db = await instance.database;
    // Ambil pesan terbaru sejumlah limit, lalu urutkan kembali secara ascending agar enak dibaca di chat
    final result = await db.rawQuery('''
      SELECT * FROM (
        SELECT * FROM ai_messages
        WHERE user_id = ?
        ORDER BY id DESC
        LIMIT ?
      ) ORDER BY id ASC
    ''', [userId, limit]);

    return result.map((json) => ChatMessage.fromMap(json)).toList();
  }

  /// Menghapus semua riwayat pesan chat untuk user_id tertentu
  Future<int> clearChatMessages(String userId) async {
    final db = await instance.database;
    return await db.delete(
      'ai_messages',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
