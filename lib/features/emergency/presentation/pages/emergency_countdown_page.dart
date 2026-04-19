import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/l10n/app_localizations.dart';

class EmergencyCountdownPage extends StatefulWidget {
  const EmergencyCountdownPage({super.key});

  @override
  State<EmergencyCountdownPage> createState() => _EmergencyCountdownPageState();
}

class _EmergencyCountdownPageState extends State<EmergencyCountdownPage> {
  int _secondsRemaining = 15;
  Timer? _timer;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
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

  void _onTimeout() {
    if (!_isCancelled) {
      // Simulate sending alert
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
                  l10n.accidentDetected.toUpperCase(),
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
                        child: _buildDataCard('IMPACT FORCE', '4.2 G', AppColors.primaryRed),
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
