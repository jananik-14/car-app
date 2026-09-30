import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';

// TEMPORARY in-memory data, works only within one browser session; 
// replace with backend API endpoints once connected.
class LocalListingsStore extends ChangeNotifier {
  static final LocalListingsStore _instance = LocalListingsStore._internal();
  factory LocalListingsStore() => _instance;
  LocalListingsStore._internal();

  final List<Map<String, dynamic>> pendingListings = [];
  final List<Map<String, dynamic>> acceptedListings = [];
  final List<Map<String, dynamic>> rejectedListings = [];
  
  final List<Map<String, dynamic>> pendingBids = [];
  final List<Map<String, dynamic>> acceptedBids = [];
  final List<Map<String, dynamic>> rejectedBids = [];

  final List<Map<String, dynamic>> pendingSubscriptions = [];
  final List<Map<String, dynamic>> acceptedSubscriptions = [];
  final List<Map<String, dynamic>> rejectedSubscriptions = [];

  final List<Map<String, dynamic>> pendingPayments = [];

  void addListing(Map<String, dynamic> listing) {
    pendingListings.add(listing);
    notifyListeners();
  }

  void acceptListing(Map<String, dynamic> listing) {
    pendingListings.removeWhere((l) => l['id'] == listing['id']);
    acceptedListings.add(listing);
    notifyListeners();
  }

  void rejectListing(Map<String, dynamic> listing) {
    pendingListings.removeWhere((l) => l['id'] == listing['id']);
    rejectedListings.add(listing);
    notifyListeners();
  }

  void addPendingBid(Map<String, dynamic> bid) {
    pendingBids.add(bid);
    notifyListeners();
  }

  void acceptBid(Map<String, dynamic> bid) {
    pendingBids.removeWhere((b) => b['id'] == bid['id']);
    acceptedBids.add(bid);
    notifyListeners();
  }

  void rejectBid(Map<String, dynamic> bid) {
    pendingBids.removeWhere((b) => b['id'] == bid['id']);
    rejectedBids.add(bid);
    notifyListeners();
  }

  void addPendingSubscription(Map<String, dynamic> sub) {
    pendingSubscriptions.add(sub);
    notifyListeners();
  }

  void acceptSubscription(Map<String, dynamic> sub) {
    pendingSubscriptions.removeWhere((s) => s['id'] == sub['id']);
    acceptedSubscriptions.add(sub);
    notifyListeners();
  }

  void rejectSubscription(Map<String, dynamic> sub) {
    pendingSubscriptions.removeWhere((s) => s['id'] == sub['id']);
    rejectedSubscriptions.add(sub);
    notifyListeners();
  }

  void addPendingPayment(Map<String, dynamic> payment) {
    pendingPayments.add(payment);
    notifyListeners();
  }

  void updatePaymentStatus(String id, String status) {
    for (var p in pendingPayments) {
      if (p['id'] == id) {
        p['status'] = status;
      }
    }
    notifyListeners();
  }
}
