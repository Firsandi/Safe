import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/features/home/presentation/pages/home_page.dart';
import 'register_page.dart';

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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocProvider(
        create: (_) => sl<AuthCubit>(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomePage(user: state.user),
                ),
              );
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.primaryRed,
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: Stack(
                children: [
                  // CONTENT (At the bottom of stack)
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOGO SECTION
                        Center(
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.shield, color: AppColors.primaryRed, size: 42),
                                  const SizedBox(width: 12),
                                  Text(
                                    'SAFE',
                                    style: AppTextStyles.heading.copyWith(
                                      color: AppColors.primaryRed,
                                      fontSize: 32,
                                      letterSpacing: 2.0,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 4,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryRed,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),

                        // HERO TEXT
                        Text(l10n.loginTitle, style: AppTextStyles.heading),
                        const SizedBox(height: 16),
                        Text(
                          l10n.loginSubTitle,
                          style: AppTextStyles.subHeading,
                        ),
                        const SizedBox(height: 50),

                        // INPUT EMAIL
                        Text(
                          l10n.emailLabel,
                          style: AppTextStyles.inputLabel,
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: emailController,
                          hint: 'email@sentinel-arch.org',
                          icon: Icons.alternate_email,
                        ),
                        const SizedBox(height: 24),

                        // INPUT PASSWORD
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.passwordLabel,
                              style: AppTextStyles.inputLabel,
                            ),
                            Text(
                              l10n.forgotPassword.toUpperCase(),
                              style: AppTextStyles.inputLabel.copyWith(
                                color: Colors.blue[800],
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInputField(
                          controller: passwordController,
                          hint: '••••••••••••••',
                          icon: _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          isPassword: true,
                          obscureText: !_isPasswordVisible,
                          onToggleVisibility: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        const SizedBox(height: 40),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryRed,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: AppColors.primaryRed.withOpacity(0.4),
                            ),
                            onPressed: state is AuthLoading
                                ? null
                                : () {
                                    context.read<AuthCubit>().login(
                                          emailController.text,
                                          passwordController.text,
                                        );
                                  },
                            child: state is AuthLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(l10n.loginButton, style: AppTextStyles.buttonPrimary),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.arrow_forward, size: 20),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // REGISTER SECTION
                        Center(
                          child: Column(
                            children: [
                              Text(
                                l10n.registerLink,
                                style: AppTextStyles.subHeading.copyWith(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: AppColors.outlineButtonBorder),
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                                    );
                                  },
                                  child: Text(
                                    l10n.registerLink.toUpperCase(),
                                    style: AppTextStyles.buttonSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 60),

                        // FOOTER
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            children: [
                              Text(
                                l10n.copyright.toUpperCase(),
                                style: AppTextStyles.footer,
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                alignment: WrapAlignment.center,
                                spacing: 20,
                                runSpacing: 10,
                                children: [
                                  Text(l10n.security.toUpperCase(), style: AppTextStyles.footer),
                                  Text(l10n.privacy.toUpperCase(), style: AppTextStyles.footer),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // LANGUAGE TOGGLE (At the top of stack)
                  Positioned(
                    top: 10,
                    right: 20,
                    child: TextButton(
                      onPressed: () => context.read<LanguageCubit>().toggleLanguage(),
                      child: Row(
                        children: [
                          const Icon(Icons.language, size: 18, color: AppColors.primaryRed),
                          const SizedBox(width: 6),
                          Text(
                            Localizations.localeOf(context).languageCode.toUpperCase(),
                            style: AppTextStyles.inputLabel.copyWith(color: AppColors.primaryRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(icon, color: AppColors.inputIconGrey, size: 22),
                  onPressed: onToggleVisibility,
                )
              : Icon(icon, color: AppColors.inputIconGrey, size: 22),
        ),
      ),
    );
  }
}