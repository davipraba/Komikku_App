import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service Singleton untuk menangani Notifikasi Lokal (Immediate & Scheduled) sesuai Modul 7 dan FR-NOTIF
class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'reminder_channel';
  static const String _channelName = 'Pengingat KomikKu';
  static const String _channelDescription =
      'Notifikasi jadwal membaca dan pengingat rilis chapter baru';

  /// Inisialisasi timezones, notifikasi Android, channel berprioritas tinggi, dan izin notifikasi
  Future<void> init() async {
    // 1. Inisialisasi Database Timezone
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {
      // Jika Asia/Jakarta tidak ditemukan, gunakan UTC/Default
    }

    // 2. Konfigurasi platform Android
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // 3. Buat Notification Channel (Importance High agar muncul sebagai pop-up / heads-up)
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      );

      await androidPlugin.createNotificationChannel(channel);

      // Minta izin notifikasi (wajib pada Android 13+)
      await androidPlugin.requestNotificationsPermission();

      // Minta izin exact alarm jika didukung (Android 12+)
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  /// Menampilkan notifikasi langsung / instant untuk pengujian (FR-NOTIF-02)
  Future<void> showInstantNotification({
    int id = 0,
    required String title,
    required String body,
  }) async {
    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    await _notificationsPlugin.show(id, title, body, details);
  }

  /// Menjadwalkan notifikasi pada tanggal dan jam tertentu (FR-NOTIF-03, FR-NOTIF-04)
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    final tzDate = tz.TZDateTime.from(scheduledDate, tz.local);
    final now = tz.TZDateTime.now(tz.local);

    // Jangan jadwalkan jika waktu target sudah lewat
    if (tzDate.isBefore(now)) return;

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tzDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Menjadwalkan pengingat harian pada jam tertentu (FR-NOTIF-06)
  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required TimeOfDay time,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Jika jam hari ini sudah lewat, jadwalkan mulai besok
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Membatalkan notifikasi terjadwal berdasarkan ID (FR-NOTIF-05)
  Future<void> cancel(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Membatalkan seluruh notifikasi
  Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }
}
