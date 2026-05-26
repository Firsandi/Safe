import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/services/location_service.dart';
import 'package:safe/core/services/offline_sync_service.dart';

class EmergencyCountdownPage extends StatefulWidget {
  final String? triggerReason;
  final String? impactForce;
  final String triggerType;
  const EmergencyCountdownPage({
    super.key,
    this.triggerReason,
    this.impactForce,
    this.triggerType = 'manual',
  });

  @override
  State<EmergencyCountdownPage> createState() => _EmergencyCountdownPageState();
}

class _EmergencyCountdownPageState extends State<EmergencyCountdownPage>
    with TickerProviderStateMixin {
  static const int _totalSeconds = 15;
  int _secondsRemaining = _totalSeconds;
  Timer? _timer;
  bool _isCancelled = false;
  Position? _currentPosition;
  bool _alertSent = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );


    _startTimer();
    _fetchInitialLocation();
  }

  Future<void> _fetchInitialLocation() async {
    final position = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _currentPosition = position;
      });
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          HapticFeedback.lightImpact();
        } else {
          _timer?.cancel();
          _onTimeout();
        }
      });
    });
  }

  void _onTimeout() async {
    if (!_isCancelled) {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryRed),
        ),
      );

      try {
        final double lat = _currentPosition?.latitude ?? -8.184486;
        final double lng = _currentPosition?.longitude ?? 113.668074;

        final dio = sl<Dio>();
        final response = await dio.post('/api/sos/trigger', data: {
          'trigger_type': widget.triggerType,
          'latitude': lat,
          'longitude': lng,
        });

        // Close loading dialog
        if (!mounted) return;
        Navigator.pop(context);

        if (response.statusCode == 200 || response.statusCode == 201) {
          final eventData = response.data;
          final sosId = eventData != null ? eventData['sos_id'] : null;
          if (sosId != null) {
            LocationService.startTrackingSos(sosId.toString());
          }

          if (!mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 10,
              backgroundColor: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // A glowing red shield icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: AppColors.primaryRed,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.alertSent.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.primaryRed,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!.alertSentDesc,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subHeading.copyWith(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'OK',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 14,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        // Close loading dialog if open
        if (!mounted) return;
        Navigator.pop(context);

        // Queue SOS request offline
        final double lat = _currentPosition?.latitude ?? -8.184486;
        final double lng = _currentPosition?.longitude ?? 113.668074;
        await OfflineSyncService.queueSos(
          triggerType: widget.triggerType,
          latitude: lat,
          longitude: lng,
        );

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(Icons.wifi_off, color: AppColors.primaryRed, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.connectionIssuesTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              AppLocalizations.of(context)!.connectionIssuesDesc,
              style: const TextStyle(fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop(); // Close Dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Go back home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _cancelEmergency() {
    setState(() {
      _isCancelled = true;
      _timer?.cancel();
    });
    Navigator.pop(context, 'cancelled');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Text(
              AppLocalizations.of(context)!.emergencyCancelled,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF193855),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _goHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_alertSent) return _buildAlertSentScreen();
    return _buildCountdownScreen();
  }

  Widget _buildCountdownScreen() {
    final l10n = AppLocalizations.of(context)!;
    final progress = _secondsRemaining / _totalSeconds;
    final isEn = Localizations.localeOf(context).languageCode == 'en';

    String headerText = '';
    if (widget.triggerReason != null && widget.triggerReason!.isNotEmpty) {
      headerText = widget.triggerReason!.toUpperCase();
    } else {
      headerText = widget.triggerType == 'auto'
          ? l10n.accidentDetected.toUpperCase()
          : (isEn ? 'IMMEDIATE ASSISTANCE REQUIRED!' : 'BUTUH BANTUAN SEGERA!');
    }

    String subtitleText = isEn
        ? 'Notifying emergency contacts in $_secondsRemaining seconds...'
        : 'Memberitahu kontak darurat dalam $_secondsRemaining detik...';

    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              const Spacer(),

              // Circular Countdown progress indicator
              ScaleTransition(
                scale: _pulseAnimation,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 6,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 6,
                          strokeCap: StrokeCap.round,
                          color: Colors.white,
                          backgroundColor: Colors.transparent,
                        ),
                      ),
                      Text(
                        '$_secondsRemaining',
                        style: const TextStyle(
                          fontSize: 110,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 56),

              // Headers
              Text(
                headerText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  subtitleText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),

              const Spacer(),

              // White button for cancelation
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _cancelEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryRed,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 4,
                  ),
                  child: Text(
                    l10n.cancelSos.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              
              SizedBox(height: 12 + MediaQuery.of(context).padding.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertSentScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEC),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryRed.withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.report_gmailerrorred_rounded,
                  size: 80,
                  color: AppColors.primaryRed,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                AppLocalizations.of(context)!.alertSent,
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.primaryRed,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  AppLocalizations.of(context)!.alertSentDesc,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subHeading.copyWith(
                    color: Colors.black87,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _goHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      AppLocalizations.of(context)!.backToHome,
                      style: AppTextStyles.heading.copyWith(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
