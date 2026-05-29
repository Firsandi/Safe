import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/services/notification_manager.dart';
import 'package:safe/features/emergency/presentation/pages/sos_route_page.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:safe/l10n/app_localizations.dart';

class SosAlertReceiverPage extends StatefulWidget {
  final Map<String, dynamic> sosEvent;

  const SosAlertReceiverPage({super.key, required this.sosEvent});

  @override
  State<SosAlertReceiverPage> createState() => _SosAlertReceiverPageState();
}

class _SosAlertReceiverPageState extends State<SosAlertReceiverPage> with SingleTickerProviderStateMixin {
  late double _victimLat;
  late double _victimLng;
  late String _victimName;
  late String _victimPhone;
  late String _profileImage;
  String _address = "";
  double? _distanceInKm;
  bool _isLoadingDistance = true;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    // Parse coordinates and data safely
    _victimLat = double.tryParse(widget.sosEvent['initial_latitude']?.toString() ?? '') ??
                 double.tryParse(widget.sosEvent['latitude']?.toString() ?? '') ?? 0.0;
    _victimLng = double.tryParse(widget.sosEvent['initial_longitude']?.toString() ?? '') ??
                 double.tryParse(widget.sosEvent['longitude']?.toString() ?? '') ?? 0.0;
                 
    _victimName = widget.sosEvent['user_name'] ?? widget.sosEvent['name'] ?? '';
    _victimPhone = widget.sosEvent['user_phone'] ?? widget.sosEvent['phone'] ?? '';
    _profileImage = widget.sosEvent['user_profile_image'] ?? widget.sosEvent['profile_image'] ?? '';

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _calculateDistance();
    _fetchAddress();
    _fetchVictimProfileImage();
  }

  Future<void> _fetchVictimProfileImage() async {
    try {
      final dio = sl<Dio>();
      final response = await dio.get('/api/contacts');
      if (response.statusCode == 200 && response.data != null) {
        final contactsList = response.data['contacts'] as List?;
        if (contactsList != null) {
          String normalize(String p) => p.replaceAll(RegExp(r'[^0-9]'), '');
          final targetPhone = normalize(_victimPhone);
          if (targetPhone.isNotEmpty) {
            for (var c in contactsList) {
              final phoneStr = c['phone_number']?.toString() ?? '';
              if (normalize(phoneStr) == targetPhone) {
                final img = c['profile_image']?.toString() ?? '';
                if (img.isNotEmpty && mounted) {
                  setState(() {
                    _profileImage = img;
                  });
                }
                break;
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _calculateDistance() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      final distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _victimLat,
        _victimLng,
      );
      if (mounted) {
        setState(() {
          _distanceInKm = distanceInMeters / 1000;
          _isLoadingDistance = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingDistance = false;
        });
      }
    }
  }

  Future<void> _fetchAddress() async {
    try {
      final dio = Dio();
      final response = await dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': _victimLat,
          'lon': _victimLng,
          'format': 'json',
          'accept-language': 'id',
        },
        options: Options(headers: {'User-Agent': 'SafeApp/1.0'}),
      );
      if (response.statusCode == 200 && response.data != null) {
        final addr = response.data['address'];
        final road = addr?['road'] ?? addr?['neighbourhood'] ?? addr?['suburb'] ?? addr?['village'];
        final city = addr?['city'] ?? addr?['town'] ?? addr?['regency'] ?? addr?['state'];
        if (mounted) {
          setState(() {
            if (road != null && city != null) {
              _address = '$road, $city';
            } else if (road != null) {
              _address = road;
            } else {
              _address = response.data['display_name'] ?? '${_victimLat.toStringAsFixed(5)}, ${_victimLng.toStringAsFixed(5)}';
            }
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _address = '${_victimLat.toStringAsFixed(5)}, ${_victimLng.toStringAsFixed(5)}';
        });
      }
    }
  }

  void _callVictim() async {
    if (_victimPhone.isEmpty) return;
    final url = 'tel:$_victimPhone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  void _goToRouteTracking() {
    NotificationManager.stopAlarm();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SosRoutePage(sosEvent: widget.sosEvent),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // RED HEADER WITH PULSATING CIRCLES
          Container(
            height: MediaQuery.of(context).size.height * 0.40,
            width: double.infinity,
            color: AppColors.primaryRed,
            child: SafeArea(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Pulsing circles
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 220 + (_pulseController.value * 40),
                            height: 220 + (_pulseController.value * 40),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.04 * (1.0 - _pulseController.value)),
                                width: 12,
                              ),
                            ),
                          ),
                          Container(
                            width: 170 + (_pulseController.value * 30),
                            height: 170 + (_pulseController.value * 30),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08 * (1.0 - _pulseController.value)),
                                width: 8,
                              ),
                            ),
                          ),
                          Container(
                            width: 120 + (_pulseController.value * 20),
                            height: 120 + (_pulseController.value * 20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12 * (1.0 - _pulseController.value)),
                                width: 6,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  
                  // Warning icon and text
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppLocalizations.of(context)!.receiverEmergencyTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.receiverEmergencySub,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // WHITE BODY CARD
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.65,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 15,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 8,
                ),
                child: Column(
                  children: [
                    // Gap for overlapping Avatar
                    const SizedBox(height: 56),
                    
                    // Sender Name
                    Text(
                      _victimName.isEmpty ? AppLocalizations.of(context)!.receiverSomeone : _victimName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Distance
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isLoadingDistance
                              ? AppLocalizations.of(context)!.receiverCalculatingDistance
                              : _distanceInKm != null
                                  ? AppLocalizations.of(context)!.receiverDistanceText(_distanceInKm!.toStringAsFixed(1))
                                  : AppLocalizations.of(context)!.receiverLocationUnreachable,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // Map view container
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(_victimLat, _victimLng),
                                  initialZoom: 15.0,
                                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.safe.app',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(_victimLat, _victimLng),
                                        width: 50,
                                        height: 50,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            Container(
                                              width: 36,
                                              height: 36,
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryRed.withOpacity(0.3),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const Icon(
                                              Icons.location_on,
                                              color: AppColors.primaryRed,
                                              size: 32,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Address bar overlay (bottom-left)
                              Positioned(
                                bottom: 12,
                                left: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B).withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _address.isEmpty ? AppLocalizations.of(context)!.receiverSearchingLocation : _address,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Button 1: Lihat Lokasi
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _goToRouteTracking,
                        icon: const Icon(Icons.explore_outlined, color: Colors.white),
                        label: Text(
                          AppLocalizations.of(context)!.receiverViewLocation,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF193855),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Button 2: Hubungi Sekarang
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _callVictim,
                        icon: const Icon(Icons.phone, color: Colors.white),
                        label: Text(
                          AppLocalizations.of(context)!.receiverCallNow,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          
          // OVERLAPPING CIRCULAR AVATAR
          Positioned(
            top: MediaQuery.of(context).size.height * 0.35 - 50,
            left: MediaQuery.of(context).size.width / 2 - 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CircleAvatar(
                  radius: 46,
                  backgroundImage: _profileImage.isNotEmpty
                      ? MemoryImage(base64Decode(_profileImage))
                      : null,
                  backgroundColor: const Color(0xFF193855),
                  child: _profileImage.isEmpty
                      ? Text(
                          _getInitials(_victimName.isEmpty ? AppLocalizations.of(context)!.receiverSomeone : _victimName),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ),
          
          // CLOSE BUTTON (Subtle option to mute and exit)
          Positioned(
            top: 40,
            left: 20,
            child: GestureDetector(
              onTap: () {
                NotificationManager.stopAlarm();
                Navigator.pop(context);
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
