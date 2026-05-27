import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/core/services/notification_manager.dart';
import 'package:safe/features/emergency/presentation/pages/sos_route_page.dart';

class SosIncomingAlertPage extends StatefulWidget {
  final Map<String, dynamic> sosData;

  const SosIncomingAlertPage({super.key, required this.sosData});

  @override
  State<SosIncomingAlertPage> createState() => _SosIncomingAlertPageState();
}

class _SosIncomingAlertPageState extends State<SosIncomingAlertPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  double? _distance;
  bool _isLocating = true;

  late double _victimLat;
  late double _victimLng;

  @override
  void initState() {
    super.initState();
    // Inisialisasi koordinat korban
    _victimLat = double.tryParse(widget.sosData['latitude']?.toString() ?? '0') ?? 0.0;
    _victimLng = double.tryParse(widget.sosData['longitude']?.toString() ?? '0') ?? 0.0;

    // Mulai animasi berdenyut untuk background
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Mulai alarm kustom jika belum menyala
    NotificationManager.startAlarm();

    // Hitung jarak dinamis antara penerima dan korban
    _calculateDistance();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _calculateDistance() async {
    try {
      // Cek izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final currentPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );
        final distanceInMeters = Geolocator.distanceBetween(
          currentPos.latitude,
          currentPos.longitude,
          _victimLat,
          _victimLng,
        );

        if (mounted) {
          setState(() {
            _distance = distanceInMeters / 1000.0;
            _isLocating = false;
          });
        }
      } else {
        if (mounted) {
          setState(() => _isLocating = false);
        }
      }
    } catch (e) {
      debugPrint('Gagal menghitung jarak: $e');
      if (mounted) {
        setState(() => _isLocating = false);
      }
    }
  }

  void _callVictim() async {
    final phone = widget.sosData['user_phone'] ?? '';
    if (phone.isNotEmpty) {
      final url = 'tel:$phone';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  void _goToTracking() {
    // Matikan alarm setelah penerima merespon tombol navigasi rute
    NotificationManager.stopAlarm();

    // Mapping data ke format yang dibutuhkan SosRoutePage
    final Map<String, dynamic> sosEvent = {
      'id': widget.sosData['sos_id'] ?? 'unknown',
      'initial_latitude': _victimLat,
      'initial_longitude': _victimLng,
      'user_name': widget.sosData['user_name'] ?? 'Korban',
      'user_phone': widget.sosData['user_phone'] ?? '-',
      'status': 'active',
      'trigger_type': widget.sosData['trigger'] ?? 'manual',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Navigasi ke halaman pelacakan rute
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SosRoutePage(sosEvent: sosEvent),
      ),
    );
  }

  void _dismissAlert() {
    NotificationManager.stopAlarm();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final victimName = widget.sosData['user_name'] ?? 'Budi Santoso';
    final profileImage = widget.sosData['profile_image'] ?? '';

    return Scaffold(
      body: Stack(
        children: [
          // ── Background Animasi Berdenyut ───────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFDC2626), // Red 600
                  Color(0xFF7F1D1D), // Red 900
                ],
              ),
            ),
          ),

          // Lingkaran Gelombang Berdenyut
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  _buildPulseCircle(300 * _pulseController.value, 0.15),
                  _buildPulseCircle(500 * _pulseController.value, 0.08),
                  _buildPulseCircle(700 * _pulseController.value, 0.03),
                ],
              );
            },
          ),

          // ── Konten Utama (Atas) ─────────────────────────────────────────
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tombol Tutup di Pojok Kiri Atas
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, top: 12.0),
                    child: IconButton(
                      onPressed: _dismissAlert,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Ikon Warning Darurat Besar
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 80,
                ),

                const SizedBox(height: 12),

                // Tulisan Darurat
                Text(
                  'DARURAT',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Bantuan segera dibutuhkan',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.subHeading.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 16,
                  ),
                ),

                const Spacer(),

                // Avatar Bulat Korban (Memotong perbatasan background merah dan card putih)
                Center(
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(65),
                      child: profileImage.isNotEmpty
                          ? Image.network(
                              profileImage,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildDefaultAvatar(),
                            )
                          : _buildDefaultAvatar(),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Card Informasi Putih (Bawah) ──────────────────────────────
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Nama Korban
                      Text(
                        victimName,
                        style: AppTextStyles.heading.copyWith(
                          color: const Color(0xFF193855),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Informasi Jarak Real-Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: AppColors.primaryRed,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isLocating
                                ? 'Menghitung jarak...'
                                : _distance != null
                                    ? '± ${_distance!.toStringAsFixed(1)} km dari Anda'
                                    : 'Jarak tidak diketahui',
                            style: AppTextStyles.subHeading.copyWith(
                              color: AppColors.textGrey,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Peta Mini non-interaktif
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: FlutterMap(
                            options: MapOptions(
                              initialCenter: LatLng(_victimLat, _victimLng),
                              initialZoom: 14.5,
                              interactionOptions: const InteractionOptions(
                                flags: InteractiveFlag.none,
                              ),
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                userAgentPackageName: 'com.safe.app',
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    point: LatLng(_victimLat, _victimLng),
                                    width: 40,
                                    height: 40,
                                    child: const Icon(
                                      Icons.location_pin,
                                      color: AppColors.primaryRed,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Tombol Lihat Lokasi Real-Time
                      ElevatedButton.icon(
                        onPressed: _goToTracking,
                        icon: const Icon(Icons.explore_outlined, color: Colors.white),
                        label: const Text(
                          'Lihat Lokasi Real-Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF193855),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 2,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Tombol Hubungi Sekarang
                      ElevatedButton.icon(
                        onPressed: _callVictim,
                        icon: const Icon(Icons.phone, color: Colors.white),
                        label: const Text(
                          'Hubungi Sekarang',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size.fromHeight(56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseCircle(double radius, double opacity) {
    return Center(
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: opacity),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.person,
        size: 70,
        color: Colors.grey,
      ),
    );
  }
}
