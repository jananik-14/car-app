import 'dart:async';
import 'package:flutter/foundation.dart';
import '../utils/local_listings_store.dart';
import '../services/client_notification_store.dart';

class AuctionLifecycleService extends ChangeNotifier {
  static final AuctionLifecycleService _instance = AuctionLifecycleService._internal();
  factory AuctionLifecycleService() => _instance;

  Timer? _timer;

  AuctionLifecycleService._internal() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _processAuctions();
      notifyListeners();
    });
  }

  void _processAuctions() {
    final store = LocalListingsStore();
    final now = DateTime.now();

    for (var listing in store.acceptedListings) {
      if (listing['status'] == 'live' && listing['endProcessed'] != true) {
        DateTime? endTime = DateTime.tryParse(listing['endTime'] ?? '');
        if (endTime != null && now.isAfter(endTime)) {
          // Process end
          listing['endProcessed'] = true;
          
          final allBids = store.acceptedBids.where((b) => b['vehicleId'] == listing['id']).toList();
          int highestBid = 0;
          String? winnerPhone;
          
          for (var b in allBids) {
            var rawAmt = b['bidAmountNum'];
            int amt = rawAmt is int ? rawAmt : int.tryParse(rawAmt?.toString() ?? '') ?? 0;
            if (amt > highestBid) {
              highestBid = amt;
              winnerPhone = b['bidderPhone'] ?? b['bidderUsername'];
            }
          }

          if (highestBid > 0 && winnerPhone != null) {
            listing['status'] = 'ended';
            // Notify winner
            ClientNotificationStore().addNotification(
              'You won the auction for ${listing['title']}!',
              'bid_won',
              winnerPhone,
              refId: listing['id'],
            );
            // Notify seller
            String sellerPhone = listing['phone'] ?? listing['sellerPhone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your vehicle ${listing['title']} sold for $highestBid!',
              'sold',
              sellerPhone,
              refId: listing['id'],
            );
          } else {
            listing['status'] = 'ended_no_bids';
          }
          
          store.updateListing(listing);
        }
      }
    }
  }

  void forceEndAuction(String id) {
    final store = LocalListingsStore();
    for (var listing in store.acceptedListings) {
      if (listing['id'] == id) {
        listing['endTime'] = DateTime.now().toIso8601String();
        break;
      }
    }
    _processAuctions();
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
