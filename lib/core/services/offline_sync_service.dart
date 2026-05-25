import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../utils/injection.dart';
import 'location_service.dart';

class OfflineSyncService {
  static const String _outboxKey = 'offline_sos_outbox';
  static Timer? _syncTimer;
  static bool _isSyncing = false;
  static VoidCallback? onSyncSuccess;

  /// Queue an SOS trigger request locally when offline
  static Future<void> queueSos({
    required String triggerType,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_outboxKey) ?? [];
      
      final newItem = jsonEncode({
        'trigger_type': triggerType,
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      list.add(newItem);
      await prefs.setStringList(_outboxKey, list);
    } catch (_) {
      // Quiet fail
    }
  }

  /// Start the background sync loop (polls every 15 seconds)
  static void startSyncLoop(BuildContext context) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      syncPending(context);
      LocationService.updateLiveLocation(); // Live Location 24/7 feature
    });
    // Run an immediate check on startup
    syncPending(context);
    LocationService.updateLiveLocation();
  }

  /// Stop the background sync loop
  static void stopSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  /// Sync all pending local SOS requests to the backend
  static Future<void> syncPending(BuildContext context) async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_outboxKey) ?? [];
      if (list.isEmpty) {
        _isSyncing = false;
        return;
      }

      final dio = sl<Dio>();
      final remainingList = List<String>.from(list);

      for (final itemStr in list) {
        final item = jsonDecode(itemStr);
        try {
          final response = await dio.post('/api/sos/trigger', data: {
            'trigger_type': item['trigger_type'],
            'latitude': item['latitude'],
            'longitude': item['longitude'],
          });

          if (response.statusCode == 200 || response.statusCode == 201) {
            // Successfully sent
            remainingList.remove(itemStr);
            
            // Extract SOS ID and start tracking
            final eventData = response.data;
            final sosId = eventData != null ? eventData['sos_id'] : null;
            if (sosId != null) {
              LocationService.startTrackingSos(sosId.toString());
            }

            if (onSyncSuccess != null) {
              onSyncSuccess!();
            }

            // Notify user visually
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS Tertunda Berhasil Dikirim (Sinyal Pulih)'),
                  backgroundColor: Color(0xFF10B981), // Green
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } catch (e) {
          // If we failed again (still offline), stop attempting remaining items for this run
          break;
        }
      }

      await prefs.setStringList(_outboxKey, remainingList);
    } catch (_) {
      // Quiet fail
    } finally {
      _isSyncing = false;
    }
  }

  /// Check if there are any pending unsent SOS requests in the queue
  static Future<bool> hasPendingSos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_outboxKey) ?? [];
      return list.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
