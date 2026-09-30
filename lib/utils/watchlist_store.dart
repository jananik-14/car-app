import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore _instance = WatchlistStore._internal();
  factory WatchlistStore() => _instance;
  WatchlistStore._internal();

  final List<Map<String, dynamic>> savedVehicles = [];

  String _getId(Map<String, dynamic> v) => (v['_id'] ?? v['id'] ?? '').toString();

  bool isSaved(Map<String, dynamic> vehicle) {
    final targetId = _getId(vehicle);
    if (targetId.isEmpty) return false;
    return savedVehicles.any((v) => _getId(v) == targetId);
  }

  void toggleSave(Map<String, dynamic> vehicle) {
    final targetId = _getId(vehicle);
    if (targetId.isEmpty) return;

    if (isSaved(vehicle)) {
      savedVehicles.removeWhere((v) => _getId(v) == targetId);
      ApiService().removeFromWatchlist(targetId);
    } else {
      savedVehicles.add(vehicle);
      ApiService().addToWatchlist(targetId);
    }
    notifyListeners();
  }

  Future<void> fetchFromBackend() async {
    try {
      final list = await ApiService().getWatchlist();
      savedVehicles.clear();
      for (var item in list) {
        if (item is Map<String, dynamic>) {
          if (item['vehicleId'] is Map<String, dynamic>) {
            savedVehicles.add(Map<String, dynamic>.from(item['vehicleId']));
          } else {
            savedVehicles.add(item);
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching watchlist in store: $e');
    }
  }
}
