import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe/features/auth/presentation/pages/new_password_page.dart';
import 'package:safe/l10n/app_localizations.dart';

class ResetOtpPage extends StatefulWidget {
  final String email;

  const ResetOtpPage({super.key, required this.email});

  @override
  State<ResetOtpPage> createState() => _ResetOtpPageState();
}

class _ResetOtpPageState extends State<ResetOtpPage> {
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  Timer? _timer;
  int _remainingSeconds = 300; // 5 menit

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String get _timerText {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _handleOtpChanged(String value, int index) {
    if (value.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 46,
      height: 56,
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _otpFocusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        style: AppTextStyles.heading.copyWith(fontSize: 22),
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.inputBackground,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primaryRed, width: 1.6),
          ),
        ),
        onChanged: (value) => _handleOtpChanged(value, index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocProvider(
        create: (_) => sl<AuthCubit>(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthActionSuccess) {
              // Navigasi ke halaman buat password baru
              final otp = _otpControllers.map((c) => c.text).join();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => NewPasswordPage(
                    email: widget.email,
                    otp: otp,
                  ),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.verifyEmailTitle, style: AppTextStyles.heading),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.enterOtpSentTo(widget.email),
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
                    ),
                    const SizedBox(height: 32),
                    Text(AppLocalizations.of(context)!.otpLabel, style: AppTextStyles.inputLabel),
                    const SizedBox(height: 6),
                    Text(
                      _remainingSeconds > 0
                          ? AppLocalizations.of(context)!.codeExpiresIn(_timerText)
                          : AppLocalizations.of(context)!.codeExpired,
                      style: AppTextStyles.subHeading.copyWith(
                        color: _remainingSeconds > 0 ? AppColors.textGrey : AppColors.primaryRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, _buildOtpBox),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                        ),
                        onPressed: state is AuthLoading || _remainingSeconds == 0
                            ? null
                            : () {
                                final otp = _otpControllers.map((c) => c.text).join();
                                if (otp.length != 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(AppLocalizations.of(context)!.enter6DigitOtp),
                                      backgroundColor: AppColors.primaryRed,
                                    ),
                                  );
                                  return;
                                }
                                context.read<AuthCubit>().verifyResetOtp(widget.email, otp);
                              },
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(AppLocalizations.of(context)!.verifyButton, style: AppTextStyles.buttonPrimary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: _remainingSeconds == 0 ? () {
                          // Resend logic if needed, currently just navigate back
                          Navigator.pop(context);
                        } : null,
                        child: Text(
                          _remainingSeconds > 0
                              ? AppLocalizations.of(context)!.waitToResend(_timerText)
                              : AppLocalizations.of(context)!.goBackAndResend,
                          style: TextStyle(
                            color: _remainingSeconds > 0 ? Colors.grey : AppColors.primaryRed,
                          ),
                        ),
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
