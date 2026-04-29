import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_countdown_page.dart';
import 'package:safe/features/emergency/presentation/pages/emergency_contacts_page.dart';
import '../widgets/sos_button.dart';
import '../widgets/navbar.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';
import 'package:safe/features/emergency/presentation/bloc/emergency_cubit.dart';
import 'package:safe/core/utils/injection.dart';

class HomePage extends StatefulWidget {
  final UserEntity user;
  const HomePage({super.key, required this.user});

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
        return _buildPlaceholderPage('Riwayat', Icons.history);
      case 3:
        return _buildPlaceholderPage('Lokasi', Icons.location_on_outlined);
      case 4:
        return _buildPlaceholderPage('Profil', Icons.person_outline);
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
          Text(
            title,
            style: AppTextStyles.heading.copyWith(color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Halaman ini belum tersedia',
            style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
          ),
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
        onTap: (index) => setState(() => _currentIndex = index),
      ),
      body: SafeArea(child: _getBody()),
    );
  }

  Widget _buildHomeContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER (Logo, Bell, Settings)
          _buildAnimated(
            index: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/logo.png',
                    height: 50,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.shield, color: AppColors.primaryRed, size: 34),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: AppColors.textDark),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textDark),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

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

          // SOS CORE
          _buildAnimated(
            index: 2,
            child: SosButton(
              onLongPress: () => _triggerEmergency(context),
              label: '',
              subLabel: '',
            ),
          ),
          const SizedBox(height: 16),

          // INSTRUCTION TEXT
          _buildAnimated(
            index: 3,
            child: Center(
              child: Text(
                'Bantuan akan segera dikirimkan ke\nlokasi Anda saat ini',
                textAlign: TextAlign.center,
                style: AppTextStyles.subHeading.copyWith(
                  color: AppColors.textGrey,
                  fontSize: 14,
                ),
              ),
            ),
          ),
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
                      subtitle: '3 aktif',
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
                      subtitle: '2 kejadian',
                      subtitleColor: AppColors.textDark,
                      icon: Icons.history,
                      iconBgColor: AppColors.primaryRed.withOpacity(0.1),
                      iconColor: AppColors.primaryRed,
                      onTap: () {},
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
                    // Mock Map Pattern
                    Opacity(
                      opacity: 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
                            fit: BoxFit.cover,
                          ),
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
    required String title,
    required String subtitle,
    required Color subtitleColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required VoidCallback onTap,
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
                    fontSize: 14,
                    color: subtitleColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
      child: const Icon(Icons.circle, color: Color(0xFF22C55E), size: 10), // Hijau
    );
  }
}
