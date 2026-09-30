import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'subscription_store.dart';
import '../utils/profile_storage_helper.dart'; // Ensure correct import
import 'admin_clients_store.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  bool isLoggedIn = false;
  String? currentPhone;
  static String currentUserRole = 'customer';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    currentPhone = prefs.getString('current_logged_in_phone');
    isLoggedIn = currentPhone != null && currentPhone!.isNotEmpty;
    notifyListeners();
  }

  Future<void> login(String phone) async {
    isLoggedIn = true;
    currentPhone = phone;
    await ProfileStorageHelper.setCurrentLoggedInPhone(phone);
    final realName = await ProfileStorageHelper.getProfileField(phone, 'user_name');
    final displayName = (realName != null && realName.isNotEmpty) ? realName : phone;
    AdminClientsStore().addLogin(phone, name: displayName); // Mock adding to active logins
    notifyListeners();
  }

  Future<void> logout() async {
    print('LOGOUT DEBUG: logout() called');
    isLoggedIn = false;
    currentPhone = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_logged_in_phone');
    
    // Reset in-memory stores
    SubscriptionStore().resetSession(); 
    
    notifyListeners();
  }
}
