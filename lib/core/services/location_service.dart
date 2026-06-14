import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'dart:typed_data';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/injection.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static String? activeSosId;

  /// Loads the persisted active SOS ID from local storage
  static Future<void> loadActiveSosId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = await SessionManager.getUserData();
      final userId = userData != null ? userData['user_id'] : null;
      if (userId != null) {
        activeSosId = prefs.getString('active_sos_id_$userId');
      } else {
        activeSosId = null;
      }
    } catch (_) {}
  }

  /// Saves or clears the active SOS ID in local storage and memory
  static Future<void> saveActiveSosId(String? id) async {
    activeSosId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = await SessionManager.getUserData();
      final userId = userData != null ? userData['user_id'] : null;
      if (userId != null) {
        if (id == null) {
          await prefs.remove('active_sos_id_$userId');
        } else {
          await prefs.setString('active_sos_id_$userId', id);
        }
      } else {
        // Fallback for global clear
        if (id == null) {
          await prefs.remove('active_sos_id');
        }
      }
    } catch (_) {}
  }

  /// Requests location permission and returns whether it is granted
  static Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Gets the current location once
  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      try {
        // Fallback to last known position if current position times out or fails
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Starts streaming real-time location and posting updates to the backend for an active SOS
  static Future<void> startTrackingSos(String sosId) async {
    // Cancel existing if any
    stopTrackingSos();

    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await saveActiveSosId(sosId);

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Send update when user moves 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        try {
          final dio = sl<Dio>();
          await dio.post(
            '/api/sos/$sosId/track',
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );
        } catch (_) {
          // Ignore network errors quietly during background stream
        }
      },
      onError: (_) {
        stopTrackingSos();
      },
    );
  }

  /// Stops tracking real-time location
  static void stopTrackingSos() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    saveActiveSosId(null);
  }

  /// Updates live location (24/7) to the backend
  static Future<void> updateLiveLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      final dio = sl<Dio>();
      await dio.put(
        '/api/location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
    } catch (_) {
      // Quiet fail if unable to update
    }
  }

  /// Inisialisasi background service untuk pelacakan 24/7
  static Future<void> initializeBackgroundService() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false, // Don't auto-start immediately to prevent crashes before permissions are granted
        isForegroundMode: true,
        initialNotificationTitle: 'SAFE Pelacakan Aktif',
        initialNotificationContent: 'SAFE berjalan di latar belakang untuk memantau lokasi.',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Note: Auto-starting here is removed to prevent ForegroundServiceStartNotAllowedException on Android 12+
    // when the app is initialized from a background event (like Firebase Cloud Messaging background notification).
    // The service is started dynamically and safely from the UI (HomePage) once permissions are verified in the foreground.
  }

  /// Menjalankan background service secara manual
  static Future<void> startBackgroundService() async {
    try {
      final service = FlutterBackgroundService();
      if (!await service.isRunning()) {
        await service.startService();
        debugPrint('Background service started manually.');
      }
    } catch (e) {
      debugPrint('Failed to start background service manually: $e');
    }
  }
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();

  StreamSubscription? gyroSub;
  StreamSubscription? accelSub;

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    gyroSub?.cancel();
    accelSub?.cancel();
    service.stopSelf();
  });

  // --- LOGIKA DETEKSI SENSOR DI LATAR BELAKANG ---
  double lastRotationRate = 0.0;
  DateTime? lastShakeTime;
  double shakeThreshold = 23.0;
  int shakeCount = 0;
  bool freefallDetected = false;
  DateTime? freefallTime;
  bool backgroundEmergencyTriggered = false;

  // 1. Monitor Gyroscope
  gyroSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval).listen((GyroscopeEvent event) {
    if (backgroundEmergencyTriggered) return;
    double x = event.x;
    double y = event.y;
    double z = event.z;
    lastRotationRate = math.sqrt(x * x + y * y + z * z);
  });

  // 2. Monitor Accelerometer
  accelSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((AccelerometerEvent event) async {
    if (backgroundEmergencyTriggered) return;

    double x = event.x;
    double y = event.y;
    double z = event.z;
    double magnitude = math.sqrt(x * x + y * y + z * z);

    // Cek apakah countdown sudah terpicu di sistem (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final isAlreadyCountdown = prefs.getBool('pending_sensor_countdown') ?? false;
    if (isAlreadyCountdown) return;

    // A. Deteksi Guncangan Keras (Shake)
    double accelerationExcludingGravity = (magnitude - 9.8).abs();
    if (accelerationExcludingGravity > shakeThreshold) {
      final now = DateTime.now();
      if (lastShakeTime == null || now.difference(lastShakeTime!) > const Duration(milliseconds: 250)) {
        if (lastShakeTime != null && now.difference(lastShakeTime!) < const Duration(seconds: 2)) {
          shakeCount++;
          if (shakeCount >= 4) {
            shakeCount = 0;
            backgroundEmergencyTriggered = true;
            await _triggerBackgroundEmergency(
              reason: "Severe Shake Detected",
              force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
              onReset: () {
                backgroundEmergencyTriggered = false;
              },
            );
          }
        } else {
          shakeCount = 1;
        }
        lastShakeTime = now;
      }
    }

    // B. Deteksi Free Fall (Jatuh Bebas)
    if (magnitude < 3.0) {
      freefallDetected = true;
      freefallTime = DateTime.now();
    }

    // C. Deteksi Tabrakan / Crash Impact
    if (magnitude > 28.0) {
      final now = DateTime.now();

      // Kasus 1: Jatuh bebas diikuti tabrakan keras dalam 1 detik
      if (freefallDetected && freefallTime != null) {
        if (now.difference(freefallTime!) < const Duration(milliseconds: 1000)) {
          freefallDetected = false;
          backgroundEmergencyTriggered = true;
          await _triggerBackgroundEmergency(
            reason: "Fall Detected",
            force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
            onReset: () {
              backgroundEmergencyTriggered = false;
            },
          );
          return;
        }
      }

      // Kasus 2: Gulingan/Crash (kecepatan rotasi gyro tinggi + benturan keras)
      if (magnitude > 38.0 && lastRotationRate > 12.0) {
        backgroundEmergencyTriggered = true;
        await _triggerBackgroundEmergency(
          reason: "Crash & Impact Detected",
          force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
          onReset: () {
            backgroundEmergencyTriggered = false;
          },
        );
        return;
      }

      // Kasus 3: Benturan Langsung Sangat Keras (>4.8 G)
      if (magnitude > 48.0) {
        backgroundEmergencyTriggered = true;
        await _triggerBackgroundEmergency(
          reason: "Severe Impact Detected",
          force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
          onReset: () {
            backgroundEmergencyTriggered = false;
          },
        );
        return;
      }
    }
  });

  // --- LOGIKA UPDATE LOKASI PERIODIK ---
  // Jalankan pelacakan setiap 5 menit
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "SAFE Pelacakan Aktif",
          content: "Lokasi Anda dipantau secara real-time demi keselamatan.",
        );
      }
    }

    await _updateBackgroundLocation();
  });

  // Lakukan update pertama saat servis dinyalakan
  await _updateBackgroundLocation();
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  await _updateBackgroundLocation();
  return true;
}

