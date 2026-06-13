import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool isInitialized = false;

  Future<void> init() async {
    if (isInitialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('Timezone could not be set: $e');
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');

    // iOS ayarları gerekliyse eklenebilir. Şimdilik Android odaklı ilerliyoruz.
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Bildirime tıklandığında yapılacak işlemler.
      },
    );

    isInitialized = true;
    await syncActiveNotificationsToHistory();
    await cleanTestNotificationsFromHistory();
    // Sabit zamanlı planlamalar kaldırıldı, SmartNotificationService kullanılıyor.
    await checkPendingNotifications();
  }

  Future<void> checkPendingNotifications() async {
    final pendingList = await flutterLocalNotificationsPlugin
        .pendingNotificationRequests();
    debugPrint('Pending notifications count: ${pendingList.length}');
    for (var req in pendingList) {
      debugPrint(' - Pending: id=${req.id}, title=${req.title}');
    }
  }

  Future<void> saveNotificationToHistory(
    String title,
    String body,
    DateTime time, {
    String type = 'Genel',
  }) async {
    // Release modda test bildirimlerini kaydetme
    if (!kDebugMode &&
        (title.contains('Test') ||
            body.contains('(Test)') ||
            body.contains('Bildirim sistemi çalışıyor'))) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('notification_history') ?? [];

    final notification = {
      'title': title,
      'body': body,
      'time': time.toIso8601String(),
      'type': type,
      'isRead': false,
    };

    final notifJson = jsonEncode(notification);
    // Don't add if already exists (basic duplicate check)
    bool exists = history.any((item) {
      final map = jsonDecode(item);
      return map['title'] == title &&
          map['body'] == body &&
          DateTime.parse(map['time']).difference(time).inMinutes.abs() < 5;
    });

    if (!exists) {
      history.insert(0, notifJson);
      if (history.length > 50) history.removeLast();
      await prefs.setStringList('notification_history', history);
    }
  }

  /// Uygulama açılışında test kayıtlarını temizler (one-time).
  Future<void> cleanTestNotificationsFromHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final alreadyCleaned = prefs.getBool('test_notifications_cleaned') ?? false;
    if (alreadyCleaned) return;

    List<String> history = prefs.getStringList('notification_history') ?? [];
    final originalLength = history.length;

    history.removeWhere((item) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        final title = (map['title'] as String?) ?? '';
        final body = (map['body'] as String?) ?? '';
        final type = (map['type'] as String?) ?? '';
        return title.contains('Test') ||
            body.contains('(Test)') ||
            body.contains('Bildirim sistemi çalışıyor') ||
            type == 'Test';
      } catch (_) {
        return false;
      }
    });

    if (history.length != originalLength) {
      await prefs.setStringList('notification_history', history);
      debugPrint(
        'Cleaned ${originalLength - history.length} test notifications from history.',
      );
    }
    await prefs.setBool('test_notifications_cleaned', true);
  }

  Future<int> getUnreadNotificationCount() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('notification_history') ?? [];
    int unreadCount = 0;
    int testFilteredCount = 0;

    for (var item in history) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;

        final title = (map['title'] as String?) ?? '';
        final body = (map['body'] as String?) ?? '';
        final type = (map['type'] as String?) ?? '';

        if (title.contains('Test') ||
            body.contains('(Test)') ||
            body.contains('Bildirim sistemi çalışıyor') ||
            type == 'Test') {
          testFilteredCount++;
          continue;
        }

        final isRead = map['isRead'] as bool? ?? false;
        if (!isRead) {
          unreadCount++;
        }
      } catch (_) {}
    }

    debugPrint(
      'Notification unread count:\n - totalHistoryCount: ${history.length}\n - unreadCount: $unreadCount\n - testFilteredCount: $testFilteredCount\n - markAllAsReadCalled: false\n - badgeUpdated: false',
    );
    return unreadCount;
  }

  Future<void> markAllNotificationsAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('notification_history') ?? [];
    List<String> updatedHistory = [];

    for (var item in history) {
      try {
        final map = jsonDecode(item) as Map<String, dynamic>;
        map['isRead'] = true;
        map['read_at'] = DateTime.now().toIso8601String();
        updatedHistory.add(jsonEncode(map));
      } catch (_) {
        updatedHistory.add(item);
      }
    }

    await prefs.setStringList('notification_history', updatedHistory);
    debugPrint(
      'Notification unread count:\n - markAllAsReadCalled: true\n - badgeUpdated: true',
    );
  }

  Future<void> syncActiveNotificationsToHistory() async {
    try {
      final List<ActiveNotification>? activeNotifications =
          await flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.getActiveNotifications();

      if (activeNotifications != null) {
        for (var notification in activeNotifications) {
          if (notification.title != null) {
            await saveNotificationToHistory(
              notification.title!,
              notification.body ?? '',
              DateTime.now(),
              type: 'Sistem',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Sync active notifications error: $e');
    }
  }

  Future<void> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidImplementation?.requestNotificationsPermission();
  }

  Future<void> cancelNotification(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id: id);
  }

  Future<void> showTestNotification() async {
    if (!kDebugMode) return;
    debugPrint('Test bildirimi gönderiliyor...');
    try {
      await flutterLocalNotificationsPlugin.show(
        id: 999,
        title: 'ChefRay',
        body: 'Bildirim sistemi çalışıyor 💧',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'chefray_notifications',
            'ChefRay Bildirimleri',
            channelDescription:
                'ChefRay su, diyet, hareket ve analiz bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
          ),
        ),
      );
      await saveNotificationToHistory(
        'ChefRay',
        'Bildirim sistemi çalışıyor 💧',
        DateTime.now(),
        type: 'Test',
      );
      debugPrint('Test bildirimi gönderildi.');
    } catch (e) {
      debugPrint('Test notification error: $e');
    }
  }

  Future<void> scheduleTestNotificationAfterOneMinute() async {
    if (!kDebugMode) return;
    debugPrint(
      'Scheduling 1 minute test notification (Smart Notification simülasyonu için korundu)...',
    );
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    final tz.TZDateTime scheduledDate = now.add(const Duration(minutes: 1));

    debugPrint('Test notification scheduled at $scheduledDate');

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        id: 9999, // Test schedule id
        title: 'Test Zamanlanmış Bildirim ⏱️',
        body: 'Bu bildirim tam 1 dakika sonra geldi!',
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'chefray_notifications',
            'ChefRay Bildirimleri',
            channelDescription:
                'ChefRay su, diyet, hareket ve analiz bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@drawable/ic_notification',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      await checkPendingNotifications();
    } catch (e) {
      debugPrint('Schedule test notification error: $e');
    }
  }

  Future<void> showLocalNotification(
    String? title,
    String? body, {
    String? payload,
    String type = 'FCM',
  }) async {
    try {
      await flutterLocalNotificationsPlugin.show(
        id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title: title ?? 'ChefRay',
        body: body ?? '',
        payload: payload,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'chefray_notifications',
            'ChefRay Bildirimleri',
            channelDescription:
                'ChefRay su, diyet, hareket ve analiz bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            enableVibration: true,
            icon: '@drawable/ic_notification',
          ),
        ),
      );
      await saveNotificationToHistory(
        title ?? 'ChefRay',
        body ?? '',
        DateTime.now(),
        type: type,
      );
    } catch (e) {
      debugPrint('Local notification error: $e');
    }
  }
}
