import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/emergency_cubit.dart';
import 'add_contact_page.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  @override
  void initState() {
    super.initState();
    // Try loading contacts but handle gracefully if API not ready
    _loadContactsSafe();
  }

  Future<void> _loadContactsSafe() async {
    try {
      context.read<EmergencyCubit>().loadContacts();
    } catch (_) {
      // Silently handle — will show empty state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 30,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.shield, color: AppColors.primaryRed, size: 30),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: AppColors.textDark),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Kontak Darurat', style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  'Kelola daftar orang yang dapat dipercaya saat situasi darurat.',
                  style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: BlocBuilder<EmergencyCubit, EmergencyState>(
              builder: (context, state) {
                if (state is EmergencyLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is EmergencyLoaded) {
                  if (state.contacts.isEmpty) {
                    return _buildEmptyState();
                  }
                  return _buildContactsList(state.contacts);
                } else if (state is EmergencyError) {
                  // If API not ready or error, show empty state instead of error
                  return _buildEmptyState();
                }
                // Initial state — show empty state
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<EmergencyCubit>(),
                child: const AddContactPage(),
              ),
            ),
          );
          // Reload contacts when coming back
          if (mounted) _loadContactsSafe();
        },
        backgroundColor: AppColors.primaryRed,
        child: const Icon(Icons.group_add_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF4FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.contact_phone_outlined,
              size: 48,
              color: Color(0xFF193855),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada kontak darurat',
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
              'Tambahkan kontak darurat agar dapat dihubungi saat situasi darurat.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeading.copyWith(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<EmergencyCubit>(),
                    child: const AddContactPage(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.add, color: AppColors.primaryRed),
            label: Text(
              'Tambah Kontak',
              style: AppTextStyles.subHeading.copyWith(
                color: AppColors.primaryRed,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<ContactEntity> contacts) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.inputBorder),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEDF4FE),
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: AppTextStyles.heading.copyWith(fontSize: 20, color: const Color(0xFF193855)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.name,
                      style: AppTextStyles.subHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      contact.phoneNumber,
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: contact.status == 'Tersambung'
                              ? const Color(0xFF22C55E)
                              : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          contact.status,
                          style: AppTextStyles.subHeading.copyWith(
                            color: contact.status == 'Tersambung'
                                ? const Color(0xFF22C55E)
                                : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
                onPressed: () {},
              ),
            ],
          ),
        );
      },
    );
  }
}
