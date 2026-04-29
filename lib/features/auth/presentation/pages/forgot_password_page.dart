import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
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
        title: Text(
          'Lupa Kata Sandi',
          style: AppTextStyles.heading.copyWith(fontSize: 18, color: AppColors.textDark),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Center Graphic
              Center(
                child: SizedBox(
                  height: 160,
                  width: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer circles
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryRed.withOpacity(0.1), width: 1),
                        ),
                      ),
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.primaryRed.withOpacity(0.2), width: 1),
                        ),
                      ),
                      // Inner red circle
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryRed,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_reset, // Menggunakan icon lock reset
                            color: Colors.white,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title & Subtitle
              Text(
                'Reset Keamanan',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading.copyWith(fontSize: 24, color: const Color(0xFF193855)),
              ),
              const SizedBox(height: 12),
              Text(
                'Masukkan alamat email yang terdaftar. Kami akan mengirimkan instruksi untuk mengatur ulang kata sandi Anda.',
                textAlign: TextAlign.center,
                style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
              ),
              const SizedBox(height: 48),

              // Email Field
              Text('Email', style: AppTextStyles.inputLabel.copyWith(color: const Color(0xFF193855))),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.inputBorder),
                ),
                child: TextField(
                  controller: _emailController,
                  style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                  decoration: InputDecoration(
                    hintText: 'nama@email.com',
                    hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    prefixIcon: const Icon(Icons.mail_outline, color: AppColors.inputIconGrey, size: 22),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
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
                  onPressed: () {
                    // TODO: Implement Forgot Password Logic
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Instruksi reset kata sandi telah dikirim ke email Anda.')),
                    );
                  },
                  child: Text('Kirim', style: AppTextStyles.buttonPrimary),
                ),
              ),
              const SizedBox(height: 48),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ingat kata sandi Anda? ',
                    style: AppTextStyles.subHeading.copyWith(fontSize: 14, color: AppColors.textGrey),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Masuk sekarang',
                      style: AppTextStyles.subHeading.copyWith(
                        fontSize: 14,
                        color: AppColors.primaryRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
