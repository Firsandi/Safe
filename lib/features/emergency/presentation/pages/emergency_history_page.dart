import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:safe/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/injection.dart';
import 'sos_route_page.dart';
import 'sos_sent_map_page.dart';
import '../../../../core/services/notification_local_service.dart';

class EmergencyHistoryPage extends StatefulWidget {
  final int initialTabIndex;
  const EmergencyHistoryPage({super.key, this.initialTabIndex = 0});

  @override
  State<EmergencyHistoryPage> createState() => _EmergencyHistoryPageState();
}

class _EmergencyHistoryPageState extends State<EmergencyHistoryPage> {
  // Loading and Error States
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasSentError = false;
  bool _hasReceivedError = false;

  // Pagination Configuration & States
  final int _pageSize = 10;

  // Sent SOS Pagination
  int _sentPage = 1;
  bool _hasMoreSent = true;
  bool _isLoadingMoreSent = false;
  bool _isSentServerPaged = false;
  List<dynamic> _allSentHistory = [];
  List<dynamic> _displayedSentHistory = [];
  final ScrollController _sentScrollController = ScrollController();

  // Received SOS Pagination
  int _receivedPage = 1;
  bool _hasMoreReceived = true;
  bool _isLoadingMoreReceived = false;
  bool _isReceivedServerPaged = false;
  List<dynamic> _allReceivedHistory = [];
  List<dynamic> _displayedReceivedHistory = [];
  final ScrollController _receivedScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchHistory();

