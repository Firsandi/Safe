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
import 'package:safe/l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  final UserEntity user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isInit = false;
  final CrashDetectionService _crashDetection = CrashDetectionService();

  // Sensor Subscriptions and States
  StreamSubscription? _accelerometerSub;
  StreamSubscription? _gyroscopeSub;

  DateTime? _lastShakeTime;
  final double _shakeThreshold = 15.0;
  int _shakeCount = 0;

  bool _freefallDetected = false;
  DateTime? _freefallTime;
  double _lastRotationRate = 0.0;
  bool _isEmergencyTriggered = false;

  // Real-time Statistics
  int _activeContactsCount = 0;
  int _sosHistoryCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isInit = true);
    });
    _startSensorMonitoring();
    _loadStats();

    // Register callback for background sync success
    OfflineSyncService.onSyncSuccess = () {
      if (mounted) {
        setState(() {});
        _loadStats();
      }
    };
    // Start background sync loop
    OfflineSyncService.startSyncLoop(context);
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

  @override
  void dispose() {
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
              _triggerEmergencyFromSensor(
                reason: "Guncangan Keras Terdeteksi",
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
            _triggerEmergencyFromSensor(
              reason: "Jatuh Terdeteksi",
              force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
            );
            return;
          }
        }

        // 2. Tumbling/Crash: high rotation rate (gyroscope) combined with high impact force
        if (_lastRotationRate > 7.0) {
          _triggerEmergencyFromSensor(
            reason: "Tabrakan & Benturan Terdeteksi",
            force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
          );
          return;
        }

        // 3. Direct Severe Impact: extremely high acceleration force (>3.5 G)
        if (magnitude > 35.0) {
          _triggerEmergencyFromSensor(
            reason: "Benturan Keras Terdeteksi",
            force: "${(magnitude / 9.8).toStringAsFixed(1)} G",
          );
          return;
        }
      }
    });
  }

  void _triggerEmergencyFromSensor({required String reason, required String force}) {
    if (_isEmergencyTriggered) return;
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
    ).then((_) {
      // Reset trigger flag when returning from countdown page
      setState(() => _isEmergencyTriggered = false);
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
          child: const EmergencyContactsPage(),
        );
      case 2:
        return const EmergencyHistoryPage();
      case 3:
        return _buildPlaceholderPage(AppLocalizations.of(context)!.locationTitle, Icons.location_on_outlined);
      case 4:
        return ProfilePage(user: widget.user);
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppColors.textGrey),
          const SizedBox(height: 16),
          Text(title, style: AppTextStyles.heading.copyWith(color: AppColors.textDark)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.notAvailableYet,
            style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      bottomNavigationBar: SafeNavbar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            _loadStats();
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
                Image.asset('assets/images/logo.png', height: 50,
                  errorBuilder: (c, e, s) => const Icon(Icons.shield, color: AppColors.primaryRed, size: 34)),
                Row(children: [
                  IconButton(icon: const Icon(Icons.notifications_none, color: AppColors.textDark), onPressed: () {}),
                  IconButton(icon: const Icon(Icons.settings_outlined, color: AppColors.textDark), onPressed: () {}),
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
                    'Halo, ${widget.user.name}',
                    style: AppTextStyles.heading.copyWith(
                      color: AppColors.primaryRed,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BreathingDot(),
                        const SizedBox(width: 8),
                        Text(
                          'Sensor Aktif — memantau',
                          style: AppTextStyles.inputLabel.copyWith(
                            color: AppColors.textGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                      title: 'Kontak darurat',
                      subtitle: '$_activeContactsCount aktif',
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
                      title: 'Riwayat SOS',
                      subtitle: '$_sosHistoryCount kejadian',
                      subtitleColor: AppColors.textDark,
                      icon: Icons.history,
                      iconBgColor: AppColors.primaryRed.withOpacity(0.1),
                      iconColor: AppColors.primaryRed,
                      onTap: () {
                        setState(() => _currentIndex = 2);
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
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  children: [
                    // Mock Map Pattern via CustomPaint
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CustomPaint(
                          painter: const MockMapPainter(),
                        ),
                      ),
                    ),
                    // Location Badge Overlay
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, color: AppColors.textDark, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Sumbersari, Jember',
                              style: AppTextStyles.subHeading.copyWith(
                                color: AppColors.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
                  'SOS AKTIF',
                  style: AppTextStyles.subHeading.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mengirimkan lokasi real-time Anda...',
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
              'Matikan',
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
          const SnackBar(
            content: Text('SOS berhasil dinonaktifkan'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menonaktifkan SOS: ${e.toString()}'),
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
    }
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
