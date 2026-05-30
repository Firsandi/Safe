import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:safe/features/auth/presentation/bloc/auth_state.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/google_auth_helper.dart';
import 'package:safe/features/auth/presentation/pages/login_page.dart';
import 'package:safe/features/auth/presentation/pages/otp_verification_page.dart';
import 'package:safe/core/localization/language_selector.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/utils/country_codes.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int _currentStep = 1; // 1 = Akun Dasar, 2 = Data Medis
  Country _selectedCountry = CountryCodes.countries.firstWhere((c) => c.code == 'ID');
  String _searchQuery = '';

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(); 
  final _medicalNotesController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedBloodType;
  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O', 'A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'];

  final List<String> _diseaseSuggestionsID = [
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

  final List<String> _diseaseSuggestionsEN = [
    'No Medical History',
    'Bronchial Asthma',
    'Type 1 Diabetes Mellitus',
    'Type 2 Diabetes Mellitus',
    'Hypertension (High Blood Pressure)',
    'Hypotension (Low Blood Pressure)',
    'Peanut Allergy',
    'Seafood Allergy (Shrimp, Crab, Squid)',
    'Penicillin Allergy',
    'Paracetamol Allergy',
    'Sulfa Antibiotics Allergy',
    'Amoxicillin Antibiotics Allergy',
    'Dust & Mite Allergy',
    'Cow\'s Milk Allergy (Lactose)',
    'Egg Allergy',
    'Wheat / Gluten Allergy',
    'Coronary Heart Disease',
    'Epilepsy',
    'Hemophilia (Blood Clotting Disorder)',
    'Anemia',
    'Gout Arthritis',
    'Chronic Kidney Disease',
    'Tuberculosis (Pulmonary TB)',
    'GERD (Acid Reflux)',
    'Gastritis',
    'Vertigo',
    'Chronic Migraine',
    'Cancer (Oncology)',
    'Benign Tumor',
    'Stroke (Ischemic/Hemorrhagic)',
    'Lupus Autoimmune Disease (SLE)',
    'Rheumatoid Arthritis Autoimmune Disease',
    'Chronic Obstructive Pulmonary Disease (COPD)',
    'Hepatitis A',
    'Hepatitis B',
    'Hepatitis C',
    'High Cholesterol (Hypercholesterolemia)',
    'Chronic Sinusitis',
    'Osteoarthritis',
    'Congestive Heart Failure',
    'Bee Sting / Insect Allergy',
    'Aspirin Allergy',
    'Cold Allergy (Cold Urticaria)',
    'Typhus (Typhoid Fever)',
    'DHF (Dengue Hemorrhagic Fever)',
    'Malaria',
    'Lymph Nodes (Lymphadenopathy)',
    'Goiter (Hypothyroidism/Hyperthyroidism)',
    'Parkinson\'s Disease',
    'Alzheimer\'s Dementia',
    'Schizophrenia / Mental Disorder',
    'Chronic Insomnia',
    'Psoriasis (Skin Disease)',
    'Eczema / Atopic Dermatitis',
  ];

  List<String> get _diseaseSuggestions {
    final languageCode = Localizations.localeOf(context).languageCode;
    return languageCode == 'en' ? _diseaseSuggestionsEN : _diseaseSuggestionsID;
  }

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
          SnackBar(
            content: Text(AppLocalizations.of(context)!.passwordsDoNotMatch), 
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
    final rawPhone = _phoneController.text.trim();
    final cleanPhone = rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;
    final fullPhone = '${_selectedCountry.dialCode}$cleanPhone';

    innerContext.read<AuthCubit>().register(
      name: _nameController.text,
      phoneNumber: fullPhone,
      email: _emailController.text,
      password: _passwordController.text,
      bloodType: skipMedical ? null : _selectedBloodType,
      medicalNotes: skipMedical ? '' : _medicalNotesController.text,
    );
  }

  void _showCountryCodePicker() {
    _searchQuery = '';
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      // Drag Handle
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.selectCountryCodeTitle,
                        style: AppTextStyles.heading.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 12),
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.searchCountryHint,
                            hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
                            prefixIcon: const Icon(Icons.search, color: AppColors.inputIconGrey, size: 20),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                          onChanged: (val) {
                            setModalState(() {
                              _searchQuery = val.toLowerCase();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Country List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: CountryCodes.countries.length,
                          itemBuilder: (context, index) {
                            final country = CountryCodes.countries[index];
                            final name = isEn ? country.nameEn : country.nameId;
                            if (_searchQuery.isNotEmpty &&
                                !name.toLowerCase().contains(_searchQuery) &&
                                !country.dialCode.contains(_searchQuery)) {
                              return const SizedBox.shrink();
                            }
                            return ListTile(
                              leading: Text(
                                country.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              title: Text(
                                name,
                                style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                              ),
                              trailing: Text(
                                country.dialCode,
                                style: AppTextStyles.subHeading.copyWith(
                                  color: AppColors.textGrey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedCountry = country;
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
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
            title: AppLocalizations.of(context)!.stepBasicAccount,
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
            title: AppLocalizations.of(context)!.stepMedicalData,
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
                SnackBar(
                  content: Text(AppLocalizations.of(context)!.registerSuccessMsg),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => OtpVerificationPage(
                    email: _emailController.text.trim(),
                  ),
                ),
              );
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
                                tooltip: AppLocalizations.of(context)!.backTooltip,
                              )
                            else
                              const SizedBox(height: 36),
                            if (_currentStep == 2)
                              TextButton(
                                onPressed: state is AuthLoading ? null : () => _submitRegistration(context, skipMedical: true),
                                child: Row(
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!.skipAndRegister,
                                      style: const TextStyle(
                                        color: AppColors.primaryRed,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_forward, size: 16, color: AppColors.primaryRed),
                                  ],
                                ),
                              )
                            else
                              const LanguageSelector(),
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
        Text(AppLocalizations.of(context)!.registerTitleText, style: AppTextStyles.heading.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.registerSubtitleText,
          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // NAMA LENGKAP FIELD
        Text(AppLocalizations.of(context)!.fullNameLabel, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _nameController,
          hint: AppLocalizations.of(context)!.fullNameHint,
          prefixIcon: Icons.person_outline,
        ),
        const SizedBox(height: 16),

        // EMAIL FIELD
        Text(AppLocalizations.of(context)!.emailLabel, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _emailController,
          hint: AppLocalizations.of(context)!.emailHint,
          prefixIcon: Icons.mail_outline,
          validator: (value) {
            if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredFieldError;
            if (!value.contains('@')) return AppLocalizations.of(context)!.emailFormatError;
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return AppLocalizations.of(context)!.emailInvalidError;
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // NOMOR HP FIELD
        Text(AppLocalizations.of(context)!.phoneLabel, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _phoneController,
          hint: AppLocalizations.of(context)!.phoneHint,
          prefixWidget: GestureDetector(
            onTap: _showCountryCodePicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _selectedCountry.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCountry.dialCode,
                    style: AppTextStyles.subHeading.copyWith(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: AppColors.inputIconGrey, size: 20),
                  Container(
                    height: 24,
                    width: 1,
                    color: AppColors.inputBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredFieldError;
            final cleanVal = value.startsWith('0') ? value.substring(1) : value;
            if (!RegExp(r'^[0-9]+$').hasMatch(cleanVal)) {
              return AppLocalizations.of(context)!.invalidPhoneFormatError;
            }
            if (cleanVal.length < 8) return AppLocalizations.of(context)!.phoneMinLengthError;
            if (cleanVal.length > 13) return AppLocalizations.of(context)!.phoneMaxLengthError;
            return null;
          },
        ),
        const SizedBox(height: 16),

        // KATA SANDI FIELD
        Text(AppLocalizations.of(context)!.passwordLabel, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _passwordController,
          hint: AppLocalizations.of(context)!.passwordHint,
          prefixIcon: Icons.lock_outline,
          isPassword: true,
          obscureText: !_isPasswordVisible,
          onToggleVisibility: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) return AppLocalizations.of(context)!.requiredFieldError;
            if (value.length < 8) return AppLocalizations.of(context)!.passwordMinLengthError;
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        // KONFIRMASI KATA SANDI
        Text(AppLocalizations.of(context)!.confirmPasswordLabel, style: AppTextStyles.inputLabel),
        const SizedBox(height: 8),
        _buildInputField(
          controller: _confirmPasswordController,
          hint: AppLocalizations.of(context)!.confirmPasswordHint,
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
                Text(AppLocalizations.of(context)!.continueButton, style: AppTextStyles.buttonPrimary),
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
                AppLocalizations.of(context)!.orText,
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
                Text(AppLocalizations.of(context)!.registerGoogle, style: AppTextStyles.buttonSecondary),
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
              AppLocalizations.of(context)!.alreadyHaveAccount + ' ',
              style: AppTextStyles.subHeading.copyWith(fontSize: 14, color: AppColors.textGrey),
            ),
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (route) => false,
                );
              },
              child: Text(
                AppLocalizations.of(context)!.loginLink,
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
        Text(AppLocalizations.of(context)!.medicalInfoTitle, style: AppTextStyles.heading.copyWith(fontSize: 24)),
        const SizedBox(height: 8),
        Text(
          AppLocalizations.of(context)!.medicalInfoSubtitle,
          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
        ),
        const SizedBox(height: 24),

        // GOLONGAN DARAH FIELD
        Text(AppLocalizations.of(context)!.bloodType, style: AppTextStyles.inputLabel),
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
                    hint: Text(AppLocalizations.of(context)!.bloodTypeHint, style: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey)),
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
        Text(AppLocalizations.of(context)!.medicalHistoryLabel, style: AppTextStyles.inputLabel),
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
                  hintText: AppLocalizations.of(context)!.medicalHistoryHint,
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
                : Text(AppLocalizations.of(context)!.registerNowButton, style: AppTextStyles.buttonPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    Widget? prefixWidget,
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
          prefixIcon: prefixWidget ?? (prefixIcon != null ? Icon(prefixIcon, color: AppColors.inputIconGrey, size: 22) : null),
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
        validator: validator ?? ((value) => value == null || value.isEmpty ? AppLocalizations.of(context)!.requiredFieldError : null),
      ),
    );
  }
}
