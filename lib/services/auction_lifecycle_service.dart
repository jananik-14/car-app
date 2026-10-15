import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/local_listings_store.dart';

class AuctionLifecycleService extends ChangeNotifier {
  static final AuctionLifecycleService _instance = AuctionLifecycleService._internal();
  factory AuctionLifecycleService() => _instance;

  Timer? _timer;

  AuctionLifecycleService._internal() {
    _processAuctions();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _processAuctions();
      notifyListeners();
    });
  }

  void _processAuctions() {
    final store = LocalListingsStore();
    final now = DateTime.now();

    for (var listing in store.acceptedListings) {
      final s = (listing['status'] ?? '').toString().toLowerCase();
      const nonLiveStatuses = {'ended', 'ended_no_bids', 'sold', 'pending', 'rejected'};
      if (!nonLiveStatuses.contains(s) && listing['endProcessed'] != true) {
        DateTime? endTime = DateTime.tryParse(listing['endTime']?.toString() ?? '');
        if (endTime != null && (now.isAfter(endTime) || now.isAtSameMomentAs(endTime))) {
          store.endAuction(listing['id']?.toString() ?? '');
        }
      }
    }
  }

  void forceEndAuction(String id) {
    LocalListingsStore().endAuction(id);
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
