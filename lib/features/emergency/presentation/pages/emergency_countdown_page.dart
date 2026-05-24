import 'dart:async';
import 'package:flutter/material.dart';
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

class _EmergencyCountdownPageState extends State<EmergencyCountdownPage> {
  int _secondsRemaining = 15;
  Timer? _timer;
  bool _isCancelled = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
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
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
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
            builder: (context) => AlertDialog(
              title: const Text('ALERT SENT'),
              content: const Text('Emergency services and contacts have been notified.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  child: const Text('OK'),
                ),
              ],
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

        // Show a premium/informative offline alert dialog in the user's language preference
        final isIndonesian = Localizations.localeOf(context).languageCode == 'id';
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
                    isIndonesian ? 'Koneksi Terganggu' : 'Connection Issues',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              isIndonesian
                  ? 'Gagal mengirim SOS karena masalah jaringan. SOS Anda telah masuk antrean offline dan akan otomatis dikirim saat sinyal membaik.\n\nHarap hubungi nomor darurat atau kontak Anda secara manual jika memungkinkan.'
                  : 'Failed to send SOS due to connection issues. Your SOS is saved in the offline queue and will sync automatically when your connection is restored.\n\nPlease contact emergency services or your contacts manually if possible.',
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
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('EMERGENCY CANCELLED - Guardian link standby.'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFE8D5D5), // Desaturated red background
      body: Stack(
        children: [
          // TACTICAL MAP BACKGROUND (Simulated)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: const NetworkImage('https://i.stack.imgur.com/HIL82.png'), // Map placeholder
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  const Color(0xFFC62828).withOpacity(0.3),
                  BlendMode.srcOver,
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // TOP BANNER
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryRed,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emergency_share, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            l10n.guardianLinkActive.toUpperCase(),
                            style: AppTextStyles.inputLabel.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=1')),
                          SizedBox(width: 4),
                          CircleAvatar(radius: 12, backgroundImage: NetworkImage('https://i.pravatar.cc/100?u=2')),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  (widget.triggerReason ?? l10n.accidentDetected).toUpperCase(),
                  style: AppTextStyles.heading.copyWith(
                    color: AppColors.primaryRed,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                  child: Text(
                    l10n.notifyingServices,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subHeading.copyWith(color: Colors.black54),
                  ),
                ),

                const Spacer(),
                
                // COUNTDOWN TIMER
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryRed.withOpacity(0.1),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$_secondsRemaining',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 130,
                            color: AppColors.primaryRed,
                            height: 1.0,
                          ),
                        ),
                        Text(
                          l10n.seconds.toUpperCase(),
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 24,
                            color: AppColors.primaryRed,
                            letterSpacing: 4,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(),

                // DATA CARDS
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildDataCard('IMPACT FORCE', widget.impactForce ?? '0.0 G', AppColors.primaryRed),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDataCard('LOCATION', 'NW-22 ST', Colors.blue),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // SWIPE TO CANCEL
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -20) {
                      _cancelEmergency();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300]!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.keyboard_double_arrow_up, color: Colors.black54, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          l10n.swipeUpCancel.toUpperCase(),
                          style: AppTextStyles.heading.copyWith(fontSize: 16, color: Colors.black),
                        ),
                        Text(
                          l10n.falseAlarm.toUpperCase(),
                          style: AppTextStyles.inputLabel.copyWith(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(String label, String value, Color accentColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border(
           left: BorderSide(color: accentColor, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.inputLabel.copyWith(fontSize: 10)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.subHeading.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
