import '../models/review.dart';
import 'supabase_service.dart';

/// Service Singleton untuk mengelola Rating & Ulasan Komik di Supabase (FR-REVIEW)
class ReviewService {
  ReviewService._internal();
  static final ReviewService instance = ReviewService._internal();

  /// Mengambil seluruh ulasan untuk sebuah komik dari Supabase (FR-REVIEW-02)
  Future<List<Review>> getReviews(String mangaId) async {
    try {
      final response = await SupabaseService.instance.client
          .from('reviews')
          .select('*, profiles(display_name)')
          .eq('manga_id', mangaId)
          .order('updated_at', ascending: false);

      final list = response as List<dynamic>;
      return list.map((item) => Review.fromMap(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Menghitung rata-rata rating komunitas untuk sebuah komik (FR-REVIEW-04)
  Future<double> getAverageRating(String mangaId) async {
    final reviews = await getReviews(mangaId);
    if (reviews.isEmpty) return 0.0;

    final sum = reviews.fold<int>(0, (prev, r) => prev + r.rating);
    return sum / reviews.length;
  }

  /// Mengambil ulasan milik pengguna saat ini untuk sebuah komik
  Future<Review?> getUserReview(String mangaId) async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final response = await SupabaseService.instance.client
          .from('reviews')
          .select('*, profiles(display_name)')
          .eq('manga_id', mangaId)
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response != null) {
        return Review.fromMap(response);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Menambah atau memperbarui ulasan (FR-REVIEW-01, FR-REVIEW-03)
  Future<void> upsertReview({
    required String mangaId,
    required int rating,
    required String comment,
  }) async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) {
      throw Exception('Anda harus masuk terlebih dahulu untuk memberi ulasan.');
    }

    final now = DateTime.now().toIso8601String();

    await SupabaseService.instance.client.from('reviews').upsert(
      {
        'user_id': currentUser.id,
        'manga_id': mangaId,
        'rating': rating,
        'comment': comment.trim(),
        'updated_at': now,
      },
      onConflict: 'user_id,manga_id',
    );
  }

  /// Menghapus ulasan milik pengguna sendiri (FR-REVIEW-03)
  Future<void> deleteReview(String mangaId) async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return;

    await SupabaseService.instance.client
        .from('reviews')
        .delete()
        .eq('user_id', currentUser.id)
        .eq('manga_id', mangaId);
  }
}
