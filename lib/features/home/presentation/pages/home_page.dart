import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_countdown_page.dart';
import '../widgets/sos_button.dart';
import '../widgets/sentinel_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) setState(() => _isInit = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FCFF),
      bottomNavigationBar: SentinelBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              _buildAnimated(
                index: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.shield, color: AppColors.primaryRed, size: 34),
                          const SizedBox(width: 16),
                          Text(
                            l10n.appTitle,
                            style: AppTextStyles.heading.copyWith(
                              color: AppColors.primaryRed,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black12, width: 1),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=a042581f4e29026704d'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // MONITORING STATUS BADGE
              _buildAnimated(
                index: 1,
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 15),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7FF),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1E88E5).withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const BreathingDot(),
                        const SizedBox(width: 8),
                        Text(
                          l10n.monitoringActive,
                          style: AppTextStyles.inputLabel.copyWith(
                            color: const Color(0xFF1E88E5),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // SUBTITLE
              _buildAnimated(
                index: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 40),
                  child: Center(
                    child: Text(
                      l10n.systemOperational,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.subHeading.copyWith(
                        color: const Color(0xFF455A64),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // SOS CORE
              _buildAnimated(
                index: 3,
                child: SosButton(
                  onLongPress: () => _triggerEmergency(context),
                  label: l10n.sosLabel,
                  subLabel: l10n.pressHold,
                ),
              ),

              const SizedBox(height: 40),

              // MENU GRID
              _buildAnimated(
                index: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMenuCard(
                          title: l10n.medicalProfileTitle,
                          subtitle: l10n.vitalsAllergies,
                          icon: Icons.assignment_ind,
                          iconBgColor: const Color(0xFFF0F7FF),
                          iconColor: const Color(0xFF1E88E5),
                          onTap: () {},
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMenuCard(
                          title: l10n.emergencyContactsTitle,
                          subtitle: l10n.trustedCircle,
                          icon: Icons.people,
                          iconBgColor: const Color(0xFFFFF1F0),
                          iconColor: AppColors.primaryRed,
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // LOCATION PANEL
              _buildAnimated(
                index: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: _premiumShadows,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F7F9),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.location_on, color: Color(0xFF546E7A), size: 26),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.currentLocation,
                                style: AppTextStyles.inputLabel.copyWith(
                                  fontSize: 10,
                                  color: const Color(0xFF546E7A),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '122 Sentinel Heights, West District',
                                style: AppTextStyles.subHeading.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 60),
            ],
          ),
        ),
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
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: _premiumShadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: AppTextStyles.subHeading.copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: AppTextStyles.footer.copyWith(
                    fontSize: 11,
                    color: Colors.black38,
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

  List<BoxShadow> get _premiumShadows => [
    BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  void _triggerEmergency(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EmergencyCountdownPage()),
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: const Icon(Icons.circle, color: Color(0xFF1E88E5), size: 10),
    );
  }
}
