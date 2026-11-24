import 'package:flutter/material.dart';
import '../models/manga.dart';
import '../services/api_service.dart';
import '../widgets/manga_card.dart';
import 'detail_screen.dart';

/// Halaman Beranda yang menampilkan daftar komik populer dengan paginasi
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<Manga> _mangaList = [];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  int _offset = 0;
  static const int _limit = 20;

  @override
  void initState() {
    super.initState();
    _fetchInitialManga();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Listener scroll untuk memuat data komik berikutnya saat mendekati bagian bawah (FR-HOME-04)
  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 250 &&
        !_isLoadingMore &&
        _hasMore &&
        _errorMessage == null) {
      _fetchMoreManga();
    }
  }

  /// Memuat data awal komik populer (FR-HOME-01, FR-HOME-02)
  Future<void> _fetchInitialManga() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _offset = 0;
      _hasMore = true;
    });

    try {
      final results = await ApiService.getMangaList(
        offset: 0,
        limit: _limit,
      );

      if (!mounted) return;

      setState(() {
        _mangaList.clear();
        _mangaList.addAll(results);
        _offset = results.length;
        _isLoading = false;
        _hasMore = results.length >= _limit;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Memuat halaman komik berikutnya
  Future<void> _fetchMoreManga() async {
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final results = await ApiService.getMangaList(
        offset: _offset,
        limit: _limit,
      );

      if (!mounted) return;

      setState(() {
        _mangaList.addAll(results);
        _offset += results.length;
        _isLoadingMore = false;
        if (results.length < _limit) {
          _hasMore = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _openDetail(String mangaId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailScreen(mangaId: mangaId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'KomikKu',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: _fetchInitialManga,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchInitialManga,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    // 1. State Loading Awal (FR-HOME-02)
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Memuat komik populer...'),
          ],
        ),
      );
    }

    // 2. State Error dengan tombol coba lagi (FR-HOME-03, TC-05)
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal Memuat Komik',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchInitialManga,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. State Kosong
    if (_mangaList.isEmpty) {
      return const Center(
        child: Text('Tidak ada komik yang tersedia saat ini.'),
      );
    }

    // 4. State GridView Komik (FR-HOME-01, FR-HOME-04)
    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final manga = _mangaList[index];
                return MangaCard(
                  manga: manga,
                  onTap: () => _openDetail(manga.id),
                );
              },
              childCount: _mangaList.length,
            ),
          ),
        ),
        // Indikator Loading Saat Paginasi
        if (_isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              ),
            ),
          ),
        // Indikator sudah mencapai akhir komik
        if (!_hasMore && _mangaList.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Semua komik populer telah dimuat',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
