/// Model data Ulasan & Rating Komik di Supabase (SRS 2.5.3, FR-REVIEW)
class Review {
  final String? id;
  final String userId;
  final String mangaId;
  final int rating; // 1 sampai 5
  final String comment;
  final String? userName;
  final String? createdAt;
  final String? updatedAt;

  const Review({
    this.id,
    required this.userId,
    required this.mangaId,
    required this.rating,
    required this.comment,
    this.userName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'manga_id': mangaId,
      'rating': rating,
      'comment': comment,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map) {
    String? authorName;
    if (map['profiles'] != null && map['profiles'] is Map) {
      authorName = map['profiles']['display_name'] as String?;
    }

    return Review(
      id: map['id']?.toString(),
      userId: map['user_id'] as String? ?? '',
      mangaId: map['manga_id'] as String? ?? '',
      rating: (map['rating'] as num?)?.toInt() ?? 5,
      comment: map['comment'] as String? ?? '',
      userName: authorName ?? 'Pembaca KomikKu',
      createdAt: map['created_at'] as String?,
      updatedAt: map['updated_at'] as String?,
    );
  }
}
