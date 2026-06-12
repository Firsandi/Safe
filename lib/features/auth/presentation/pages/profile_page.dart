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
import 'package:safe/core/utils/google_auth_helper.dart';
import 'package:safe/core/utils/session_manager.dart';
import 'package:safe/features/auth/data/models/user_model.dart';
import 'package:safe/features/auth/presentation/pages/login_page.dart';
import 'package:safe/features/home/presentation/pages/language_page.dart';
import 'package:safe/features/home/presentation/pages/help_center_page.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:safe/core/utils/country_codes.dart';


class ProfilePage extends StatefulWidget {
  final UserEntity user;
  final bool showEditForm;
  const ProfilePage({super.key, required this.user, this.showEditForm = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String _currentName;
  late String _currentPhone;
  late String _currentProfileImage;
  late bool _isEditMode;
  String? _tempBase64Image; // Stores newly selected base64 during edit
  String? _selectedBloodType;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _medicalNotesController;
  late Country _selectedCountry;
  String _searchQuery = '';

  Country _parseCountry(String fullPhone) {
    final sortedCountries = List<Country>.from(CountryCodes.countries)
      ..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));
    
    for (final country in sortedCountries) {
      if (fullPhone.startsWith(country.dialCode)) {
        return country;
      }
    }
    return CountryCodes.countries.firstWhere((c) => c.code == 'ID');
  }

  void _showCountryCodePicker(StateSetter setSheetState) {
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
                                setSheetState(() {});
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

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.showEditForm;
    _currentName = widget.user.name;
    _currentPhone = widget.user.phoneNumber;
    _currentProfileImage = widget.user.profileImage ?? '';
    _nameController = TextEditingController(text: _currentName);
    
    final country = _parseCountry(_currentPhone);
    _selectedCountry = country;
    final remainingPhone = _currentPhone.startsWith(country.dialCode)
        ? _currentPhone.substring(country.dialCode.length)
        : _currentPhone;
    _phoneController = TextEditingController(text: remainingPhone);
    
    _medicalNotesController = TextEditingController();
    _fetchMedicalProfile();
    _loadSessionUser();
  }

