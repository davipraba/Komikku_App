/// Model data Riwayat Baca untuk penyimpanan lokal SQLite (SRS 2.5.1)
class ReadingHistory {
  final int? id;
  final String userId;
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final String chapterId;
  final String chapterLabel;
  final int lastPage;
  final String updatedAt;
  final int isSynced;

  const ReadingHistory({
    this.id,
    required this.userId,
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
    required this.chapterId,
    required this.chapterLabel,
    this.lastPage = 1,
    required this.updatedAt,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'manga_id': mangaId,
      'manga_title': mangaTitle,
      'cover_url': coverUrl,
      'chapter_id': chapterId,
      'chapter_label': chapterLabel,
      'last_page': lastPage,
      'updated_at': updatedAt,
      'is_synced': isSynced,
    };
  }

  factory ReadingHistory.fromMap(Map<String, dynamic> map) {
    return ReadingHistory(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? '',
      mangaId: map['manga_id'] as String? ?? '',
      mangaTitle: map['manga_title'] as String? ?? '',
      coverUrl: map['cover_url'] as String?,
      chapterId: map['chapter_id'] as String? ?? '',
      chapterLabel: map['chapter_label'] as String? ?? '',
      lastPage: map['last_page'] as int? ?? 1,
      updatedAt: map['updated_at'] as String? ?? '',
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}
