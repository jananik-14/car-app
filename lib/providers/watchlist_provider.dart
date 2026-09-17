import 'package:flutter/material.dart';
import '../services/api_service.dart';

class WatchlistProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _savedVehicles = [];
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> get savedVehicles => _savedVehicles;

  Future<void> loadWatchlist() async {
    try {
      final data = await _apiService.getWatchlist();
      _savedVehicles = List<Map<String, dynamic>>.from(data);
      notifyListeners();
    } catch (e) {
      print('Failed to load watchlist: $e');
    }
  }

  bool isSaved(String id) {
    return _savedVehicles.any((vehicle) => vehicle['vehicleId'] == id || vehicle['id'] == id);
  }

  Future<void> toggleVehicle(Map<String, dynamic> vehicle) async {
    final id = vehicle['id'] ?? vehicle['vehicleId'];
    if (isSaved(id)) {
      _savedVehicles.removeWhere((v) => (v['id'] ?? v['vehicleId']) == id);
      notifyListeners();
      await _apiService.removeFromWatchlist(id);
    } else {
      _savedVehicles.add(vehicle);
      notifyListeners();
      await _apiService.addToWatchlist(id);
    }
  }
}
