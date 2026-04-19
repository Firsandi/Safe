import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/localization/language_cubit.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/features/home/presentation/pages/home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _medicalNotesController = TextEditingController();

  String? _selectedBloodType;
  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O', 'O+', 'O-', 'A+', 'A-', 'B+', 'B-'];

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F8),
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
              child: Stack(
                children: [
                  // CONTENT (At the bottom of stack)
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                    child: Column(
                      children: [
                        // HEADER SECTION
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.shield, color: AppColors.primaryRed, size: 48),
                              const SizedBox(height: 8),
                              Text(
                                'SAFE',
                                style: AppTextStyles.heading.copyWith(
                                  color: AppColors.primaryRed,
                                  fontSize: 32,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.loginSubTitle, 
                                style: AppTextStyles.subHeading.copyWith(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ACCOUNT SETUP CARD
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(28.0),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(l10n.stepIndicator,
                                                textAlign: TextAlign.start,
                                                style: AppTextStyles.inputLabel.copyWith(color: AppColors.primaryRed)),
                                            const SizedBox(height: 4),
                                            Text(l10n.registerTitle,
                                                textAlign: TextAlign.start,
                                                style: AppTextStyles.heading.copyWith(fontSize: 24)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(l10n.profileStatus,
                                                textAlign: TextAlign.end,
                                                style: AppTextStyles.inputLabel.copyWith(fontSize: 10)),
                                            const SizedBox(height: 4),
                                            Text(l10n.initialEntry,
                                                textAlign: TextAlign.end,
                                                style: AppTextStyles.subHeading.copyWith(
                                                  color: Colors.blue[800],
                                                  fontWeight: FontWeight.bold,
                                                )),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 32),

                                  _buildSectionHeader(l10n.basicCredentials),
                                  const SizedBox(height: 20),

                                  _buildLabel(l10n.fullName),
                                  _buildInputField(controller: _nameController, hint: "Johnathan Doe"),
                                  const SizedBox(height: 16),

                                  _buildLabel(l10n.emailAddress),
                                  _buildInputField(controller: _emailController, hint: "john@guardian.com"),
                                  const SizedBox(height: 16),

                                  _buildLabel(l10n.mobileId),
                                  _buildInputField(controller: _phoneController, hint: "+62 8xx xxxx xxxx"),
                                  const SizedBox(height: 16),

                                  _buildLabel(l10n.passwordLabel),
                                  _buildInputField(
                                    controller: _passwordController,
                                    hint: "••••••••",
                                    isPassword: true,
                                    obscureText: !_isPasswordVisible,
                                    onToggleVisibility: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return 'Wajib diisi';
                                      if (v.length < 6) return 'Minimal 6 karakter';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 32),

                                  _buildSectionHeader(l10n.medicalProfile, icon: Icons.medical_services),
                                  const SizedBox(height: 20),

                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildLabel(l10n.bloodType),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                color: AppColors.inputBackground,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButtonFormField<String>(
                                                  value: _selectedBloodType,
                                                  decoration: const InputDecoration(border: InputBorder.none),
                                                  items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                                                  onChanged: (v) => setState(() => _selectedBloodType = v),
                                                ),
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
                                            _buildLabel(l10n.criticalAllergies),
                                            _buildInputField(
                                              controller: _medicalNotesController,
                                              hint: "e.g. Penicillin, Latex",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 40),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryRed,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      ),
                                      onPressed: state is AuthLoading
                                          ? null
                                          : () {
                                              if (_formKey.currentState!.validate()) {
                                                context.read<AuthCubit>().register(
                                                      nama: _nameController.text,
                                                      nomorHp: _phoneController.text,
                                                      email: _emailController.text,
                                                      password: _passwordController.text,
                                                      golDarah: _selectedBloodType,
                                                      catatanMedis: _medicalNotesController.text,
                                                    );
                                              }
                                            },
                                      child: state is AuthLoading
                                          ? const CircularProgressIndicator(color: Colors.white)
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(l10n.createAccount, style: AppTextStyles.buttonPrimary),
                                                const SizedBox(width: 10),
                                                const Icon(Icons.arrow_forward, size: 20),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: RichText(
                                        text: TextSpan(
                                          style: AppTextStyles.subHeading.copyWith(fontSize: 14, color: AppColors.textDark),
                                          children: [
                                            TextSpan(text: l10n.alreadyHaveAccount + " "),
                                            TextSpan(
                                              text: l10n.loginLink,
                                              style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            l10n.legalFooter,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.footer.copyWith(fontSize: 10, height: 1.5),
                          ),
                        ),
                        const SizedBox(height: 20),
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

  Widget _buildSectionHeader(String title, {IconData? icon}) {
    return Row(
      children: [
        Container(height: 1, width: 20, color: Colors.grey[300]),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.inputLabel),
        const Spacer(),
        if (icon != null) Icon(icon, color: Colors.blue[800], size: 20),
      ],
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: AppTextStyles.inputLabel.copyWith(fontSize: 10)),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        style: AppTextStyles.subHeading.copyWith(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.inputIconGrey.withOpacity(0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.inputIconGrey,
                    size: 20,
                  ),
                  onPressed: onToggleVisibility,
                )
              : null,
        ),
        validator: validator ?? (v) => v!.isEmpty ? 'Required' : null,
      ),
    );
  }
}
