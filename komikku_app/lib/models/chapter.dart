/// Model data Chapter dari MangaDex
class Chapter {
  final String id;
  final String chapterNumber;
  final String title;
  final String language;
  final int pages;
  final String? publishAt;

  const Chapter({
    required this.id,
    required this.chapterNumber,
    required this.title,
    required this.language,
    required this.pages,
    this.publishAt,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};

    final rawChapter = attributes['chapter'] as String?;
    final chapterNumber = (rawChapter != null && rawChapter.isNotEmpty)
        ? rawChapter
        : '0';

    final title = attributes['title'] as String? ?? '';
    final language = attributes['translatedLanguage'] as String? ?? 'en';
    final pages = attributes['pages'] as int? ?? 0;
    final publishAt = attributes['publishAt'] as String?;

    return Chapter(
      id: json['id'] as String? ?? '',
      chapterNumber: chapterNumber,
      title: title,
      language: language,
      pages: pages,
      publishAt: publishAt,
    );
  }

  /// Menampilkan judul tampilan chapter (misal: "Chapter 10: Kebangkitan" atau "Chapter 10")
  String get displayTitle {
    if (title.isNotEmpty) {
      return 'Ch. $chapterNumber - $title';
    }
    return 'Chapter $chapterNumber';
  }
}
