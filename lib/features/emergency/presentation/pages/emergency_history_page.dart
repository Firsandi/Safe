import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/injection.dart';

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
    if (_sentScrollController.position.pixels >= _sentScrollController.position.maxScrollExtent - 200) {
      _loadMoreSent();
    }
  }

  void _onReceivedScroll() {
    if (_receivedScrollController.position.pixels >= _receivedScrollController.position.maxScrollExtent - 200) {
      _loadMoreReceived();
    }
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _sentPage = 1;
      _receivedPage = 1;
      _hasMoreSent = true;
      _hasMoreReceived = true;
      _displayedSentHistory = [];
      _displayedReceivedHistory = [];
    });

    try {
      final dio = sl<Dio>();
      
      // Fetch initial pages in parallel
      final results = await Future.wait([
        dio.get('/api/sos/history/sent', queryParameters: {'page': 1, 'limit': _pageSize}),
        dio.get('/api/sos/history/received', queryParameters: {'page': 1, 'limit': _pageSize}),
      ]);

      final rawSent = results[0].data ?? [];
      final rawReceived = results[1].data ?? [];

      if (!mounted) return;
      setState(() {
        // 1. Sent History Pagination setup
        if (rawSent.length > _pageSize) {
          // Server ignored page parameters (returned all). Fallback to client-side progressive pagination.
          _isSentServerPaged = false;
          _allSentHistory = rawSent;
          _displayedSentHistory = _allSentHistory.take(_pageSize).toList();
          _hasMoreSent = _allSentHistory.length > _pageSize;
        } else {
          // Server supports query parameters.
          _isSentServerPaged = true;
          _displayedSentHistory = List.from(rawSent);
          _hasMoreSent = rawSent.length == _pageSize;
        }

        // 2. Received History Pagination setup
        if (rawReceived.length > _pageSize) {
          // Server ignored page parameters (returned all). Fallback to client-side progressive pagination.
          _isReceivedServerPaged = false;
          _allReceivedHistory = rawReceived;
          _displayedReceivedHistory = _allReceivedHistory.take(_pageSize).toList();
          _hasMoreReceived = _allReceivedHistory.length > _pageSize;
        } else {
          // Server supports query parameters.
          _isReceivedServerPaged = true;
          _displayedReceivedHistory = List.from(rawReceived);
          _hasMoreReceived = rawReceived.length == _pageSize;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Gagal memuat riwayat: ${e.toString()}';
        _isLoading = false;
      });
    }
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
        final res = await dio.get('/api/sos/history/sent', queryParameters: {'page': nextPage, 'limit': _pageSize});
        final newItems = res.data ?? [];
        
        if (!mounted) return;
        setState(() {
          _sentPage = nextPage;
          _displayedSentHistory.addAll(newItems);
          _hasMoreSent = newItems.length == _pageSize;
        });
      } else {
        // Client-side pagination: load from locally stored list
        await Future.delayed(const Duration(milliseconds: 200)); // Smooth loading feel
        final currentLen = _displayedSentHistory.length;
        final nextItems = _allSentHistory.skip(currentLen).take(_pageSize).toList();
        
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
        final res = await dio.get('/api/sos/history/received', queryParameters: {'page': nextPage, 'limit': _pageSize});
        final newItems = res.data ?? [];
        
        if (!mounted) return;
        setState(() {
          _receivedPage = nextPage;
          _displayedReceivedHistory.addAll(newItems);
          _hasMoreReceived = newItems.length == _pageSize;
        });
      } else {
        // Client-side pagination: load from locally stored list
        await Future.delayed(const Duration(milliseconds: 200)); // Smooth loading feel
        final currentLen = _displayedReceivedHistory.length;
        final nextItems = _allReceivedHistory.skip(currentLen).take(_pageSize).toList();
        
        if (!mounted) return;
        setState(() {
          _displayedReceivedHistory.addAll(nextItems);
          _hasMoreReceived = _displayedReceivedHistory.length < _allReceivedHistory.length;
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
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
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
        label = 'AKTIF';
        break;
      case 'resolved':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF10B981);
        label = 'SELESAI';
        break;
      case 'false_alarm':
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = 'ALARM PALSU';
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
                  Text('Riwayat Darurat', style: AppTextStyles.heading),
                  const SizedBox(height: 8),
                  Text(
                    'Arsip riwayat pengiriman dan penerimaan sinyal SOS.',
                    style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 14),
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
                labelStyle: AppTextStyles.subHeading.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: AppTextStyles.subHeading.copyWith(fontSize: 14),
                tabs: const [
                  Tab(text: 'SOS Saya'),
                  Tab(text: 'SOS Diterima'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Content Area
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      itemCount: 4,
                      itemBuilder: (context, index) => const BreathingSkeletonCard(),
                    )
                  : _errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.primaryRed, size: 48),
                                const SizedBox(height: 16),
                                Text(_errorMessage!, textAlign: TextAlign.center, style: AppTextStyles.subHeading),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchHistory,
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF193855)),
                                  child: const Text('Coba Lagi', style: TextStyle(color: Colors.white)),
                                )
                              ],
                            ),
                          ),
                        )
                      : TabBarView(
                          children: [
                            _buildSentTab(),
                            _buildReceivedTab(),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentTab() {
    if (_displayedSentHistory.isEmpty) {
      return _buildEmptyState('Anda belum pernah mengirim sinyal SOS.');
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
                  child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2),
                ),
              ),
            );
          }

          final event = _displayedSentHistory[index];
          final triggerType = event['trigger_type'] ?? 'manual';
          final isAuto = triggerType == 'auto';

          return Container(
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
                          color: isAuto ? AppColors.primaryRed : const Color(0xFF193855),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isAuto ? 'Deteksi Otomatis' : 'Pemicu Manual',
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
                    const Icon(Icons.access_time, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      _formatDateTime(event['created_at']),
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${event['initial_latitude'] ?? 0.0}, ${event['initial_longitude'] ?? 0.0}',
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceivedTab() {
    if (_displayedReceivedHistory.isEmpty) {
      return _buildEmptyState('Belum ada sinyal SOS masuk dari kontak Anda.');
    }

    return RefreshIndicator(
      onRefresh: _fetchHistory,
      child: ListView.builder(
        controller: _receivedScrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _displayedReceivedHistory.length + (_isLoadingMoreReceived ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _displayedReceivedHistory.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: AppColors.primaryRed, strokeWidth: 2),
                ),
              ),
            );
          }

          final event = _displayedReceivedHistory[index];
          final triggerType = event['trigger_type'] ?? 'manual';
          final isAuto = triggerType == 'auto';

          return Container(
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
                        const Icon(Icons.person_outline, color: Color(0xFF193855), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          event['user_name'] ?? 'Kontak',
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
                const SizedBox(height: 8),
                Text(
                  'No. HP: ${event['user_phone'] ?? '-'}',
                  style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                ),
                const Divider(height: 24, color: AppColors.inputBorder),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAuto ? Icons.sensors : Icons.touch_app_outlined,
                          color: isAuto ? AppColors.primaryRed : const Color(0xFF193855),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isAuto ? 'Deteksi Otomatis' : 'Pemicu Manual',
                          style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      _formatDateTime(event['created_at']),
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      '${event['initial_latitude'] ?? 0.0}, ${event['initial_longitude'] ?? 0.0}',
                      style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                    ),
                  ],
                ),
              ],
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
            'Tidak ada riwayat',
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
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
