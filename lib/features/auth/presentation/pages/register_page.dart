import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe/core/utils/injection.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); // Ditambahkan untuk sinkronisasi dengan ERD
  final _medicalNotesController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedBloodType;
  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O'];

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _medicalNotesController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: BlocProvider(
        create: (context) => sl<AuthCubit>(),
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registrasi Berhasil! Silakan Login.'), backgroundColor: Colors.green),
              );
              Navigator.pop(context);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: AppColors.primaryRed),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LOGO Asset
                      Image.asset(
                        'assets/images/logo.png',
                        height: 56,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.shield, color: AppColors.primaryRed, size: 56),
                      ),
                      const SizedBox(height: 32),

                      // TITLES
                      Text('Daftar Akun', style: AppTextStyles.heading),
                      const SizedBox(height: 8),
                      Text(
                        'Bergabunglah dengan SAFE untuk perlindungan dan ketenangan pikiran Anda.',
                        style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
                      ),
                      const SizedBox(height: 32),

                      // NAMA LENGKAP FIELD
                      Text('NAMA LENGKAP', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _nameController,
                        hint: 'Masukkan nama lengkap Anda',
                        prefixIcon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),

                      // EMAIL FIELD
                      Text('EMAIL', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _emailController,
                        hint: 'nama@email.com',
                        prefixIcon: Icons.mail_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Wajib diisi';
                          if (!value.contains('@')) return 'Format email harus mengandung @';
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // NOMOR HP FIELD (Not in design but required in ERD)
                      Text('NOMOR HANDPHONE', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _phoneController,
                        hint: '081234567890',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Wajib diisi';
                          if (!value.startsWith('08')) return 'Nomor harus diawali 08';
                          if (value.length < 10) return 'Nomor minimal 10 digit';
                          if (value.length > 15) return 'Nomor terlalu panjang';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // GOLONGAN DARAH & RIWAYAT PENYAKIT
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('GOLONGAN DARAH', style: AppTextStyles.inputLabel),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.inputBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.inputBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.water_drop_outlined, color: AppColors.inputIconGrey, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: DropdownButtonHideUnderline(
                                          child: DropdownButton<String>(
                                            value: _selectedBloodType,
                                            hint: Text('Pilih', style: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey)),
                                            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.inputIconGrey),
                                            isExpanded: true,
                                            style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                                            items: _bloodTypes.map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (newValue) {
                                              setState(() {
                                                _selectedBloodType = newValue;
                                              });
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('RIWAYAT PENYAKIT', style: AppTextStyles.inputLabel),
                                const SizedBox(height: 8),
                                _buildInputField(
                                  controller: _medicalNotesController,
                                  hint: 'Cth: Asma',
                                  prefixIcon: Icons.medical_services_outlined,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // KATA SANDI FIELD
                      Text('KATA SANDI', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _passwordController,
                        hint: 'Minimal 8 karakter',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: !_isPasswordVisible,
                        onToggleVisibility: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // KONFIRMASI KATA SANDI
                      Text('KONFIRMASI KATA SANDI', style: AppTextStyles.inputLabel),
                      const SizedBox(height: 8),
                      _buildInputField(
                        controller: _confirmPasswordController,
                        hint: 'Ulangi kata sandi Anda',
                        prefixIcon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: !_isPasswordVisible,
                      ),
                      const SizedBox(height: 32),

                      // REGISTER BUTTON
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
                                  if (_formKey.currentState!.validate()) {
                                    if (_passwordController.text != _confirmPasswordController.text) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Kata sandi tidak cocok'), backgroundColor: AppColors.primaryRed),
                                      );
                                      return;
                                    }
                                    context.read<AuthCubit>().register(
                                          name: _nameController.text,
                                          phoneNumber: _phoneController.text, // Tetap menggunakan phoneNumber dari ERD
                                          email: _emailController.text,
                                          password: _passwordController.text,
                                          bloodType: _selectedBloodType,
                                          medicalNotes: _medicalNotesController.text,
                                        );
                                  }
                                },
                          child: state is AuthLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text('Daftar Sekarang', style: AppTextStyles.buttonPrimary),
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
                              'ATAU',
                              style: AppTextStyles.inputLabel.copyWith(color: AppColors.inputIconGrey),
                            ),
                          ),
                          Expanded(child: Divider(color: AppColors.inputBorder)),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // GOOGLE REGISTER BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: BorderSide(color: AppColors.inputBorder),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(27),
                            ),
                          ),
                          onPressed: () {
                            // TODO: Implement Google Sign Up
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const FaIcon(FontAwesomeIcons.google, color: Colors.blue, size: 20),
                              const SizedBox(width: 12),
                              Text('Daftar dengan Google', style: AppTextStyles.buttonSecondary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // LOGIN LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sudah punya akun? ',
                            style: AppTextStyles.subHeading.copyWith(fontSize: 14, color: AppColors.textGrey),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              'Masuk',
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
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          prefixIcon: Icon(prefixIcon, color: AppColors.inputIconGrey, size: 22),
          suffixIcon: isPassword && onToggleVisibility != null
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
        validator: validator ?? ((value) => value == null || value.isEmpty ? 'Wajib diisi' : null),
      ),
    );
  }
}