  @override
  void didUpdateWidget(ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user != oldWidget.user) {
      setState(() {
        _currentName = widget.user.name;
        _currentPhone = widget.user.phoneNumber;
        _currentProfileImage = widget.user.profileImage ?? '';
        _nameController.text = _currentName;
        final country = _parseCountry(_currentPhone);
        _selectedCountry = country;
        _phoneController.text = _currentPhone.startsWith(country.dialCode)
            ? _currentPhone.substring(country.dialCode.length)
            : _currentPhone;
      });
    }
  }

  Future<void> _loadSessionUser() async {
    try {
      final userData = await SessionManager.getUserData();
      if (userData != null && mounted) {
        final user = UserModel.fromJson(userData);
        setState(() {
          _currentName = user.name;
          _currentPhone = user.phoneNumber;
          _currentProfileImage = user.profileImage ?? '';
          _nameController.text = _currentName;
          final country = _parseCountry(_currentPhone);
          _selectedCountry = country;
          _phoneController.text = _currentPhone.startsWith(country.dialCode)
              ? _currentPhone.substring(country.dialCode.length)
              : _currentPhone;
        });
      }
    } catch (_) {}
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
    if (source == ImageSource.camera) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin kamera diperlukan untuk mengambil foto.'),
              backgroundColor: AppColors.primaryRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }
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
              statusBarLight: false, // Light icons on dark status bar
              navBarLight: true,
              activeControlsWidgetColor: const Color(0xFFEF4444), // Crimson red accent color for controls
              backgroundColor: const Color(0xFF0F172A), // Slate-900 root view background
              cropFrameColor: const Color(0xFFEF4444), // Crimson red crop frame
              cropGridColor: const Color(0x4DEF4444), // Soft crimson red crop grid guidelines
              dimmedLayerColor: const Color(0xCC0B0F19), // Dark dimmed background outside bounds
              cropFrameStrokeWidth: 2,
              cropGridStrokeWidth: 1,
              showCropGrid: true,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
              aspectRatioPresets: [CropAspectRatioPreset.square],
              cropStyle: CropStyle.circle,
              hideBottomControls: false,
            ),
            IOSUiSettings(
              title: 'Potong Foto Profil',
              doneButtonTitle: 'Selesai',
              cancelButtonTitle: 'Batal',
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

  Future<void> _saveProfile(BuildContext sheetOrPageContext, [StateSetter? setSheetState]) async {
    final navigator = Navigator.of(sheetOrPageContext);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    if (setSheetState != null) {
      setSheetState(() {}); // Trigger rebuild of the sheet to show loading indicator
    }
    try {
      final dio = sl<Dio>();

      // 1. Save Medical Profile Details first so that the user returned by basic profile update includes the new medical data
      await dio.post('/api/profile/medical', data: {
        'blood_type': _selectedBloodType ?? '',
        'medical_notes': _medicalNotesController.text,
      });

      // 2. Save Basic Profile Details & Profile Image
      final newImage = _tempBase64Image ?? _currentProfileImage;
      final rawPhone = _phoneController.text.trim();
      final cleanPhone = rawPhone.startsWith('0') ? rawPhone.substring(1) : rawPhone;
      final fullPhone = '${_selectedCountry.dialCode}$cleanPhone';
      final profileResponse = await dio.put('/api/profile', data: {
        'name': _nameController.text,
        'phone_number': fullPhone,
        'profile_image': newImage,
      });

      if (profileResponse.statusCode == 200) {
        setState(() {
          _currentName = _nameController.text;
          _currentPhone = fullPhone;
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

        navigator.pop(); // Close sheet or page
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
      if (setSheetState != null) {
        try {
          setSheetState(() {}); // Reset loading indicator in sheet if still open
        } catch (_) {}
      }
    }
  }

  void _showQrCodeDialog() {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title & Close Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEn ? 'My QR Code' : 'Kode QR Saya',
                      style: AppTextStyles.heading.copyWith(fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => Navigator.pop(dialogContext),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Profile & Name Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: _currentProfileImage.isNotEmpty
                          ? MemoryImage(base64Decode(_currentProfileImage))
                          : null,
                      backgroundColor: const Color(0xFF193855),
                      child: _currentProfileImage.isEmpty
                          ? Text(
                              _getInitials(_currentName),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _currentName,
                            style: AppTextStyles.subHeading.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentPhone,
                            style: AppTextStyles.subHeading.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                
                // QR Code Container
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: QrImageView(
                    data: widget.user.userId,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                    foregroundColor: const Color(0xFF193855),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Instructions Info Text
                Text(
                  isEn
                      ? 'Ask your friend to scan this QR code on their device to add you as an emergency contact.'
                      : 'Minta teman Anda memindai kode QR ini di perangkat mereka untuk menambahkan Anda sebagai kontak darurat.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subHeading.copyWith(
                    color: AppColors.textGrey,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.logoutDialogTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(AppLocalizations.of(context)!.logoutDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              AppLocalizations.of(context)!.cancel,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              AppLocalizations.of(context)!.logoutConfirm,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear FCM Token on backend so that they stop receiving push notifications after logging out
      try {
        final dio = sl<Dio>();
        await dio.put('/api/profile/fcm', data: {'fcm_token': ''});
      } catch (e) {
        debugPrint('Failed to clear FCM token on logout: $e');
      }

      LocationService.stopTrackingSos();
      await GoogleAuthHelper.signOut();
      await SessionManager.clearSession();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditMode) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: () {
              if (widget.showEditForm) {
                Navigator.pop(context);
              } else {
                setState(() {
                  _isEditMode = false;
                });
              }
            },
          ),
          title: Text(
            AppLocalizations.of(context)!.editProfileTitle,
            style: AppTextStyles.heading.copyWith(fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // CAMERA EDIT AVATAR
                    Center(
                      child: GestureDetector(
                        onTap: () => _showImageSourceDialog(setState),
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
                      hint: '81234567890',
                      keyboardType: TextInputType.phone,
                      prefixWidget: GestureDetector(
                        onTap: () => _showCountryCodePicker(setState),
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
                            setState(() {
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
                        setState(() {
                          _medicalNotesController.text = selection;
                        });
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
                        onPressed: _isLoading ? null : () => _saveProfile(context),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(AppLocalizations.of(context)!.saveChanges, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // HEADER BAR (Title & Edit Profile Button)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.navProfile,
                              style: AppTextStyles.heading,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.profileDesc,
                              style: AppTextStyles.subHeading.copyWith(
                                color: AppColors.textGrey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Outlined or beautiful compact elevated edit button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _isEditMode = true;
                          });
                        },
                        icon: const Icon(Icons.edit, size: 14, color: Colors.white),
                        label: Text(
                          AppLocalizations.of(context)!.editButtonLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF193855),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
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
                        Divider(height: 1, indent: 64, endIndent: 16, color: Colors.grey[200]),
                        // Kode QR row
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.qr_code, color: Colors.black87, size: 20),
                          ),
                          title: Text(
                            Localizations.localeOf(context).languageCode == 'en'
                                ? 'My QR Code'
                                : 'Kode QR Kontak',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            Localizations.localeOf(context).languageCode == 'en'
                                ? 'Show your QR code to add contact'
                                : 'Tampilkan kode QR untuk tambah kontak',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                          trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                          onTap: _showQrCodeDialog,
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
    Widget? prefixWidget,
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
          prefixIcon: prefixWidget,
        ),
      ),
    );
  }
}
