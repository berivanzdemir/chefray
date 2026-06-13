import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_service.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Arka planda gelen FCM mesajlarını işleyen top-level fonksiyon.
/// Bu fonksiyon sınıf dışında tanımlanmalıdır (Firebase gereksinimi).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('═══════════════════════════════════════════════════════');
  debugPrint('🔔 FCM ARKA PLAN MESAJI ALINDI');
  debugPrint('   messageId: ${message.messageId}');
  debugPrint('   title: ${message.notification?.title}');
  debugPrint('   body: ${message.notification?.body}');
  debugPrint('═══════════════════════════════════════════════════════');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static FcmService get instance => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// ChefRay bildirim kanalı — Android bildirim panelinde görünecek.
  static const AndroidNotificationChannel _chefrayChannel =
      AndroidNotificationChannel(
        'chefray_notifications',
        'ChefRay Bildirimleri',
        description: 'ChefRay uygulama bildirimleri',
        importance: Importance.high,
      );

  /// FCM varsayılan kanal (AndroidManifest.xml ile eşleşir).
  static const AndroidNotificationChannel _fcmDefaultChannel =
      AndroidNotificationChannel(
        'fcm_default_channel',
        'Genel Bildirimler',
        description: 'Firebase Cloud Messaging bildirimleri',
        importance: Importance.high,
      );

  /// FCM servisini başlatır. main() içinden çağrılmalıdır.
  Future<void> init() async {
    if (_isInitialized) return;

    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🚀 FCM SERVİSİ BAŞLATILIYOR...');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      // 1. Arka plan mesaj işleyicisini kaydet
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );
      debugPrint('✅ Arka plan mesaj işleyicisi kaydedildi');

      // 2. Yerel bildirim eklentisini başlat
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 Yerel bildirime tıklandı: ${response.payload}');
        },
      );
      debugPrint('✅ Yerel bildirim eklentisi başlatıldı');

      // 3. Android bildirim kanallarını oluştur
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(_chefrayChannel);
        await androidPlugin.createNotificationChannel(_fcmDefaultChannel);
        debugPrint('✅ Bildirim kanalları oluşturuldu');
      }

      // 4. Ön plandayken gelen mesajları dinle
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      debugPrint('✅ Ön plan mesaj dinleyicisi kaydedildi');

      // 5. Bildirime tıklanarak uygulama açıldığında
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 6. Uygulama kapalıyken bildirime tıklanarak açıldıysa
      final RemoteMessage? initialMessage = await _messaging
          .getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📩 Uygulama bildirimden açıldı: ${initialMessage.data}');
        _handleMessageOpenedApp(initialMessage);
      }

      // 7. Token yenilenme dinleyicisi
      _messaging.onTokenRefresh.listen((newToken) async {
        if (kDebugMode) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint(
            '🔄 FCM TOKEN YENİLENDİ: ...${newToken.length > 10 ? newToken.substring(newToken.length - 10) : newToken}',
          );
          debugPrint('═══════════════════════════════════════════════════════');
        }
        await _saveTokenToSupabase(newToken);
      });
      debugPrint('✅ Token yenilenme dinleyicisi kaydedildi');

      _isInitialized = true;
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('✅ FCM SERVİSİ BAŞARIYLA BAŞLATILDI');
      debugPrint('═══════════════════════════════════════════════════════');
    } catch (e, st) {
      debugPrint('❌ FCM servis başlatma hatası: $e');
      debugPrint('   Stack trace: $st');
    }
  }

  /// Android bildirim izni iste + FCM token al.
  /// Bu metot hem FirebaseMessaging hem de flutter_local_notifications
  /// üzerinden izin ister (Android 13+ için gerekli).
  Future<String?> requestPermissionAndGetToken() async {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔐 BİLDİRİM İZNİ İSTENİYOR...');
    debugPrint('═══════════════════════════════════════════════════════');

    try {
      // ── 1. Firebase Messaging izni ─────────────────────────────────
      final NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('📋 Firebase izin durumu: ${settings.authorizationStatus}');

      // ── 2. Android yerel bildirim izni (Android 13+ POST_NOTIFICATIONS) ──
      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final bool? granted = await androidPlugin
            .requestNotificationsPermission();
        debugPrint('📋 Android POST_NOTIFICATIONS izni: $granted');
      }

      // ── 3. İzin durumunu logla ─────────────────────────────────────
      final status = settings.authorizationStatus;
      switch (status) {
        case AuthorizationStatus.authorized:
          debugPrint('✅ Bildirim izni VERİLDİ (authorized)');
          break;
        case AuthorizationStatus.provisional:
          debugPrint('⚠️ Bildirim izni GEÇİCİ (provisional)');
          break;
        case AuthorizationStatus.denied:
          debugPrint('❌ Bildirim izni REDDEDİLDİ (denied)');
          debugPrint('   Kullanıcı ayarlardan manuel olarak açabilir.');
          break;
        case AuthorizationStatus.notDetermined:
          debugPrint('❓ Bildirim izni BELİRLENMEDİ (notDetermined)');
          break;
      }

      // ── 4. FCM Token al ────────────────────────────────────────────
      final String? token = await _messaging.getToken();

      if (kDebugMode) {
        debugPrint('═══════════════════════════════════════════════════════');
        debugPrint(
          '🎫 FCM TOKEN: ...${token != null && token.length > 10 ? token.substring(token.length - 10) : token}',
        );
        debugPrint('═══════════════════════════════════════════════════════');
      }

      if (token != null) {
        await _saveTokenToSupabase(token);
      }

      return token;
    } catch (e, st) {
      debugPrint('❌ İzin/token hatası: $e');
      debugPrint('   Stack trace: $st');
      return null;
    }
  }

  /// Mevcut izin durumunu kontrol et (popup göstermeden).
  Future<AuthorizationStatus> checkPermissionStatus() async {
    final settings = await _messaging.getNotificationSettings();
    debugPrint('📋 Mevcut bildirim izni: ${settings.authorizationStatus}');
    return settings.authorizationStatus;
  }

  /// Debug/test amaçlı yerel bildirim göster.
  Future<void> showTestNotification() async {
    debugPrint('🧪 Test bildirimi gönderiliyor...');
    try {
      await _localNotifications.show(
        id: 9999,
        title: 'ChefRay 🍳',
        body: 'Bildirim sistemi çalışıyor 💧',
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'chefray_notifications',
            'ChefRay Bildirimleri',
            channelDescription: 'ChefRay uygulama bildirimleri',
            icon: '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
      debugPrint('✅ Test bildirimi gönderildi');
    } catch (e) {
      debugPrint('❌ Test bildirimi hatası: $e');
    }
  }

  /// Ön planda gelen FCM mesajlarını işle — yerel bildirim göster.
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('📩 FCM ÖN PLAN MESAJI ALINDI');
    debugPrint('   title: ${message.notification?.title}');
    debugPrint('   body: ${message.notification?.body}');
    debugPrint('═══════════════════════════════════════════════════════');

    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    NotificationService().showLocalNotification(
      notification.title,
      notification.body,
    );
  }

  /// Bildirime tıklanarak uygulama açıldığında.
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('👆 BİLDİRİME TIKLANARAK UYGULAMA AÇILDI');
    debugPrint('   data: ${message.data}');
    debugPrint('═══════════════════════════════════════════════════════');
    // İleride deep link / navigasyon mantığı buraya eklenebilir.
  }

  /// Alınan FCM token'ı Supabase'e kaydeder.
  Future<void> _saveTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        debugPrint('FCM Token kayıt atlandı: Kullanıcı giriş yapmamış.');
        return;
      }

      final platformStr = Platform.isAndroid
          ? 'android'
          : (Platform.isIOS ? 'ios' : 'unknown');

      if (kDebugMode) {
        debugPrint('FCM token alındı mı?: Evet');
        debugPrint('userId var mı?: Evet (${user.id})');
        debugPrint('Supabase user_fcm_tokens tablosuna kayıt başlatılıyor...');
      }

      await Supabase.instance.client.from('user_fcm_tokens').upsert({
        'user_id': user.id,
        'token': token,
        'platform': platformStr,
        'device_id': null, // cihaz id kütüphanesi olmadığı için şimdilik null
        'is_active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'token');

      if (kDebugMode) {
        debugPrint("Supabase'e kayıt başarılı mı?: Evet");
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM Token Supabase kayıt hatası detayları: $e');
      }
    }
  }

  /// Kullanıcı çıkış yaptığında mevcut token'ı pasif duruma getirir.
  Future<void> deactivateCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        if (kDebugMode) {
          debugPrint('Çıkış yapılıyor: Mevcut token pasife alınıyor...');
        }
        await Supabase.instance.client
            .from('user_fcm_tokens')
            .update({'is_active': false})
            .eq('token', token);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Token pasife alma hatası: $e');
      }
    }
  }
}
