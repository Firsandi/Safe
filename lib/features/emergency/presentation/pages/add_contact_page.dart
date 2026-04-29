import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/emergency_cubit.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _phoneController = TextEditingController();
  bool _hasSearched = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _phoneController.text.trim();
    if (query.isEmpty) return;
    setState(() => _hasSearched = true);
    context.read<EmergencyCubit>().searchUsers(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/images/logo.png',
          height: 30,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.shield, color: AppColors.primaryRed, size: 30),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tambah Kontak Darurat', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  'Cari berdasarkan nomor telepon. Hanya pengguna yang sudah terdaftar yang dapat ditambahkan.',
                  style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('NOMOR TELEPON', style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Phone input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                          onChanged: (value) {
                            // Auto-search when user types 10+ digits
                            if (value.trim().length >= 10) {
                              _onSearch();
                            }
                          },
                          onSubmitted: (_) => _onSearch(),
                          decoration: InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.inputIconGrey, size: 22),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Search button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF193855),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _onSearch,
                        icon: const Icon(Icons.search, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Divider
          if (_hasSearched)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: Divider(color: AppColors.inputBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'HASIL PENCARIAN',
                      style: AppTextStyles.inputLabel.copyWith(
                        color: AppColors.inputIconGrey,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: AppColors.inputBorder)),
                ],
              ),
            ),

          // Search Results
          Expanded(
            child: BlocBuilder<EmergencyCubit, EmergencyState>(
              builder: (context, state) {
                if (!_hasSearched) {
                  return _buildInitialHint();
                }

                if (state is EmergencySearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is EmergencySearchSuccess) {
                  if (state.users.isEmpty) {
                    return _buildNotFoundState();
                  }
                  return _buildUserList(state.users);
                } else if (state is EmergencyError) {
                  return _buildNotFoundState();
                }
                return _buildInitialHint();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: AppColors.textGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Masukkan nomor telepon untuk mencari',
            style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryRed.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_off_outlined, size: 48, color: AppColors.primaryRed),
          ),
          const SizedBox(height: 16),
          Text(
            'Pengguna tidak ditemukan',
            style: AppTextStyles.subHeading.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Nomor ini belum terdaftar di aplikasi SAFE. Hanya pengguna terdaftar yang bisa ditambahkan.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList(List<ContactEntity> users) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _confirmAddContact(user),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(0xFFEDF4FE),
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                        style: AppTextStyles.heading.copyWith(fontSize: 18, color: const Color(0xFF193855)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: AppTextStyles.subHeading.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.phoneNumber,
                            style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF193855),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Tambah',
                            style: AppTextStyles.subHeading.copyWith(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmAddContact(ContactEntity user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Tambah Kontak', style: AppTextStyles.heading.copyWith(fontSize: 18)),
        content: Text(
          'Tambahkan ${user.name} sebagai kontak darurat?',
          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Batal', style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF193855),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              context.read<EmergencyCubit>().addContact(user.id, user.name, user.phoneNumber);
              Navigator.pop(dialogContext); // close dialog
              Navigator.pop(context); // go back to contacts page
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.name} berhasil ditambahkan sebagai kontak darurat'),
                  backgroundColor: const Color(0xFF22C55E),
                ),
              );
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