Future<void> _updateBackgroundLocation() async {
  try {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty && token != 'logged_in') {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://safe-backend-production-abb2.up.railway.app/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      await dio.put(
        '/api/location',
        data: {
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );
    }
  } catch (_) {
    // Quiet fail
  }
}

Future<void> _triggerBackgroundEmergency({
  required String reason,
  required String force,
  required VoidCallback onReset,
}) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    
    // Simpan tanda pending agar ketika user membuka aplikasi, UI langsung masuk halaman countdown
    await prefs.setBool('pending_sensor_countdown', true);
    await prefs.setString('pending_sensor_reason', reason);
    await prefs.setString('pending_sensor_force', force);

    // Tampilkan notifikasi darurat persisten tingkat tinggi (sirine menyala)
    await _showBackgroundCountdownNotification(reason, force);

    // Tunggu 15 detik countdown latar belakang untuk kirim SOS otomatis
    Timer(const Duration(seconds: 15), () async {
      final freshPrefs = await SharedPreferences.getInstance();
      final stillPending = freshPrefs.getBool('pending_sensor_countdown') ?? false;
      
      if (stillPending) {
        // Kirim sinyal SOS darurat otomatis ke server
        await _sendBackgroundSosTrigger(reason, force);
        
        // Hapus status pending
        await freshPrefs.remove('pending_sensor_countdown');
        await freshPrefs.remove('pending_sensor_reason');
        await freshPrefs.remove('pending_sensor_force');
      }

      onReset();
    });
  } catch (_) {
    onReset();
  }
}

Future<void> _sendBackgroundSosTrigger(String reason, String force) async {
  try {
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 8),
      );
    } catch (_) {
      try {
        position = await Geolocator.getLastKnownPosition();
      } catch (_) {}
    }

    if (position == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    if (token != null && token.isNotEmpty && token != 'logged_in') {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'https://safe-backend-production-abb2.up.railway.app/',
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );

      final response = await dio.post(
        '/api/sos/trigger',
        data: {
          'trigger_type': 'auto',
          'latitude': position.latitude,
          'longitude': position.longitude,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Tampilkan notifikasi sukses kirim SOS
        await _showBackgroundSosSentNotification();
      }
    }
  } catch (_) {}
}

Future<void> _showBackgroundCountdownNotification(String reason, String force) async {
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  
  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'sensor_countdown_channel_v1',
    'Sensor Countdown Alert',
    channelDescription: 'Digunakan untuk menampilkan hitung mundur SOS dari sensor saat di latar belakang.',
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

  await notifications.show(
    999,
    'KEADAAN DARURAT TERDETEKSI',
    'Sinyal SOS akan dikirim otomatis dalam 15 detik. Ketuk untuk membatalkan!',
    details,
    payload: jsonEncode({
      'type': 'sensor_countdown',
      'reason': reason,
      'force': force,
    }),
  );
}

Future<void> _showBackgroundSosSentNotification() async {
  final FlutterLocalNotificationsPlugin notifications = FlutterLocalNotificationsPlugin();
  
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

  await notifications.show(
    998,
    'SOS Terkirim Otomatis',
    'Sinyal darurat kecelakaan Anda telah berhasil dikirim ke kontak darurat.',
    details,
  );
}
