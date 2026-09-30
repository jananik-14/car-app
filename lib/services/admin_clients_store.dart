import 'package:flutter/foundation.dart';

class AdminClientsStore extends ChangeNotifier {
  static final AdminClientsStore _instance = AdminClientsStore._internal();
  factory AdminClientsStore() => _instance;
  AdminClientsStore._internal();

  final List<Map<String, dynamic>> clients = [
    {'name': 'Vikram Rathore', 'email': 'vikram@example.com', 'date': '12 Sep 2026', 'status': 'Verified', 'phone': '9999999991'},
    {'name': 'Priya Sharma', 'email': 'priya.s@example.com', 'date': '10 Sep 2026', 'status': 'Pending', 'phone': '9999999992'},
    {'name': 'Amit Kumar', 'email': 'amit.k@example.com', 'date': '08 Sep 2026', 'status': 'Verified', 'phone': '9999999993'},
    {'name': 'Sneha Patel', 'email': 'sneha.p@example.com', 'date': '05 Sep 2026', 'status': 'Verified', 'phone': '9999999994'},
    {'name': 'Rahul Verma', 'email': 'rahul.v@example.com', 'date': '01 Sep 2026', 'status': 'Pending', 'phone': '9999999995'},
    {'name': 'Neha Gupta', 'email': 'neha.g@example.com', 'date': '28 Aug 2026', 'status': 'Verified', 'phone': '9999999996'},
  ];

  final List<Map<String, dynamic>> activeLogins = [
    {'name': 'Vikram Rathore', 'region': 'DL-01', 'status': 'Active 2m ago', 'ip': '192.168.1.1', 'id': '45892', 'phone': '9999999991'},
    {'name': 'Amit Kumar', 'region': 'MH-02', 'status': 'Active 5m ago', 'ip': '192.168.1.5', 'id': '45889', 'phone': '9999999993'},
  ];

  final List<Map<String, dynamic>> history = [
    {'name': 'Vikram Rathore', 'action': 'updated KYC', 'time': 'Today, 10:30 AM', 'type': 'Success'},
    {'name': 'Priya Sharma', 'action': 'logged in', 'time': 'Today, 09:15 AM', 'type': 'Session'},
    {'name': 'Amit Kumar', 'action': 'placed bid on Audi Q5', 'time': 'Yesterday, 04:20 PM', 'type': 'Success'},
    {'name': 'Rahul Verma', 'action': 'failed login attempt', 'time': 'Yesterday, 11:10 AM', 'type': 'Session'},
    {'name': 'Neha Gupta', 'action': 'completed profile', 'time': '12 Sep, 02:45 PM', 'type': 'Success'},
  ];

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
