import 'dart:async';
import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/features/auth/presentation/pages/splash_page.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/features/auth/data/models/user_model.dart';
import 'package:safe/features/home/presentation/pages/home_page.dart';
import 'package:safe/core/services/notification_manager.dart';
import 'package:safe/core/services/navigation_service.dart';
import 'package:safe/features/emergency/presentation/pages/sos_incoming_alert_page.dart';

class InitialSplashPage extends StatefulWidget {
  const InitialSplashPage({super.key});

  @override
  State<InitialSplashPage> createState() => _InitialSplashPageState();
}

class _InitialSplashPageState extends State<InitialSplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isSessionChecked = false;
  bool _isTimerFinished = false;
  bool _hasNavigated = false;
  Widget? _targetPage;

  @override
  void initState() {
    super.initState();

    // Set up the animation controller (duration: 1500ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Scale animation (starts smaller, grows to full size with a bouncy elastic curve)
    _scaleAnimation = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Opacity animation for smooth fade-in
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    // Start the animation
    _controller.forward();

    // Start session check
    _checkSession();

    // Start timer to navigate after 2.5 seconds
    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _isTimerFinished = true;
        });
        _tryNavigation();
      }
    });
  }

  Future<void> _checkSession() async {
    try {
      final isLoggedIn = await SessionManager.isLoggedIn();
      if (isLoggedIn) {
        final userData = await SessionManager.getUserData();
        if (userData != null) {
          final user = UserModel.fromJson(userData);
          _targetPage = HomePage(user: user);
          NotificationManager.uploadFcmToken(); // Refresh FCM token in background
        }
      }
    } catch (e) {
      debugPrint('Error checking session in splash: $e');
    } finally {
      // If not logged in or invalid data, fallback to SplashPage
      _targetPage ??= const SplashPage();
      if (mounted) {
        setState(() {
          _isSessionChecked = true;
        });
        _tryNavigation();
      }
    }
  }

  void _tryNavigation() {
    if (_isSessionChecked && _isTimerFinished) {
      _navigate();
    }
  }

  void _navigate() {
    if (_hasNavigated || !mounted) return;
    setState(() {
      _hasNavigated = true;
    });
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => _targetPage!,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Custom fade transition between splash pages for premium feel
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 650),
      ),
    );

    // Trigger the notification/action checks after routing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (NotificationManager.pendingSosData != null) {
        final data = NotificationManager.pendingSosData!;
        NotificationManager.pendingSosData = null;
        if (!SosIncomingAlertPage.isCurrentlyOpen) {
          NavigationService.navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => SosIncomingAlertPage(sosData: data),
            ),
          );
        }
      } else {
        // Check if the app was launched by the local notification full-screen intent
        await NotificationManager.checkLaunchNotification();
        // Also check for pending actions in SharedPreferences
        await NotificationManager.checkPendingActions();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryRed,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo Image with color filter to render it in white
                    Image.asset(
                      'assets/images/logo.png',
                      height: 120,
                      color: Colors.white,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.shield, color: Colors.white, size: 120),
                    ),
                    const SizedBox(height: 24),
                    // SAFE Text Branding
                    const Text(
                      'SAFE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
