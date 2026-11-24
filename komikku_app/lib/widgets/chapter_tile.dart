import 'package:flutter/material.dart';
import '../models/chapter.dart';

/// Widget Tile untuk menampilkan item daftar chapter komik
class ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final VoidCallback onTap;

  const ChapterTile({
    super.key,
    required this.chapter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isIndo = chapter.language.toLowerCase() == 'id';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        title: Text(
          chapter.displayTitle,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            // Badge Bahasa
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isIndo
                    ? Colors.red.withValues(alpha: 0.15)
                    : Colors.blue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isIndo ? 'IND' : chapter.language.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isIndo ? Colors.red[700] : Colors.blue[700],
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (chapter.pages > 0)
              Text(
                '${chapter.pages} Halaman',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        trailing: const Icon(
          Icons.chevron_right,
          size: 20,
        ),
      ),
    );
  }
}