    // Attach listeners for infinite scroll
    _sentScrollController.addListener(_onSentScroll);
    _receivedScrollController.addListener(_onReceivedScroll);
  }

  @override
  void dispose() {
    _sentScrollController.removeListener(_onSentScroll);
    _receivedScrollController.removeListener(_onReceivedScroll);
    _sentScrollController.dispose();
    _receivedScrollController.dispose();
    super.dispose();
  }

  void _onSentScroll() {
    if (_sentScrollController.position.pixels >=
        _sentScrollController.position.maxScrollExtent - 200) {
      _loadMoreSent();
    }
  }

  void _onReceivedScroll() {
    if (_receivedScrollController.position.pixels >=
        _receivedScrollController.position.maxScrollExtent - 200) {
      _loadMoreReceived();
    }
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSentError = false;
      _hasReceivedError = false;
      _sentPage = 1;
      _receivedPage = 1;
      _hasMoreSent = true;
      _hasMoreReceived = true;
      _displayedSentHistory = [];
      _displayedReceivedHistory = [];
    });

    try {
      final dio = sl<Dio>();

      // Fetch initial pages and contacts list in parallel, catching errors individually so one failure doesn't break the entire UI
      final results = await Future.wait([
        dio.get(
          '/api/sos/history/sent',
          queryParameters: {'page': 1, 'limit': _pageSize},
        ).catchError((e) {
          debugPrint('Error fetching sent history: $e');
          return Response(
            requestOptions: RequestOptions(path: '/api/sos/history/sent'),
            data: <dynamic>[],
            statusCode: 500,
          );
        }),
        dio.get(
          '/api/sos/history/received',
          queryParameters: {'page': 1, 'limit': _pageSize},
          options: Options(receiveTimeout: const Duration(seconds: 30)),
        ).catchError((e) {
          debugPrint('Error fetching received history: $e');
          return Response(
            requestOptions: RequestOptions(path: '/api/sos/history/received'),
            data: <dynamic>[],
            statusCode: 500,
          );
        }),
        dio.get('/api/contacts').catchError((e) {
          debugPrint('Error fetching contacts: $e');
          return Response(
            requestOptions: RequestOptions(path: '/api/contacts'),
            data: {'contacts': <dynamic>[]},
            statusCode: 500,
          );
        }),
      ]);

      final sentRes = results[0];
      final receivedRes = results[1];
      final contactsRes = results[2];

      // If the received endpoint returned unauthorized, prompt user to login
      if (receivedRes.statusCode == 401) {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Sesi login kadaluwarsa. Silakan login kembali untuk melihat SOS diterima.'),
                backgroundColor: AppColors.primaryRed,
                duration: const Duration(seconds: 4),
              ),
            );
          });
        }
      }

      final sentFailed = sentRes.statusCode == 500;
      final receivedFailed = receivedRes.statusCode == 500;

      // If both endpoints failed completely, we throw an error to show the general error screen
      if (sentFailed && receivedFailed) {
        throw Exception("Gagal memuat riwayat dari server.");
      }

      final rawSent = sentRes.data ?? [];
      final rawReceived = receivedRes.data ?? [];
      final rawContacts = contactsRes.statusCode == 200 && contactsRes.data != null
          ? contactsRes.data['contacts'] as List?
          : null;

      if (rawContacts != null) {
        await NotificationLocalService.syncConnectionTimestamps(rawContacts);
      }

      if (!mounted) return;
      setState(() {
        _hasSentError = sentFailed;
        _hasReceivedError = receivedFailed;

        // 1. Sent History Pagination setup
        if (rawSent.length > _pageSize) {
          _isSentServerPaged = false;
          _allSentHistory = rawSent;
          _displayedSentHistory = _allSentHistory.take(_pageSize).toList();
          _hasMoreSent = _allSentHistory.length > _pageSize;
        } else {
          _isSentServerPaged = true;
          _displayedSentHistory = List.from(rawSent);
          _hasMoreSent = rawSent.length == _pageSize && !sentFailed;
        }

        // 2. Received History Pagination setup
        if (rawReceived.length > _pageSize) {
          _isReceivedServerPaged = false;
          _allReceivedHistory = rawReceived;
          _displayedReceivedHistory = _allReceivedHistory.take(_pageSize).toList();
          _hasMoreReceived = _allReceivedHistory.length > _pageSize;
        } else {
          _isReceivedServerPaged = true;
          _displayedReceivedHistory = List.from(rawReceived);
          _hasMoreReceived = rawReceived.length == _pageSize && !receivedFailed;
        }

        _isLoading = false;
      });

      _syncReceivedSosToNotifications(rawReceived);

      // If one of the tabs failed to load, show a SnackBar to alert the user
      if (sentFailed || receivedFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  sentFailed
                      ? 'Gagal memuat riwayat terkirim.'
                      : 'Gagal memuat riwayat diterima.',
                ),
                backgroundColor: AppColors.primaryRed,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _syncReceivedSosToNotifications(List<dynamic> receivedList) async {
    if (receivedList.isEmpty) return;
    try {
      final connectionTimestamps = await NotificationLocalService.getConnectionTimestamps();
      final notifications = await NotificationLocalService.loadNotifications();
      final List<LocalNotification> newNotifs = [];
      for (final item in receivedList) {
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
          final triggerLabel = item['trigger_type'] == 'auto'
              ? 'Sensor Otomatis'
              : 'Manual';

          newNotifs.add(
            LocalNotification(
              id: notifId,
              title: title,
              body:
                  '$name mengalami keadaan darurat ($triggerLabel)! Segera periksa lokasi.',
              type: 'sos_alert',
              timestamp:
                  DateTime.tryParse(item['created_at'] ?? '') ?? DateTime.now(),
              isRead: false,
              payload: Map<String, dynamic>.from(item),
            ),
          );
        }
      }
      if (newNotifs.isNotEmpty) {
        await NotificationLocalService.saveNotifications(newNotifs);
      }
    } catch (_) {}
  }

  Future<void> _loadMoreSent() async {
    if (_isLoadingMoreSent || !_hasMoreSent) return;

    setState(() {
      _isLoadingMoreSent = true;
    });

    try {
      if (_isSentServerPaged) {
        final dio = sl<Dio>();
        final nextPage = _sentPage + 1;
        final res = await dio.get(
          '/api/sos/history/sent',
          queryParameters: {'page': nextPage, 'limit': _pageSize},
        );
        final newItems = res.data ?? [];

        if (!mounted) return;
        setState(() {
          _sentPage = nextPage;
          _displayedSentHistory.addAll(newItems);
          _hasMoreSent = newItems.length == _pageSize;
        });
      } else {
        // Client-side pagination: load from locally stored list
        await Future.delayed(
          const Duration(milliseconds: 200),
        ); // Smooth loading feel
        final currentLen = _displayedSentHistory.length;
        final nextItems = _allSentHistory
            .skip(currentLen)
            .take(_pageSize)
            .toList();

        if (!mounted) return;
        setState(() {
          _displayedSentHistory.addAll(nextItems);
          _hasMoreSent = _displayedSentHistory.length < _allSentHistory.length;
        });
      }
    } catch (_) {
      // Quiet fail
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreSent = false;
        });
      }
    }
  }

  Future<void> _loadMoreReceived() async {
    if (_isLoadingMoreReceived || !_hasMoreReceived) return;

    setState(() {
      _isLoadingMoreReceived = true;
    });

    try {
      if (_isReceivedServerPaged) {
        final dio = sl<Dio>();
        final nextPage = _receivedPage + 1;
        final res = await dio.get(
          '/api/sos/history/received',
          queryParameters: {'page': nextPage, 'limit': _pageSize},
        );
        final newItems = res.data ?? [];

        if (!mounted) return;
        setState(() {
          _receivedPage = nextPage;
          _displayedReceivedHistory.addAll(newItems);
          _hasMoreReceived = newItems.length == _pageSize;
        });
      } else {
        // Client-side pagination: load from locally stored list
        await Future.delayed(
          const Duration(milliseconds: 200),
        ); // Smooth loading feel
        final currentLen = _displayedReceivedHistory.length;
        final nextItems = _allReceivedHistory
            .skip(currentLen)
            .take(_pageSize)
            .toList();

        if (!mounted) return;
        setState(() {
          _displayedReceivedHistory.addAll(nextItems);
          _hasMoreReceived =
              _displayedReceivedHistory.length < _allReceivedHistory.length;
        });
      }
    } catch (_) {
      // Quiet fail
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreReceived = false;
        });
      }
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final locale = Localizations.localeOf(context).toLanguageTag();
      return DateFormat('dd MMM yyyy, HH:mm', locale).format(dateTime);
    } catch (_) {
      return dateStr;
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'active':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFEF4444);
        label = AppLocalizations.of(context)!.statusActive;
        break;
      case 'resolved':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF10B981);
        label = AppLocalizations.of(context)!.statusResolved;
        break;
      case 'false_alarm':
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = AppLocalizations.of(context)!.statusFalseAlarm;
        break;
      default:
        bgColor = const Color(0xFFE5E7EB);
        textColor = const Color(0xFF374151);
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTextStyles.inputLabel.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTabIndex,
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.emergencyHistoryTitle,
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.historySosDesc,
                    style: AppTextStyles.subHeading.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // TabBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TabBar(
                labelColor: const Color(0xFF193855),
                unselectedLabelColor: AppColors.textGrey,
                indicatorColor: const Color(0xFF193855),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorWeight: 3,
                labelStyle: AppTextStyles.subHeading.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                unselectedLabelStyle: AppTextStyles.subHeading.copyWith(
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: l10n.historyTabSent),
                  Tab(text: l10n.historyTabReceived),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) =>
                          const BreathingSkeletonCard(),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.primaryRed,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '${l10n.historyLoadFailed}: $_errorMessage',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.subHeading,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchHistory,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF193855),
                              ),
                              child: Text(
                                l10n.retry,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : TabBarView(
                      children: [_buildSentTab(), _buildReceivedTab()],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_hasSentError && _displayedSentHistory.isEmpty) {
      return _buildErrorState(l10n.historyLoadFailed);
    }
    if (_displayedSentHistory.isEmpty) {
      return _buildEmptyState(l10n.historyNoSent);
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        controller: _sentScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _displayedSentHistory.length + (_isLoadingMoreSent ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedSentHistory.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryRed,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          final event = _displayedSentHistory[index];
          final triggerType = event['trigger_type'] ?? 'manual';
          final isAuto = triggerType == 'auto';

          return InkWell(
            onTap: () async {
              try {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SosSentMapPage(sosEvent: event),
                  ),
                );
              } catch (e, st) {
                debugPrint('Failed to open SosSentMapPage: $e\n$st');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuka detail SOS: $e')),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAuto ? Icons.sensors : Icons.touch_app_outlined,
                            color: isAuto
                                ? AppColors.primaryRed
                                : const Color(0xFF193855),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isAuto ? l10n.triggerAuto : l10n.triggerManual,
                            style: AppTextStyles.subHeading.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                      _buildStatusBadge(event['status'] ?? 'active'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textGrey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatDateTime(event['created_at']),
                        style: AppTextStyles.subHeading.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _AddressText(
                          latitude: double.tryParse(event['initial_latitude']?.toString() ?? '') ?? 0.0,
                          longitude: double.tryParse(event['initial_longitude']?.toString() ?? '') ?? 0.0,
                          style: AppTextStyles.subHeading.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceivedTab() {
    final l10n = AppLocalizations.of(context)!;
    if (_hasReceivedError && _displayedReceivedHistory.isEmpty) {
      return _buildErrorState(l10n.historyLoadFailed);
    }
    if (_displayedReceivedHistory.isEmpty) {
      return _buildEmptyState(l10n.historyNoReceived);
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        controller: _receivedScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount:
            _displayedReceivedHistory.length + (_isLoadingMoreReceived ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedReceivedHistory.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.primaryRed,
                    strokeWidth: 2,
                  ),
                ),
              ),
            );
          }

          final event = _displayedReceivedHistory[index];
          final triggerType = event['trigger_type'] ?? 'manual';
          final isAuto = triggerType == 'auto';

          return InkWell(
            onTap: () async {
              try {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SosRoutePage(sosEvent: event),
                  ),
                );
              } catch (e, st) {
                debugPrint('Failed to open SosRoutePage: $e\n$st');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal membuka rute SOS: $e')),
                  );
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.inputBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.person_outline,
                              color: Color(0xFF193855),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                event['user_name'] ?? l10n.contactPlaceholder,
                                style: AppTextStyles.subHeading.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(event['status'] ?? 'active'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.phoneLabelAbbr} ${event['user_phone'] ?? '-'}',
                    style: AppTextStyles.subHeading.copyWith(
                      color: AppColors.textGrey,
                      fontSize: 13,
                    ),
                  ),
                  const Divider(height: 24, color: AppColors.inputBorder),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isAuto ? Icons.sensors : Icons.touch_app_outlined,
                            color: isAuto
                                ? AppColors.primaryRed
                                : const Color(0xFF193855),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isAuto ? l10n.triggerAuto : l10n.triggerManual,
                            style: AppTextStyles.subHeading.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDateTime(event['created_at']),
                        style: AppTextStyles.subHeading.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2.0),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _AddressText(
                          latitude: double.tryParse(event['initial_latitude']?.toString() ?? '') ?? 0.0,
                          longitude: double.tryParse(event['initial_longitude']?.toString() ?? '') ?? 0.0,
                          style: AppTextStyles.subHeading.copyWith(
                            color: AppColors.textGrey,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
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
              Icons.history,
              size: 48,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            AppLocalizations.of(context)!.noHistory,
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
              message,
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

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.primaryRed,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.subHeading,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchHistory,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF193855),
              ),
              child: Text(
                AppLocalizations.of(context)!.retry,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Beautiful Custom Pulsing Skeleton Card for Loading states
class BreathingSkeletonCard extends StatefulWidget {
  const BreathingSkeletonCard({super.key});

  @override
  State<BreathingSkeletonCard> createState() => _BreathingSkeletonCardState();
}

class _BreathingSkeletonCardState extends State<BreathingSkeletonCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final blockColor = Colors.grey[200]!;
    return FadeTransition(
      opacity: _animation,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: blockColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 100,
                      height: 14,
                      decoration: BoxDecoration(
                        color: blockColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 65,
                  height: 20,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: blockColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 150,
                  height: 12,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: blockColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 110,
                  height: 12,
                  decoration: BoxDecoration(
                    color: blockColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressText extends StatefulWidget {
  final double latitude;
  final double longitude;
  final TextStyle style;

  const _AddressText({
    required this.latitude,
    required this.longitude,
    required this.style,
  });

  @override
  State<_AddressText> createState() => _AddressTextState();
}

class _AddressTextState extends State<_AddressText> {
  static final Map<String, String> _cache = {};
  String? _resolvedAddress;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  @override
  void didUpdateWidget(_AddressText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude || oldWidget.longitude != widget.longitude) {
      _loadAddress();
    }
  }

  Future<void> _loadAddress() async {
    final key = '${widget.latitude},${widget.longitude}';
    if (_cache.containsKey(key)) {
      if (mounted) {
        setState(() {
          _resolvedAddress = _cache[key];
        });
      }
      return;
    }

    String displayAddress = '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}';

    try {
      // 1. Try local/native geocoding package
      final placemarks = await placemarkFromCoordinates(widget.latitude, widget.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final List<String> parts = [];
        final street = place.street ?? '';
        if (street.isNotEmpty) parts.add(street);
        final subLocality = place.subLocality ?? '';
        if (subLocality.isNotEmpty && subLocality != street) parts.add(subLocality);
        final locality = place.locality ?? '';
        if (locality.isNotEmpty) parts.add(locality);
        final subAdmin = place.subAdministrativeArea ?? '';
        if (subAdmin.isNotEmpty) parts.add(subAdmin);
        final admin = place.administrativeArea ?? '';
        if (admin.isNotEmpty && admin != subAdmin) parts.add(admin);
        
        displayAddress = parts.isNotEmpty ? parts.join(', ') : 'Lokasi ditemukan';
      }
    } catch (_) {
      // 2. Fallback to OpenStreetMap Nominatim reverse geocoding API
      try {
        final dio = Dio();
        final response = await dio.get(
          'https://nominatim.openstreetmap.org/reverse',
          queryParameters: {
            'format': 'json',
            'lat': widget.latitude,
            'lon': widget.longitude,
            'zoom': 14,
            'addressdetails': 1,
            'accept-language': 'id',
          },
          options: Options(headers: {'User-Agent': 'SafeApp/1.0'}),
        );
        if (response.statusCode == 200 && response.data != null) {
          final addressData = response.data['address'];
          if (addressData != null) {
            final road = addressData['road'] ?? addressData['pedestrian'] ?? '';
            final suburb = addressData['suburb'] ?? addressData['neighbourhood'] ?? addressData['village'] ?? '';
            final city = addressData['city'] ?? addressData['town'] ?? addressData['county'] ?? '';
            final state = addressData['state'] ?? '';
            
            final parts = <String>[];
            if (road.isNotEmpty) parts.add(road.toString());
            if (suburb.isNotEmpty) parts.add(suburb.toString());
            if (city.isNotEmpty) parts.add(city.toString());
            if (state.isNotEmpty) parts.add(state.toString());
            
            displayAddress = parts.isNotEmpty ? parts.join(', ') : (response.data['display_name'] ?? 'Lokasi ditemukan');
          }
        }
      } catch (_) {}
    }

    _cache[key] = displayAddress;
    if (mounted) {
      setState(() {
        _resolvedAddress = displayAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _resolvedAddress ?? '${widget.latitude.toStringAsFixed(6)}, ${widget.longitude.toStringAsFixed(6)}',
      style: widget.style,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
