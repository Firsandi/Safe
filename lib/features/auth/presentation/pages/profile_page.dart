import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:safe/core/error/dio_error_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/auth/domain/entities/user_entity.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/features/auth/presentation/pages/login_page.dart';
import 'package:safe/features/home/presentation/pages/language_page.dart';
import 'package:safe/features/home/presentation/pages/help_center_page.dart';
import 'package:safe/l10n/app_localizations.dart';

class ProfilePage extends StatefulWidget {
  final UserEntity user;
  const ProfilePage({super.key, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _currentName;
  late String _currentPhone;
  late String _currentProfileImage;
  String? _tempBase64Image; // Stores newly selected base64 during edit
  String? _selectedBloodType;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _medicalNotesController;

  final List<String> _bloodTypes = ['A', 'B', 'AB', 'O', 'A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'];

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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.user.name;
    _currentPhone = widget.user.phoneNumber;
    _currentProfileImage = widget.user.profileImage ?? '';
    _nameController = TextEditingController(text: _currentName);
    _phoneController = TextEditingController(text: _currentPhone);
    _medicalNotesController = TextEditingController();
    _fetchMedicalProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _medicalNotesController.dispose();
    super.dispose();
  }

  Future<void> _fetchMedicalProfile() async {
    setState(() => _isLoading = true);
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/api/profile/medical');
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        setState(() {
          _selectedBloodType = data['blood_type'] != "" ? data['blood_type'] : null;
          _medicalNotesController.text = data['medical_notes'] ?? '';
        });
      }
    } catch (e) {
      // Gracefully ignore or log
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _pickImage(StateSetter setSheetState, ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024, // increase resolution so cropper has high quality input
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Potong Foto Profil',
              toolbarColor: const Color(0xFF193855),
              toolbarWidgetColor: Colors.white,
              statusBarColor: const Color(0xFF193855),
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
              cropStyle: CropStyle.circle,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Potong Foto Profil',
              aspectRatioLockEnabled: true,
              resetAspectRatioEnabled: false,
              aspectRatioPresets: [CropAspectRatioPreset.square],
              cropStyle: CropStyle.circle,
            ),
          ],
        );

        if (croppedFile != null) {
          final bytes = await croppedFile.readAsBytes();
          final base64String = base64Encode(bytes);
          setSheetState(() {
            _tempBase64Image = base64String;
          });
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil/memotong foto: ${e.toString()}'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog(StateSetter setSheetState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // DRAG HANDLE
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Pilih Sumber Foto',
                  style: AppTextStyles.heading.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Ambil foto langsung dari kamera atau pilih dari galeri.',
                  style: AppTextStyles.subHeading.copyWith(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // CAMERA OPTION
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(setSheetState, ImageSource.camera);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              border: Border.all(color: AppColors.inputBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8ECEF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF193855),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Kamera',
                                  style: AppTextStyles.subHeading.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // GALLERY OPTION
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _pickImage(setSheetState, ImageSource.gallery);
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: AppColors.inputBackground,
                              border: Border.all(color: AppColors.inputBorder),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8ECEF),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_outlined,
                                    color: Color(0xFF193855),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Galeri',
                                  style: AppTextStyles.subHeading.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProfile(BuildContext sheetContext, StateSetter setSheetState) async {
    final navigator = Navigator.of(sheetContext);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    setSheetState(() {}); // Trigger rebuild of the sheet to show loading indicator
    try {
      final dio = sl<Dio>();

      // 1. Save Basic Profile Details & Profile Image
      final newImage = _tempBase64Image ?? _currentProfileImage;
      final profileResponse = await dio.put('/api/profile', data: {
        'name': _nameController.text,
        'phone_number': _phoneController.text,
        'profile_image': newImage,
      });

      // 2. Save Medical Profile Details
      await dio.post('/api/profile/medical', data: {
        'blood_type': _selectedBloodType ?? '',
        'medical_notes': _medicalNotesController.text,
      });

      if (profileResponse.statusCode == 200) {
        setState(() {
          _currentName = _nameController.text;
          _currentPhone = _phoneController.text;
          _currentProfileImage = newImage;
        });

        // Sync with SessionManager
        final token = await SessionManager.getToken();
        if (token != null && profileResponse.data['user'] != null) {
          await SessionManager.saveSession(
            token: token,
            userData: profileResponse.data['user'],
          );
        }

        navigator.pop(); // Close sheet
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Profil & Riwayat Medis berhasil diperbarui!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(DioErrorHandler.getMessage(e)),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Gagal memperbarui profil. Silakan coba lagi.'),
          backgroundColor: AppColors.primaryRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
      try {
        setSheetState(() {}); // Reset loading indicator in sheet if still open
      } catch (_) {}
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Keluar dari Akun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin keluar dari aplikasi SAFE?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _showEditProfileBottomSheet() {
    // Reset temp base64 image when sheet opens
    _tempBase64Image = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom +
                    MediaQuery.of(this.context).padding.bottom +
                    56,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DRAG HANDLE
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.editProfileTitle,
                      style: AppTextStyles.heading.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.editProfileSub,
                      style: AppTextStyles.subHeading.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // CAMERA EDIT AVATAR
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImageSourceDialog(setSheetState),
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 46,
                              backgroundImage: (_tempBase64Image ?? _currentProfileImage).isNotEmpty
                                  ? MemoryImage(base64Decode(_tempBase64Image ?? _currentProfileImage))
                                  : null,
                              backgroundColor: const Color(0xFF193855),
                              child: (_tempBase64Image ?? _currentProfileImage).isEmpty
                                  ? Text(
                                      _getInitials(_nameController.text),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF193855),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // EDIT NAMA
                    Text(AppLocalizations.of(context)!.fullNameLabel, style: AppTextStyles.inputLabel),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _nameController,
                      hint: AppLocalizations.of(context)!.enterFullName,
                    ),
                    const SizedBox(height: 16),

                    // EDIT HANDPHONE
                    Text(AppLocalizations.of(context)!.phoneLabel, style: AppTextStyles.inputLabel),
                    const SizedBox(height: 8),
                    _buildInputField(
                      controller: _phoneController,
                      hint: '081234567890',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // EDIT GOLONGAN DARAH
                    Text(AppLocalizations.of(context)!.bloodTypeLabel, style: AppTextStyles.inputLabel),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.inputBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBloodType,
                          hint: Text(AppLocalizations.of(context)!.choose, style: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey)),
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
                            setSheetState(() {
                              _selectedBloodType = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // EDIT ALERGI (Autocomplete)
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
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF193855),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : () => _saveProfile(sheetContext, setSheetState),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(AppLocalizations.of(context)!.saveChanges, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER BAR (SAFE logo & edit pencil icon button)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        height: 48,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shield, color: AppColors.primaryRed, size: 32),
                      ),
                      GestureDetector(
                        onTap: _showEditProfileBottomSheet,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, color: Colors.black87, size: 20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // TOP CARD (User details)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundImage: _currentProfileImage.isNotEmpty
                              ? MemoryImage(base64Decode(_currentProfileImage))
                              : null,
                          backgroundColor: const Color(0xFF193855),
                          child: _currentProfileImage.isEmpty
                              ? Text(
                                  _getInitials(_currentName),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.user.email,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentPhone,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // PUSAT DATA MEDIS SECTION
                  Text(
                    AppLocalizations.of(context)!.medicalDataCenter,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TWO COLUMNS (GOL. DARAH & ALERGI)
                  Row(
                    children: [
                      // GOL. DARAH CARD
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          height: 105,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.water_drop, color: AppColors.primaryRed, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.bloodTypeCard,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryRed,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                _selectedBloodType ?? '-',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // ALERGI CARD
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          height: 105,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.01),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.coronavirus_outlined, color: Color(0xFF193855), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context)!.allergiesCard,
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF193855),
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                _medicalNotesController.text.isNotEmpty ? _medicalNotesController.text : AppLocalizations.of(context)!.none,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // PENGATURAN SECTION
                  Text(
                    AppLocalizations.of(context)!.settings,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // SETTINGS LIST CARD
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Bahasa row
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.language, color: Colors.black87, size: 20),
                          ),
                          title: Text(AppLocalizations.of(context)!.settingsLanguage, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(AppLocalizations.of(context)!.settingsLanguageSub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LanguagePage()),
                            );
                          },
                        ),
                        Divider(height: 1, indent: 64, endIndent: 16, color: Colors.grey[200]),
                        // Pusat bantuan row
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.help_outline, color: Colors.black87, size: 20),
                          ),
                          title: Text(AppLocalizations.of(context)!.settingsHelp, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(AppLocalizations.of(context)!.settingsHelpSub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const HelpCenterPage()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
                      ),
                      onPressed: _logout,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context)!.logout,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
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
        keyboardType: keyboardType,
        style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
