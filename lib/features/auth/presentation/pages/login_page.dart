import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe/features/home/presentation/pages/home_page.dart';
import 'package:safe/core/utils/google_auth_helper.dart';
import 'otp_verification_page.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'package:safe/core/services/notification_manager.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/core/localization/language_selector.dart';
import 'package:safe/l10n/app_localizations.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocProvider(
        create: (_) => sl<AuthCubit>(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) async {
            if (state is AuthSuccess) {
              // Simpan session
              await SessionManager.saveSession(
                token: state.user.token ?? 'logged_in',
                userData: {
                  'user_id': state.user.userId,
                  'name': state.user.name,
                  'email': state.user.email,
                  'phone_number': state.user.phoneNumber,
                  'blood_type': state.user.bloodType,
                  'medical_notes': state.user.medicalNotes,
                  'profile_image': state.user.profileImage,
                },
              );
              NotificationManager.uploadFcmToken();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(user: state.user),
                ),
                (route) => false, // Hapus semua route sebelumnya
              );
            } else if (state is AuthOtpRequired) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.blue,
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpVerificationPage(
                    email: state.email,
                    isLoginOtp: true,
                  ),
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryRed,
                  action: state.message.contains('Email belum diverifikasi')
                      ? SnackBarAction(
                          label: 'Verifikasi',
                          textColor: Colors.white,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OtpVerificationPage(
                                  email: emailController.text.trim(),
                                ),
                              ),
                            );
                          },
                        )
                      : null,
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // LOGO & LANGUAGE SELECTOR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            height: 56,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.shield, color: AppColors.primaryRed, size: 56),
                          ),
                          const LanguageSelector(),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // TITLES
                    Text(AppLocalizations.of(context)!.loginWelcome, style: AppTextStyles.heading),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.loginWelcomeSub,
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),

                    // EMAIL FIELD
                    Text(AppLocalizations.of(context)!.emailLabel, style: AppTextStyles.inputLabel),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: emailController,
                      hint: 'nama@email.com',
                      prefixIcon: Icons.mail_outline,
                    ),
                    const SizedBox(height: 20),

                    // PASSWORD FIELD
                    Text(AppLocalizations.of(context)!.passwordLabel, style: AppTextStyles.inputLabel),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: passwordController,
                      hint: 'Kata sandi',
                      prefixIcon: Icons.lock_outline,
                      isPassword: true,
                      obscureText: !_isPasswordVisible,
                      onToggleVisibility: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // FORGOT PASSWORD
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.forgotPassword,
                          style: AppTextStyles.subHeading.copyWith(
                            color: const Color(0xFF193855),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.primaryRed.withOpacity(0.3),
                        ),
                        onPressed: state is AuthLoading
                            ? null
                            : () {
                                if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.fillEmailPasswordError),
                                      backgroundColor: AppColors.primaryRed,
                                    ),
                                  );
                                  return;
                                }
                                if (!emailController.text.contains('@')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.invalidEmailError),
                                      backgroundColor: AppColors.primaryRed,
                                    ),
                                  );
                                  return;
                                }
                                context.read<AuthCubit>().login(
                                      emailController.text,
                                      passwordController.text,
                                    );
                              },
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(AppLocalizations.of(context)!.loginButton, style: AppTextStyles.buttonPrimary),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OR DIVIDER
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.inputBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            AppLocalizations.of(context)!.orText,
                            style: AppTextStyles.inputLabel.copyWith(color: AppColors.inputIconGrey),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.inputBorder)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // GOOGLE LOGIN BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.textDark,
                          side: const BorderSide(color: AppColors.inputBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(27),
                          ),
                          elevation: 1,
                          shadowColor: Colors.black.withOpacity(0.15),
                        ),
                        onPressed: () => GoogleAuthHelper.signIn(context),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/images/google_logo.png', height: 20, width: 20),
                            const SizedBox(width: 12),
                            Text(AppLocalizations.of(context)!.loginGoogle, style: AppTextStyles.buttonSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // REGISTER LINK
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.noAccountText + ' ',
                          style: AppTextStyles.subHeading.copyWith(fontSize: 14, color: AppColors.textGrey),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text(
                            AppLocalizations.of(context)!.registerNow,
                            style: AppTextStyles.subHeading.copyWith(
                              fontSize: 14,
                              color: const Color(0xFF193855),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(prefixIcon, color: AppColors.inputIconGrey, size: 22),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: AppColors.inputIconGrey,
                    size: 22,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _resendVerificationEmail(BuildContext context) async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.enterEmailFirstError),
          backgroundColor: AppColors.primaryRed,
        ),
      );
      return;
    }

    try {
      final response = await sl<Dio>().post('/api/resend-verification', data: {
        'email': email,
      });
      final message = response.data['message'] ?? 'Kode OTP baru sudah dikirim.';
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
        ),
      );
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? AppLocalizations.of(context)!.failedResendOtpError;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.primaryRed,
        ),
      );
    }
  }
}
