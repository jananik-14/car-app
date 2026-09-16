import 'package:flutter/material.dart';

class WatchlistProvider extends ChangeNotifier {
  final List<Map<String, dynamic>> _savedVehicles = [];

  List<Map<String, dynamic>> get savedVehicles => _savedVehicles;

  bool isSaved(String id) {
    return _savedVehicles.any((vehicle) => vehicle['id'] == id);
  }

  void toggleVehicle(Map<String, dynamic> vehicle) {
    final id = vehicle['id'];
    if (isSaved(id)) {
      _savedVehicles.removeWhere((v) => v['id'] == id);
    } else {
      _savedVehicles.add(vehicle);
    }
    notifyListeners();
  }
}
