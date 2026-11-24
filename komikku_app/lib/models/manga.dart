/// Model data Manga/Komik dari MangaDex
class Manga {
  final String id;
  final String title;
  final String description;
  final String? coverUrl;
  final String author;
  final String status;
  final List<String> tags;
  final double? rating;

  const Manga({
    required this.id,
    required this.title,
    required this.description,
    this.coverUrl,
    required this.author,
    required this.status,
    required this.tags,
    this.rating,
  });

  factory Manga.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    // 1. Ekstrak Judul (prioritaskan id/en lalu nilai pertama)
    final titleMap = attributes['title'] as Map<String, dynamic>? ?? {};
    String title = 'Tanpa Judul';
    if (titleMap.isNotEmpty) {
      title = (titleMap['id'] ?? titleMap['en'] ?? titleMap.values.first).toString();
    } else {
      final altTitles = attributes['altTitles'] as List<dynamic>?;
      if (altTitles != null && altTitles.isNotEmpty) {
        final firstAlt = altTitles.first as Map<String, dynamic>?;
        if (firstAlt != null && firstAlt.isNotEmpty) {
          title = firstAlt.values.first.toString();
        }
      }
    }

    // 2. Ekstrak Sinopsis
    final descMap = attributes['description'] as Map<String, dynamic>? ?? {};
    String description = 'Tidak ada sinopsis.';
    if (descMap.isNotEmpty) {
      description = (descMap['id'] ?? descMap['en'] ?? descMap.values.first).toString();
    }

    // 3. Ekstrak Status
    final status = attributes['status'] as String? ?? 'unknown';

    // 4. Ekstrak Tags
    final rawTags = attributes['tags'] as List<dynamic>? ?? [];
    final List<String> tags = [];
    for (final tag in rawTags) {
      if (tag is Map<String, dynamic>) {
        final tagAttr = tag['attributes'] as Map<String, dynamic>? ?? {};
        final nameMap = tagAttr['name'] as Map<String, dynamic>? ?? {};
        final name = nameMap['en'] ?? (nameMap.isNotEmpty ? nameMap.values.first : null);
        if (name != null) {
          tags.add(name.toString());
        }
      }
    }

    // 5. Ekstrak Cover Art & Author dari relationships
    String? coverUrl;
    String author = 'Tidak diketahui';

    final relationships = json['relationships'] as List<dynamic>? ?? [];
    for (final rel in relationships) {
      if (rel is Map<String, dynamic>) {
        final type = rel['type'] as String?;
        final relAttributes = rel['attributes'] as Map<String, dynamic>?;

        if (type == 'cover_art' && relAttributes != null) {
          final fileName = relAttributes['fileName'] as String?;
          if (fileName != null && fileName.isNotEmpty) {
            coverUrl = 'https://uploads.mangadex.org/covers/$id/$fileName.256.jpg';
          }
        } else if ((type == 'author' || type == 'artist') && relAttributes != null) {
          final authorName = relAttributes['name'] as String?;
          if (authorName != null && authorName.isNotEmpty) {
            author = authorName;
          }
        }
      }
    }

    return Manga(
      id: id,
      title: title,
      description: description,
      coverUrl: coverUrl,
      author: author,
      status: status,
      tags: tags,
    );
  }
}
