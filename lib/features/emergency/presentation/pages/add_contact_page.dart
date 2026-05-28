import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import '../../../../core/error/dio_error_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/injection.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/emergency_cubit.dart';
import 'package:safe/l10n/app_localizations.dart';

class AddContactPage extends StatefulWidget {
  const AddContactPage({super.key});

  @override
  State<AddContactPage> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  final _phoneController = TextEditingController();
  bool _hasSearched = false;

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

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
                Text(AppLocalizations.of(context)!.addContactTitle, style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.addContactDesc,
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
                Text(AppLocalizations.of(context)!.addContactInputLabel, style: AppTextStyles.inputLabel),
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Phone / Email input
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.emailAddress,
                          style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark),
                          onChanged: (value) {
                            // Auto-search when user types 10+ characters
                            if (value.trim().length >= 10) {
                              _onSearch();
                            }
                          },
                          onSubmitted: (_) => _onSearch(),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.addContactInputHint,
                            hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            prefixIcon: const Icon(Icons.contact_mail_outlined, color: AppColors.inputIconGrey, size: 22),
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
                      AppLocalizations.of(context)!.addContactSearchResults,
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
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 48, color: AppColors.textGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            l10n.addContactInitialHint,
            style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    final l10n = AppLocalizations.of(context)!;
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
            l10n.addContactNotFound,
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
              l10n.addContactNotFoundDesc,
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
        final bool isAlreadyAdded = user.status == 'Tersambung' || user.status == 'Menunggu Konfirmasi';

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
              onTap: isAlreadyAdded ? null : () => _confirmAddContact(user),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: (user.profileImage != null && user.profileImage!.isNotEmpty)
                          ? MemoryImage(base64Decode(user.profileImage!))
                          : null,
                      backgroundColor: const Color(0xFFEDF4FE),
                      child: (user.profileImage == null || user.profileImage!.isEmpty)
                          ? Text(
                              _getInitials(user.name),
                              style: AppTextStyles.heading.copyWith(fontSize: 18, color: const Color(0xFF193855)),
                            )
                          : null,
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
                        color: isAlreadyAdded
                            ? Colors.grey[200]
                            : const Color(0xFF193855),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAlreadyAdded
                                ? (user.status == 'Tersambung' ? Icons.check : Icons.hourglass_empty)
                                : Icons.add,
                            color: isAlreadyAdded ? Colors.grey[600] : Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            user.status.isNotEmpty
                                ? (user.status == 'Tersambung'
                                    ? AppLocalizations.of(context)!.connected
                                    : (user.status == 'Menunggu Konfirmasi'
                                        ? AppLocalizations.of(context)!.pending
                                        : user.status))
                                : AppLocalizations.of(context)!.addContactButton,
                            style: AppTextStyles.subHeading.copyWith(
                              color: isAlreadyAdded ? Colors.grey[600] : Colors.white,
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.addContactConfirmTitle, style: AppTextStyles.heading.copyWith(fontSize: 18)),
        content: Text(
          l10n.addContactConfirmDesc(user.name),
          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel, style: TextStyle(color: AppColors.textGrey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF193855),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext); // close confirm dialog
              _addContactRemote(user); // perform API call
            },
            child: Text(l10n.addContactButton, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _addContactRemote(ContactEntity user) async {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryRed),
      ),
    );

    try {
      final dio = sl<Dio>();
      final response = await dio.post(
        '/api/contacts',
        data: {'target_user_id': user.id},
      );

      // Pop loading dialog
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        // Reload BLoC contacts
        if (mounted) {
          context.read<EmergencyCubit>().loadContacts();
          Navigator.pop(context); // Go back to emergency page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.addContactSuccess(user.name)),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on DioException catch (e) {
      // Pop loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(DioErrorHandler.getMessage(e)),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Pop loading dialog
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.addContactFailed),
            backgroundColor: AppColors.primaryRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
