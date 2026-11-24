import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/favorite.dart';
import '../models/reading_history.dart';
import '../services/database_helper.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';
import 'detail_screen.dart';

/// Halaman Perpustakaan Lokal (FR-LIB)
/// Berisi dua tab: Favorit (Grid) dan Riwayat Baca (List).
/// Seluruh data tersimpan secara offline di SQLite dan difilter per user_id.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Favorite> _favorites = [];
  List<ReadingHistory> _historyList = [];

  bool _isLoadingFav = true;
  bool _isLoadingHistory = true;

  String get _currentUserId =>
      PrefsService.userId ??
      SupabaseService.instance.currentUser?.id ??
      'local_user';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Memuat data favorit dan riwayat dari SQLite lokal
  Future<void> _loadAllData() async {
    _loadFavorites();
    _loadHistory();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoadingFav = true);
    final favs = await DatabaseHelper.instance.getFavorites(_currentUserId);
    if (mounted) {
      setState(() {
        _favorites = favs;
        _isLoadingFav = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await DatabaseHelper.instance.getHistory(_currentUserId);
    if (mounted) {
      setState(() {
        _historyList = history;
        _isLoadingHistory = false;
      });
    }
  }

  /// Menghapus satu item favorit
  Future<void> _removeFavorite(Favorite fav) async {
    await DatabaseHelper.instance.removeFavorite(_currentUserId, fav.mangaId);
    _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${fav.title}" dihapus dari favorit'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Menghapus satu baris riwayat baca
  Future<void> _deleteHistoryItem(ReadingHistory history) async {
    await DatabaseHelper.instance.deleteHistoryOne(_currentUserId, history.mangaId);
    _loadHistory();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Riwayat "${history.mangaTitle}" dihapus'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Menghapus seluruh riwayat baca dengan dialog konfirmasi (FR-LIB-04)
  Future<void> _clearAllHistory() async {
    if (_historyList.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Semua Riwayat?'),
        content: const Text(
          'Seluruh riwayat membaca Anda akan dihapus dari perangkat ini. Tindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    await DatabaseHelper.instance.deleteHistoryAll(_currentUserId);
    _loadHistory();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Seluruh riwayat baca telah dihapus.')),
    );
  }

  /// Format tanggal ISO8601 ke teks terbaca
  String _formatDate(String isoString) {
    try {
      final dt = DateTime.parse(isoString).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Perpustakaan Saya',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.favorite_rounded),
              text: 'Favorit (${_favorites.length})',
            ),
            Tab(
              icon: const Icon(Icons.history_rounded),
              text: 'Riwayat (${_historyList.length})',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _loadAllData,
          ),
          // Tombol Hapus Riwayat (hanya muncul saat di tab riwayat)
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) {
              if (_tabController.index == 1 && _historyList.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Hapus Semua Riwayat',
                  onPressed: _clearAllHistory,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Favorit (FR-LIB-02, TC-06)
          RefreshIndicator(
            onRefresh: _loadFavorites,
            child: _buildFavoritesTab(theme),
          ),

          // Tab 2: Riwayat Baca (FR-LIB-03, TC-07)
          RefreshIndicator(
            onRefresh: _loadHistory,
            child: _buildHistoryTab(theme),
          ),
        ],
      ),
    );
  }

  // ====================================================================
  // TAB FAVORIT
  // ====================================================================
  Widget _buildFavoritesTab(ThemeData theme) {
    if (_isLoadingFav) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Komik Favorit',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tandai komik favorit Anda di halaman detail untuk melihatnya di sini, bahkan saat offline.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final fav = _favorites[index];
        return Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DetailScreen(mangaId: fav.mangaId),
                ),
              );
              _loadFavorites();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      fav.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: fav.coverUrl!,
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
                      // Tombol Hapus Favorit Cepat
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.favorite, color: Colors.red, size: 18),
                            tooltip: 'Hapus Favorit',
                            onPressed: () => _removeFavorite(fav),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    fav.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====================================================================
  // TAB RIWAYAT BACA
  // ====================================================================
  Widget _buildHistoryTab(ThemeData theme) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_historyList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history_rounded,
                size: 72,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Riwayat Baca',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Komik dan bab yang Anda baca akan otomatis tercatat di sini sehingga Anda tidak kehilangan progres.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _historyList.length,
      itemBuilder: (context, index) {
        final item = _historyList[index];

        return Dismissible(
          key: Key('history_${item.mangaId}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteHistoryItem(item),
          child: Card(
            elevation: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                // Buka detail komik untuk melanjutkan baca
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(mangaId: item.mangaId),
                  ),
                );
                _loadHistory();
              },
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Row(
                  children: [
                    // Cover Miniatur
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 80,
                        child: item.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.coverUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image, size: 20),
                                ),
                              )
                            : Container(
                                color: theme.colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.menu_book, size: 24),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Detail Progres Baca
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.mangaTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.chapterLabel} • Hal. ${item.lastPage}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Dibaca: ${_formatDate(item.updatedAt)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tombol Hapus Baris
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      color: theme.colorScheme.error,
                      tooltip: 'Hapus dari Riwayat',
                      onPressed: () => _deleteHistoryItem(item),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
