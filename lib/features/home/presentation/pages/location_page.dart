import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe/core/theme/app_colors.dart';
import 'package:safe/core/theme/app_text_styles.dart';
import 'package:safe/features/emergency/domain/entities/contact_entity.dart';
import 'package:dio/dio.dart';
import 'package:safe/core/utils/injection.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:safe/l10n/app_localizations.dart';
import 'package:safe/features/emergency/data/models/contact_model.dart';

class LocationPage extends StatefulWidget {
  const LocationPage({Key? key}) : super(key: key);

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  List<ContactEntity> _contacts = [];
  List<dynamic> _activeSosHistory = []; // from /api/sos/history/received
  bool _isLoading = true;
  Timer? _refreshTimer;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchData());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _currentPosition = pos;
        });
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
      }
    } catch (_) {}
  }

  Future<void> _fetchData() async {
    try {
      final dio = sl<Dio>();
      
      // Fetch contacts
      final contactsRes = await dio.get('/api/contacts');
      final List<dynamic> contactsData = contactsRes.data['contacts'] ?? [];
      final List<ContactEntity> loadedContacts = contactsData
          .map((c) => ContactModel.fromJson(c))
          .where((c) => c.status == 'Tersambung')
          .toList();

      // Fetch received SOS to check who is currently in active SOS
      final sosRes = await dio.get('/api/sos/history/received');
      final List<dynamic> sosData = sosRes.data ?? [];
      final activeSos = sosData.where((s) => s['status'] == 'active').toList();

      if (mounted) {
        setState(() {
          _contacts = loadedContacts;
          _activeSosHistory = activeSos;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  bool _isSosActive(ContactEntity contact) {
    return _activeSosHistory.any((sos) => sos['user_id'] == contact.id);
  }

  dynamic _getSosEvent(ContactEntity contact) {
    try {
      return _activeSosHistory.firstWhere((sos) => sos['user_id'] == contact.id);
    } catch (_) {
      return null;
    }
  }

  void _openNavigation(double lat, double lng) async {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  LatLng? _getTargetLocation(ContactEntity contact) {
    double? lat = _isSosActive(contact) ? (_getSosEvent(contact)?['initial_latitude'] ?? contact.lastLatitude) : contact.lastLatitude;
    double? lng = _isSosActive(contact) ? (_getSosEvent(contact)?['initial_longitude'] ?? contact.lastLongitude) : contact.lastLongitude;
    
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Filter and Sort contacts
    var displayContacts = _contacts.where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    
    // Sort: SOS first
    displayContacts.sort((a, b) {
      final aSos = _isSosActive(a);
      final bSos = _isSosActive(b);
      if (aSos && !bSos) return -1;
      if (!aSos && bSos) return 1;
      return 0;
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // MAP BACKGROUND
          _buildMap(displayContacts),

          // HEADER SECTION
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white.withOpacity(0.95),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.locationPageTitle, style: AppTextStyles.heading.copyWith(color: AppColors.primaryRed, fontSize: 18)),
                  Text(l10n.locationPageSubtitle, style: AppTextStyles.subHeading.copyWith(color: AppColors.textGrey, fontSize: 12)),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: l10n.searchContactHint,
                        prefixIcon: const Icon(Icons.search, color: AppColors.textGrey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MAP CONTROLS
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapButton(Icons.my_location, () {
                    if (_currentPosition != null) {
                      _mapController.move(LatLng(_currentPosition!.latitude, _currentPosition!.longitude), 15.0);
                    }
                  }),
                  const SizedBox(height: 8),
                  _buildMapButton(Icons.add, () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  }),
                  const SizedBox(height: 8),
                  _buildMapButton(Icons.remove, () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  }),
                ],
              ),
            ),
          ),

          // BOTTOM SHEET / CARDS
          if (displayContacts.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: SizedBox(
                height: displayContacts.length > 1 ? 160 : 80,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: displayContacts.length,
                  itemBuilder: (context, index) {
                    final contact = displayContacts[index];
                    final isSos = _isSosActive(contact);
                    return _buildContactCard(contact, isSos, l10n);
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildMap(List<ContactEntity> contacts) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(-8.1691, 113.7022), // Default Jember
        initialZoom: 13.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.safe.app',
        ),
        MarkerLayer(
          markers: [
            // User Location
            if (_currentPosition != null)
              Marker(
                point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                width: 60,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                      ),
                    ),
                  ),
                ),
              ),
            // Contact Locations
            for (var contact in contacts)
              if (_getTargetLocation(contact) != null)
                Marker(
                  point: _getTargetLocation(contact)!,
                  width: _isSosActive(contact) ? 80 : 60,
                  height: 40,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isSosActive(contact) ? AppColors.primaryRed : Colors.green[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isSosActive(contact) ? 'SOS' : contact.name.split(' ').first,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _isSosActive(contact) ? AppColors.primaryRed : Colors.green[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard(ContactEntity contact, bool isSos, AppLocalizations l10n) {
    String distanceStr = l10n.distanceCalculating;
    final targetLatLng = _getTargetLocation(contact);

    if (_currentPosition != null && targetLatLng != null) {
      final distance = const Distance().as(LengthUnit.Meter,
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        targetLatLng,
      );
      distanceStr = distance > 1000 ? "${(distance / 1000).toStringAsFixed(1)} km" : "${distance.toInt()} m";
    } else if (targetLatLng == null) {
      distanceStr = l10n.locationNotAvailable;
    }

    String timeStr = l10n.unknownUpdateTime;
    if (contact.lastLocationUpdate != null) {
      final diff = DateTime.now().difference(contact.lastLocationUpdate!);
      if (diff.inMinutes < 1) {
        timeStr = l10n.justNow;
      } else {
        timeStr = l10n.minutesAgo(diff.inMinutes);
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSos ? AppColors.primaryRed : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isSos ? Colors.white : const Color(0xFFD0E0FF),
            foregroundColor: isSos ? AppColors.primaryRed : AppColors.textDark,
            child: Text(contact.name.substring(0, 2).toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(contact.name, style: TextStyle(
                  color: isSos ? Colors.white : AppColors.textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                )),
                Text("${l10n.positionLabel} $distanceStr • ${l10n.updatedLabel} $timeStr", style: TextStyle(
                  color: isSos ? Colors.white.withOpacity(0.9) : AppColors.textGrey,
                  fontSize: 12,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
