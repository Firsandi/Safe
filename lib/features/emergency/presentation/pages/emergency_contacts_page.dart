import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/contact_entity.dart';
import '../bloc/emergency_cubit.dart';
import 'add_contact_page.dart';
import 'dart:convert';
import 'package:safe/l10n/app_localizations.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContactsSafe() async {
    try {
      context.read<EmergencyCubit>().loadContacts();
    } catch (_) {}
  }

  List<ContactEntity> _filterContacts(List<ContactEntity> contacts) {
    if (_searchQuery.isEmpty) return contacts;
    final q = _searchQuery.toLowerCase();
    return contacts.where((c) =>
      c.name.toLowerCase().contains(q) ||
      c.phoneNumber.toLowerCase().contains(q)
    ).toList();
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
                  child: _isSearching ? _buildSearchBar() : _buildHeader(),
                ),

                // Title
                if (!_isSearching)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(AppLocalizations.of(context)!.emergencyContactsTitle, style: AppTextStyles.heading),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.emergencyContactsDesc,
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
                      Tab(text: AppLocalizations.of(context)!.myContacts),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(AppLocalizations.of(context)!.incomingRequests),
                            if (pendingCount > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                      _buildTabContent(state, () {
                        final filtered = _filterContacts(contacts);
                        if (contacts.isEmpty) return _buildEmptyState();
                        if (filtered.isEmpty) return _buildNoSearchResults();
                        return _buildContactsList(filtered);
                      }),
                      _buildTabContent(state, () {
                        if (requests.isEmpty) return _buildEmptyRequestsState();
                        return _buildRequestsList(requests);
                      }),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(
                  builder: (_) => BlocProvider.value(value: context.read<EmergencyCubit>(), child: const AddContactPage()),
                ));
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

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Image.asset('assets/images/logo.png', height: 48,
          errorBuilder: (c, e, s) => const Icon(Icons.shield, color: AppColors.primaryRed, size: 32)),
        IconButton(
          icon: const Icon(Icons.search, color: AppColors.textDark),
          onPressed: () => setState(() => _isSearching = true),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: AppColors.inputIconGrey, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: AppTextStyles.subHeading.copyWith(color: AppColors.textDark, fontSize: 14),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchPlaceholder,
                hintStyle: AppTextStyles.subHeading.copyWith(color: AppColors.inputIconGrey, fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textGrey, size: 20),
            onPressed: () {
              setState(() { _isSearching = false; _searchQuery = ''; _searchController.clear(); });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(EmergencyState state, Widget Function() onLoaded) {
    if (state is EmergencyLoading) return const Center(child: CircularProgressIndicator());
    if (state is EmergencyLoaded) return onLoaded();
    if (state is EmergencyError) return _buildErrorState(state.message);
    return _buildEmptyState();
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: AppColors.primaryRed.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.primaryRed),
            ),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.contactsLoadFailed, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadContactsSafe,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(AppLocalizations.of(context)!.retry),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF193855),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppColors.textGrey.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.noResultsFound, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)),
          const SizedBox(height: 8),
          Text(AppLocalizations.of(context)!.noContactsMatching(_searchQuery), textAlign: TextAlign.center, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFEDF4FE), shape: BoxShape.circle),
            child: const Icon(Icons.contact_phone_outlined, size: 48, color: Color(0xFF193855))),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.noEmergencyContacts, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(AppLocalizations.of(context)!.addContactsInstruction, textAlign: TextAlign.center, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildEmptyRequestsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(padding: const EdgeInsets.all(24), decoration: const BoxDecoration(color: Color(0xFFF3F4F6), shape: BoxShape.circle),
            child: const Icon(Icons.mark_email_read_outlined, size: 48, color: Color(0xFF6B7280))),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.noIncomingRequests, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)),
          const SizedBox(height: 8),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(AppLocalizations.of(context)!.incomingRequestsInstruction, textAlign: TextAlign.center, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13))),
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
        final statusText = isConnected 
            ? AppLocalizations.of(context)!.connected 
            : AppLocalizations.of(context)!.pending;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.inputBorder)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (contact.profileImage != null && contact.profileImage!.isNotEmpty) ? MemoryImage(base64Decode(contact.profileImage!)) : null,
                backgroundColor: const Color(0xFFEDF4FE),
                child: (contact.profileImage == null || contact.profileImage!.isEmpty)
                    ? Text(_getInitials(contact.name), style: AppTextStyles.heading.copyWith(fontSize: 20, color: const Color(0xFF193855)))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(contact.name, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(contact.phoneNumber, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.circle, size: 8, color: isConnected ? const Color(0xFF22C55E) : Colors.orange),
                    const SizedBox(width: 6),
                    Text(statusText, style: AppTextStyles.subHeading.copyWith(color: isConnected ? const Color(0xFF22C55E) : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)),
                  ]),
                ]),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textGrey),
                onPressed: () => _showContactOptions(contact),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showContactOptions(ContactEntity contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                // Contact info header
                Row(children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: (contact.profileImage != null && contact.profileImage!.isNotEmpty) ? MemoryImage(base64Decode(contact.profileImage!)) : null,
                    backgroundColor: const Color(0xFFEDF4FE),
                    child: (contact.profileImage == null || contact.profileImage!.isEmpty)
                        ? Text(_getInitials(contact.name), style: AppTextStyles.heading.copyWith(fontSize: 18, color: const Color(0xFF193855)))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(contact.name, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    Text(contact.phoneNumber, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13)),
                  ])),
                ]),
                const SizedBox(height: 16),
                const Divider(),
                // Menu items
                _buildOptionTile(Icons.phone_outlined, AppLocalizations.of(context)!.callContact, const Color(0xFF193855), () {
                  Navigator.pop(ctx);
                  _launchDialer(contact.phoneNumber);
                }),
                _buildOptionTile(Icons.chat_outlined, AppLocalizations.of(context)!.sendWhatsApp, const Color(0xFF25D366), () {
                  Navigator.pop(ctx);
                  _launchWhatsApp(contact.phoneNumber);
                }),
                _buildOptionTile(Icons.person_outline, AppLocalizations.of(context)!.viewProfile, const Color(0xFF193855), () {
                  Navigator.pop(ctx);
                  _showContactProfile(contact);
                }),
                _buildOptionTile(Icons.delete_outline, AppLocalizations.of(context)!.deleteContactTitle, AppColors.primaryRed, () {
                  Navigator.pop(ctx);
                  _confirmDeleteContact(contact);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionTile(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: color == AppColors.primaryRed ? AppColors.primaryRed : AppColors.textDark, fontSize: 15)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
      onTap: onTap,
    );
  }

  Future<void> _launchDialer(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) { await launchUrl(uri); }
  }

  Future<void> _launchWhatsApp(String phone) async {
    String cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) cleaned = '62${cleaned.substring(1)}';
    final uri = Uri.parse('https://wa.me/$cleaned');
    if (await canLaunchUrl(uri)) { await launchUrl(uri, mode: LaunchMode.externalApplication); }
  }

  void _showContactProfile(ContactEntity contact) {
    final isConnected = contact.status == 'Tersambung';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 24),
              CircleAvatar(
                radius: 40,
                backgroundImage: (contact.profileImage != null && contact.profileImage!.isNotEmpty) ? MemoryImage(base64Decode(contact.profileImage!)) : null,
                backgroundColor: const Color(0xFF193855),
                child: (contact.profileImage == null || contact.profileImage!.isEmpty)
                    ? Text(_getInitials(contact.name), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white))
                    : null,
              ),
              const SizedBox(height: 16),
              Text(contact.name, style: AppTextStyles.heading.copyWith(fontSize: 20)),
              const SizedBox(height: 8),
              Text(contact.phoneNumber, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isConnected ? const Color(0xFF22C55E).withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 8, color: isConnected ? const Color(0xFF22C55E) : Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? AppLocalizations.of(context)!.connected : AppLocalizations.of(context)!.pending,
                    style: TextStyle(color: isConnected ? const Color(0xFF22C55E) : Colors.orange, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _launchDialer(contact.phoneNumber); },
                  icon: const Icon(Icons.phone, size: 18),
                  label: Text(AppLocalizations.of(context)!.callContact),
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF193855), side: const BorderSide(color: Color(0xFF193855)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
                const SizedBox(width: 12),
                Expanded(child: ElevatedButton.icon(
                  onPressed: () { Navigator.pop(ctx); _launchWhatsApp(contact.phoneNumber); },
                  icon: const Icon(Icons.chat, size: 18),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 14)),
                )),
              ]),
            ]),
          ),
        );
      },
    );
  }

  void _confirmDeleteContact(ContactEntity contact) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(AppLocalizations.of(context)!.deleteContactTitle, style: AppTextStyles.heading.copyWith(fontSize: 18)),
        content: Text(AppLocalizations.of(context)!.deleteContactConfirm(contact.name), style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel, style: TextStyle(color: AppColors.textGrey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<EmergencyCubit>().deleteContact(contact.id);
            },
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.inputBorder)),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: (request.profileImage != null && request.profileImage!.isNotEmpty) ? MemoryImage(base64Decode(request.profileImage!)) : null,
                backgroundColor: const Color(0xFFEDF4FE),
                child: (request.profileImage == null || request.profileImage!.isEmpty)
                    ? Text(_getInitials(request.name), style: AppTextStyles.heading.copyWith(fontSize: 20, color: const Color(0xFF193855)))
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(request.name, style: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text(request.phoneNumber, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13)),
              ])),
              IconButton(
                icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle), child: const Icon(Icons.close, color: Colors.red, size: 20)),
                onPressed: () async { await context.read<EmergencyCubit>().rejectRequest(request.id); _loadContactsSafe(); },
              ),
              IconButton(
                icon: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Color(0xFF193855), shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 20)),
                onPressed: () async { await context.read<EmergencyCubit>().acceptRequest(request.id); _loadContactsSafe(); },
              ),
            ],
          ),
        );
      },
    );
  }
}
