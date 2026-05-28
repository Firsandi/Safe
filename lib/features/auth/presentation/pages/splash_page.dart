import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/auth/presentation/pages/login_page.dart';
import 'package:safe/features/auth/presentation/pages/register_page.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header Logo (Top Left)
                        Image.asset(
                          'assets/images/logo.png',
                          height: 28,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.shield,
                                color: AppColors.primaryRed,
                                size: 28,
                              ),
                        ),

                        const Spacer(),

                        // Center Graphic (Concentric circles with shield)
                        Center(
                          child: SizedBox(
                            height: 280,
                            width: 280,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Outer circles
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.inputBorder.withOpacity(
                                        0.5,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 200,
                                  height: 200,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.inputBorder,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                // Inner red circle with glow
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryRed.withOpacity(
                                          0.4,
                                        ),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: Colors.white,
                                      size: 60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const Spacer(),

                        // Texts
                        Text(
                          'Keamanan di Ujung\nJari Anda',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 28,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Satu sentuhan, Satu keluarga, Selalu\naman',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.subHeading.copyWith(
                            color: AppColors.primaryRed,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Button Mulai Sekarang
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 4,
                              shadowColor: AppColors.primaryRed.withOpacity(
                                0.4,
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RegisterPage(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Mulai Sekarang',
                                  style: AppTextStyles.buttonPrimary,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Punya akun? ',
                              style: AppTextStyles.subHeading.copyWith(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: Text(
                                'Masuk',
                                style: AppTextStyles.subHeading.copyWith(
                                  fontSize: 14,
                                  color: AppColors.primaryRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
}
