import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../utils/injection.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static String? activeSosId;

  /// Requests location permission and returns whether it is granted
  static Future<bool> requestPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  /// Gets the current location once
  static Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (_) {
      try {
        // Fallback to last known position if current position times out or fails
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }

  /// Starts streaming real-time location and posting updates to the backend for an active SOS
  static void startTrackingSos(String sosId) async {
    // Cancel existing if any
    stopTrackingSos();

    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    activeSosId = sosId;

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Send update when user moves 5 meters
    );

    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
      (Position position) async {
        try {
          final dio = sl<Dio>();
          await dio.post(
            '/api/sos/$sosId/track',
            data: {
              'latitude': position.latitude,
              'longitude': position.longitude,
            },
          );
        } catch (_) {
          // Ignore network errors quietly during background stream
        }
      },
      onError: (_) {
        stopTrackingSos();
      },
    );
  }

  /// Stops tracking real-time location
  static void stopTrackingSos() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    activeSosId = null;
  }
}
