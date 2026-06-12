import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:dio/dio.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/core/services/notification_local_service.dart';
import 'package:safe/features/emergency/presentation/pages/sos_incoming_alert_page.dart';
import 'package:safe/core/services/navigation_service.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_countdown_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Top-level background handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Handling a background message: ${message.messageId}');
  await NotificationManager.saveLocalNotificationRecord(message);
  if (message.data['type'] == 'sos_alert') {
    final isOwn = await NotificationManager.isOwnSos(message.data);
    if (isOwn) {
      // Quietly show "SOS sent" notification instead of alarm sound
      await NotificationManager._showLocalNotification(message);
      return;
    }

    // Initialize notification channels/plugin settings in background isolate
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('ic_notification');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    await NotificationManager._localNotifications.initialize(initSettings);

    NotificationManager.startAlarm();
    await NotificationManager._showLocalNotification(message);

    // Save to SharedPreferences for auto-launch on resume
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_receiver_sos', jsonEncode(message.data));
      debugPrint('Saved pending receiver SOS to SharedPreferences');
    } catch (e) {
      debugPrint('Failed to save pending receiver SOS to SharedPreferences: $e');
    }

    // Force bring the app to the foreground immediately
    NotificationManager.bringAppToForeground();
  }
}

class NotificationManager {
  static const MethodChannel _appRetrieverChannel = MethodChannel('com.pbm.safe/app_retriever');
  static final AudioPlayer _audioPlayer = AudioPlayer();
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static bool _isAlarmPlaying = false;
  static Map<String, dynamic>? pendingSosData;
  static bool _hasCheckedLaunchNotification = false;

