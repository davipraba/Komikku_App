/// Model data Pengingat Baca Komik (SRS 2.5.1, FR-NOTIF)
class Reminder {
  final int? id; // ID ini juga digunakan sebagai id notifikasi lokal
  final String mangaId;
  final String mangaTitle;
  final String scheduledAt; // ISO8601 string
  final int repeatDaily; // 0: sekali, 1: berulang harian

  const Reminder({
    this.id,
    required this.mangaId,
    required this.mangaTitle,
    required this.scheduledAt,
    this.repeatDaily = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'manga_id': mangaId,
      'manga_title': mangaTitle,
      'scheduled_at': scheduledAt,
      'repeat_daily': repeatDaily,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      mangaId: map['manga_id'] as String? ?? '',
      mangaTitle: map['manga_title'] as String? ?? '',
      scheduledAt: map['scheduled_at'] as String? ?? '',
      repeatDaily: map['repeat_daily'] as int? ?? 0,
    );
  }
}
