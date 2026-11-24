import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/favorite.dart';
import '../models/reminder.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';
import '../services/prefs_service.dart';
import '../services/supabase_service.dart';

/// Halaman Pengingat Baca Komik (FR-NOTIF)
/// Mengelola pengingat jadwal membaca (sekali atau harian) yang tersimpan di SQLite
/// dan dijadwalkan dengan flutter_local_notifications.
class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<Reminder> _reminders = [];
  List<Favorite> _favorites = [];
  bool _isLoading = true;

  String get _currentUserId =>
      PrefsService.userId ??
      SupabaseService.instance.currentUser?.id ??
      'local_user';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final reminders = await DatabaseHelper.instance.getReminders();
    final favorites = await DatabaseHelper.instance.getFavorites(_currentUserId);

    if (mounted) {
      setState(() {
        _reminders = reminders;
        _favorites = favorites;
        _isLoading = false;
      });
    }
  }

  /// Menjalankan notifikasi instan langsung untuk uji coba (FR-NOTIF-02)
  Future<void> _testInstantNotification() async {
    await NotificationService.instance.showInstantNotification(
      id: 9999,
      title: 'Waktunya Membaca Komik! 📖',
      body: 'Ini adalah notifikasi uji coba langsung dari KomikKu.',
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi uji coba dikirim! Periksa panel notifikasi Anda.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Menghapus reminder dan membatalkan jadwal notifikasinya (FR-NOTIF-05)
  Future<void> _deleteReminder(Reminder reminder) async {
    if (reminder.id != null) {
      // Batalkan alarm notifikasi di sistem Android
      await NotificationService.instance.cancel(reminder.id!);
      // Hapus data dari database SQLite
      await DatabaseHelper.instance.deleteReminder(reminder.id!);
    }
    _loadData();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pengingat untuk "${reminder.mangaTitle}" dibatalkan'),
      ),
    );
  }

  /// Menampilkan modal dialog formulir pembuatan pengingat baru (FR-NOTIF-03, FR-NOTIF-06)
  Future<void> _showAddReminderDialog() async {
    if (_favorites.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Belum Ada Komik Favorit'),
          content: const Text(
            'Untuk membuat pengingat membaca, tandai terlebih dahulu komik yang ingin Anda baca sebagai Favorit di halaman detail.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
      return;
    }

    Favorite selectedManga = _favorites.first;
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    bool repeatDaily = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedDate = DateFormat('EEEE, dd MMM yyyy').format(selectedDate);
            final formattedTime = selectedTime.format(context);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Row(
                    children: [
                      const Icon(Icons.alarm_add_rounded, color: Colors.deepOrange),
                      const SizedBox(width: 8),
                      Text(
                        'Buat Pengingat Baca',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Pilih Komik dari Favorit
                  const Text('Pilih Komik Favorit:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Favorite>(
                    initialValue: selectedManga,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _favorites.map((fav) {
                      return DropdownMenuItem<Favorite>(
                        value: fav,
                        child: Text(
                          fav.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedManga = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 2. Pilih Tanggal (jika bukan harian)
                  if (!repeatDaily) ...[
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                      ),
                      leading: const Icon(Icons.calendar_today_rounded),
                      title: const Text('Tanggal Pengingat'),
                      subtitle: Text(formattedDate),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedTime.hour,
                              selectedTime.minute,
                            );
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. Pilih Jam
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    leading: const Icon(Icons.access_time_rounded),
                    title: const Text('Waktu / Jam'),
                    subtitle: Text(formattedTime),
                    trailing: const Icon(Icons.more_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() {
                          selectedTime = picked;
                          selectedDate = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            picked.hour,
                            picked.minute,
                          );
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // 4. Checkbox Ulangi Harian (FR-NOTIF-06)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.repeat_rounded),
                    title: const Text('Ulangi Setiap Hari'),
                    subtitle: const Text('Kirim notifikasi setiap hari pada jam ini'),
                    value: repeatDaily,
                    onChanged: (val) {
                      setModalState(() => repeatDaily = val);
                    },
                  ),
                  const SizedBox(height: 20),

                  // 5. Tombol Simpan
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Simpan & Pasang Pengingat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final fullScheduledDateTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );

                      // Cek waktu jika bukan harian
                      if (!repeatDaily && fullScheduledDateTime.isBefore(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Waktu pengingat harus berada di masa depan.'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                        return;
                      }

                      final messenger = ScaffoldMessenger.of(context);

                      // Simpan data reminder ke SQLite
                      final reminder = Reminder(
                        mangaId: selectedManga.mangaId,
                        mangaTitle: selectedManga.title,
                        scheduledAt: fullScheduledDateTime.toIso8601String(),
                        repeatDaily: repeatDaily ? 1 : 0,
                      );

                      final newId = await DatabaseHelper.instance.addReminder(reminder);

                      // Jadwalkan notifikasi menggunakan ID baris SQLite (FR-NOTIF-04)
                      if (repeatDaily) {
                        await NotificationService.instance.scheduleDaily(
                          id: newId,
                          title: 'Waktunya Membaca: ${selectedManga.title}! 📚',
                          body: 'Saatnya melanjutkan petualangan komik favorit Anda.',
                          time: selectedTime,
                        );
                      } else {
                        await NotificationService.instance.scheduleNotification(
                          id: newId,
                          title: 'Waktunya Membaca: ${selectedManga.title}! 📚',
                          body: 'Jadwal membaca komik favorit Anda telah tiba.',
                          scheduledDate: fullScheduledDateTime,
                        );
                      }

                      if (!mounted) return;
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      _loadData();
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('Pengingat untuk "${selectedManga.title}" berhasil dipasang!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
          },
        );
      },
    );
  }

  String _formatReminderDate(String isoString, int repeatDaily) {
    try {
      final dt = DateTime.parse(isoString);
      if (repeatDaily == 1) {
        return 'Setiap hari pukul ${DateFormat('HH:mm').format(dt)}';
      }
      return DateFormat('EEEE, dd MMM yyyy • HH:mm').format(dt);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengingat Baca'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Tes Notifikasi Sekarang',
            onPressed: _testInstantNotification,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Banner Uji Coba Notifikasi
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Tekan ikon lonceng di atas untuk menguji notifikasi langsung.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),

                // Daftar Reminder Aktif
                Expanded(
                  child: _reminders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.alarm_off_rounded,
                                  size: 72,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Belum Ada Pengingat',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Jadwalkan pengingat baca agar Anda tidak melewatkan komik favorit.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: _showAddReminderDialog,
                                  icon: const Icon(Icons.add_alarm),
                                  label: const Text('Tambah Pengingat'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _reminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _reminders[index];
                            final isDaily = reminder.repeatDaily == 1;

                            return Card(
                              elevation: 1.5,
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isDaily
                                      ? Colors.blue.withValues(alpha: 0.15)
                                      : theme.colorScheme.primaryContainer,
                                  child: Icon(
                                    isDaily ? Icons.repeat : Icons.alarm,
                                    color: isDaily
                                        ? Colors.blue[700]
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                title: Text(
                                  reminder.mangaTitle,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _formatReminderDate(
                                    reminder.scheduledAt,
                                    reminder.repeatDaily,
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  color: theme.colorScheme.error,
                                  tooltip: 'Batalkan Pengingat',
                                  onPressed: () => _deleteReminder(reminder),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddReminderDialog,
        icon: const Icon(Icons.add_alarm_rounded),
        label: const Text('Tambah Pengingat'),
      ),
    );
  }
}
