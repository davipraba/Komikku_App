import 'dart:async';
import 'package:flutter/material.dart';
import '../models/genre_tag.dart';
import '../models/manga.dart';
import '../services/api_service.dart';
import '../widgets/manga_card.dart';
import 'detail_screen.dart';

/// Halaman Pencarian Komik dengan Debounce 500ms dan Filter Genre (FR-SEARCH)
class SearchScreen extends StatefulWidget {
  final String? initialQuery;
  const SearchScreen({super.key, this.initialQuery});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  List<GenreTag> _tags = [];
  final List<String> _selectedTagIds = [];
  final List<Manga> _searchResults = [];

  bool _isLoadingTags = true;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTags();
    if (widget.initialQuery != null && widget.initialQuery!.trim().isNotEmpty) {
      _searchController.text = widget.initialQuery!.trim();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _performSearch();
        }
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Memuat daftar tag/genre dari API MangaDex
  Future<void> _loadTags() async {
    try {
      final tags = await ApiService.getTags();
      if (!mounted) return;
      setState(() {
        _tags = tags;
        _isLoadingTags = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTags = false;
      });
    }
  }

  /// Listener input text dengan Debounce 500ms (FR-SEARCH-02)
  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  /// Melakukan request pencarian ke API MangaDex (FR-SEARCH-01, FR-SEARCH-03)
  Future<void> _performSearch() async {
    final query = _searchController.text.trim();

    // Jangan cari jika query kosong dan tidak ada tag yang dipilih
    if (query.isEmpty && _selectedTagIds.isEmpty) {
      setState(() {
        _searchResults.clear();
        _hasSearched = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results = await ApiService.getMangaList(
        title: query.isNotEmpty ? query : null,
        tagIds: _selectedTagIds.isNotEmpty ? _selectedTagIds : null,
        limit: 30,
      );

      if (!mounted) return;

      setState(() {
        _searchResults.clear();
        _searchResults.addAll(results);
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isSearching = false;
      });
    }
  }

  /// Menangani pemilihan filter genre
  void _toggleTag(String tagId) {
    setState(() {
      if (_selectedTagIds.contains(tagId)) {
        _selectedTagIds.remove(tagId);
      } else {
        _selectedTagIds.add(tagId);
      }
    });
    _performSearch();
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
        title: const Text('Cari Komik'),
      ),
      body: Column(
        children: [
          // 1. Kolom Input Pencarian
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Ketik judul komik...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Filter Chip Genre/Tag (FR-SEARCH-03)
          if (!_isLoadingTags && _tags.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  final isSelected = _selectedTagIds.contains(tag.id);

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      onSelected: (_) => _toggleTag(tag.id),
                    ),
                  );
                },
              ),
            ),

          const Divider(height: 1),

          // 3. Tampilan Hasil Pencarian
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final theme = Theme.of(context);

    if (_isSearching) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari komik...'),
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
              Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _performSearch,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 72,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Temukan komik favorit Anda',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ketik judul di atas atau pilih genre yang disukai',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // State Kosong: Komik tidak ditemukan (FR-SEARCH-04)
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Komik tidak ditemukan',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain atau kurangi filter genre',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // Tampilkan Grid Hasil Pencarian
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final manga = _searchResults[index];
        return MangaCard(
          manga: manga,
          onTap: () => _openDetail(manga.id),
        );
      },
    );
  }
}
