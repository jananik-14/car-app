import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/profile_storage_helper.dart';

class ClientNotificationItem {
  final String title;
  final String type;
  final String? refId;
  final String? recipientRole; // 'seller' or 'buyer'
  final DateTime timestamp;
  final String forPhone;
  bool isRead;

  static String inferType(String type, String title) {
    final t = type.trim();
    if (t.isNotEmpty && t != 'unknown') return t;
    final lower = title.toLowerCase();
    if (lower.contains('is now live') || lower.contains('approved')) {
      return 'listing_live';
    }
    if (lower.contains('rejected') || lower.contains('declined')) {
      return lower.contains('payment') ? 'payment_rejected' : 'listing_rejected';
    }
    if (lower.contains('you won')) {
      return 'bid_won';
    }
    if (lower.contains('token payment') || lower.contains('token confirmed')) {
      return 'token_confirmed';
    }
    if (lower.contains('sold')) {
      return 'sold';
    }
    if (lower.contains('subscription')) {
      return 'subscription_active';
    }
    if (lower.contains('outbid')) {
      return 'outbid';
    }
    if (lower.contains('balance payment') || lower.contains('balance paid')) {
      return 'balance_paid';
    }
    return t;
  }

  String? get targetRoute {
    if (recipientRole == 'seller') {
      return '/my_activity?tab=listings&filter=sold';
    }
    if (recipientRole == 'buyer') {
      return '/my_activity?tab=bids&filter=won';
    }
    return ClientNotificationStore.routeForType(effectiveType, recipientRole: recipientRole);
  }
  String get effectiveType => ClientNotificationStore.inferType(type, title);

  ClientNotificationItem({
    required this.title,
    required this.type,
    this.refId,
    this.recipientRole,
    required this.timestamp,
    required this.forPhone,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'type': type,
        'refId': refId,
        'recipientRole': recipientRole,
        'timestamp': timestamp.toIso8601String(),
        'forPhone': forPhone,
        'isRead': isRead,
      };

  factory ClientNotificationItem.fromJson(Map<String, dynamic> json) =>
      ClientNotificationItem(
        title: json['title'] ?? '',
        type: json['type'] ?? '',
        refId: json['refId'],
        recipientRole: json['recipientRole'],
        timestamp: DateTime.parse(json['timestamp']),
        forPhone: json['forPhone'] ?? '',
        isRead: json['isRead'] ?? false,
      );
}

class ClientNotificationStore extends ChangeNotifier {
  static final ClientNotificationStore _instance = ClientNotificationStore._internal();
  factory ClientNotificationStore() => _instance;

  static String? routeForType(String type, {String? recipientRole}) {
    if (recipientRole == 'seller') {
      return '/my_activity?tab=listings&filter=sold';
    }
    if (recipientRole == 'buyer') {
      return '/my_activity?tab=bids&filter=won';
    }
    switch (type) {
      case 'bid_won':
      case 'token_confirmed':
      case 'balance_paid':
      case 'payment_rejected':
      case 'payment':
        return '/my_activity?tab=bids&filter=won';
      case 'listing_live':
      case 'listing_approved':
      case 'listing_rejected':
      case 'sold':
      case 'ended':
        return '/my_activity?tab=listings';
      case 'outbid':
      case 'bid_lost':
        return '/my_activity?tab=bids';
      case 'subscription_active':
        return '/subscription';
      default:
        return null;
    }
  }

  static String inferType(String type, String title) =>
      ClientNotificationItem.inferType(type, title);

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

  void addNotification(
    String title,
    String type,
    String forPhone, {
    String? refId,
    String? recipientRole,
  }) {
    notifications.insert(0, ClientNotificationItem(
      title: title,
      type: type,
      refId: refId,
      recipientRole: recipientRole,
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
