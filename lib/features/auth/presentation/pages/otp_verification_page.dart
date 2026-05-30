import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final bool isLoginOtp;

  const OtpVerificationPage({
    super.key,
    required this.email,
    this.isLoginOtp = false,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  Timer? _timer;
  Timer? _resendTimer;
  late DateTime _expiresAt;
  late DateTime _resendAvailableAt;
  int _remainingSeconds = 300;
  int _resendRemainingSeconds = 180;
  bool _isLoading = false;
  bool _isResending = false;
  bool _isCancellingExpiredRegistration = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _loadTimers();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resendTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _expiryStorageKey => 'otp_expires_at_${widget.email.toLowerCase()}';
  String get _resendStorageKey => 'otp_resend_available_at_${widget.email.toLowerCase()}';

  Future<void> _loadTimers() async {
    final synced = await _loadTimersFromBackend();
    if (synced) return;

    await _loadTimer();
    await _loadResendCooldown();
  }

  Future<bool> _loadTimersFromBackend() async {
    try {
      final response = await sl<Dio>().post('/api/verification-status', data: {
        'email': widget.email,
      });
      final data = response.data as Map<String, dynamic>;
      final otpSeconds = data['otp_expires_in_seconds'] as int? ?? 0;
      final resendSeconds = data['resend_available_in_seconds'] as int? ?? 0;

      if (otpSeconds <= 0) {
        await _cancelExpiredRegistration();
        return true;
      }

      final prefs = await SharedPreferences.getInstance();
      _expiresAt = DateTime.now().add(Duration(seconds: otpSeconds));
      _resendAvailableAt = DateTime.now().add(Duration(seconds: resendSeconds));
      await prefs.setString(_expiryStorageKey, _expiresAt.toIso8601String());
      await prefs.setString(_resendStorageKey, _resendAvailableAt.toIso8601String());
      _runTimer();
      _runResendTimer();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final storedExpiry = prefs.getString(_expiryStorageKey);
    final parsedExpiry = storedExpiry == null ? null : DateTime.tryParse(storedExpiry);

    if (parsedExpiry != null && parsedExpiry.isAfter(DateTime.now())) {
      _expiresAt = parsedExpiry;
      _runTimer();
      return;
    }
    if (parsedExpiry != null) {
      _expiresAt = parsedExpiry;
      _syncRemainingSeconds();
      _cancelExpiredRegistration();
      return;
    }

    await _startTimer();
  }

  Future<void> _startTimer() async {
    _timer?.cancel();
    _expiresAt = DateTime.now().add(const Duration(minutes: 5));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_expiryStorageKey, _expiresAt.toIso8601String());
    _runTimer();
  }

  void _runTimer() {
    _timer?.cancel();
    _syncRemainingSeconds();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncRemainingSeconds();
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _cancelExpiredRegistration();
      }
    });
  }

  void _syncRemainingSeconds() {
    final remaining = _expiresAt.difference(DateTime.now()).inSeconds;
    if (!mounted) return;
    setState(() => _remainingSeconds = remaining > 0 ? remaining : 0);
  }

  String get _timerText {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _resendTimerText {
    final minutes = (_resendRemainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_resendRemainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _loadResendCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final storedResendAt = prefs.getString(_resendStorageKey);
    final parsedResendAt = storedResendAt == null ? null : DateTime.tryParse(storedResendAt);

    if (parsedResendAt != null && parsedResendAt.isAfter(DateTime.now())) {
      _resendAvailableAt = parsedResendAt;
    } else {
      _resendAvailableAt = DateTime.now().add(const Duration(minutes: 3));
      await prefs.setString(_resendStorageKey, _resendAvailableAt.toIso8601String());
    }
    _runResendTimer();
  }

  Future<void> _startResendCooldown() async {
    _resendAvailableAt = DateTime.now().add(const Duration(minutes: 3));
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resendStorageKey, _resendAvailableAt.toIso8601String());
    _runResendTimer();
  }

  void _runResendTimer() {
    _resendTimer?.cancel();
    _syncResendRemainingSeconds();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _syncResendRemainingSeconds();
      if (_resendRemainingSeconds <= 0) {
        timer.cancel();
      }
    });
  }

  void _syncResendRemainingSeconds() {
    final remaining = _resendAvailableAt.difference(DateTime.now()).inSeconds;
    if (!mounted) return;
    setState(() => _resendRemainingSeconds = remaining > 0 ? remaining : 0);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      _showMessage('Masukkan kode OTP 6 digit', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final endpoint = widget.isLoginOtp ? '/api/verify-login-otp' : '/api/verify-email';
      final response = await sl<Dio>().post(endpoint, data: {
        'email': widget.email,
        'otp': otp,
      });

      if (widget.isLoginOtp) {
        final token = response.data['token'] as String?;
        final deviceToken = response.data['device_token'] as String?;
        final user = response.data['user'];

        if (token != null) {
          await SessionManager.saveSession(
            token: token,
            userData: {
              'user_id': user['user_id'],
              'email': user['email'],
              'name': user['name'],
              'phone_number': user['phone_number'],
              'blood_type': user['blood_type'],
              'medical_notes': user['medical_notes'],
              'profile_image': user['profile_image'],
            },
          );
        }
        if (deviceToken != null) {
          await SessionManager.saveDeviceToken(deviceToken);
        }
      }

      final message = response.data['message'] ?? (widget.isLoginOtp ? 'Login berhasil.' : 'Email berhasil diverifikasi. Silakan login.');
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_expiryStorageKey);
      await prefs.remove(_resendStorageKey);
      _showMessage(message);

      if (widget.isLoginOtp) {
        // Harus navigate ke HomePage
        // Kita butuh UserModel, bisa parsing dari user map. Tapi untuk simplicity, HomePage butuh UserModel
        // Mending kita gunakan Bloc untuk verifyLoginOtp atau emit success. Tapi karena ini direct, kita harus panggil AuthCubit.
        // Sebenarnya lebih baik redirect ke "/" (splash) agar otomatis terdetect sudah login.
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Kode OTP tidak valid atau sudah kedaluwarsa.';
      _showMessage(message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    try {
      final response = await sl<Dio>().post('/api/resend-verification', data: {
        'email': widget.email,
      });
      final message = response.data['message'] ?? 'Kode OTP baru sudah dikirim.';
      _clearOtp();
      await _startTimer();
      await _startResendCooldown();
      _showMessage(message);
    } on DioException catch (e) {
      final message = e.response?.data?['error'] ?? 'Gagal mengirim ulang OTP.';
      _showMessage(message, isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _cancelExpiredRegistration() async {
    if (_isCancellingExpiredRegistration) return;
    _isCancellingExpiredRegistration = true;

    try {
      await sl<Dio>().post('/api/cancel-registration', data: {
        'email': widget.email,
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_expiryStorageKey);
      await prefs.remove(_resendStorageKey);
      if (!mounted) return;
      _showMessage('Kode OTP kedaluwarsa. Registrasi dibatalkan, silakan daftar ulang.', isError: true);
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (_) {
      if (!mounted) return;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_expiryStorageKey);
      await prefs.remove(_resendStorageKey);
      _showMessage('Kode OTP kedaluwarsa. Silakan daftar ulang.', isError: true);
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  void _clearOtp() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _otpFocusNodes.first.requestFocus();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.primaryRed : Colors.green,
      ),
    );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verifikasi Email', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Masukkan kode OTP 6 digit yang dikirim ke ${widget.email}',
                style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 32),
              Text('KODE OTP', style: AppTextStyles.inputLabel),
              const SizedBox(height: 6),
              Text(
                _remainingSeconds > 0
                    ? 'Kode kedaluwarsa dalam $_timerText'
                    : 'Kode OTP sudah kedaluwarsa',
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                  ),
                  onPressed: _isLoading ? null : _verifyOtp,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('VERIFIKASI', style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _isResending || _resendRemainingSeconds > 0 ? null : _resendOtp,
                  child: Text(
                    _isResending
                        ? 'Mengirim ulang...'
                        : (_resendRemainingSeconds > 0
                            ? 'Kirim ulang dalam $_resendTimerText'
                            : 'Kirim ulang kode OTP'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
