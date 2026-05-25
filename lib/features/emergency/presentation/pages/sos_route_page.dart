import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';

class SosRoutePage extends StatefulWidget {
  final Map<String, dynamic> sosEvent;

  const SosRoutePage({super.key, required this.sosEvent});

  @override
  State<SosRoutePage> createState() => _SosRoutePageState();
}

class _SosRoutePageState extends State<SosRoutePage> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  String _errorMessageKey = "";
  String _destinationAddress = "";
  double _currentZoom = 14.0;

  late double _targetLat;
  late double _targetLng;

  @override
  void initState() {
    super.initState();
    _targetLat = (widget.sosEvent['initial_latitude'] ?? 0.0) as double;
    _targetLng = (widget.sosEvent['initial_longitude'] ?? 0.0) as double;

    _initLocationAndRoute();
    _fetchAddressFromCoords(_targetLat, _targetLng);
  }

  /// Reverse geocoding menggunakan Nominatim OSM
  Future<void> _fetchAddressFromCoords(double lat, double lng) async {
    try {
      final dio = Dio();
      final response = await dio.get(
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
        final road = addr?['road'] ??
            addr?['neighbourhood'] ??
            addr?['suburb'] ??
            addr?['village'] ??
            addr?['city_district'] ??
            addr?['county'];
        final city = addr?['city'] ??
            addr?['town'] ??
            addr?['regency'] ??
            addr?['state'];
        if (mounted) {
          setState(() {
            if (road != null && city != null) {
              _destinationAddress = '$road, $city';
            } else if (road != null) {
              _destinationAddress = road;
            } else {
              _destinationAddress = response.data['display_name'] ??
                  '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}';
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _destinationAddress =
              '${_targetLat.toStringAsFixed(6)}, ${_targetLng.toStringAsFixed(6)}';
        });
      }
    }
  }

  Future<void> _initLocationAndRoute() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (mounted) {
        setState(() => _currentPosition = pos);

        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([
            LatLng(pos.latitude, pos.longitude),
            LatLng(_targetLat, _targetLng),
          ]),
          padding: const EdgeInsets.fromLTRB(60, 120, 60, 60),
        ));

        await _fetchRoute(
            pos.latitude, pos.longitude, _targetLat, _targetLng);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _errorMessageKey = "gpsFailed";
        });
      }
    }
  }

  Future<void> _fetchRoute(
      double sLat, double sLng, double eLat, double eLng) async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/$sLng,$sLat;$eLng,$eLat?geometries=geojson';
      final response = await Dio().get(url);

      if (response.statusCode == 200) {
        final routes = response.data['routes'];
        if (routes != null && routes.isNotEmpty) {
          final coords = routes[0]['geometry']['coordinates'] as List;
          final List<LatLng> pts =
              coords.map((c) => LatLng(c[1] as double, c[0] as double)).toList();
          if (mounted) {
            setState(() {
              _routePoints = pts;
              _isLoadingRoute = false;
            });
          }
        }
      } else {
        throw Exception("OSRM error");
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
          _errorMessageKey = "routeDownloadFailed";
        });
      }
    }
  }

  void _goToCurrentLocation() {
    if (_currentPosition != null) {
      _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          15.0);
      setState(() => _currentZoom = 15.0);
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

  void _openGoogleMaps() async {
    final url =
        'https://www.google.com/maps/dir/?api=1&destination=$_targetLat,$_targetLng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Resolve error message based on key
    String displayError = "";
    if (_errorMessageKey == "gpsFailed") displayError = l10n.gpsFailed;
    if (_errorMessageKey == "routeDownloadFailed") displayError = l10n.routeDownloadFailed;

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
                  // Tombol Kembali — bulat dengan shadow tipis
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
                  // Judul & Subtitle
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.emergencyHistoryTitle, style: AppTextStyles.heading.copyWith(fontSize: 18)),
                      const SizedBox(height: 2),
                      Text(
                        l10n.sosHistoryReceivedSubtitle,
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
                // Peta
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
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.safe.app',
                    ),
                    // Rute oren
                    PolylineLayer(
                      polylines: [
                        if (_routePoints.isNotEmpty)
                          Polyline(
                            points: _routePoints,
                            color: Colors.orange,
                            strokeWidth: 5.0,
                          ),
                      ],
                    ),
                    // Marker
                    MarkerLayer(
                      markers: [
                        // Titik biru — lokasi user
                        if (_currentPosition != null)
                          Marker(
                            point: LatLng(_currentPosition!.latitude,
                                _currentPosition!.longitude),
                            width: 60,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.25),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.fromBorderSide(BorderSide(
                                        color: Colors.white, width: 2.5)),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Pin merah — lokasi korban
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
                                    horizontal: 5, vertical: 2),
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
                                  widget.sosEvent['user_name'] ?? l10n.contactPlaceholder,
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

                // Loading overlay
                if (_isLoadingRoute)
                  Container(
                    color: Colors.black.withValues(alpha: 0.28),
                    child: const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryRed),
                    ),
                  ),

                // Error banner
                if (displayError.isNotEmpty)
                  Positioned(
                    top: 12,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(displayError,
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center),
                    ),
                  ),

                // Info Card — ATAS TENGAH (full width)
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: _buildRouteInfoCard(l10n),
                ),

                // 3 Tombol Kontrol — KANAN TENGAH (Vertically Centered)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMapBtn(Icons.my_location, _goToCurrentLocation),
                        const SizedBox(height: 8),
                        _buildMapBtn(Icons.add, _zoomIn),
                        const SizedBox(height: 8),
                        _buildMapBtn(Icons.remove, _zoomOut),
                      ],
                    ),
                  ),
                ),

                // Tombol Google Maps — KANAN BAWAH
                Positioned(
                  right: 16,
                  bottom: 24,
                  child: FloatingActionButton(
                    onPressed: _openGoogleMaps,
                    backgroundColor: const Color(0xFF193855),
                    tooltip: l10n.openGoogleMaps,
                    child: const Icon(Icons.directions,
                        color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info Card (Desain Riwayat Darurat) ───────────────────────────────────
  Widget _buildRouteInfoCard(AppLocalizations l10n) {
    final event = widget.sosEvent;
    final triggerType = event['trigger_type'] ?? 'manual';
    final isAuto = triggerType == 'auto';
    final korbanName = event['user_name'] ?? l10n.contactPlaceholder;
    final phone = event['user_phone'] ?? '-';
    
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
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: Color(0xFF193855), size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        korbanName,
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
            '${l10n.phoneNumberPrefix} $phone',
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
                    isAuto ? l10n.triggerAuto : l10n.triggerManual,
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
              Expanded(
                child: Text(
                  _destinationAddress.isEmpty ? l10n.searchingLocation : _destinationAddress, 
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

  // ── Tombol Kontrol ─────────────────────────────────────────────────────────
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
