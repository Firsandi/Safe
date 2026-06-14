import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/services/notification_local_service.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:dio/dio.dart';


class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<LocalNotification> _notifications = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isAscending = false; // default false = newest first (descending)

  void _sortNotifications(List<LocalNotification> list) {
    if (_isAscending) {
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    } else {
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
      if (_selectedIds.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _notifications.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(_notifications.map((n) => n.id));
      }
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteNotificationTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.deleteSelectedConfirm(_selectedIds.length)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final listToDelete = _selectedIds.toList();
      await NotificationLocalService.deleteNotifications(listToDelete);
      if (mounted) {
        setState(() {
          _notifications.removeWhere((n) => listToDelete.contains(n.id));
          _selectedIds.clear();
          _isSelectionMode = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.selectedDeletedSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // 1. Load cached notifications instantly for zero perceived delay
    var list = await NotificationLocalService.loadNotifications();
    _sortNotifications(list);

    if (mounted) {
      setState(() {
        _notifications = list;
        // Show loading indicator only if we have no cached data yet
        _isLoading = _notifications.isEmpty;
      });
    }

    // 2. Perform background sync from server
    try {
      await _syncNotificationsFromServer();
      // 3. Reload and display the fresh synced notifications
      list = await NotificationLocalService.loadNotifications();
      _sortNotifications(list);
    } catch (e) {
      debugPrint('Background sync failed: $e');
    } finally {
      if (mounted) {
        setState(() {
          _notifications = list;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncNotificationsFromServer() async {
    try {
      final dio = sl<Dio>();
      
      // Parallel fetches for sync
      final results = await Future.wait([
        dio.get('/api/contacts/requests'),
        dio.get('/api/sos/history/received'),
        dio.get('/api/contacts'),
        dio.get('/api/sos/history/sent'),
      ]);
      
      final requestsData = results[0].data['requests'] as List?;
      final receivedSosData = results[1].data as List?;
      final contactsData = results[2].data['contacts'] as List?;
      final sentSosData = results[3].data as List?;
      
      if (contactsData != null) {
        await NotificationLocalService.syncConnectionTimestamps(contactsData);
      }
      
      final connectionTimestamps = await NotificationLocalService.getConnectionTimestamps();
      final List<LocalNotification> newNotifs = [];

      if (requestsData != null && requestsData.isNotEmpty) {
        final notifications = await NotificationLocalService.loadNotifications();
        for (final req in requestsData) {
          final reqId = req['id']?.toString() ?? '';
          if (reqId.isEmpty) continue;
          final notifId = 'contact_req_$reqId';
          final exists = notifications.any((n) => n.id == notifId);
          if (!exists) {
            newNotifs.add(LocalNotification(
              id: notifId,
              title: 'Permintaan Kontak Darurat',
              body: '${req['name'] ?? 'Seseorang'} ingin menambahkan Anda sebagai kontak darurat.',
              type: 'contact_request',
              timestamp: DateTime.now(),
              isRead: false,
            ));
          }
        }
      }
      
      if (receivedSosData != null && receivedSosData.isNotEmpty) {
        final notifications = await NotificationLocalService.loadNotifications();
        for (final item in receivedSosData) {
          final status = item['status']?.toString() ?? '';
          if (status != 'active') continue; // Skip resolved/past SOS events to prevent notification flooding
          
          final sosId = item['sos_id']?.toString() ?? '';
          if (sosId.isEmpty) continue;
          
          // Check if event occurred after becoming friends
          final contactUserId = item['user_id']?.toString() ?? '';
          final connectionTimeStr = connectionTimestamps[contactUserId];
          if (connectionTimeStr != null) {
            final connectionTime = DateTime.parse(connectionTimeStr);
            final eventTime = DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now();
            if (eventTime.isBefore(connectionTime)) {
              // The event occurred before we became friends
              continue;
            }
          } else {
            // If contact is not in our active contacts list, skip
            continue;
          }
          
          final notifId = 'sos_event_$sosId';
          final exists = notifications.any((n) => n.id == notifId || (n.payload != null && n.payload!['sos_id']?.toString() == sosId));
          if (!exists) {
             final title = item['trigger_type'] == 'auto'
                ? 'EMERGENCY: BENTURAN/KECELAKAAN TERDETEKSI!'
                : 'EMERGENCY: BUTUH BANTUAN SEGERA!';
            final name = item['user_name'] ?? item['name'] ?? 'Seseorang';
            final triggerLabel = item['trigger_type'] == 'auto' ? 'Sensor Otomatis' : 'Manual';
            
            newNotifs.add(LocalNotification(
              id: notifId,
              title: title,
              body: '$name mengalami keadaan darurat ($triggerLabel)! Segera periksa lokasi.',
              type: 'sos_alert',
              timestamp: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              isRead: false,
              payload: Map<String, dynamic>.from(item),
            ));
          }
        }
      }

      if (sentSosData != null && sentSosData.isNotEmpty) {
        final notifications = await NotificationLocalService.loadNotifications();
        for (final item in sentSosData) {
          final sosId = item['sos_id']?.toString() ?? '';
          if (sosId.isEmpty) continue;
          
          final notifId = 'sos_sent_$sosId';
          final exists = notifications.any((n) => n.id == notifId || (n.payload != null && n.payload!['sos_id']?.toString() == sosId && n.type == 'sos_sent'));
          if (!exists) {
            newNotifs.add(LocalNotification(
              id: notifId,
              title: 'SOS Berhasil Terkirim',
              body: 'Sinyal darurat Anda telah berhasil dikirim ke kontak darurat.',
              type: 'sos_sent',
              timestamp: DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              isRead: false,
              payload: Map<String, dynamic>.from(item),
            ));
          }
        }
      }

      if (newNotifs.isNotEmpty) {
        await NotificationLocalService.saveNotifications(newNotifs);
      }
    } catch (_) {
      // Quietly ignore network failures and load local notifications
    }
  }


  Future<void> _markAllAsRead() async {
    await NotificationLocalService.markAllAsRead();
    await _loadNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.allMarkedReadSuccess),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF193855),
      ),
    );
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAllNotificationsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(AppLocalizations.of(context)!.deleteAllNotificationsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await NotificationLocalService.clearAll();
      if (mounted) {
        setState(() {
          _notifications = [];
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.allNotificationsDeletedSuccess),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.primaryRed,
          ),
        );
      }
    }
  }

  String _getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    final l10n = AppLocalizations.of(context)!;

    if (difference.inMinutes < 1) {
      return l10n.timeJustNow;
    } else if (difference.inMinutes < 60) {
      return l10n.timeMinutesAgo(difference.inMinutes);
    } else if (difference.inHours < 24) {
      return l10n.timeHoursAgo(difference.inHours);
    } else if (difference.inDays == 1) {
      return l10n.timeYesterday;
    } else {
      return l10n.timeDaysAgo(difference.inDays);
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'sos_alert':
        return Icons.warning_amber_rounded;
      case 'sos_sent':
        return Icons.send_rounded;
      case 'contact_request':
        return Icons.person_add_outlined;
      case 'contact_request_sent':
        return Icons.person_add_outlined;
      case 'contact_accepted':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'sos_alert':
        return AppColors.primaryRed;
      case 'sos_sent':
        return const Color(0xFF10B981); // Green
      case 'contact_request':
        return const Color(0xFF3B82F6); // Blue
      case 'contact_request_sent':
        return const Color(0xFF8B5CF6); // Purple
      case 'contact_accepted':
        return const Color(0xFF10B981); // Green
      default:
        return AppColors.textGrey;
    }
  }

  void _handleNotificationTap(LocalNotification notif) async {
    // 1. Mark as read locally
    await NotificationLocalService.markAsRead(notif.id);
    
    // 2. Perform redirection back to Home with action payload
    if (mounted) {
      if (notif.type == 'sos_alert') {
        // Redirect to SOS History -> Received tab (index 2 in Home, with initialTabIndex = 1)
        Navigator.pop(context, {'action': 'go_to_history', 'tab': 1});
      } else if (notif.type == 'sos_sent') {
        // Redirect to SOS History -> Sent tab (index 2 in Home, with initialTabIndex = 0)
        Navigator.pop(context, {'action': 'go_to_history', 'tab': 0});
      } else if (notif.type == 'contact_request') {
        // Redirect to Contacts tab -> Permintaan Masuk tab (tab index 1)
        Navigator.pop(context, {'action': 'go_to_contacts', 'tab': 1});
      } else if (notif.type == 'contact_request_sent') {
        // Redirect to Contacts tab -> Kontak Saya tab (tab index 0)
        Navigator.pop(context, {'action': 'go_to_contacts', 'tab': 0});
      } else if (notif.type == 'contact_accepted') {
        // Redirect to Contacts tab -> Kontak Saya tab (tab index 0)
        Navigator.pop(context, {'action': 'go_to_contacts', 'tab': 0});
      } else {
        // Default simply reload and mark as read
        _loadNotifications();
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Text(
          _isSelectionMode
              ? AppLocalizations.of(context)!.notificationsSelected(_selectedIds.length)
              : AppLocalizations.of(context)!.notificationsTitle,
          style: AppTextStyles.heading.copyWith(fontSize: 18, color: AppColors.textDark),
        ),
        leading: IconButton(
          icon: Icon(_isSelectionMode ? Icons.close : Icons.arrow_back_ios, color: AppColors.textDark, size: 20),
          onPressed: () {
            if (_isSelectionMode) {
              setState(() {
                _isSelectionMode = false;
                _selectedIds.clear();
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: _notifications.isNotEmpty
            ? (_isSelectionMode
                ? [
                    IconButton(
                      icon: Icon(
                        _selectedIds.length == _notifications.length
                            ? Icons.deselect_outlined
                            : Icons.select_all_outlined,
                        color: const Color(0xFF193855),
                      ),
                      tooltip: _selectedIds.length == _notifications.length
                          ? AppLocalizations.of(context)!.deselectAll
                          : AppLocalizations.of(context)!.selectAll,
                      onPressed: _toggleSelectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
                      tooltip: AppLocalizations.of(context)!.deleteSelectedTooltip,
                      onPressed: _deleteSelected,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.checklist_outlined, color: Color(0xFF193855)),
                      tooltip: AppLocalizations.of(context)!.selectNotificationsTooltip,
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.done_all, color: Color(0xFF193855)),
                      tooltip: AppLocalizations.of(context)!.markAllAsReadTooltip,
                      onPressed: _markAllAsRead,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.primaryRed),
                      tooltip: AppLocalizations.of(context)!.deleteAllTooltip,
                      onPressed: _deleteAll,
                    ),
                  ])
            : null,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
            : _notifications.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                    _buildSortHeader(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notif = _notifications[index];
                    final color = _getColorForType(notif.type);
                    final icon = _getIconForType(notif.type);

                    return Dismissible(
                      key: Key(notif.id),
                      direction: _isSelectionMode ? DismissDirection.none : DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryRed,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.white),
                      ),
                      onDismissed: (direction) async {
                        final notifId = notif.id;
                        final deleteSuccessText = AppLocalizations.of(context)!.notificationDeletedSuccess;
                        setState(() {
                          _notifications.removeAt(index);
                        });
                        final messenger = ScaffoldMessenger.of(context);
                        await NotificationLocalService.deleteNotification(notifId);
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(deleteSuccessText),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Row(
                        children: [
                          if (_isSelectionMode) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.only(right: 12, bottom: 12),
                              child: InkWell(
                                onTap: () => _toggleSelection(notif.id),
                                borderRadius: BorderRadius.circular(100),
                                child: Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _selectedIds.contains(notif.id)
                                        ? AppColors.primaryRed
                                        : Colors.white,
                                    border: Border.all(
                                      color: _selectedIds.contains(notif.id)
                                          ? AppColors.primaryRed
                                          : Colors.grey[300]!,
                                      width: 2,
                                    ),
                                  ),
                                  child: _selectedIds.contains(notif.id)
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: notif.isRead ? Colors.white : const Color(0xFFF0F5FA),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: notif.isRead ? Colors.grey[100]! : const Color(0xFFD4E2F0),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.01),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _isSelectionMode
                                      ? () => _toggleSelection(notif.id)
                                      : () => _handleNotificationTap(notif),
                                  onLongPress: !_isSelectionMode
                                      ? () {
                                          setState(() {
                                            _isSelectionMode = true;
                                            _selectedIds.add(notif.id);
                                          });
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Icon
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: color.withOpacity(0.1),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(icon, color: color, size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        
                                        // Text Content
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  // Time
                                                  Text(
                                                    _getRelativeTime(notif.timestamp),
                                                    style: AppTextStyles.subHeading.copyWith(
                                                      fontSize: 11,
                                                      color: AppColors.textGrey,
                                                    ),
                                                  ),
                                                  // Unread Indicator Dot
                                                  if (!notif.isRead)
                                                    Container(
                                                      width: 8,
                                                      height: 8,
                                                      decoration: const BoxDecoration(
                                                        color: Color(0xFF3B82F6), // Blue dot
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _getLocalizedTitle(notif),
                                                style: AppTextStyles.subHeading.copyWith(
                                                  fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w800,
                                                  fontSize: 13,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _getLocalizedBody(notif),
                                                style: AppTextStyles.subHeading.copyWith(
                                                  fontSize: 12,
                                                  color: Colors.grey[700],
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
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                    ),
                  ],
                ),
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
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 48,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noNotifications,
            style: AppTextStyles.heading.copyWith(fontSize: 16, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              AppLocalizations.of(context)!.noNotificationsDesc,
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
  String _getLocalizedTitle(LocalNotification notif) {
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final title = notif.title;
    
    if (isEn) {
      if (title == 'EMERGENCY: BENTURAN/KECELAKAAN TERDETEKSI!') {
        return 'EMERGENCY: IMPACT/ACCIDENT DETECTED!';
      }
      if (title == 'EMERGENCY: BUTUH BANTUAN SEGERA!') {
        return 'EMERGENCY: NEED IMMEDIATE HELP!';
      }
      if (title == 'Permintaan Kontak Darurat') {
        return 'Emergency Contact Request';
      }
      if (title == 'Permintaan Kontak Diterima' || title == 'Kontak Tersambung') {
        return 'Emergency Contact Request Accepted';
      }
      if (title == 'Notifikasi Baru') {
        return 'New Notification';
      }
      if (title == 'SOS Berhasil Terkirim') {
        return 'SOS Successfully Sent';
      }
      if (title == 'Permintaan Kontak Dikirim') {
        return 'Emergency Contact Request Sent';
      }
    } else {
      if (title == 'EMERGENCY: IMPACT/ACCIDENT DETECTED!') {
        return 'EMERGENCY: BENTURAN/KECELAKAAN TERDETEKSI!';
      }
      if (title == 'EMERGENCY: NEED IMMEDIATE HELP!') {
        return 'EMERGENCY: BUTUH BANTUAN SEGERA!';
      }
      if (title == 'Emergency Contact Request') {
        return 'Permintaan Kontak Darurat';
      }
      if (title == 'Emergency Contact Request Accepted' || title == 'Contact Connected') {
        return 'Permintaan Kontak Diterima';
      }
      if (title == 'New Notification') {
        return 'Notifikasi Baru';
      }
      if (title == 'SOS Successfully Sent') {
        return 'SOS Berhasil Terkirim';
      }
      if (title == 'Emergency Contact Request Sent') {
        return 'Permintaan Kontak Dikirim';
      }
    }
    return title;
  }

  String _getLocalizedBody(LocalNotification notif) {
    final lang = Localizations.localeOf(context).languageCode;
    final isEn = lang == 'en';
    final body = notif.body;

    if (isEn) {
      if (body.contains('mengalami keadaan darurat')) {
        final regex = RegExp(r'^(.+) mengalami keadaan darurat \((.+)\)! Segera periksa lokasi\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          var trigger = match.group(2);
          if (trigger == 'Sensor Otomatis') {
            trigger = 'Auto Sensor';
          }
          return '$name is experiencing an emergency ($trigger)! Check their location immediately.';
        }
      }

      if (body.contains('ingin menambahkan Anda sebagai kontak darurat')) {
        final regex = RegExp(r'^(.+) ingin menambahkan Anda sebagai kontak darurat\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          return '$name wants to add you as an emergency contact.';
        }
      }

      if (body.contains('telah menyetujui permintaan kontak darurat Anda')) {
        final regex = RegExp(r'^(.+) telah menyetujui permintaan kontak darurat Anda\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          return '$name accepted your emergency contact request.';
        }
      }

      if (body == 'Sinyal darurat Anda telah berhasil dikirim ke kontak darurat.') {
        return 'Your emergency signal has been successfully sent to emergency contacts.';
      }

      if (body.contains('Permintaan kontak darurat telah dikirim ke')) {
        final regex = RegExp(r'^Permintaan kontak darurat telah dikirim ke (.+)\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          return 'Emergency contact request has been sent to $name.';
        }
      }

      if (body == 'Anda menerima pesan darurat baru.') {
        return 'You received a new emergency message.';
      }
    } else {
      if (body.contains('is experiencing an emergency')) {
        final regex = RegExp(r'^(.+) is experiencing an emergency \((.+)\)! Check their location immediately\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          var trigger = match.group(2);
          if (trigger == 'Auto Sensor') {
            trigger = 'Sensor Otomatis';
          }
          return '$name mengalami keadaan darurat ($trigger)! Segera periksa lokasi.';
        }
      }

      if (body.contains('wants to add you as an emergency contact')) {
        final regex = RegExp(r'^(.+) wants to add you as an emergency contact\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          return '$name ingin menambahkan Anda sebagai kontak darurat.';
        }
      }

      if (body.contains('accepted your emergency contact request')) {
        final regex = RegExp(r'^(.+) accepted your emergency contact request\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          return '$name telah menyetujui permintaan kontak darurat Anda.';
        }
      }

      if (body == 'Your emergency signal has been successfully sent to emergency contacts.') {
        return 'Sinyal darurat Anda telah berhasil dikirim ke kontak darurat.';
      }

      if (body.contains('Emergency contact request has been sent to')) {
        final regex = RegExp(r'^Emergency contact request has been sent to (.+)\.$');
        final match = regex.firstMatch(body);
        if (match != null) {
          final name = match.group(1);
          return 'Permintaan kontak darurat telah dikirim ke $name.';
        }
      }

      if (body == 'You received a new emergency message.') {
        return 'Anda menerima pesan darurat baru.';
      }
    }

    return body;
  }

  Widget _buildSortHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)!.notificationListHeader,
            style: AppTextStyles.subHeading.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textGrey,
              fontSize: 12,
            ),
          ),
          InkWell(
            onTap: () {
              setState(() {
                _isAscending = !_isAscending;
                _sortNotifications(_notifications);
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    _isAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: const Color(0xFF193855),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _isAscending ? AppLocalizations.of(context)!.sortOldest : AppLocalizations.of(context)!.sortNewest,
                    style: AppTextStyles.subHeading.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF193855),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
