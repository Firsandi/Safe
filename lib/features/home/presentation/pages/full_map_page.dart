import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:geolocator/geolocator.dart';
import 'package:safe/core/theme/app_colors.dart';

class FullMapPage extends StatefulWidget {
  final LatLng initialLocation;
  const FullMapPage({super.key, required this.initialLocation});

  @override
  State<FullMapPage> createState() => _FullMapPageState();
}

class _FullMapPageState extends State<FullMapPage> {
  final MapController _mapController = MapController();
  LatLng? _currentLocation;
  double _currentZoom = 15.0;

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.initialLocation;
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() => _currentLocation = LatLng(pos.latitude, pos.longitude));
        _mapController.move(_currentLocation!, _currentZoom);
      }
    } catch (_) {}
  }

  void _goToMe() {
    if (_currentLocation != null) {
      _mapController.move(_currentLocation!, 15.0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Stack(
        children: [
          // ── MAP ──────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialLocation,
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
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 60, height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.25),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 18, height: 18,
                            decoration: BoxDecoration(
                              color: Colors.blue, shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 8)],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // ── Tombol Back ──────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF193855), size: 20),
                ),
              ),
            ),
          ),

          // ── Map controls ──────────────────────────────────
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMapBtn(Icons.my_location_rounded, _goToMe),
                  const SizedBox(height: 12),
                  _buildMapBtn(Icons.add_rounded, _zoomIn),
                  const SizedBox(height: 8),
                  _buildMapBtn(Icons.remove_rounded, _zoomOut),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Icon(icon, color: const Color(0xFF193855), size: 24),
      ),
    );
  }
}