  static Future<bool> isOwnSos(Map<String, dynamic> data) async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData == null) return false;

      final myPhone = userData['phone_number']?.toString();
      final senderPhone = data['user_phone']?.toString();
      if (myPhone != null && senderPhone != null && myPhone.trim() == senderPhone.trim()) {
        return true;
      }

      final myId = userData['user_id']?.toString();
      final senderId = data['user_id']?.toString();
      if (myId != null && senderId != null && myId.trim() == senderId.trim()) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> saveLocalNotificationRecord(RemoteMessage message) async {
    try {
      final title = message.notification?.title ?? message.data['title'] ?? 'Notifikasi Baru';
      final body = message.notification?.body ?? message.data['body'] ?? 'Anda menerima pesan darurat baru.';
      var type = message.data['type'] ?? 'general';

      String finalTitle = title;
      String finalBody = body;
      if (type == 'sos_alert') {
        final isOwn = await isOwnSos(message.data);
        if (isOwn) {
          type = 'sos_sent';
          finalTitle = 'SOS Berhasil Terkirim';
          finalBody = 'Sinyal darurat Anda telah berhasil dikirim ke kontak darurat.';
        }
      }

      final localNotif = LocalNotification(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: finalTitle,
        body: finalBody,
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

      // 3. Request permissions (Commented out here, now requested after login on HomePage)
      /*
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
      */

      // 4. Initialize Local Notifications for Android Channels
      const AndroidInitializationSettings androidInit = AndroidInitializationSettings('ic_notification');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          stopAlarm();
          if (details.payload != null) {
            try {
              final Map<String, dynamic> data = Map<String, dynamic>.from(
                jsonDecode(details.payload!),
              );
              if (data['type'] == 'sos_alert') {
                navigateToSosAlert(data);
              } else if (data['type'] == 'sensor_countdown') {
                navigateToSensorCountdown(data);
              }
            } catch (e) {
              debugPrint('Error parsing notification response: $e');
            }
          }
        },
      );

      // Create Android Notification Channel for Emergency Calls
      final AndroidNotificationChannel channel = AndroidNotificationChannel(
        'emergency_call_channel_v5',
        'Panggilan Darurat (SOS)',
        description: 'Digunakan untuk menerima panggilan darurat SOS dengan prioritas tertinggi.',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Create Android Notification Channel for Sensor Countdown
      final AndroidNotificationChannel sensorChannel = AndroidNotificationChannel(
        'sensor_countdown_channel_v1',
        'Sensor Countdown Alert',
        description: 'Digunakan untuk menampilkan hitung mundur SOS dari sensor saat di latar belakang.',
        importance: Importance.max,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('alarm_sound'),
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
        enableLights: true,
        showBadge: true,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(sensorChannel);

      // Create Android Notification Channel for Live Location
      final AndroidNotificationChannel locationChannel = AndroidNotificationChannel(
        'safe_location_channel',
        'SAFE Pelacakan Aktif',
        description: 'Digunakan untuk menampilkan pembaruan lokasi penting.',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
        showBadge: false,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(locationChannel);

      // 5. Handle Foreground Messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Got a message in the foreground: ${message.messageId}');

        final isOwn = message.data['type'] == 'sos_alert' && await isOwnSos(message.data);

        // Save notification locally
        await saveLocalNotificationRecord(message);

        // Display local heads-up notification
        _showLocalNotification(message);

        if (message.data['type'] == 'sos_alert' && !isOwn) {
          startAlarm();
          navigateToSosAlert(message.data);
        }
      });

      // 6. Handle App Opened via Notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
        debugPrint('App opened via notification: ${message.messageId}');
        await saveLocalNotificationRecord(message);
        stopAlarm();
        final isOwn = message.data['type'] == 'sos_alert' && await isOwnSos(message.data);
        if (message.data['type'] == 'sos_alert' && !isOwn) {
          navigateToSosAlert(message.data);
        }
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
          stopAlarm();
          final isOwn = initialMessage.data['type'] == 'sos_alert' && await isOwnSos(initialMessage.data);
          if (initialMessage.data['type'] == 'sos_alert' && !isOwn) {
            navigateToSosAlert(initialMessage.data);
          }
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

    // Support data-only messages as well as notification messages
    var title = notification?.title ?? message.data['title'] ?? 'Panggilan Darurat';
    var body = notification?.body ?? message.data['body'] ?? 'Bantuan segera dibutuhkan';
    final type = message.data['type'] ?? 'general';

    final isOwn = type == 'sos_alert' && await isOwnSos(message.data);

    if (isOwn) {
      // Quietly show "SOS sent" notification instead of alarm sound
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'safe_location_channel',
        'SAFE Pelacakan Aktif',
        channelDescription: 'Digunakan untuk menampilkan pembaruan lokasi penting.',
        importance: Importance.high,
        priority: Priority.high,
        color: Color(0xFFC21A1A),
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
      );

      await _localNotifications.show(
        message.messageId.hashCode,
        'SOS Berhasil Terkirim',
        'Sinyal darurat Anda telah berhasil dikirim ke kontak darurat.',
        details,
        payload: jsonEncode(message.data),
      );
      return;
    }

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_call_channel_v5',
      'Panggilan Darurat (SOS)',
      channelDescription: 'Digunakan untuk menerima panggilan darurat SOS dengan prioritas tertinggi.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      additionalFlags: Int32List.fromList([4]),
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      color: const Color(0xFFC21A1A),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      message.messageId.hashCode,
      title,
      body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Navigates to SosIncomingAlertPage globally
  static void navigateToSosAlert(Map<String, dynamic> data) {
    if (SosIncomingAlertPage.isCurrentlyOpen) return;
    final context = NavigationService.navigatorKey.currentContext;
    if (context != null && NavigationService.navigatorKey.currentState != null) {
      NavigationService.navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => SosIncomingAlertPage(sosData: data),
        ),
      );
    } else {
      pendingSosData = data;
      debugPrint('Stashed pending SOS data since navigator is not ready');
    }
  }

  /// Checks if the app was launched by a local notification click or full-screen intent
  static Future<void> checkLaunchNotification() async {
    if (_hasCheckedLaunchNotification) return;
    _hasCheckedLaunchNotification = true;
    try {
      final NotificationAppLaunchDetails? launchDetails =
          await _localNotifications.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null) {
          final Map<String, dynamic> data = Map<String, dynamic>.from(jsonDecode(payload));
          final isOwn = data['type'] == 'sos_alert' && await isOwnSos(data);
          if (data['type'] == 'sos_alert' && !isOwn) {
            debugPrint('Found launch notification payload in checkLaunchNotification: $data');
            stopAlarm();
            navigateToSosAlert(data);
          } else if (data['type'] == 'sensor_countdown') {
            debugPrint('Found launch sensor countdown payload in checkLaunchNotification: $data');
            navigateToSensorCountdown(data);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking launch notification: $e');
    }
  }

  /// Displays a full-screen local notification to trigger the countdown page when in background
  static Future<void> showSensorCountdownNotification({
    required String reason,
    required String force,
  }) async {
    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'emergency_call_channel_v5',
      'Panggilan Darurat (SOS)',
      channelDescription: 'Digunakan untuk menerima panggilan darurat SOS dengan prioritas tertinggi.',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      ongoing: true,
      autoCancel: false,
      additionalFlags: Int32List.fromList([4]),
      visibility: NotificationVisibility.public,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('alarm_sound'),
      audioAttributesUsage: AudioAttributesUsage.alarm,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      color: const Color(0xFFC21A1A),
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      999, // Static ID for sensor countdown to prevent duplicate notifications
      'KEADAAN DARURAT TERDETEKSI',
      '$reason ($force). Ketuk untuk membatalkan SOS!',
      details,
      payload: jsonEncode({
        'type': 'sensor_countdown',
        'reason': reason,
        'force': force,
      }),
    );
  }

  /// Navigates to EmergencyCountdownPage globally
  static void navigateToSensorCountdown(Map<String, dynamic> data) {
    if (EmergencyCountdownPage.isCurrentlyOpen) return;
    final context = NavigationService.navigatorKey.currentContext;
    _localNotifications.cancel(999);
    if (context != null && NavigationService.navigatorKey.currentState != null) {
      NavigationService.navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => EmergencyCountdownPage(
            triggerReason: data['reason'],
            impactForce: data['force'],
            triggerType: 'auto',
          ),
        ),
      );
    } else {
      debugPrint('Stashed pending sensor countdown since navigator is not ready');
    }
  }

  /// Brings the app to the foreground using Draw Over Other Apps (Overlay) permission
  static Future<void> bringAppToForeground() async {
    try {
      await _appRetrieverChannel.invokeMethod('bringToForeground');
      debugPrint('Successfully invoked bringToForeground method channel');
    } catch (e) {
      debugPrint('Failed to bring app to foreground via method channel: $e');
    }
  }

  /// Checks if there are any stashed actions (sender countdown or receiver SOS) in SharedPreferences and routes them
  static Future<void> checkPendingActions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. Check for pending sensor countdown (sender)
      final pendingCountdown = prefs.getBool('pending_sensor_countdown') ?? false;
      if (pendingCountdown) {
        final reason = prefs.getString('pending_sensor_reason') ?? '';
        final force = prefs.getString('pending_sensor_force') ?? '';
        await prefs.remove('pending_sensor_countdown');
        await prefs.remove('pending_sensor_reason');
        await prefs.remove('pending_sensor_force');
        
        debugPrint('Found pending sensor countdown in SharedPreferences, navigating...');
        navigateToSensorCountdown({
          'reason': reason,
          'force': force,
        });
        return;
      }

      // 2. Check for pending receiver SOS
      final pendingSosStr = prefs.getString('pending_receiver_sos');
      if (pendingSosStr != null) {
        await prefs.remove('pending_receiver_sos');
        debugPrint('Found pending receiver SOS in SharedPreferences, navigating...');
        try {
          final data = Map<String, dynamic>.from(jsonDecode(pendingSosStr));
          navigateToSosAlert(data);
        } catch (e) {
          debugPrint('Error parsing pending receiver SOS: $e');
        }
      }
    } catch (e) {
      debugPrint('Error checking pending actions: $e');
    }
  }

  /// Starts playing the physical alarm sound at maximum volume in a loop
  static Future<void> startAlarm() async {
    if (_isAlarmPlaying) return;
    _isAlarmPlaying = true;
    try {
      // Set audio context to play as an Alarm on Android, bypassing DND
      await _audioPlayer.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            usageType: AndroidUsageType.alarm,
            contentType: AndroidContentType.sonification,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {
              AVAudioSessionOptions.duckOthers,
              AVAudioSessionOptions.defaultToSpeaker,
            },
          ),
        ),
      );

      await _audioPlayer.setVolume(1.0);
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);

      // Attempt to play local asset, fallback to a remote URL source if local file not found
      try {
        await _audioPlayer.play(AssetSource('sounds/alarm_sound.mp3'));
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
