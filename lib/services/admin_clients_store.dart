import 'package:flutter/foundation.dart';

class AdminClientsStore extends ChangeNotifier {
  static final AdminClientsStore _instance = AdminClientsStore._internal();
  factory AdminClientsStore() => _instance;
  AdminClientsStore._internal();

  final List<Map<String, dynamic>> clients = [];

  final List<Map<String, dynamic>> activeLogins = [];

  final List<Map<String, dynamic>> history = [];

  void addClient(String name, String phone, {String email = ''}) {
    clients.insert(0, {
      'name': name,
      'email': email,
      'date': 'Just now',
      'status': 'Pending',
      'phone': phone,
    });
    notifyListeners();
  }

  void addLogin(String phone, {String name = 'Client'}) {
    // If the phone is already in active logins, move to top and update status
    activeLogins.removeWhere((l) => l['phone'] == phone);

    activeLogins.insert(0, {
      'name': name,
      'region': 'Current',
      'status': 'Active Now',
      'ip': '192.168.x.x',
      'id': 'new_session',
      'phone': phone,
    });
    
    history.insert(0, {
      'name': name,
      'action': 'logged in',
      'time': 'Just now',
      'type': 'Session',
    });
    notifyListeners();
  }
}
