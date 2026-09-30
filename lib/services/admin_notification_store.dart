import 'package:flutter/material.dart';

// TODO: TEMPORARY — notifications are stored in-memory only for this session.
// Replace with real-time backend notifications (e.g., via WebSocket or polling GET /api/admin/notifications) once connected.
class AdminNotificationItem {
  final String title;
  final String type; // 'login', 'bid', 'listing', 'client', 'subscription', 'profile_edit', 'payment'
  final DateTime timestamp;
  bool isRead;
  final String? relatedItemId;
  AdminNotificationItem({required this.title, required this.type, required this.timestamp, this.isRead = false, this.relatedItemId});
}

class AdminNotificationStore extends ChangeNotifier {
  static final AdminNotificationStore _instance = AdminNotificationStore._internal();
  factory AdminNotificationStore() => _instance;
  AdminNotificationStore._internal();

  final List<AdminNotificationItem> notifications = [];

  void addNotification(String title, String type, {String? relatedItemId}) {
    notifications.insert(0, AdminNotificationItem(title: title, type: type, timestamp: DateTime.now(), relatedItemId: relatedItemId));
    notifyListeners();
  }

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  void markAllRead() {
    for (var n in notifications) { n.isRead = true; }
    notifyListeners();
  }
}
