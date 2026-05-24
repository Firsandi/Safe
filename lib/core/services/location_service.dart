import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe/core/utils/session_manager.dart';
import '../utils/injection.dart';

class LocationService {
  static StreamSubscription<Position>? _positionStreamSubscription;
  static String? activeSosId;

  /// Loads the persisted active SOS ID from local storage
  static Future<void> loadActiveSosId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = await SessionManager.getUserData();
      final userId = userData != null ? userData['user_id'] : null;
      if (userId != null) {
        activeSosId = prefs.getString('active_sos_id_$userId');
      } else {
        activeSosId = null;
      }
    } catch (_) {}
  }

  /// Saves or clears the active SOS ID in local storage and memory
  static Future<void> saveActiveSosId(String? id) async {
    activeSosId = id;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = await SessionManager.getUserData();
      final userId = userData != null ? userData['user_id'] : null;
      if (userId != null) {
        if (id == null) {
          await prefs.remove('active_sos_id_$userId');
        } else {
          await prefs.setString('active_sos_id_$userId', id);
        }
      } else {
        // Fallback for global clear
        if (id == null) {
          await prefs.remove('active_sos_id');
        }
      }
    } catch (_) {}
  }

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
  static Future<void> startTrackingSos(String sosId) async {
    // Cancel existing if any
    stopTrackingSos();

    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await saveActiveSosId(sosId);

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
    saveActiveSosId(null);
  }
}
