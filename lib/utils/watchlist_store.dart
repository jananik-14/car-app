import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore _instance = WatchlistStore._internal();
  factory WatchlistStore() => _instance;
  WatchlistStore._internal() {
    _init();
  }

  final List<String> savedVehicleIds = [];

  Future<void> resetSession() async {
    savedVehicleIds.clear();
    await _init();
    notifyListeners();
  }

  String _getStorageKey() {
    final phoneStr = AuthService().currentPhone ?? '';
    final normalizedPhone = phoneStr.replaceAll(RegExp(r'^\+91|\D'), '');
    return 'watchlist_$normalizedPhone';
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getStorageKey();
    final storedList = prefs.getStringList(key) ?? [];
    
    savedVehicleIds.clear();
    bool migrated = false;

    for (final item in storedList) {
      if (item.trim().startsWith('{')) {
        // Old JSON format, try to extract id
        try {
          final map = jsonDecode(item);
          if (map['id'] != null) {
            savedVehicleIds.add(map['id'].toString());
            migrated = true;
          }
        } catch (e) {
          // ignore invalid JSON
        }
      } else {
        // Plain ID
        if (item.isNotEmpty) {
          savedVehicleIds.add(item);
        }
      }
    }

    if (migrated) {
      _save();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_getStorageKey(), savedVehicleIds);
  }

  bool isSaved(String vehicleId) => savedVehicleIds.contains(vehicleId);

  void toggleSave(String? vehicleId) {
    if (vehicleId == null || vehicleId.isEmpty) return;
    
    if (isSaved(vehicleId)) {
      savedVehicleIds.remove(vehicleId);
    } else {
      savedVehicleIds.add(vehicleId);
    }
    _save();
    notifyListeners();
  }
  
  void removeIfStale(String vehicleId) {
    if (savedVehicleIds.contains(vehicleId)) {
      savedVehicleIds.remove(vehicleId);
      _save();
      notifyListeners();
    }
  }
}
