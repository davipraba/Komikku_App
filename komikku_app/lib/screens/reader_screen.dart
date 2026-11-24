import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/chapter.dart';
import '../models/reading_history.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';

/// Halaman Pembaca Chapter Komik (FR-READER)
/// Mendukung mode baca Vertikal (Scroll) dan Horizontal (Swipe),
/// indikator halaman x/y, tombol chapter sebelumnya/berikutnya,
/// dan otomatis menyimpan progres riwayat baca ke SQLite (FR-READER-05).
class ReaderScreen extends StatefulWidget {
  final Chapter chapter;
  final String mangaId;
  final String mangaTitle;
  final String? coverUrl;
  final List<Chapter> chapterList;
  final int initialPage; // 0-based index

  const ReaderScreen({
    super.key,
    required this.chapter,
    required this.mangaId,
    required this.mangaTitle,
    this.coverUrl,
    this.chapterList = const [],
    this.initialPage = 0,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Chapter _currentChapter;
  List<String> _pageUrls = [];

  bool _isLoading = true;
  String? _errorMessage;
  late int _currentPageIndex;
  bool _showControls = true;
  late String _readerMode;

  late PageController _pageController;
  final ScrollController _scrollController = ScrollController();
  Timer? _saveDebounceTimer;

  @override
  void initState() {
    super.initState();
    _currentChapter = widget.chapter;
    _currentPageIndex = widget.initialPage;
    _readerMode = PrefsService.readerMode;
    _pageController = PageController(initialPage: widget.initialPage);
    _loadPages();
    _scrollController.addListener(_onVerticalScroll);
  }

  @override
  void dispose() {
    _saveDebounceTimer?.cancel();
    // Simpan progres baca terakhir saat keluar dari layar (TC-07)
    _saveReadingProgressDirectly();
    _pageController.dispose();
    _scrollController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  /// Menghitung perkiraan halaman saat membaca dalam mode vertikal
  void _onVerticalScroll() {
    if (_pageUrls.isEmpty || !_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (maxScroll <= 0) return;

    final progress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    final calculatedPage = (progress * (_pageUrls.length - 1)).round();

    if (calculatedPage != _currentPageIndex) {
      setState(() {
        _currentPageIndex = calculatedPage;
      });
      _scheduleSaveProgress();
    }
  }

  /// Mengambil URL daftar halaman dari MangaDex @at-home server (FR-READER-01)
  Future<void> _loadPages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final pages = await ApiService.getChapterPages(
        _currentChapter.id,
        dataSaver: PrefsService.dataSaver,
      );

      if (!mounted) return;

      setState(() {
        _pageUrls = pages;
        _isLoading = false;
      });

      // Pastikan index halaman valid
      if (_currentPageIndex >= pages.length) {
        _currentPageIndex = 0;
      }

      // Simpan riwayat pembukaan chapter
      _scheduleSaveProgress();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Menjadwalkan penyimpanan progres riwayat baca ke SQLite dengan Debounce 1.5 detik
  void _scheduleSaveProgress() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 1500), () {
      _saveReadingProgressDirectly();
    });
  }

  /// Menyimpan progres baca ke SQLite secara langsung (FR-READER-05)
  void _saveReadingProgressDirectly() {
    final userId = PrefsService.userId ??
        SupabaseService.instance.currentUser?.id ??
        'local_user';

    final history = ReadingHistory(
      userId: userId,
      mangaId: widget.mangaId,
      mangaTitle: widget.mangaTitle,
      coverUrl: widget.coverUrl,
      chapterId: _currentChapter.id,
      chapterLabel: _currentChapter.displayTitle,
      lastPage: _currentPageIndex + 1,
      updatedAt: DateTime.now().toIso8601String(),
    );

    DatabaseHelper.instance.upsertHistory(history);
  }

  /// Menemukan index chapter saat ini di dalam daftar chapter
  int get _currentChapterIndex {
    return widget.chapterList.indexWhere((c) => c.id == _currentChapter.id);
  }

  bool get _hasPreviousChapter {
    final idx = _currentChapterIndex;
    return idx > 0 && widget.chapterList.isNotEmpty;
  }

  bool get _hasNextChapter {
    final idx = _currentChapterIndex;
    return idx >= 0 && idx < widget.chapterList.length - 1;
  }

  /// Pindah ke chapter sebelumnya
  void _goToPreviousChapter() {
    if (!_hasPreviousChapter) return;
    _saveReadingProgressDirectly();
    setState(() {
      _currentChapter = widget.chapterList[_currentChapterIndex - 1];
      _currentPageIndex = 0;
    });
    _pageController.jumpToPage(0);
    _loadPages();
  }

  /// Pindah ke chapter berikutnya
  void _goToNextChapter() {
    if (!_hasNextChapter) return;
    _saveReadingProgressDirectly();
    setState(() {
      _currentChapter = widget.chapterList[_currentChapterIndex + 1];
      _currentPageIndex = 0;
    });
    _pageController.jumpToPage(0);
    _loadPages();
  }

  /// Toggle tampilan kontrol navigasi (layar penuh saat membaca)
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
  }

