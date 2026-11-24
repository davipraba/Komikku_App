/// Model data Genre/Tag dari MangaDex
class GenreTag {
  final String id;
  final String name;
  final String group;

  const GenreTag({
    required this.id,
    required this.name,
    this.group = 'genre',
  });

  factory GenreTag.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] as Map<String, dynamic>? ?? {};
    final nameMap = attributes['name'] as Map<String, dynamic>? ?? {};
    final name = nameMap['en'] ?? (nameMap.isNotEmpty ? nameMap.values.first : 'Umum');

    return GenreTag(
      id: json['id'] as String? ?? '',
      name: name.toString(),
      group: attributes['group'] as String? ?? 'genre',
    );
  }
}
