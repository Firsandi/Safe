import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/emergency_cubit.dart';
import 'add_contact_page.dart';
import 'dart:convert';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadContactsSafe();
  }

  Future<void> _loadContactsSafe() async {
    try {
      context.read<EmergencyCubit>().loadContacts();
    } catch (_) {
      // Silently handle
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmergencyCubit, EmergencyState>(
      builder: (context, state) {
        int pendingCount = 0;
        List<ContactEntity> contacts = [];
        List<ContactEntity> requests = [];

        if (state is EmergencyLoaded) {
          contacts = state.contacts;
          requests = state.requests;
          pendingCount = requests.length;
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
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
                        height: 48,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.shield, color: AppColors.primaryRed, size: 32),
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
                const SizedBox(height: 8),

                // Custom TabBar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TabBar(
                    labelColor: const Color(0xFF193855),
                    unselectedLabelColor: AppColors.textGrey,
                    indicatorColor: const Color(0xFF193855),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorWeight: 3,
                    labelStyle: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                    unselectedLabelStyle: AppTextStyles.subHeading.copyWith(fontSize: 14),
                    tabs: [
                      const Tab(text: 'Kontak Saya'),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Permintaan Masuk'),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '$pendingCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: Kontak Saya
                      _buildTabContent(state, () {
                        if (contacts.isEmpty) {
                          return _buildEmptyState();
                        }
                        return _buildContactsList(contacts);
                      }),

                      // TAB 2: Permintaan Masuk
                      _buildTabContent(state, () {
                        if (requests.isEmpty) {
                          return _buildEmptyRequestsState();
                        }
                        return _buildRequestsList(requests);
                      }),
                    ],
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
                if (mounted) _loadContactsSafe();
              },
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              child: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabContent(EmergencyState state, Widget Function() onLoaded) {
    if (state is EmergencyLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is EmergencyLoaded) {
      return onLoaded();
    } else if (state is EmergencyError) {
      return _buildEmptyState();
    }
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFEDF4FE),
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
        ],
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Tidak ada permintaan masuk',
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
              'Permintaan masuk dari pengguna lain yang ingin menambahkan Anda akan muncul di sini.',
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeading.copyWith(
                color: AppColors.textGrey,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactsList(List<ContactEntity> contacts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final isConnected = contact.status == 'Tersambung';
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
                backgroundImage: (contact.profileImage != null && contact.profileImage!.isNotEmpty)
                    ? MemoryImage(base64Decode(contact.profileImage!))
                    : null,
                backgroundColor: const Color(0xFFEDF4FE),
                child: (contact.profileImage == null || contact.profileImage!.isEmpty)
                    ? Text(
                        _getInitials(contact.name),
                        style: AppTextStyles.heading.copyWith(fontSize: 20, color: const Color(0xFF193855)),
                      )
                    : null,
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
                          color: isConnected ? const Color(0xFF22C55E) : Colors.orange,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          contact.status,
                          style: AppTextStyles.subHeading.copyWith(
                            color: isConnected ? const Color(0xFF22C55E) : Colors.orange,
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

  Widget _buildRequestsList(List<ContactEntity> requests) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
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
                backgroundImage: (request.profileImage != null && request.profileImage!.isNotEmpty)
                    ? MemoryImage(base64Decode(request.profileImage!))
                    : null,
                backgroundColor: const Color(0xFFEDF4FE),
                child: (request.profileImage == null || request.profileImage!.isEmpty)
                    ? Text(
                        _getInitials(request.name),
                        style: AppTextStyles.heading.copyWith(fontSize: 20, color: const Color(0xFF193855)),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.name,
                      style: AppTextStyles.subHeading.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.phoneNumber,
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Reject Button (Red cross circle)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 20),
                ),
                onPressed: () async {
                  await context.read<EmergencyCubit>().rejectRequest(request.id);
                  _loadContactsSafe();
                },
              ),
              // Accept Button (Dark Blue check circle)
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFF193855),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                onPressed: () async {
                  await context.read<EmergencyCubit>().acceptRequest(request.id);
                  _loadContactsSafe();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