  /// Mengganti mode baca antara vertikal dan horizontal
  void _toggleReaderMode() {
    setState(() {
      _readerMode = _readerMode == 'vertical' ? 'horizontal' : 'vertical';
      PrefsService.readerMode = _readerMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Konten Pembaca Gambar
          GestureDetector(
            onTap: _toggleControls,
            child: _buildReaderContent(),
          ),

          // 2. AppBar Atas (Tampil jika _showControls == true)
          if (_showControls)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.8),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.mangaTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              _currentChapter.displayTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Tombol Ganti Mode Baca
                      IconButton(
                        icon: Icon(
                          _readerMode == 'vertical'
                              ? Icons.view_day_outlined
                              : Icons.view_carousel_outlined,
                          color: Colors.white,
                        ),
                        tooltip: _readerMode == 'vertical'
                            ? 'Mode: Vertikal (Ganti ke Horizontal)'
                            : 'Mode: Horizontal (Ganti ke Vertikal)',
                        onPressed: _toggleReaderMode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Floating Indikator Halaman (FR-READER-03)
          if (!_isLoading && _pageUrls.isNotEmpty)
            Positioned(
              bottom: _showControls ? 80 : 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24, width: 0.8),
                  ),
                  child: Text(
                    'Halaman ${_currentPageIndex + 1} / ${_pageUrls.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

          // 4. Bar Navigasi Chapter Bawah (FR-READER-04)
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _hasPreviousChapter ? _goToPreviousChapter : null,
                        icon: const Icon(Icons.skip_previous, size: 18),
                        label: const Text('Sebelumnya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[900],
                          disabledForegroundColor: Colors.white30,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _hasNextChapter ? _goToNextChapter : null,
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text('Berikutnya'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[850],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[900],
                          disabledForegroundColor: Colors.white30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReaderContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepOrange),
            SizedBox(height: 16),
            Text(
              'Memuat halaman komik...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.broken_image, size: 64, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadPages,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang Halaman'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pageUrls.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada halaman yang ditemukan pada chapter ini.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Mode Horizontal (FR-READER-02)
    if (_readerMode == 'horizontal') {
      return PageView.builder(
        controller: _pageController,
        itemCount: _pageUrls.length,
        onPageChanged: (index) {
          setState(() {
            _currentPageIndex = index;
          });
          _scheduleSaveProgress();
        },
        itemBuilder: (context, index) {
          return _buildPageImage(_pageUrls[index], index + 1);
        },
      );
    }

    // Mode Vertikal (FR-READER-02)
    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: _pageUrls.length,
      itemBuilder: (context, index) {
        return _buildPageImage(_pageUrls[index], index + 1);
      },
    );
  }

  /// Menampilkan satu gambar halaman dengan loading progress dan retry error
  Widget _buildPageImage(String url, int pageNumber) {
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.contain,
      progressIndicatorBuilder: (context, url, downloadProgress) => SizedBox(
        height: 400,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                value: downloadProgress.progress,
                color: Colors.deepOrange,
                strokeWidth: 3,
              ),
              const SizedBox(height: 12),
              Text(
                'Memuat hal. $pageNumber...',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        height: 300,
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
              const SizedBox(height: 8),
              Text(
                'Gagal memuat hal. $pageNumber',
                style: const TextStyle(color: Colors.white70),
              ),
              TextButton(
                onPressed: () {
                  setState(() {});
                },
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
