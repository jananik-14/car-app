import 'package:flutter/foundation.dart';
import '../utils/temp_admin_config.dart';

class AdminClientsStore extends ChangeNotifier {
  static final AdminClientsStore _instance = AdminClientsStore._internal();
  factory AdminClientsStore() => _instance;
  AdminClientsStore._internal();

  final List<Map<String, dynamic>> clients = [];

  final List<Map<String, dynamic>> activeLogins = [];

  final List<Map<String, dynamic>> history = [];

  void addClient(String name, String phone, {String email = '', String status = 'Pending'}) {
    final nowIso = DateTime.now().toIso8601String();
    clients.removeWhere((c) => c['phone'] == phone);
    clients.insert(0, {
      'name': name,
      'email': email,
      'date': nowIso,
      'status': status,
      'phone': phone,
    });
    notifyListeners();
  }

  void addLogin(String phone, {String name = 'Client', String device = 'Web'}) {
    // Exclude admin's own login
    if (TempAdminConfig.isAdminNumber(phone) || phone == '9999999999') {
      return;
    }

    // If the phone is already in active logins, move to top and update status
    activeLogins.removeWhere((l) => l['phone'] == phone);

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    activeLogins.insert(0, {
      'name': name,
      'phone': phone,
      'device': device,
      'status': 'Active Now',
      'loginTime': nowIso,
      'time': nowIso,
    });
    
    addHistoryEntry(
      name: name,
      phone: phone,
      action: 'logged in',
      type: 'login',
      timestamp: now,
    );
    notifyListeners();
  }

  void removeLogin(String phone, {String? reason}) {
    final existing = activeLogins.firstWhere(
      (l) => l['phone'] == phone,
      orElse: () => <String, dynamic>{},
    );
    final clientName = existing['name']?.toString() ?? 'Client';
    activeLogins.removeWhere((l) => l['phone'] == phone);

    if (reason != null && reason.isNotEmpty) {
      addHistoryEntry(
        name: clientName,
        phone: phone,
        action: reason,
        type: 'logout',
      );
    }
    notifyListeners();
  }

  void forceLogout(String phone, {String name = 'Client'}) {
    removeLogin(phone, reason: 'Force logged out by admin');
  }

  void addHistoryEntry({
    required String name,
    required String action,
    required String type,
    String phone = '',
    DateTime? timestamp,
  }) {
    // Exclude admin's own login or actions
    if (type.toLowerCase() == 'login' && (TempAdminConfig.isAdminNumber(phone) || phone == '9999999999')) {
      return;
    }
    final nowIso = (timestamp ?? DateTime.now()).toIso8601String();
    history.insert(0, {
      'name': name,
      'phone': phone,
      'action': action,
      'type': type,
      'timestamp': nowIso,
      'time': nowIso,
    });
    notifyListeners();
  }
}

