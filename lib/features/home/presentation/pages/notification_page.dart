import 'package:flutter/material.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/services/notification_local_service.dart';

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
        title: const Text('Hapus Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Apakah Anda yakin ingin menghapus ${_selectedIds.length} notifikasi terpilih?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
          const SnackBar(
            content: Text('Notifikasi terpilih berhasil dihapus'),
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
    setState(() => _isLoading = true);
    var list = await NotificationLocalService.loadNotifications();

    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    await NotificationLocalService.markAllAsRead();
    await _loadNotifications();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Semua notifikasi ditandai telah dibaca'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF193855),
      ),
    );
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Semua Notifikasi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Apakah Anda yakin ingin menghapus semua riwayat notifikasi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
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
          const SnackBar(
            content: Text('Semua notifikasi berhasil dihapus'),
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

    if (difference.inMinutes < 1) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays == 1) {
      return 'Kemarin';
    } else {
      return '${difference.inDays} hari lalu';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'sos_alert':
        return Icons.warning_amber_rounded;
      case 'contact_request':
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
      case 'contact_request':
        return const Color(0xFF3B82F6); // Blue
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
      } else if (notif.type == 'contact_request' || notif.type == 'contact_accepted') {
        // Redirect to Contacts tab (index 1 in Home)
        Navigator.pop(context, {'action': 'go_to_contacts'});
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
          _isSelectionMode ? '${_selectedIds.length} Terpilih' : 'Notifikasi',
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
                          ? 'Batal pilih semua'
                          : 'Pilih semua',
                      onPressed: _toggleSelectAll,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.primaryRed),
                      tooltip: 'Hapus terpilih',
                      onPressed: _deleteSelected,
                    ),
                  ]
                : [
                    IconButton(
                      icon: const Icon(Icons.checklist_outlined, color: Color(0xFF193855)),
                      tooltip: 'Pilih notifikasi',
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.done_all, color: Color(0xFF193855)),
                      tooltip: 'Tandai semua dibaca',
                      onPressed: _markAllAsRead,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.primaryRed),
                      tooltip: 'Hapus semua',
                      onPressed: _deleteAll,
                    ),
                  ])
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryRed))
          : _notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        setState(() {
                          _notifications.removeAt(index);
                        });
                        final messenger = ScaffoldMessenger.of(context);
                        await NotificationLocalService.deleteNotification(notifId);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Notifikasi berhasil dihapus'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 1),
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
                                                notif.title,
                                                style: AppTextStyles.subHeading.copyWith(
                                                  fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w800,
                                                  fontSize: 13,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                notif.body,
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
            'Tidak Ada Notifikasi',
            style: AppTextStyles.heading.copyWith(fontSize: 16, color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Seluruh pemberitahuan masuk terkait SOS dan kontak darurat Anda akan ditampilkan di sini.',
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
}
