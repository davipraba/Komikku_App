/// Model data Favorit untuk penyimpanan lokal SQLite (SRS 2.5.1)
class Favorite {
  final int? id;
  final String userId;
  final String mangaId;
  final String title;
  final String? coverUrl;
  final String createdAt;
  final String updatedAt;
  final int isDeleted; // 0: aktif, 1: soft-deleted
  final int isSynced;  // 0: belum sinkron, 1: sudah sinkron

  const Favorite({
    this.id,
    required this.userId,
    required this.mangaId,
    required this.title,
    this.coverUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = 0,
    this.isSynced = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'manga_id': mangaId,
      'title': title,
      'cover_url': coverUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'is_deleted': isDeleted,
      'is_synced': isSynced,
    };
  }

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      id: map['id'] as int?,
      userId: map['user_id'] as String? ?? '',
      mangaId: map['manga_id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      coverUrl: map['cover_url'] as String?,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
      isDeleted: map['is_deleted'] as int? ?? 0,
      isSynced: map['is_synced'] as int? ?? 0,
    );
  }
}
