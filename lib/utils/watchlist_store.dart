import 'package:flutter/material.dart';

// TODO: TEMPORARY LOCAL STORE — replace with backend API (POST/DELETE /api/watchlist) once connected.
class WatchlistStore extends ChangeNotifier {
  static final WatchlistStore _instance = WatchlistStore._internal();
  factory WatchlistStore() => _instance;
  WatchlistStore._internal();

  final List<Map<String, dynamic>> savedVehicles = [];

  bool isSaved(Map<String, dynamic> vehicle) => savedVehicles.any((v) => v['id'] == vehicle['id']);

  void toggleSave(Map<String, dynamic> vehicle) {
    if (isSaved(vehicle)) {
      savedVehicles.removeWhere((v) => v['id'] == vehicle['id']);
    } else {
      savedVehicles.add(vehicle);
    }
    notifyListeners();
  }
}
