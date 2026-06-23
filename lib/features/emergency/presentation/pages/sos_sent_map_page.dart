import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:geocoding/geocoding.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class SosSentMapPage extends StatefulWidget {
  final Map<String, dynamic> sosEvent;

  const SosSentMapPage({super.key, required this.sosEvent});

  @override
  State<SosSentMapPage> createState() => _SosSentMapPageState();
}

class _SosSentMapPageState extends State<SosSentMapPage> {
  final MapController _mapController = MapController();
  String _address = "";
  double _currentZoom = 15.0;

  late double _targetLat;
  late double _targetLng;

  @override
  void initState() {
    super.initState();
    _targetLat = (widget.sosEvent['initial_latitude'] ?? 0.0) as double;
    _targetLng = (widget.sosEvent['initial_longitude'] ?? 0.0) as double;
    _fetchAddressFromCoords(_targetLat, _targetLng);
  }

  Future<void> _fetchAddressFromCoords(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
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
        
        if (mounted) {
          setState(() {
            _address = parts.isNotEmpty ? parts.join(', ') : 'Lokasi ditemukan';
          });
        }
        return;
      }
    } catch (_) {}

    try {
      final response = await Dio().get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'accept-language': 'id',
        },
        options: Options(headers: {'User-Agent': 'SafeApp/1.0'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        final addr = response.data['address'];
        if (addr != null) {
          final road = addr['road'] ?? addr['pedestrian'] ?? '';
          final suburb = addr['suburb'] ?? addr['neighbourhood'] ?? addr['village'] ?? '';
          final city = addr['city'] ?? addr['town'] ?? addr['county'] ?? '';
          final state = addr['state'] ?? '';
          
          final parts = <String>[];
          if (road.isNotEmpty) parts.add(road.toString());
          if (suburb.isNotEmpty) parts.add(suburb.toString());
          if (city.isNotEmpty) parts.add(city.toString());
          if (state.isNotEmpty) parts.add(state.toString());
          
          if (mounted) {
            setState(() {
              _address = parts.isNotEmpty ? parts.join(', ') : (response.data['display_name'] ?? 'Lokasi ditemukan');
            });
          }
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '${_targetLat.toStringAsFixed(6)}, ${_targetLng.toStringAsFixed(6)}';
        });
      }
    }
  }

  void _zoomIn() {
    final z = (_currentZoom + 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
    setState(() => _currentZoom = z);
  }

  void _zoomOut() {
    final z = (_currentZoom - 1).clamp(1.0, 18.0);
    _mapController.move(_mapController.camera.center, z);
    setState(() => _currentZoom = z);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Column(
        children: [
          // ── Custom Header ─────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 24, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Color(0xFF193855),
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.emergencyHistoryTitle, style: AppTextStyles.heading.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        l10n.sosHistorySentSubtitle,
                        style: AppTextStyles.subHeading.copyWith(
                          color: AppColors.textGrey,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Area Peta ───────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(_targetLat, _targetLng),
                    initialZoom: _currentZoom,
                    onPositionChanged: (pos, _) {
                      if (mounted) setState(() => _currentZoom = pos.zoom);
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.safe.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_targetLat, _targetLng),
                          width: 120,
                          height: 100,
                          alignment: Alignment.topCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on,
                                  color: AppColors.primaryRed, size: 44),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.12),
                                        blurRadius: 4)
                                  ],
                                ),
                                child: Text(
                                  l10n.yourLocation,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Info Card — ATAS TENGAH (full width)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _buildSentInfoCard(l10n),
                ),

                // 2 Tombol Kontrol (Zoom in/out) — KANAN TENGAH (Vertically Centered)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapBtn(Icons.add, _zoomIn),
                        const SizedBox(height: 8),
                        _buildMapBtn(Icons.remove, _zoomOut),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentInfoCard(AppLocalizations l10n) {
    final event = widget.sosEvent;
    final triggerType = event['trigger_type'] ?? 'manual';
    final isAuto = triggerType == 'auto';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              Expanded(
                child: Text(
                  _address.isEmpty ? l10n.searchingLocation : _address,
                  style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
        label = AppLocalizations.of(context)?.statusActive ?? 'ACTIVE';
        break;
      case 'resolved':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF10B981);
        label = AppLocalizations.of(context)?.statusResolved ?? 'RESOLVED';
        break;
      case 'false_alarm':
        bgColor = const Color(0xFFF3F4F6);
        textColor = const Color(0xFF6B7280);
        label = AppLocalizations.of(context)?.statusFalseAlarm ?? 'FALSE ALARM';
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

  Widget _buildMapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.13),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF193855), size: 22),
      ),
    );
  }
}
