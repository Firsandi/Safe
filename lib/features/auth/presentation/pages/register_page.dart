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
  int _currentStep = 1; // 1 = Akun Dasar, 2 = Data Medis

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); 
  final _medicalNotesController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedBloodType;
  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O'];

  final List<String> _diseaseSuggestions = [
    'Tidak Ada Riwayat Penyakit',
    'Asma Bronkial',
    'Diabetes Melitus Tipe 1',
    'Diabetes Melitus Tipe 2',
    'Hipertensi (Tekanan Darah Tinggi)',
    'Hipotensi (Tekanan Darah Rendah)',
    'Alergi Kacang-kacangan',
    'Alergi Seafood (Udang, Kepiting, Cumi)',
    'Alergi Obat Penicillin',
    'Alergi Obat Parasetamol',
    'Alergi Antibiotik Golongan Sulfa',
    'Alergi Antibiotik Amoksisilin',
    'Alergi Debu & Tungau',
    'Alergi Susu Sapi (Laktosa)',
    'Alergi Telur',
    'Alergi Gandum / Gluten',
    'Penyakit Jantung Koroner',
    'Epilepsi (Ayan)',
    'Hemofilia (Gangguan Pembekuan Darah)',
    'Anemia (Kurang Darah)',
    'Asam Urat (Gout Arthritis)',
    'Penyakit Ginjal Kronis',
    'TBC (Tuberkulosis Paru)',
    'GERD (Asam Lambung Kronis)',
    'Gastritis (Maag Kronis)',
    'Vertigo (Pusing Berputar)',
    'Migrain Kronis',
    'Kanker (Onkologi)',
    'Tumor Jinak',
    'Stroke (Riwayat Iskemia/Hemoragik)',
    'Penyakit Autoimun Lupus (SLE)',
    'Penyakit Autoimun Rheumatoid Arthritis',
    'Penyakit Paru Obstruktif Kronis (PPOK)',
    'Hepatitis A',
    'Hepatitis B',
    'Hepatitis C',
    'Kolesterol Tinggi (Hiperkolesterolemia)',
    'Sinusitis Kronis',
    'Radang Sendi (Osteoarthritis)',
    'Gagal Jantung Kongestif',
    'Alergi Sengatan Lebah / Serangga',
    'Alergi Obat Aspirin',
    'Alergi Dingin (Urtikaria Dingin)',
    'Tifus (Demam Tifoid)',
    'DBD (Demam Berdarah Dengue)',
    'Malaria',
    'Kelenjar Getah Bening (Limfadenopati)',
    'Gondok (Hipotiroid/Hipertiroid)',
    'Penyakit Parkinson',
    'Demensia Alzheimer',
    'Skizofrenia / Gangguan Mental',
    'Insomnia Kronis',
    'Psoriasis (Penyakit Kulit)',
    'Eksim / Dermatitis Atopik',
  ];

  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

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

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kata sandi tidak cocok'), 
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() {
        _currentStep = 2;
      });
    }
  }

  void _previousStep() {
    setState(() {
      _currentStep = 1;
    });
  }

  void _submitRegistration(BuildContext innerContext, {bool skipMedical = false}) {
    innerContext.read<AuthCubit>().register(
      name: _nameController.text,
      phoneNumber: _phoneController.text,
      email: _emailController.text,
      password: _passwordController.text,
      bloodType: skipMedical ? null : _selectedBloodType,
      medicalNotes: skipMedical ? '' : _medicalNotesController.text,
    );
  }

  Widget _buildStepper() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          _buildStepIndicator(
            step: 1,
            title: 'Akun Dasar',
            isActive: _currentStep >= 1,
            isCompleted: _currentStep > 1,
          ),
          Expanded(
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: _currentStep > 1 ? const Color(0xFF193855) : AppColors.inputBorder,
            ),
          ),
          _buildStepIndicator(
            step: 2,
            title: 'Data Medis',
            isActive: _currentStep >= 2,
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required int step,
    required String title,
    required bool isActive,
    required bool isCompleted,
  }) {
    final activeColor = const Color(0xFF193855);
    final color = isCompleted
        ? Colors.green
        : (isActive ? activeColor : AppColors.inputIconGrey);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: isActive && !isCompleted
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.inputLabel.copyWith(
            color: isActive ? AppColors.textDark : AppColors.textGrey,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ],
    );
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
                const SnackBar(
                  content: Text('Registrasi Berhasil! Silakan Login.'), 
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pop(context);
            } else if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message), 
                  backgroundColor: AppColors.primaryRed,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // HEADER NAVIGATION & SKIP FOR STEP 2
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_currentStep == 2)
                              IconButton(
                                icon: const Icon(Icons.arrow_back, color: Color(0xFF193855)),
                                onPressed: _previousStep,
                                tooltip: 'Kembali',
                              )
                            else
                              // Logo Fallback Header in Step 1
                              Image.asset(
                                'assets/images/logo.png',
                                height: 36,
                                errorBuilder: (context, error, stackTrace) => 
                                    const Icon(Icons.shield, color: AppColors.primaryRed, size: 36),
                              ),
                            if (_currentStep == 2)
                              TextButton(
                                onPressed: state is AuthLoading ? null : () => _submitRegistration(context, skipMedical: true),
                                child: Row(
                                  children: [
                                    Text(
                                      'Lewati & Daftar',
                                      style: TextStyle(
                                        color: AppColors.primaryRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryRed),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // STEPPER INDICATOR
                        _buildStepper(),

                        // CONTENT DYNAMIC BASED ON STEP
                        _currentStep == 1
                            ? _buildStep1Content(context, state)
                            : _buildStep2Content(context, state),
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

  Widget _buildStep1Content(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLES
        Text('Daftar Akun Baru', style: AppTextStyles.heading.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          'Bergabunglah dengan SAFE untuk perlindungan dan ketenangan pikiran Anda.',
          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(height: 24),

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
        
        // NOMOR HP FIELD
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
          obscureText: !_isConfirmPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 28),

        // CONTINUE BUTTON
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
            onPressed: _nextStep,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Lanjutkan', style: AppTextStyles.buttonPrimary),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

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
        const SizedBox(height: 24),

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
                Image.asset('assets/images/google_logo.png', height: 20, width: 20),
                const SizedBox(width: 12),
                Text('Daftar dengan Google', style: AppTextStyles.buttonSecondary),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),


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
    );
  }

  Widget _buildStep2Content(BuildContext context, AuthState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITLES
        Text('Informasi Medis', style: AppTextStyles.heading.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          'Informasi golongan darah dan penyakit/alergi akan sangat membantu tim penolong dalam situasi darurat.',
          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // GOLONGAN DARAH FIELD
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
                    hint: Text('Pilih Golongan Darah', style: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey)),
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
        const SizedBox(height: 20),

        // RIWAYAT PENYAKIT / ALERGI FIELD
        Text('RIWAYAT PENYAKIT ATAU ALERGI', style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return const Iterable<String>.empty();
            }
            return _diseaseSuggestions.where((String option) {
              return option.toLowerCase().contains(
                    textEditingValue.text.toLowerCase(),
                  );
            });
          },
          onSelected: (String selection) {
            _medicalNotesController.text = selection;
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            if (controller.text.isEmpty && _medicalNotesController.text.isNotEmpty) {
              controller.text = _medicalNotesController.text;
            }
            controller.addListener(() {
              _medicalNotesController.text = controller.text;
            });
            return Container(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: TextFormField(
                controller: controller,
                focusNode: focusNode,
                style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                decoration: InputDecoration(
                  hintText: 'Cari penyakit/alergi (cth: Asma)',
                  hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  prefixIcon: const Icon(Icons.medical_services_outlined, color: AppColors.inputIconGrey, size: 22),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 36),

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
            onPressed: state is AuthLoading ? null : () => _submitRegistration(context, skipMedical: false),
            child: state is AuthLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Text('Daftar Sekarang', style: AppTextStyles.buttonPrimary),
          ),
        ),
      ],
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
