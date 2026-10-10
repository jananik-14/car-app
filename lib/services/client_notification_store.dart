import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/profile_storage_helper.dart';

class ClientNotificationItem {
  final String title;
  final String type;
  final String? refId;
  final DateTime timestamp;
  final String forPhone;
  bool isRead;

  ClientNotificationItem({
    required this.title,
    required this.type,
    this.refId,
    required this.timestamp,
    required this.forPhone,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'refId': refId,
        'timestamp': timestamp.toIso8601String(),
        'forPhone': forPhone,
        'isRead': isRead,
      };

  factory ClientNotificationItem.fromJson(Map<String, dynamic> json) =>
      ClientNotificationItem(
        title: json['title'],
        type: json['type'] ?? '',
        refId: json['refId'],
        timestamp: DateTime.parse(json['timestamp']),
        forPhone: json['forPhone'],
        isRead: json['isRead'] ?? false,
      );
}

class ClientNotificationStore extends ChangeNotifier {
  static final ClientNotificationStore _instance = ClientNotificationStore._internal();
  factory ClientNotificationStore() => _instance;

  final List<ClientNotificationItem> notifications = [];
  bool _isInitialized = false;

  ClientNotificationStore._internal() {
    _loadFromStorage();
  }

  void resetSession() {
    notifications.clear();
    _loadFromStorage();
    notifyListeners();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('client_notifications_store');
    if (jsonStr != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonStr);
        notifications.clear();
        for (var item in decoded) {
          notifications.add(ClientNotificationItem.fromJson(item));
        }
      } catch (e) {
        debugPrint('Error loading notifications: $e');
      }
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToStorage() async {
    if (!_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    final jsonList = notifications.map((n) => n.toJson()).toList();
    await prefs.setString('client_notifications_store', jsonEncode(jsonList));
  }

  void addNotification(String title, String type, String forPhone, {String? refId}) {
    notifications.insert(0, ClientNotificationItem(
      title: title,
      type: type,
      refId: refId,
      timestamp: DateTime.now(),
      forPhone: ProfileStorageHelper.normalizePhone(forPhone),
    ));
    _saveToStorage();
    notifyListeners();
  }

  List<ClientNotificationItem> forCurrentUser(String phone) =>
      notifications.where((n) => n.forPhone == ProfileStorageHelper.normalizePhone(phone)).toList();

  int unreadCountFor(String phone) =>
      forCurrentUser(phone).where((n) => !n.isRead).length;

  void markAllAsReadFor(String phone) {
    for (var n in forCurrentUser(phone)) {
      n.isRead = true;
    }
    _saveToStorage();
    notifyListeners();
  }

  void markAsRead(ClientNotificationItem item) {
    item.isRead = true;
    _saveToStorage();
    notifyListeners();
  }

  void clearAllFor(String phone) {
    notifications.removeWhere((n) => n.forPhone == ProfileStorageHelper.normalizePhone(phone));
    _saveToStorage();
    notifyListeners();
  }
}
