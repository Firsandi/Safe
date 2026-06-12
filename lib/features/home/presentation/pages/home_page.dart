import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:dio/dio.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/services/crash_detection_service.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_countdown_page.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_contacts_page.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_history_page.dart';
import 'package:safe/core/services/location_service.dart';
import 'package:safe/core/services/offline_sync_service.dart';
import '../widgets/sos_button.dart';
import '../widgets/navbar.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';
import 'package:safe/features/emergency/presentation/bloc/emergency_cubit.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/features/auth/presentation/pages/profile_page.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/features/auth/data/models/user_model.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/services/notification_local_service.dart';
import 'package:safe/features/home/presentation/pages/notification_page.dart';
import 'package:safe/features/home/presentation/pages/location_page.dart';
import 'package:safe/features/home/presentation/pages/language_page.dart';
import 'package:safe/features/home/presentation/pages/help_center_page.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geocoding/geocoding.dart';
import 'package:safe/features/home/presentation/pages/full_map_page.dart';
import 'package:safe/core/services/notification_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatefulWidget {
  final UserEntity user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late UserEntity _currentUser;
  int _currentIndex = 0;
  bool _isInit = false;
  static bool _hasPromptedProfile = false;
  final CrashDetectionService _crashDetection = CrashDetectionService();
  LatLng? _currentLocation;
  String _currentAddress = 'Mencari lokasi...';

  // Sensor Subscriptions and States
  StreamSubscription? _accelerometerSub;
  StreamSubscription? _gyroscopeSub;
  double _lastRotationRate = 0.0;
  DateTime? _lastShakeTime;
  final double _shakeThreshold = 23.0; // Increased from 15.0 to reduce sensitivity
  int _shakeCount = 0;

  bool _freefallDetected = false;
  DateTime? _freefallTime;
  bool _isEmergencyTriggered = false;
  DateTime? _lastCancelledTime;

  // Real-time Statistics
  int _activeContactsCount = 0;
  int _sosHistoryCount = 0;
  int _unreadNotificationCount = 0;
  int _historyInitialTabIndex = 0;
  int _contactsInitialTabIndex = 0;
  StreamSubscription<int>? _unreadNotificationsSubscription;

  // Permissions check state
  bool _hasLocationPermission = true;
  bool _hasNotificationPermission = true;
  bool _hasOverlayPermission = true;
  bool _hasDndPermission = true;
  bool _hasBatteryBypassPermission = true;
  bool _checkingPermissions = true;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.user;
    _loadUserFromSession();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsState().then((_) {
      if (mounted && (!_hasLocationPermission || !_hasNotificationPermission || !_hasOverlayPermission || !_hasDndPermission || !_hasBatteryBypassPermission)) {
        _requestPermissions();
      }
    });

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isInit = true);
    });
    _startSensorMonitoring();
    _loadStats();
    _loadUnreadNotificationCount();
    _syncNotificationsFromServer();
    _unreadNotificationsSubscription = NotificationLocalService.unreadCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    });
    _syncActiveSosState(); // Check and synchronize active SOS event

    // Register callback for background sync success
    OfflineSyncService.onSyncSuccess = () {
      if (mounted) {
        setState(() {});
        _loadStats();
        _loadUnreadNotificationCount();
      }
    };
    // Start background sync loop
    OfflineSyncService.startSyncLoop(context);
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await NotificationLocalService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadNotificationCount = count;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserFromSession() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null && mounted) {
        setState(() {
          _currentUser = UserModel.fromJson(userData);
        });
        _checkProfileCompletion();
      }
    } catch (_) {}
  }

  void _checkProfileCompletion() {
    if (_hasPromptedProfile) return;

    // Only show if all permissions are granted (permission request screen is gone)
    if (_checkingPermissions || !_hasLocationPermission || !_hasNotificationPermission || !_hasOverlayPermission || !_hasDndPermission) {
      return;
    }

    final phone = _currentUser.phoneNumber.trim();
    final blood = _currentUser.bloodType;

    if (phone.isEmpty || blood == null || blood.trim().isEmpty) {
      _hasPromptedProfile = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Lengkapi Profil',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              content: const Text(
                'Silakan lengkapi profil Anda agar fitur penyelamatan darurat dapat berjalan optimal.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textGrey,
                  height: 1.4,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Nanti',
                    style: TextStyle(
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => ProfilePage(
                          user: _currentUser,
                          showEditForm: true,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOutCubic;
                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    ).then((_) {
                      _loadUserFromSession();
                    });
                  },
                  child: const Text(
                    'Lengkapi',
                    style: TextStyle(
                      color: AppColors.primaryRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      });
    }
  }

  Future<void> _navigateToNotifications() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NotificationPage()),
    );

    _loadUnreadNotificationCount();

    if (result != null && result is Map) {
      final action = result['action'];
      if (action == 'go_to_history') {
        final tabIndex = result['tab'] ?? 0;
        setState(() {
          _currentIndex = 2; // Riwayat SOS
          _historyInitialTabIndex = tabIndex;
        });
      } else if (action == 'go_to_contacts') {
        final tabIndex = result['tab'] ?? 0;
        setState(() {
          _currentIndex = 1; // Kontak darurat
          _contactsInitialTabIndex = tabIndex;
        });
      }
    }
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    l10n.settings,
                    style: AppTextStyles.heading.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language, color: Color(0xFF193855)),
                    ),
                    title: Text(
                      l10n.settingsLanguage,
                      style: AppTextStyles.subHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      l10n.settingsLanguageSub,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LanguagePage()),
                      );
                    },
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.help_outline, color: Color(0xFF193855)),
                    ),
                    title: Text(
                      l10n.settingsHelp,
                      style: AppTextStyles.subHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      l10n.settingsHelpSub,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpCenterPage()),
                      );
                    },
                  ),
                   const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.battery_saver, color: Color(0xFF193855)),
                    ),
                    title: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'Background Tracking'
                          : 'Pelacakan Latar Belakang',
                      style: AppTextStyles.subHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'Optimize battery bypass for 24/7 safety'
                          : 'Bypass penghemat baterai untuk keselamatan 24/7',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      _requestBatteryOptimizationBypass(context);
                    },
                  ),
                  const Divider(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.info_outline, color: AppColors.primaryRed),
                    ),
                    title: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'About SAFE'
                          : 'Tentang SAFE',
                      style: AppTextStyles.subHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: Text(
                      Localizations.localeOf(context).languageCode == 'en'
                          ? 'Application details and system info'
                          : 'Detail aplikasi dan info sistem',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _requestBatteryOptimizationBypass(BuildContext context) async {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final isIgnoring = await Permission.ignoreBatteryOptimizations.isGranted;

    if (isIgnoring) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEn ? 'Already Configured' : 'Sudah Aktif'),
          content: Text(isEn 
              ? 'SAFE is already configured to bypass battery optimization. 24/7 background tracking is active.'
              : 'Aplikasi SAFE sudah diatur untuk mengabaikan penghemat baterai. Pelacakan latar belakang berjalan normal.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: AppColors.primaryRed)),
            )
          ],
        ),
      );
      return;
    }

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isEn ? 'Background Optimization' : 'Optimasi Latar Belakang'),
        content: Text(isEn
            ? 'To monitor emergency location 24/7 when the app is closed, you need to disable battery optimization for SAFE.\n\nAfter clicking "Grant", please select "Allow" or "Unrestricted" in the system dialog.'
            : 'Untuk dapat memantau lokasi darurat 24 jam saat aplikasi ditutup, Anda perlu mematikan penghemat baterai untuk SAFE.\n\nSetelah menekan "Izinkan", pilih "Izinkan" atau "Tidak Dibatasi" pada dialog sistem HP Anda.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isEn ? 'Cancel' : 'Batal', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final status = await Permission.ignoreBatteryOptimizations.request();
              if (!status.isGranted) {
                // Open app settings as fallback if request is denied or unsupported directly
                await openAppSettings();
              }
            },
            child: Text(isEn ? 'Grant' : 'Izinkan', style: const TextStyle(color: AppColors.primaryRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final isEn = Localizations.localeOf(context).languageCode == 'en';
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            isEn ? 'About SAFE' : 'Tentang SAFE',
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 64,
                color: AppColors.primaryRed,
              ),
              const SizedBox(height: 16),
              const Text(
                'SAFE App',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF193855),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'v1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEn
                    ? 'SAFE is a secure, real-time emergency monitoring system equipped with automated impact detection and offline cueing logic.'
                    : 'SAFE adalah sistem pemantauan darurat real-time aman yang dilengkapi dengan deteksi benturan otomatis dan logika antrean offline.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[800],
                  height: 1.4,
                ),
              ),
              const Divider(height: 32),
              Text(
                '© 2026 SAFE Project. All Rights Reserved.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                isEn ? 'Close' : 'Tutup',
                style: const TextStyle(
                  color: Color(0xFF193855),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _syncActiveSosState() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/api/sos/active');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data['active'] == true && data['sos_id'] != null) {
          final sosId = data['sos_id'].toString();
          await LocationService.saveActiveSosId(sosId);
          LocationService.startTrackingSos(sosId);
        } else {
          await LocationService.saveActiveSosId(null);
          LocationService.stopTrackingSos();
        }
      }
    } catch (e) {
      // Offline fallback: load local persisted state
      await LocationService.loadActiveSosId();
      if (LocationService.activeSosId != null) {
        LocationService.startTrackingSos(LocationService.activeSosId!);
      }
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadStats() async {
    try {
      final dio = sl<Dio>();
      
      // Fetch contacts count
      final contactsRes = await dio.get('/api/contacts');
      final contactsList = contactsRes.data['contacts'] as List?;
      final activeContacts = contactsList?.where((c) => c['status'] == 'Tersambung').length ?? 0;

      // Fetch history count
      final historyRes = await dio.get('/api/sos/history/sent');
      final historyList = historyRes.data as List?;
      final historyCount = historyList?.length ?? 0;

      if (mounted) {
        setState(() {
          _activeContactsCount = activeContacts;
          _sosHistoryCount = historyCount;
        });
      }
    } catch (_) {
      // Quietly ignore
    }
  }

  Future<void> _syncNotificationsFromServer() async {
    try {
      final dio = sl<Dio>();
      
      // Parallel fetches for sync
      final results = await Future.wait([
        dio.get('/api/contacts/requests'),
        dio.get('/api/sos/history/received'),
        dio.get('/api/contacts'),
        dio.get('/api/sos/history/sent'),
      ]);
      
      final requestsData = results[0].data['requests'] as List?;
      final receivedSosData = results[1].data as List?;
      final contactsData = results[2].data['contacts'] as List?;
      final sentSosData = results[3].data as List?;
      
      if (contactsData != null) {
        await NotificationLocalService.syncConnectionTimestamps(contactsData);
      }
      
      final connectionTimestamps = await NotificationLocalService.getConnectionTimestamps();
      final List<LocalNotification> newNotifs = [];

      if (requestsData != null && requestsData.isNotEmpty) {
        final notifications = await NotificationLocalService.loadNotifications();
        for (final req in requestsData) {
          final reqId = req['id']?.toString() ?? '';
          if (reqId.isEmpty) continue;
          final notifId = 'contact_req_$reqId';
          final exists = notifications.any((n) => n.id == notifId);
          if (!exists) {
            newNotifs.add(LocalNotification(
              id: notifId,
              title: 'Permintaan Kontak Darurat',
              body: '${req['name'] ?? 'Seseorang'} ingin menambahkan Anda sebagai kontak darurat.',
              type: 'contact_request',
              timestamp: DateTime.now(),
              isRead: false,
            ));
          }
        }
      }
      
      if (receivedSosData != null && receivedSosData.isNotEmpty) {
        final notifications = await NotificationLocalService.loadNotifications();
        for (final item in receivedSosData) {
          final status = item['status']?.toString() ?? '';
          if (status != 'active') continue; // Skip resolved/past SOS events to prevent notification flooding
          
          final sosId = item['sos_id']?.toString() ?? '';
          if (sosId.isEmpty) continue;
          
          // Skip if it's our own SOS
          final contactUserId = item['user_id']?.toString() ?? '';
          if (contactUserId == _currentUser.userId) continue;

          // Check if event occurred after becoming friends
          final connectionTimeStr = connectionTimestamps[contactUserId];
          if (connectionTimeStr != null) {
            final connectionTime = DateTime.parse(connectionTimeStr);
            final eventTime = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
            if (eventTime.isBefore(connectionTime)) {
              // The event occurred before we became friends
              continue;
            }
          } else {
            // If contact is not in our active contacts list, skip
            continue;
          }
          
          final notifId = 'sos_event_$sosId';
          final exists = notifications.any((n) => n.id == notifId || (n.payload != null && n.payload!['sos_id']?.toString() == sosId));
          if (!exists) {
             final title = item['trigger_type'] == 'auto'
                ? 'EMERGENCY: BENTURAN/KECELAKAAN TERDETEKSI!'
                : 'EMERGENCY: BUTUH BANTUAN SEGERA!';
            final name = item['user_name'] ?? item['name'] ?? 'Seseorang';
            final triggerLabel = item['trigger_type'] == 'auto' ? 'Sensor Otomatis' : 'Manual';
            
            newNotifs.add(LocalNotification(
              id: notifId,
              title: title,
              body: '$name mengalami keadaan darurat ($triggerLabel)! Segera periksa lokasi.',
              type: 'sos_alert',
              timestamp: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              isRead: false,
              payload: Map<String, dynamic>.from(item),
            ));
          }
        }
      }

      if (sentSosData != null && sentSosData.isNotEmpty) {
        final notifications = await NotificationLocalService.loadNotifications();
        for (final item in sentSosData) {
          final sosId = item['sos_id']?.toString() ?? '';
          if (sosId.isEmpty) continue;
          
          final notifId = 'sos_sent_$sosId';
          final exists = notifications.any((n) => n.id == notifId || (n.payload != null && n.payload!['sos_id']?.toString() == sosId && n.type == 'sos_sent'));
          if (!exists) {
            newNotifs.add(LocalNotification(
              id: notifId,
              title: 'SOS Berhasil Terkirim',
              body: 'Sinyal darurat Anda telah berhasil dikirim ke kontak darurat.',
              type: 'sos_sent',
              timestamp: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              isRead: false,
              payload: Map<String, dynamic>.from(item),
            ));
          }
        }
      }

      if (newNotifs.isNotEmpty) {
        await NotificationLocalService.saveNotifications(newNotifs);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _unreadNotificationsSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    OfflineSyncService.onSyncSuccess = null;
    OfflineSyncService.stopSyncLoop();
    super.dispose();
  }

  void _startSensorMonitoring() {
    // 1. Gyroscope to measure angular velocity (tumbling/rotation rate)
    _gyroscopeSub = gyroscopeEventStream(samplingPeriod: SensorInterval.uiInterval).listen((GyroscopeEvent event) {
      if (_isEmergencyTriggered) return;

      double x = event.x;
      double y = event.y;
      double z = event.z;
      // Calculate rotation rate magnitude in rad/s
      _lastRotationRate = math.sqrt(x * x + y * y + z * z);
    });

    // 2. Accelerometer to measure linear acceleration forces (including gravity)
    _accelerometerSub = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval).listen((AccelerometerEvent event) {
      if (_isEmergencyTriggered) return;

      double x = event.x;
      double y = event.y;
      double z = event.z;
      
      // Calculate total acceleration magnitude (including gravity, normally around 9.8 m/s^2)
      double magnitude = math.sqrt(x * x + y * y + z * z);

      // --- SHAKE DETECTION ---
      // Measure change excluding gravity
      double accelerationExcludingGravity = (magnitude - 9.8).abs();
      if (accelerationExcludingGravity > _shakeThreshold) {
        final now = DateTime.now();
        // Debounce shake events
        if (_lastShakeTime == null || now.difference(_lastShakeTime!) > const Duration(milliseconds: 250)) {
          if (_lastShakeTime != null && now.difference(_lastShakeTime!) < const Duration(seconds: 2)) {
            _shakeCount++;
            if (_shakeCount >= 4) {
              _shakeCount = 0;
              if (!mounted) return;
              _triggerEmergencyFromSensor(
                reason: AppLocalizations.of(context)?.severeShakeDetected ?? "Severe Shake Detected",
                force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
              );
            }
          } else {
            _shakeCount = 1;
          }
          _lastShakeTime = now;
        }
      }

      // --- FALL / CRASH DETECTION ---
      // Step A: Detect Free Fall (magnitude drops close to 0 m/s^2)
      if (magnitude < 3.0) {
        _freefallDetected = true;
        _freefallTime = DateTime.now();
      }

      // Step B: Detect Impact (magnitude spikes high)
      if (magnitude > 28.0) {
        final now = DateTime.now();
        
        // 1. Classic Fall: free fall followed shortly by a high impact
        if (_freefallDetected && _freefallTime != null) {
          if (now.difference(_freefallTime!) < const Duration(milliseconds: 1000)) {
            _freefallDetected = false;
            if (!mounted) return;
            _triggerEmergencyFromSensor(
              reason: AppLocalizations.of(context)?.fallDetected ?? "Fall Detected",
              force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
            );
            return;
          }
        }

        // 2. Tumbling/Crash: high rotation rate (gyroscope) combined with high impact force (both thresholds raised for calibration)
        if (magnitude > 38.0 && _lastRotationRate > 12.0) {
          if (!mounted) return;
          _triggerEmergencyFromSensor(
            reason: AppLocalizations.of(context)?.crashImpactDetected ?? "Crash & Impact Detected",
            force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
          );
          return;
        }

        // 3. Direct Severe Impact: extremely high acceleration force (>4.8 G, raised from 3.5 G)
        if (magnitude > 48.0) {
          if (!mounted) return;
          _triggerEmergencyFromSensor(
            reason: AppLocalizations.of(context)?.severeImpactDetected ?? "Severe Impact Detected",
            force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
          );
          return;
        }
      }
    });
  }

  void _triggerEmergencyFromSensor({required String reason, required String force}) async {
    if (EmergencyCountdownPage.isCurrentlyOpen) return;
    if (_isEmergencyTriggered) return;

    // Check if we are in a cooldown period (30 seconds after cancellation)
    if (_lastCancelledTime != null &&
        DateTime.now().difference(_lastCancelledTime!) < const Duration(seconds: 30)) {
      debugPrint('Sensor trigger ignored due to active cancellation cooldown');
      return;
    }

    // Check if the app is in the background (inactive/paused/detached)
    final isBackground = WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed;

    if (isBackground) {
      // Save to SharedPreferences for auto-launch on resume
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('pending_sensor_countdown', true);
        await prefs.setString('pending_sensor_reason', reason);
        await prefs.setString('pending_sensor_force', force);
        debugPrint('Saved pending sensor countdown to SharedPreferences');
      } catch (e) {
        debugPrint('Failed to save pending sensor countdown: $e');
      }
      
      setState(() => _isEmergencyTriggered = true);

      if (!mounted) return;
      // Push the route immediately so that it is active when the activity resumes
      if (!EmergencyCountdownPage.isCurrentlyOpen) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmergencyCountdownPage(
              triggerReason: reason,
              impactForce: force,
              triggerType: 'auto',
            ),
          ),
        ).then((result) {
          // Reset trigger flag when returning from countdown page
          setState(() => _isEmergencyTriggered = false);
          if (result == 'cancelled') {
            _lastCancelledTime = DateTime.now();
          }
          _loadStats(); // reload statistics
        });
      }

      NotificationManager.showSensorCountdownNotification(reason: reason, force: force);
      NotificationManager.bringAppToForeground();
      return;
    }

    setState(() => _isEmergencyTriggered = true);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyCountdownPage(
          triggerReason: reason,
          impactForce: force,
          triggerType: 'auto',
        ),
      ),
    ).then((result) {
      // Reset trigger flag when returning from countdown page
      setState(() => _isEmergencyTriggered = false);
      if (result == 'cancelled') {
        _lastCancelledTime = DateTime.now();
      }
      _loadStats(); // reload statistics
    });
  }

  Widget _getBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return BlocProvider(
          create: (_) => sl<EmergencyCubit>(),
          child: EmergencyContactsPage(
            initialTabIndex: _contactsInitialTabIndex,
            key: ValueKey('contacts_page_$_contactsInitialTabIndex'),
          ),
        );
      case 2:
        return EmergencyHistoryPage(
          initialTabIndex: _historyInitialTabIndex,
          key: ValueKey('history_page_$_historyInitialTabIndex'),
        );
      case 3:
        return const LocationPage();
      case 4:
        return ProfilePage(user: _currentUser);
      default:
        return _buildHomeContent();
    }
  }



  @override
  Widget build(BuildContext context) {
    if (_checkingPermissions) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );
    }

    if (!_hasLocationPermission || !_hasNotificationPermission || !_hasOverlayPermission || !_hasDndPermission || !_hasBatteryBypassPermission) {
      return _buildPermissionRequestScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: SafeNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 2) {
              _historyInitialTabIndex = 0; // reset to default tab
            }
          });
          _loadUserFromSession();
          if (index == 0) {
            _loadStats();
            _loadUnreadNotificationCount();
          }
        },
      ),
      body: SafeArea(child: _getBody()),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          _buildAnimated(index: 0, child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SAFE',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryRed,
                    letterSpacing: 1.2,
                  ),
                ),
                Row(children: [
                  IconButton(
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none, color: AppColors.textDark),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primaryRed,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: _navigateToNotifications,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
                    onPressed: () => _showSettingsBottomSheet(context),
                  ),
                ]),
              ],
            ),
          )),

          // ACTIVE SOS BANNER (only shown if location tracking is currently active)
          _buildActiveSosBanner(),

          // GREETING & BADGE
          _buildAnimated(
            index: 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.helloUser(_currentUser.name),
                    style: AppTextStyles.heading.copyWith(
                      color: AppColors.primaryRed,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // SOS BUTTON
          _buildAnimated(index: 2, child: SosButton(
            onLongPress: () => _triggerEmergency(context), label: '', subLabel: '')),
          const SizedBox(height: 16),

          // INSTRUCTION
          _buildAnimated(index: 3, child: Center(
            child: Text(AppLocalizations.of(context)!.helpSentToLocation,
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14)))),
          const SizedBox(height: 32),

          // MENU GRID (Two cards)
          _buildAnimated(
            index: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMenuCard(
                      title: AppLocalizations.of(context)!.emergencyContactsTitle,
                      subtitle: AppLocalizations.of(context)!.activeContactsCount(_activeContactsCount),
                      subtitleColor: AppColors.primaryRed,
                      icon: Icons.contact_phone_outlined,
                      iconBgColor: const Color(0xFFEDF4FE),
                      iconColor: const Color(0xFF193855),
                      onTap: () {
                        setState(() => _currentIndex = 1);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMenuCard(
                      title: AppLocalizations.of(context)!.historySos,
                      subtitle: AppLocalizations.of(context)!.sosHistoryCount(_sosHistoryCount),
                      subtitleColor: AppColors.textDark,
                      icon: Icons.history,
                      iconBgColor: AppColors.primaryRed.withOpacity(0.1),
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        setState(() {
                          _currentIndex = 2;
                          _historyInitialTabIndex = 0; // reset to default tab
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // MAP PANEL
          _buildAnimated(
            index: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () {
                  if (_currentLocation != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullMapPage(initialLocation: _currentLocation!),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey[800],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                  child: Stack(
                    children: [
                      if (_currentLocation != null)
                        FlutterMap(
                          options: MapOptions(
                            initialCenter: _currentLocation!,
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.example.safe',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _currentLocation!,
                                  width: 40,
                                  height: 40,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      Container(
                                        width: 16,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        const Center(
                          child: CircularProgressIndicator(color: AppColors.primaryRed),
                        ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: AppColors.textDark,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _currentAddress,
                                  style: AppTextStyles.subHeading.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAnimated({required int index, required Widget child}) {
    return AnimatedOpacity(
      duration: Duration(milliseconds: 500 + (index * 100)),
      opacity: _isInit ? 1.0 : 0.0,
      child: AnimatedPadding(
        duration: Duration(milliseconds: 500 + (index * 100)),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.only(top: _isInit ? 0 : 20),
        child: child,
      ),
    );
  }

  Widget _buildMenuCard({
    required String title, required String subtitle, required Color subtitleColor,
    required IconData icon, required Color iconBgColor, required Color iconColor, required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: AppTextStyles.subHeading.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.subHeading.copyWith(
                    color: subtitleColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveSosBanner() {
    if (LocationService.activeSosId == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const _BlinkingLocationIcon(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.sosActiveBanner,
                  style: AppTextStyles.subHeading.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)!.sendingRealtimeLocation,
                  style: AppTextStyles.subHeading.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _resolveActiveSos,
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              AppLocalizations.of(context)!.turnOff,
              style: AppTextStyles.subHeading.copyWith(
                color: const Color(0xFFEF4444),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveActiveSos() async {
    final sosId = LocationService.activeSosId;
    if (sosId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      ),
    );

    try {
      final dio = sl<Dio>();
      await dio.post('/api/sos/$sosId/resolve', data: {
        'status': 'resolved',
      });

      LocationService.stopTrackingSos();

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        _loadStats();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sosDisabledSuccess),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sosDisableFailed(e.toString())),
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  void _triggerEmergency(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyCountdownPage()),
    );
    // If cancelled, start cooldown on crash detection service
    if (result == 'cancelled') {
      _crashDetection.startCooldown();
      _lastCancelledTime = DateTime.now();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionsState();
      NotificationManager.checkPendingActions();
    }
  }

  Future<void> _checkPermissionsState() async {
    try {
      // 1. Cek izin lokasi (tanpa mengharuskan GPS aktif)
      final locPermission = await Geolocator.checkPermission();
      final locGranted = locPermission == LocationPermission.always ||
          locPermission == LocationPermission.whileInUse;

      // 2. Cek izin notifikasi
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final notifGranted = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      // 3. Cek izin overlay (draw over other apps)
      final overlayGranted = await Permission.systemAlertWindow.isGranted;

      // 4. Cek izin akses jangan ganggu (DND)
      final dndGranted = await Permission.accessNotificationPolicy.isGranted;

      // 5. Cek izin battery optimization bypass
      final batteryBypassGranted = await Permission.ignoreBatteryOptimizations.isGranted;

      if (mounted) {
        setState(() {
          _hasLocationPermission = locGranted;
          _hasNotificationPermission = notifGranted;
          _hasOverlayPermission = overlayGranted;
          _hasDndPermission = dndGranted;
          _hasBatteryBypassPermission = batteryBypassGranted;
          _checkingPermissions = false;
        });
        if (locGranted) {
          _loadCurrentLocation();
          LocationService.startBackgroundService();
        }
        _checkProfileCompletion();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingPermissions = false);
      }
    }
  }

  Future<void> _loadCurrentLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      _fetchAddress(pos.latitude, pos.longitude);
    } else if (mounted) {
      // Default location if failed
      setState(() {
        _currentLocation = const LatLng(-8.1691, 113.7020); // Jember
        _currentAddress = 'Lokasi tidak ditemukan';
      });
    }
  }

  Future<void> _fetchAddress(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> parts = [];
        final street = place.street ?? '';
        if (street.isNotEmpty) parts.add(street);
        final subLocality = place.subLocality ?? '';
        if (subLocality.isNotEmpty && subLocality != street) parts.add(subLocality);
        final locality = place.locality ?? '';
        if (locality.isNotEmpty) parts.add(locality);
        final subAdmin = place.subAdministrativeArea ?? '';
        if (subAdmin.isNotEmpty) parts.add(subAdmin);
        final admin = place.administrativeArea ?? '';
        if (admin.isNotEmpty && admin != subAdmin) parts.add(admin);
        
        final address = parts.isNotEmpty ? parts.join(', ') : 'Lokasi ditemukan';

        if (mounted) {
          setState(() {
            _currentAddress = address;
          });
        }
        return;
      }
    } catch (e) {
      // Fallback to OpenStreetMap Nominatim API if Geocoder throws (e.g. no Play Services)
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'format': 'json',
            'lat': lat,
            'lon': lng,
            'zoom': 14,
            'addressdetails': 1,
          },
        );
        if (response.statusCode == 200 && response.data != null) {
          final addressData = response.data['address'];
          if (addressData != null) {
            final road = addressData['road'] ?? addressData['pedestrian'] ?? '';
            final suburb = addressData['suburb'] ?? addressData['neighbourhood'] ?? addressData['village'] ?? '';
            final city = addressData['city'] ?? addressData['town'] ?? addressData['county'] ?? '';
            final state = addressData['state'] ?? '';
            
            final parts = <String>[];
            if (road.isNotEmpty) parts.add(road.toString());
            if (suburb.isNotEmpty) parts.add(suburb.toString());
            if (city.isNotEmpty) parts.add(city.toString());
            if (state.isNotEmpty) parts.add(state.toString());
            
            final address = parts.isNotEmpty ? parts.join(', ') : (response.data['display_name'] ?? 'Lokasi ditemukan');

            if (mounted) {
              setState(() {
                _currentAddress = address;
              });
            }
            return;
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _currentAddress = 'Gagal memuat alamat';
      });
    }
  }

  Future<void> _requestPermissions() async {
    // 1. Minta izin lokasi secara langsung via Geolocator
    var locPermissionStatus = await Geolocator.checkPermission();
    if (locPermissionStatus == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }
    if (locPermissionStatus == LocationPermission.denied) {
      locPermissionStatus = await Geolocator.requestPermission();
      if (locPermissionStatus == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        return;
      }
      if (locPermissionStatus == LocationPermission.denied) {
        // User denied location, stop execution and refresh UI
        await _checkPermissionsState();
        return;
      }
    }
    
    // Add a delay to allow the activity to resume fully before requesting the next permission
    await Future.delayed(const Duration(milliseconds: 1000));

    // 2. Minta izin notifikasi menggunakan permission_handler
    var notifStatus = await Permission.notification.status;
    if (!notifStatus.isGranted) {
      notifStatus = await Permission.notification.request();
    }

    // Jika notifikasi diizinkan, langsung unggah token ke backend
    if (notifStatus.isGranted) {
      await NotificationManager.uploadFcmToken();
    }

    // Add a delay to allow the activity to resume fully before requesting overlay permission
    await Future.delayed(const Duration(milliseconds: 1000));

    // 3. Minta izin overlay (draw over other apps)
    var overlayStatus = await Permission.systemAlertWindow.status;
    if (!overlayStatus.isGranted) {
      overlayStatus = await Permission.systemAlertWindow.request();
    }

    // Add a delay to allow the activity to resume fully before requesting DND permission
    await Future.delayed(const Duration(milliseconds: 1000));

    // 4. Minta izin akses jangan ganggu (DND)
    var dndStatus = await Permission.accessNotificationPolicy.status;
    if (!dndStatus.isGranted) {
      dndStatus = await Permission.accessNotificationPolicy.request();
    }

    // Add a delay to allow the activity to resume fully before requesting battery bypass permission
    await Future.delayed(const Duration(milliseconds: 1000));

    // 5. Minta izin ignoreBatteryOptimizations
    var batteryBypassStatus = await Permission.ignoreBatteryOptimizations.status;
    if (!batteryBypassStatus.isGranted) {
      batteryBypassStatus = await Permission.ignoreBatteryOptimizations.request();
      if (!batteryBypassStatus.isGranted) {
        // Fallback: open app settings
        await openAppSettings();
      }
    }

    await _checkPermissionsState();
  }

  Widget _buildPermissionRequestScreen() {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        // Premium Concentric Circles with Shield Icon
                        Center(
                          child: SizedBox(
                            height: 220,
                            width: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer circle 1
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.inputBorder.withOpacity(0.4), width: 1.5),
                                  ),
                                ),
                                // Outer circle 2
                                Container(
                                  width: 170,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: AppColors.inputBorder.withOpacity(0.8), width: 1.5),
                                  ),
                                ),
                                // Glowing center circle
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryRed.withOpacity(0.35),
                                        blurRadius: 30,
                                        spreadRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.security_outlined,
                                      color: Colors.white,
                                      size: 52,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 36),
                        // Title
                        Text(
                          l10n.permissionRequiredTitle,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading.copyWith(
                            color: AppColors.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Description
                        Text(
                          l10n.permissionRequiredDesc,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subHeading.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        // List of permissions missing
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                          decoration: BoxDecoration(
                            color: AppColors.inputBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.inputBorder, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildPermissionStatusRow(
                                icon: Icons.location_on_outlined,
                                title: l10n.locationTitle,
                                isGranted: _hasLocationPermission,
                              ),
                              Divider(height: 28, color: AppColors.inputBorder.withOpacity(0.6)),
                              _buildPermissionStatusRow(
                                icon: Icons.notifications_none_outlined,
                                title: l10n.notificationsTitle,
                                isGranted: _hasNotificationPermission,
                              ),
                              Divider(height: 28, color: AppColors.inputBorder.withOpacity(0.6)),
                              _buildPermissionStatusRow(
                                icon: Icons.layers_outlined,
                                title: Localizations.localeOf(context).languageCode == 'en'
                                    ? 'Display Over Other Apps'
                                    : 'Tampilkan di Atas Aplikasi Lain',
                                isGranted: _hasOverlayPermission,
                              ),
                              Divider(height: 28, color: AppColors.inputBorder.withOpacity(0.6)),
                              _buildPermissionStatusRow(
                                icon: Icons.do_not_disturb_on_outlined,
                                title: Localizations.localeOf(context).languageCode == 'en'
                                    ? 'Access Do Not Disturb (DND)'
                                    : 'Akses Jangan Ganggu (DND)',
                                isGranted: _hasDndPermission,
                              ),
                              Divider(height: 28, color: AppColors.inputBorder.withOpacity(0.6)),
                              _buildPermissionStatusRow(
                                icon: Icons.battery_saver,
                                title: Localizations.localeOf(context).languageCode == 'en'
                                    ? 'Background Tracking (Bypass Battery)'
                                    : 'Pelacakan Latar Belakang (Bypass Baterai)',
                                isGranted: _hasBatteryBypassPermission,
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Instruction
                        Text(
                          l10n.openSettingsInstruction,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.footer.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _requestPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 3,
                              shadowColor: AppColors.primaryRed.withOpacity(0.3),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  l10n.allowPermissionsButton,
                                  style: AppTextStyles.buttonPrimary,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward_rounded, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPermissionStatusRow({
    required IconData icon,
    required String title,
    required bool isGranted,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isGranted ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isGranted ? const Color(0xFF2E7D32) : AppColors.primaryRed,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            title,
            style: AppTextStyles.subHeading.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: AppColors.textDark,
            ),
          ),
        ),
        Icon(
          isGranted ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: isGranted ? const Color(0xFF2E7D32) : AppColors.primaryRed,
          size: 24,
        ),
      ],
    );
  }
}

class _BlinkingLocationIcon extends StatefulWidget {
  const _BlinkingLocationIcon();

  @override
  State<_BlinkingLocationIcon> createState() => _BlinkingLocationIconState();
}

class _BlinkingLocationIconState extends State<_BlinkingLocationIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_controller),
      child: const Icon(
        Icons.location_on,
        color: Colors.white,
        size: 28,
      ),
    );
  }
}

class BreathingDot extends StatefulWidget {
  const BreathingDot({super.key});
  @override
  State<BreathingDot> createState() => _BreathingDotState();
}

class _BreathingDotState extends State<BreathingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _animation,
      child: const Icon(Icons.circle, color: Color(0xFF22C55E), size: 10));
  }
}

class MockMapPainter extends CustomPainter {
  const MockMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Background Grid
    final gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1.0;

    const double step = 20.0;
    for (double i = 0; i < size.width; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += step) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }

    // Abstract roads
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw main roads
    final roadPath1 = Path()
      ..moveTo(0, size.height * 0.4)
      ..lineTo(size.width, size.height * 0.6);

    final roadPath2 = Path()
      ..moveTo(size.width * 0.35, 0)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.5, size.width * 0.7, size.height);

    canvas.drawPath(roadPath1, roadBorderPaint);
    canvas.drawPath(roadPath1, roadPaint);

    canvas.drawPath(roadPath2, roadBorderPaint);
    canvas.drawPath(roadPath2, roadPaint);

    // Glowing location circle indicator
    final centerPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.15) // Red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 24.0, centerPaint);

    final innerPaint = Paint()
      ..color = const Color(0xFFEF4444).withOpacity(0.3) // Red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.45), 12.0, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
