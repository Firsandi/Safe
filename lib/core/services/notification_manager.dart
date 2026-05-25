import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/core/services/notification_local_service.dart';

// Top-level background handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  await NotificationManager.saveLocalNotificationRecord(message);
  if (message.data['type'] == 'sos_alert') {
    NotificationManager.startAlarm();
  }
}

class NotificationManager {
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isAlarmPlaying = false;

  static Future<void> saveLocalNotificationRecord(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? message.data['title'] ?? 'Notifikasi Baru';
      final body = message.notification?.body ?? message.data['body'] ?? 'Anda menerima pesan darurat baru.';
      final type = message.data['type'] ?? 'general';
      
      final localNotif = LocalNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
        payload: Map<String, dynamic>.from(message.data),
      );
      
      await NotificationLocalService.saveNotification(localNotif);
    } catch (e) {
      debugPrint('Failed to save local notification: $e');
    }
  }

  static Future<void> initialize() async {
    try {
      // 1. Initialize Firebase Core
      await Firebase.initializeApp();

      // 2. Setup Background Handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Request permissions (including Critical Alerts for iOS)
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Crucial for iOS DND bypass
        provisional: false,
        sound: true,
      );

      // 4. Initialize Local Notifications for Android Channels
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        requestCriticalPermission: true,
      );
      
      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          // Stop alarm when user clicks/taps the notification
          stopAlarm();
        },
      );

      // Create Android Notification Channel for Emergency
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_channel_id',
        'Panggilan Darurat',
        description: 'Digunakan untuk mengirimkan notifikasi darurat SOS dengan prioritas tertinggi.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        showBadge: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Got a message in the foreground: ${message.messageId}');
        
        // Save notification locally
        await saveLocalNotificationRecord(message);
        
        // Display local heads-up notification
        _showLocalNotification(message);

        if (message.data['type'] == 'sos_alert') {
          startAlarm();
        }
      });

      // 6. Handle App Opened via Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint('App opened via notification: ${message.messageId}');
        await saveLocalNotificationRecord(message);
        stopAlarm();
      });

      // 7. Token Refresh listener
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        uploadFcmToken(token);
      });

      // 8. Handle Initial Message (App launched from terminated state via notification click)
      try {
        final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
        if (initialMessage != null) {
          debugPrint('App launched via initial message: ${initialMessage.messageId}');
          await saveLocalNotificationRecord(initialMessage);
        }
      } catch (e) {
        debugPrint('Failed to get initial message: $e');
      }

    } catch (e) {
      debugPrint('Failed to initialize NotificationManager: $e');
    }
  }

  /// Uploads FCM Token to backend if logged in
  static Future<void> uploadFcmToken([String? explicitToken]) async {
    try {
      final isLoggedIn = await SessionManager.isLoggedIn();
      if (!isLoggedIn) return;

      final token = explicitToken ?? await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        final dio = sl<Dio>();
        await dio.put('/api/profile/fcm', data: {'fcm_token': token});
        debugPrint('Successfully uploaded FCM Token to backend');
      }
    } catch (e) {
      debugPrint('Failed to upload FCM Token: $e');
    }
  }

  /// Displays local notification on Android/iOS when app is in foreground
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_channel_id',
      'Panggilan Darurat',
      channelDescription: 'Digunakan untuk mengirimkan notifikasi darurat SOS dengan prioritas tertinggi.',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  /// Starts playing the physical alarm sound at maximum volume in a loop
  static Future<void> startAlarm() async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;
    try {
      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      
      // Attempt to play local asset, fallback to a remote URL source if local file not found
      try {
        await _audioPlayer.play(AssetSource('raw/alarm_sound.mp3'));
      } catch (_) {
        // Fallback to high-quality remote watch alarm sound for reliable out-of-the-box testing
        await _audioPlayer.play(UrlSource('https://actions.google.com/sounds/v1/alarms/digital_watch_alarm_long.ogg'));
      }
      debugPrint('Alarm started playing successfully');
    } catch (e) {
      _isAlarmPlaying = false;
      debugPrint('Failed to play alarm: $e');
    }
  }

  /// Stops the alarm sound
  static Future<void> stopAlarm() async {
    if (!_isAlarmPlaying) return;
    _isAlarmPlaying = false;
    try {
      await _audioPlayer.stop();
      debugPrint('Alarm stopped successfully');
    } catch (e) {
      debugPrint('Failed to stop alarm: $e');
    }
  }
}
