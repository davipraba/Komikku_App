import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chapter.dart';
import '../models/favorite.dart';
import '../models/manga.dart';
import '../models/reading_history.dart';
import '../models/review.dart';
import '../services/ai_service.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/prefs_service.dart';
import '../services/review_service.dart';
import '../services/supabase_service.dart';
import '../services/sync_service.dart';
import '../widgets/chapter_tile.dart';
import '../widgets/rating_bar.dart';
import 'reader_screen.dart';

/// Halaman Detail Komik (FR-DETAIL & FR-REVIEW)
/// Menampilkan informasi lengkap komik, sinopsis expand/collapse,
/// filter & urutan chapter, aksi Favorit & Lanjut Baca (SQLite),
/// serta fitur Rating & Ulasan Komunitas (Supabase PostgreSQL).
class DetailScreen extends StatefulWidget {
  final String mangaId;

  const DetailScreen({
    super.key,
    required this.mangaId,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  Manga? _manga;
  List<Chapter> _chapters = [];
  ReadingHistory? _lastHistory;

  bool _isLoading = true;
  String? _errorMessage;

  bool _isSynopsisExpanded = false;
  bool _isFavorite = false;

  String _chapterOrder = 'asc'; // 'asc' atau 'desc'
  String? _selectedLanguage; // null (semua), 'id', 'en'

  // State untuk Rating & Ulasan (FR-REVIEW)
  List<Review> _reviews = [];
  double _averageRating = 0.0;
  Review? _userReview;
  bool _isLoadingReviews = true;

  String get _currentUserId =>
      PrefsService.userId ??
      SupabaseService.instance.currentUser?.id ??
      'local_user';

  @override
  void initState() {
    super.initState();
    _loadMangaAndChapters();
  }

  /// Memuat data detail komik, feed chapter, status SQLite, dan ulasan Supabase
  Future<void> _loadMangaAndChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mangaFuture = ApiService.getMangaDetail(widget.mangaId);
      final chaptersFuture = ApiService.getChapters(
        widget.mangaId,
        order: _chapterOrder,
        language: _selectedLanguage,
      );
      final isFavFuture = DatabaseHelper.instance.isFavorite(
        _currentUserId,
        widget.mangaId,
      );
      final historyFuture = DatabaseHelper.instance.getHistoryForManga(
        _currentUserId,
        widget.mangaId,
      );

      final results = await Future.wait([
        mangaFuture,
        chaptersFuture,
        isFavFuture,
        historyFuture,
      ]);

      if (!mounted) return;

      setState(() {
        _manga = results[0] as Manga;
        _chapters = results[1] as List<Chapter>;
        _isFavorite = results[2] as bool;
        _lastHistory = results[3] as ReadingHistory?;
        _isLoading = false;
      });

      // Muat ulasan komunitas dari Supabase
      _loadReviews();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Memuat rating dan ulasan dari Supabase
  Future<void> _loadReviews() async {
    try {
      final reviews = await ReviewService.instance.getReviews(widget.mangaId);
      final avg = await ReviewService.instance.getAverageRating(widget.mangaId);
      final myReview = await ReviewService.instance.getUserReview(widget.mangaId);

      if (mounted) {
        setState(() {
          _reviews = reviews;
          _averageRating = avg;
          _userReview = myReview;
          _isLoadingReviews = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingReviews = false);
      }
    }
  }

  /// Memperbarui status riwayat baca dari database lokal
  Future<void> _refreshHistory() async {
    final history = await DatabaseHelper.instance.getHistoryForManga(
      _currentUserId,
      widget.mangaId,
    );
    if (mounted) {
      setState(() {
        _lastHistory = history;
      });
    }
    // Jalankan sync ke cloud di background
    SyncService.instance.syncAll();
  }

  /// Mengubah urutan chapter (Naik / Turun)
  void _toggleChapterOrder() {
    setState(() {
      _chapterOrder = _chapterOrder == 'asc' ? 'desc' : 'asc';
    });
    _loadMangaAndChapters();
  }

  /// Mengubah filter bahasa chapter
  void _changeLanguageFilter(String? lang) {
    setState(() {
      _selectedLanguage = lang;
    });
    _loadMangaAndChapters();
  }

  /// Toggle Favorit tersimpan di SQLite lokal dan picu sinkronisasi cloud (FR-LIB-01, FR-SYNC-01)
  Future<void> _toggleFavorite() async {
    if (_manga == null) return;

    if (_isFavorite) {
      await DatabaseHelper.instance.removeFavorite(_currentUserId, widget.mangaId);
      if (!mounted) return;
      setState(() => _isFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dihapus dari favorit'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final now = DateTime.now().toIso8601String();
      final fav = Favorite(
        userId: _currentUserId,
        mangaId: widget.mangaId,
        title: _manga!.title,
        coverUrl: _manga!.coverUrl,
        createdAt: now,
        updatedAt: now,
      );
      await DatabaseHelper.instance.addFavorite(fav);
      if (!mounted) return;
      setState(() => _isFavorite = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ditambahkan ke favorit (Tersimpan di SQLite)'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }

    // Picu sinkronisasi cloud otomatis di background (FR-SYNC-01)
    SyncService.instance.syncAll();
  }

  /// Aksi Lanjut Baca yang membuka chapter dan halaman terakhir dari riwayat baca (FR-DETAIL-04, TC-07)
  Future<void> _handleContinueReading() async {
    if (_chapters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada chapter yang tersedia.')),
      );
      return;
    }

    Chapter targetChapter;
    int targetPage = 0;

    if (_lastHistory != null) {
      final matched = _chapters.where((c) => c.id == _lastHistory!.chapterId);
      if (matched.isNotEmpty) {
        targetChapter = matched.first;
        targetPage = _lastHistory!.lastPage > 0 ? _lastHistory!.lastPage - 1 : 0;
      } else {
        targetChapter = _chapters.first;
      }
    } else {
      targetChapter = _chapters.first;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          chapter: targetChapter,
          mangaId: widget.mangaId,
          mangaTitle: _manga?.title ?? 'Komik',
          coverUrl: _manga?.coverUrl,
          chapterList: _chapters,
          initialPage: targetPage,
        ),
      ),
    );

    _refreshHistory();
  }

  /// Dialog formulir untuk menulis atau mengedit ulasan & rating bintang (FR-REVIEW-01)
  Future<void> _showReviewDialog({Review? existingReview}) async {
    int selectedRating = existingReview?.rating ?? 5;
    final commentController = TextEditingController(text: existingReview?.comment ?? '');
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingReview != null ? 'Edit Ulasan Anda' : 'Tulis Ulasan Komik'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Beri Rating Bintang:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Center(
                    child: RatingBar(
                      rating: selectedRating.toDouble(),
                      starSize: 36,
                      isInteractive: true,
                      onRatingChanged: (newRating) {
                        setDialogState(() => selectedRating = newRating);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Ulasan / Komentar:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tuliskan pendapat Anda tentang alur cerita komik ini...',
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (commentController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Komentar ulasan tidak boleh kosong.')),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          setDialogState(() => isSubmitting = true);
                          try {
                            await ReviewService.instance.upsertReview(
                              mangaId: widget.mangaId,
                              rating: selectedRating,
                              comment: commentController.text.trim(),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            _loadReviews();
                            if (mounted) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Ulasan Anda berhasil disimpan!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(e.toString().replaceAll('Exception: ', '')),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Kirim'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Menghapus ulasan milik pengguna sendiri (FR-REVIEW-03)
  Future<void> _deleteUserReview() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Ulasan?'),
        content: const Text('Apakah Anda yakin ingin menghapus ulasan Anda untuk komik ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ReviewService.instance.deleteReview(widget.mangaId);
      _loadReviews();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ulasan Anda telah dihapus.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus ulasan: $e')),
        );
      }
    }
  }

  /// Membuka Modal Bottom Sheet ringkasan sinopsis AI 3 poin (FR-DETAIL-05, FR-AI-05)
  void _showAiSummaryBottomSheet() {
    if (_manga == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _AiSummaryBottomSheet(
        comicTitle: _manga!.title,
        synopsis: _manga!.description,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat detail komik...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null || _manga == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ?? 'Gagal memuat komik.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadMangaAndChapters,
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final manga = _manga!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          manga.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            tooltip: 'Favorit',
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // 1. Header Detail Komik (Cover + Info)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 170,
                    child: manga.coverUrl != null
                        ? CachedNetworkImage(
                            imageUrl: manga.coverUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: theme.colorScheme.surfaceContainerHighest,
                              child: const Icon(Icons.broken_image),
                            ),
                          )
                        : Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.menu_book),
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info Judul, Penulis, Status, dan Rata-rata Rating
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        manga.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              manga.author,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Tampilan Rating Komunitas (FR-REVIEW-04)
                      Row(
                        children: [
                          RatingBar(rating: _averageRating, starSize: 16),
                          const SizedBox(width: 6),
                          Text(
                            _averageRating > 0
                                ? '${_averageRating.toStringAsFixed(1)} / 5'
                                : 'Belum ada rating',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          manga.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Bar Tombol Aksi (Lanjut Baca, Ringkas AI)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _handleContinueReading,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(
                      _lastHistory != null
                          ? 'Lanjut: ${_lastHistory!.chapterLabel} (Hal. ${_lastHistory!.lastPage})'
                          : 'Mulai Baca',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _showAiSummaryBottomSheet,
                  icon: const Icon(Icons.auto_awesome, color: Colors.deepOrange),
                  label: const Text('Ringkas AI'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Genre Tags
          if (manga.tags.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Wrap(
                spacing: 6,
                runSpacing: 4,
                children: manga.tags.take(6).map((tag) {
                  return Chip(
                    label: Text(tag, style: const TextStyle(fontSize: 11)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // 4. Sinopsis (Expand/Collapse)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sinopsis',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  manga.description,
                  maxLines: _isSynopsisExpanded ? null : 3,
                  overflow: _isSynopsisExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSynopsisExpanded = !_isSynopsisExpanded;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      _isSynopsisExpanded ? 'Sembunyikan' : 'Lihat lebih banyak',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32),

          // 5. Header Daftar Chapter + Filter & Pengurutan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daftar Chapter (${_chapters.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    PopupMenuButton<String?>(
                      icon: const Icon(Icons.language, size: 20),
                      tooltip: 'Filter Bahasa',
                      initialValue: _selectedLanguage,
                      onSelected: _changeLanguageFilter,
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: null,
                          child: Text('Semua Bahasa'),
                        ),
                        const PopupMenuItem(
                          value: 'id',
                          child: Text('Indonesia (ID)'),
                        ),
                        const PopupMenuItem(
                          value: 'en',
                          child: Text('Inggris (EN)'),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _chapterOrder == 'asc'
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 20,
                      ),
                      tooltip: _chapterOrder == 'asc'
                          ? 'Urutan: Terlama -> Terbaru'
                          : 'Urutan: Terbaru -> Terlama',
                      onPressed: _toggleChapterOrder,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 6. List Chapter
          if (_chapters.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: Text('Tidak ada chapter yang ditemukan untuk bahasa ini.'),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                return ChapterTile(
                  chapter: chapter,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReaderScreen(
                          chapter: chapter,
                          mangaId: widget.mangaId,
                          mangaTitle: manga.title,
                          coverUrl: manga.coverUrl,
                          chapterList: _chapters,
                          initialPage: 0,
                        ),
                      ),
                    );
                    _refreshHistory();
                  },
                );
              },
            ),

          const Divider(height: 36),

          // ====================================================================
          // 7. SEKSI RATING & ULASAN KOMUNITAS (FR-REVIEW)
          // ====================================================================
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ulasan Komunitas',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _averageRating > 0
                          ? 'Rata-rata ${_averageRating.toStringAsFixed(1)} dari 5 bintang (${_reviews.length} ulasan)'
                          : 'Belum ada rating dari komunitas',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showReviewDialog(existingReview: _userReview),
                  icon: Icon(_userReview != null ? Icons.edit : Icons.rate_review, size: 16),
                  label: Text(_userReview != null ? 'Ubah Ulasan' : 'Tulis Ulasan'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ulasan Milik Pengguna Saat Ini (Jika Ada)
          if (_userReview != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Ulasan Anda',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            tooltip: 'Edit Ulasan',
                            onPressed: () => _showReviewDialog(existingReview: _userReview),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            tooltip: 'Hapus Ulasan',
                            onPressed: _deleteUserReview,
                          ),
                        ],
                      ),
                      RatingBar(rating: _userReview!.rating.toDouble(), starSize: 18),
                      const SizedBox(height: 6),
                      Text(
                        _userReview!.comment,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Daftar Ulasan dari Pembaca Lain
          if (_isLoadingReviews)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_reviews.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Text(
                  'Belum ada ulasan untuk komik ini.\nJadilah orang pertama yang memberi penilaian!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _reviews.length,
              itemBuilder: (context, index) {
                final review = _reviews[index];
                // Jangan tampilkan ulasan pengguna dua kali jika sudah ditampilkan di atas
                if (_userReview != null && review.id == _userReview!.id) {
                  return const SizedBox.shrink();
                }

                String formattedDate = '';
                if (review.updatedAt != null) {
                  try {
                    final dt = DateTime.parse(review.updatedAt!).toLocal();
                    formattedDate = DateFormat('dd MMM yyyy').format(dt);
                  } catch (_) {}
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: theme.colorScheme.primaryContainer,
                              child: Text(
                                review.userName != null && review.userName!.isNotEmpty
                                    ? review.userName![0].toUpperCase()
                                    : 'U',
                                style: TextStyle(fontSize: 11, color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                review.userName ?? 'Pembaca',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            if (formattedDate.isNotEmpty)
                              Text(
                                formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        RatingBar(rating: review.rating.toDouble(), starSize: 14),
                        const SizedBox(height: 6),
                        Text(
                          review.comment,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Widget konten Modal Bottom Sheet untuk menampilkan ringkasan sinopsis AI (FR-DETAIL-05, FR-AI-05)
class _AiSummaryBottomSheet extends StatefulWidget {
  final String comicTitle;
  final String synopsis;

  const _AiSummaryBottomSheet({
    required this.comicTitle,
    required this.synopsis,
  });

  @override
  State<_AiSummaryBottomSheet> createState() => _AiSummaryBottomSheetState();
}

class _AiSummaryBottomSheetState extends State<_AiSummaryBottomSheet> {
  bool _isLoading = true;
  String? _summary;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    if (widget.synopsis.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sinopsis komik ini kosong, tidak dapat dirangkum.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await AiService.instance.summarize(widget.synopsis);
      if (!mounted) return;
      setState(() {
        _summary = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header BottomSheet
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.deepOrange, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Sinopsis AI',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.comicTitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 24),

          // Konten Ringkasan / Loading / Error
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 36.0),
              child: Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Merangkum sinopsis komik dengan AI...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: _fetchSummary,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Text(
                _summary ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Diringkas oleh Gemini 2.5 Flash via Edge Function',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}

