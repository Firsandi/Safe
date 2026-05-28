import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safe/core/utils/session_manager.dart';

class LocalNotification {
  final String id;
  final String title;
  final String body;
  final String type; // 'sos_alert', 'contact_request', 'contact_accepted'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? payload;

  LocalNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.payload,
  });

  LocalNotification copyWith({
    String? id,
    String? title,
    String? body,
    String? type,
    DateTime? timestamp,
    bool? isRead,
    Map<String, dynamic>? payload,
  }) {
    return LocalNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      payload: payload ?? this.payload,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'payload': payload,
    };
  }

  factory LocalNotification.fromJson(Map<String, dynamic> json) {
    return LocalNotification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'general',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
      payload: json['payload'],
    );
  }
}

class NotificationLocalService {
  static final StreamController<int> _unreadCountController = StreamController<int>.broadcast();

  /// Stream that emits the current unread count whenever it changes
  static Stream<int> get unreadCountStream => _unreadCountController.stream;

  /// Helper to fetch and emit the latest unread count
  static Future<void> _updateUnreadCount() async {
    final count = await getUnreadCount();
    _unreadCountController.add(count);
  }

  static Future<String> _getStorageKey() async {
    final userData = await SessionManager.getUserData();
    final userId = userData != null ? userData['user_id'] : 'guest';
    return 'local_notifications_$userId';
  }

  /// Loads the notification list for the currently logged-in user
  static Future<List<LocalNotification>> loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final dataStr = prefs.getString(key);
      if (dataStr == null) return [];
      
      final List<dynamic> decoded = jsonDecode(dataStr);
      return decoded.map((item) => LocalNotification.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Saves a notification to SharedPreferences
  static Future<void> saveNotification(LocalNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final notifications = await loadNotifications();
      
      // Avoid duplicate notification IDs
      notifications.removeWhere((item) => item.id == notification.id);
      notifications.insert(0, notification); // newest first
      
      final dataStr = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(key, dataStr);
      await _updateUnreadCount();
    } catch (_) {}
  }

  /// Saves multiple notifications to SharedPreferences in a single batch
  static Future<void> saveNotifications(List<LocalNotification> newNotifications) async {
    if (newNotifications.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final notifications = await loadNotifications();
      
      final Set<String> existingIds = notifications.map((n) => n.id).toSet();
      final List<LocalNotification> uniqueNew = newNotifications
          .where((n) => !existingIds.contains(n.id))
          .toList();
          
      if (uniqueNew.isEmpty) return;

      // Add all unique new items, then sort by timestamp descending (newest first)
      notifications.addAll(uniqueNew);
      notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      final dataStr = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(key, dataStr);
      await _updateUnreadCount();
    } catch (_) {}
  }

  /// Marks a specific notification as read
  static Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final notifications = await loadNotifications();
      
      final index = notifications.indexWhere((item) => item.id == id);
      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        final dataStr = jsonEncode(notifications.map((n) => n.toJson()).toList());
        await prefs.setString(key, dataStr);
        await _updateUnreadCount();
      }
    } catch (_) {}
  }

  /// Marks all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final notifications = await loadNotifications();
      
      final updated = notifications.map((n) => n.copyWith(isRead: true)).toList();
      final dataStr = jsonEncode(updated.map((n) => n.toJson()).toList());
      await prefs.setString(key, dataStr);
      await _updateUnreadCount();
    } catch (_) {}
  }

  /// Gets the count of unread notifications
  static Future<int> getUnreadCount() async {
    final notifications = await loadNotifications();
    return notifications.where((n) => !n.isRead).length;
  }

  /// Deletes a specific notification by ID
  static Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final notifications = await loadNotifications();
      
      notifications.removeWhere((item) => item.id == id);
      
      final dataStr = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(key, dataStr);
      await _updateUnreadCount();
    } catch (_) {}
  }

  /// Deletes multiple notifications by their IDs
  static Future<void> deleteNotifications(List<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      final notifications = await loadNotifications();
      
      notifications.removeWhere((item) => ids.contains(item.id));
      
      final dataStr = jsonEncode(notifications.map((n) => n.toJson()).toList());
      await prefs.setString(key, dataStr);
      await _updateUnreadCount();
    } catch (_) {}
  }

  /// Clears all notifications
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = await _getStorageKey();
      await prefs.remove(key);
      await _updateUnreadCount();
    } catch (_) {}
  }
}
