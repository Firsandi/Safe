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
  late AnimationController _cancelSliderController;
  double _dragPosition = 0.0;

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

    _cancelSliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
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
    _cancelSliderController.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9ECEC), // Desaturated red/pink clean background
      body: Stack(
        children: [
          // TACTICAL MAP BACKGROUND (Simulated with Fallback & Fade)
          Positioned.fill(
            child: Opacity(
              opacity: 0.22,
              child: Image.network(
                'https://i.stack.imgur.com/HIL82.png',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildMapPlaceholder();
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildMapPlaceholder();
                },
              ),
            ),
          ),

          // RADIAL GRADIENT VIGNETTE OVERLAY
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    const Color(0xFFF9ECEC).withOpacity(0.5),
                    const Color(0xFFF9ECEC),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                
                // ACCIDENT DETECTED HEADER
                Text(
                  (widget.triggerReason ?? l10n.accidentDetected).toUpperCase(),
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.primaryRed,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    l10n.notifyingServices,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subHeading.copyWith(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),

                const Spacer(),

                // PULSING COUNTDOWN TIMER (Centered & Smooth)
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(0.12),
                          blurRadius: 25,
                          spreadRadius: 5,
                        )
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Circular Progress Indicator around circle
                        SizedBox(
                          width: 242,
                          height: 242,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 5,
                            strokeCap: StrokeCap.round,
                            color: AppColors.primaryRed,
                            backgroundColor: AppColors.primaryRed.withOpacity(0.08),
                          ),
                        ),
                        // Inner content
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$_secondsRemaining',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 110,
                                color: AppColors.primaryRed,
                                height: 1.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n.seconds.toUpperCase(),
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 16,
                                color: AppColors.primaryRed,
                                letterSpacing: 4,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // DATA CARDS (Modern & clean)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDataCard(Icons.speed, AppLocalizations.of(context)!.impactForceLabel, widget.impactForce ?? '0.0 G', AppColors.primaryRed),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _buildDataCard(Icons.location_on_outlined, AppLocalizations.of(context)!.locationLabel, 'NW-22 ST', Colors.blue),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // SWIPE TO CANCEL (Highly interactive & smooth spring-back gesture slider)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: _buildSwipeToCancelSlider(l10n),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder() {
    return Container(
      color: const Color(0xFFF9ECEC),
      child: GridPaper(
        color: AppColors.primaryRed.withOpacity(0.06),
        divisions: 1,
        subdivisions: 1,
        interval: 30,
      ),
    );
  }


  Widget _buildSwipeToCancelSlider(AppLocalizations l10n) {
    const double sliderHeight = 90.0;
    const double handleHeight = 56.0;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDragDistance = sliderHeight - handleHeight - 8.0; // 8.0 is padding

        return Container(
          width: double.infinity,
          height: sliderHeight,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(45),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Sliding track guide text
              Positioned.fill(
                child: Center(
                  child: Opacity(
                    opacity: (1.0 - _dragPosition).clamp(0.2, 1.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.keyboard_double_arrow_up, 
                          color: AppColors.primaryRed.withOpacity(0.6), 
                          size: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.swipeUpCancel.toUpperCase(),
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 12, 
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        Text(
                          l10n.falseAlarm.toUpperCase(),
                          style: AppTextStyles.inputLabel.copyWith(
                            fontSize: 9, 
                            color: Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Draggable Action Handle
              Positioned(
                bottom: _dragPosition * maxDragDistance,
                left: 0,
                right: 0,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      // Note: dragging up is negative delta, so we subtract
                      final delta = -details.primaryDelta! / maxDragDistance;
                      _dragPosition = (_dragPosition + delta).clamp(0.0, 1.0);
                    });
                    if (_dragPosition >= 0.95) {
                      HapticFeedback.vibrate();
                      _cancelEmergency();
                    }
                  },
                  onVerticalDragEnd: (details) {
                    if (_dragPosition < 0.95) {
                      // Animate back down smoothly
                      final currentPosition = _dragPosition;
                      _cancelSliderController.duration = Duration(
                        milliseconds: (currentPosition * 250).toInt().clamp(50, 250),
                      );
                      
                      final Animation<double> animation = Tween<double>(
                        begin: currentPosition,
                        end: 0.0,
                      ).animate(
                        CurvedAnimation(
                          parent: _cancelSliderController,
                          curve: Curves.easeOutBack,
                        ),
                      );

                      animation.addListener(() {
                        setState(() {
                          _dragPosition = animation.value;
                        });
                      });

                      _cancelSliderController.forward(from: 0.0);
                    }
                  },
                  child: Container(
                    height: handleHeight,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primaryRed,
                          const Color(0xFFD32F2F),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryRed.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.shield, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.swipeUpCancel.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataCard(IconData icon, String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border(
          left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label, 
                  style: AppTextStyles.inputLabel.copyWith(
                    fontSize: 9, 
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.subHeading.copyWith(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
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
