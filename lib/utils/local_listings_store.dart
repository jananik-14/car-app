import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'blob_storage.dart';
import 'profile_storage_helper.dart';
class BidResult {
  final bool isSuccess;
  final String? errorMessage;
  BidResult.success() : isSuccess = true, errorMessage = null;
  BidResult.failure(this.errorMessage) : isSuccess = false;
}

// Persists data in SharedPreferences to survive hot restarts
class LocalListingsStore extends ChangeNotifier {
  static final LocalListingsStore _instance = LocalListingsStore._internal();
  factory LocalListingsStore() => _instance;
  LocalListingsStore._internal() {
    _init();
  }

  List<Map<String, dynamic>> pendingListings = [];
  List<Map<String, dynamic>> acceptedListings = [];
  List<Map<String, dynamic>> rejectedListings = [];
  
  List<Map<String, dynamic>> pendingBids = [];
  List<Map<String, dynamic>> acceptedBids = [];
  List<Map<String, dynamic>> rejectedBids = [];

  List<Map<String, dynamic>> pendingSubscriptions = [];
  List<Map<String, dynamic>> acceptedSubscriptions = [];
  List<Map<String, dynamic>> rejectedSubscriptions = [];

  List<Map<String, dynamic>> pendingPayments = [];

  bool _initialized = false;

  Future<void> _init() async {
    if (_initialized) return;
    final prefs = await SharedPreferences.getInstance();
    
    pendingListings = _loadList(prefs, 'pendingListings');
    acceptedListings = _loadList(prefs, 'acceptedListings');
    rejectedListings = _loadList(prefs, 'rejectedListings');
    pendingBids = _loadList(prefs, 'pendingBids');
    acceptedBids = _loadList(prefs, 'acceptedBids');
    rejectedBids = _loadList(prefs, 'rejectedBids');
    pendingSubscriptions = _loadList(prefs, 'pendingSubscriptions');
    acceptedSubscriptions = _loadList(prefs, 'acceptedSubscriptions');
    rejectedSubscriptions = _loadList(prefs, 'rejectedSubscriptions');
    pendingPayments = _loadList(prefs, 'pendingPayments');
    
    _initialized = true;
    notifyListeners();
  }

  List<Map<String, dynamic>> _loadList(SharedPreferences prefs, String key) {
    final strList = prefs.getStringList(key);
    if (strList == null) return [];
    
    final List<Map<String, dynamic>> validItems = [];
    for (var str in strList) {
      try {
        final decoded = jsonDecode(str);
        Map<String, dynamic>? itemMap;
        if (decoded is Map<String, dynamic>) {
          itemMap = decoded;
        } else if (decoded is Map) {
          itemMap = Map<String, dynamic>.from(decoded);
        }
        
        if (itemMap != null) {
          if (itemMap.containsKey('price')) {
            var p = itemMap['price'];
            if (p is String) {
              if (p.toUpperCase().contains('L')) {
                String numStr = p.replaceAll(RegExp(r'[^0-9.]'), '');
                double val = double.tryParse(numStr) ?? 0;
                itemMap['price'] = (val * 100000).toInt();
              } else {
                itemMap['price'] = int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              }
            }
          }
          if (itemMap.containsKey('bidAmount')) {
            var p = itemMap['bidAmount'];
            if (p is String) {
              itemMap['bidAmount'] = int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
          }
          
          if (itemMap.containsKey('currentBid')) {
            var p = itemMap['currentBid'];
            if (p is String) {
              itemMap['currentBid'] = int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
          }
          if (itemMap.containsKey('bidAmountNum')) {
            var p = itemMap['bidAmountNum'];
            if (p is String) {
              itemMap['bidAmountNum'] = int.tryParse(p.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            }
          }
          
          if (itemMap.containsKey('year')) {
            var y = itemMap['year'];
            if (y is String) {
              itemMap['year'] = int.tryParse(y);
            }
          }
          if (itemMap.containsKey('reservePrice')) {
            var r = itemMap['reservePrice'];
            if (r is String) {
              itemMap['reservePrice'] = int.tryParse(r.replaceAll(RegExp(r'[^0-9]'), ''));
            }
          }
          if (itemMap.containsKey('locationDisplay') && itemMap['locationDisplay'] != null) {
            itemMap['locationDisplay'] = itemMap['locationDisplay'].toString();
          }
          
          if (key.contains('Bids') && itemMap['id'] == null) {
            throw const FormatException('Bid missing ID');
          }
          
          // Defensive decoding for bytes (Migration code: keeping base64Decode for older listings)
          if (itemMap.containsKey('inspectionReportBytes') && itemMap['inspectionReportBytes'] != null) {
            var val = itemMap['inspectionReportBytes'];
            if (val is String) {
              itemMap['inspectionReportBytes'] = base64Decode(val);
            } else if (val is List) {
              itemMap['inspectionReportBytes'] = Uint8List.fromList(List<int>.from(val));
            }
          }
          
          if (itemMap.containsKey('photos') && itemMap['photos'] != null) {
            var val = itemMap['photos'];
            if (val is List) {
              itemMap['photos'] = val.map((e) {
                if (e is String) return base64Decode(e);
                if (e is List) return Uint8List.fromList(List<int>.from(e));
                return e;
              }).toList();
            }
          }
          
          if (itemMap.containsKey('kycDocumentBytes') && itemMap['kycDocumentBytes'] != null) {
            var val = itemMap['kycDocumentBytes'];
            if (val is String) {
              itemMap['kycDocumentBytes'] = base64Decode(val);
            } else if (val is List) {
              itemMap['kycDocumentBytes'] = Uint8List.fromList(List<int>.from(val));
            }
          }

          if (itemMap.containsKey('paymentProofBytes') && itemMap['paymentProofBytes'] != null) {
            var val = itemMap['paymentProofBytes'];
            if (val is String) {
              itemMap['paymentProofBytes'] = base64Decode(val);
            } else if (val is List) {
              itemMap['paymentProofBytes'] = Uint8List.fromList(List<int>.from(val));
            }
          }
          
          validItems.add(itemMap);
        }
      } catch (e) {
        debugPrint('Skipping corrupted listing in $key: $e');
      }
    }
    return validItems;
  }

  Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Put bytes into BlobStorage before saving JSON
    for (var item in list) {
      final String id = item['id']?.toString() ?? '';
      final String phone = item['sellerPhone']?.toString() ?? item['dealerPhone']?.toString() ?? 'unknown_phone';
      
      if (id.isEmpty) continue;

      if (item.containsKey('photos') && item['photos'] is List) {
        final photos = item['photos'] as List;
        for (int i = 0; i < photos.length; i++) {
          final p = photos[i];
          if (p is Uint8List) {
            try {
              await BlobStorage().put('$phone/$id/photo_$i', p);
            } catch (e) {
              throw Exception('Failed to save photo $i to BlobStorage: $e');
            }
          }
        }
      }

      if (item.containsKey('inspectionReportBytes') && item['inspectionReportBytes'] is Uint8List) {
        try {
          await BlobStorage().put('$phone/$id/inspection', item['inspectionReportBytes'] as Uint8List);
        } catch (e) {
          throw Exception('Failed to save inspection report to BlobStorage: $e');
        }
      }

      if (item.containsKey('kycDocumentBytes') && item['kycDocumentBytes'] is Uint8List) {
        try {
          await BlobStorage().put('$phone/$id/kyc', item['kycDocumentBytes'] as Uint8List);
        } catch (e) {
          throw Exception('Failed to save KYC to BlobStorage: $e');
        }
      }
      
      if (item.containsKey('paymentProofBytes') && item['paymentProofBytes'] is Uint8List) {
        try {
          await BlobStorage().put('$phone/$id/payment', item['paymentProofBytes'] as Uint8List);
        } catch (e) {
          throw Exception('Failed to save payment proof to BlobStorage: $e');
        }
      }
    }

    try {
      final strList = list.map((item) {
        final Map<String, dynamic> itemToSave = Map<String, dynamic>.from(item);
        
        // Remove bytes from JSON, keep only metadata
        if (itemToSave.containsKey('photos') && itemToSave['photos'] is List) {
          itemToSave['photoSlots'] = (itemToSave['photos'] as List).length;
          itemToSave.remove('photos');
        }
        if (itemToSave.containsKey('inspectionReportBytes')) {
          itemToSave['hasInspectionReport'] = itemToSave['inspectionReportBytes'] != null;
          itemToSave.remove('inspectionReportBytes');
        }
        if (itemToSave.containsKey('kycDocumentBytes')) {
          itemToSave['hasKycDocument'] = itemToSave['kycDocumentBytes'] != null;
          itemToSave.remove('kycDocumentBytes');
        }
        if (itemToSave.containsKey('paymentProofBytes')) {
          itemToSave['hasPaymentProof'] = itemToSave['paymentProofBytes'] != null;
          itemToSave.remove('paymentProofBytes');
        }

        return jsonEncode(itemToSave, toEncodable: (nonEncodable) {
          if (nonEncodable is Color) {
            return nonEncodable.toARGB32();
          } else if (nonEncodable is DateTime) {
            return nonEncodable.toIso8601String();
          } else if (nonEncodable is Uint8List) {
            return null; // Do not use base64 encoding anymore
          }
          return nonEncodable.toString();
        });
      }).toList();
      await prefs.setStringList(key, strList);
    } catch (e) {
      debugPrint('Failed to save list metadata to SharedPreferences: $e');
      throw Exception('Failed to save list metadata: $e');
    }
  }

  Future<void> addListing(Map<String, dynamic> listing) async {
    pendingListings.add(listing);
    try {
      await _saveList('pendingListings', pendingListings);
    } catch (e) {
      pendingListings.removeLast();
      rethrow;
    }
    notifyListeners();
  }

  void updateListing(Map<String, dynamic> updatedListing) {
    // Helper to update any listing, useful for extensions/edits
    bool found = false;
    for (int i = 0; i < acceptedListings.length; i++) {
      if (acceptedListings[i]['id'] == updatedListing['id']) {
        acceptedListings[i] = updatedListing;
        found = true;
        break;
      }
    }
    if (found) _saveList('acceptedListings', acceptedListings);
    notifyListeners();
  }

  void acceptListing(Map<String, dynamic> listing) {
    pendingListings.removeWhere((l) => l['id'] == listing['id']);
    acceptedListings.add(listing);
    _saveList('pendingListings', pendingListings);
    _saveList('acceptedListings', acceptedListings);
    notifyListeners();
  }

  void rejectListing(Map<String, dynamic> listing) {
    pendingListings.removeWhere((l) => l['id'] == listing['id']);
    rejectedListings.add(listing);
    _saveList('pendingListings', pendingListings);
    _saveList('rejectedListings', rejectedListings);
    notifyListeners();
  }

  void addPendingBid(Map<String, dynamic> bid) {
    pendingBids.add(bid);
    _saveList('pendingBids', pendingBids);
    notifyListeners();
  }

  void acceptBid(Map<String, dynamic> bid) {
    pendingBids.removeWhere((b) => b['id'] == bid['id']);
    acceptedBids.add(bid);
    _saveList('pendingBids', pendingBids);
    _saveList('acceptedBids', acceptedBids);
    notifyListeners();
  }

  void rejectBid(Map<String, dynamic> bid) {
    pendingBids.removeWhere((b) => b['id'] == bid['id']);
    rejectedBids.add(bid);
    _saveList('pendingBids', pendingBids);
    _saveList('rejectedBids', rejectedBids);
    notifyListeners();
  }

  void addPendingSubscription(Map<String, dynamic> sub) {
    pendingSubscriptions.add(sub);
    _saveList('pendingSubscriptions', pendingSubscriptions);
    notifyListeners();
  }

  void acceptSubscription(Map<String, dynamic> sub) {
    pendingSubscriptions.removeWhere((s) => s['id'] == sub['id']);
    acceptedSubscriptions.add(sub);
    _saveList('pendingSubscriptions', pendingSubscriptions);
    _saveList('acceptedSubscriptions', acceptedSubscriptions);
    notifyListeners();
  }

  void rejectSubscription(Map<String, dynamic> sub) {
    pendingSubscriptions.removeWhere((s) => s['id'] == sub['id']);
    rejectedSubscriptions.add(sub);
    _saveList('pendingSubscriptions', pendingSubscriptions);
    _saveList('rejectedSubscriptions', rejectedSubscriptions);
    notifyListeners();
  }

  int _getCurrentHighestBid(Map<String, dynamic> vehicle) {
    final currentBidVal = vehicle['currentBid'] ?? vehicle['price'] ?? vehicle['bid'] ?? '0';
    String str = currentBidVal.toString().trim();
    if (str.toUpperCase().contains('L')) {
      String numStr = str.replaceAll(RegExp(r'[^0-9.]'), '');
      double val = double.tryParse(numStr) ?? 0;
      return (val * 100000).toInt();
    }
    String currentBidStr = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(currentBidStr) ?? 0;
  }
  
  String _formatCurrency(int amount) {
    String str = amount.toString();
    if (str.length <= 3) return str;
    String lastThree = str.substring(str.length - 3);
    String otherNumbers = str.substring(0, str.length - 3);
    if (otherNumbers.isNotEmpty) {
      lastThree = ',$lastThree';
    }
    String result = '';
    for (int i = otherNumbers.length - 1, count = 1; i >= 0; i--, count++) {
      result = otherNumbers[i] + result;
      if (count % 2 == 0 && i != 0) {
        result = ',$result';
      }
    }
    return result + lastThree;
  }

  // TODO: TEMPORARY — bidding is fully local/instant for now (no payment authorization,
  // no real-time multi-user sync across devices). Once backend is connected:
  // - Bid placement should POST to a real API and broadcast via WebSocket to all connected clients
  // - Token/deposit verification (already covered by the subscription/payment gates) should be
  //   enforced server-side before a bid is accepted
  BidResult placeLiveBid(Map<String, dynamic> bid, String vehicleId) {
    Map<String, dynamic>? listing;
    int index = -1;
    for (int i = 0; i < acceptedListings.length; i++) {
      if (acceptedListings[i]['id'] == vehicleId) {
        listing = acceptedListings[i];
        index = i;
        break;
      }
    }
    
    if (listing == null) return BidResult.failure('Vehicle not found');

    String bidderPhone = ProfileStorageHelper.normalizePhone(bid['bidderPhone'] ?? bid['bidderUsername'] ?? '');
    String sellerPhone = ProfileStorageHelper.normalizePhone(listing['phone'] ?? listing['sellerPhone'] ?? '');
    
    if (bidderPhone.isNotEmpty && sellerPhone.isNotEmpty && bidderPhone == sellerPhone) {
      return BidResult.failure('You cannot bid on your own listing');
    }

    final liveCurrentHighestBid = _getCurrentHighestBid(listing);
    final bidsPlaced = int.tryParse(listing['bidsPlaced']?.toString() ?? '0') ?? int.tryParse(listing['bids_placed']?.toString() ?? '0') ?? 0;
    final minimumRequiredBid = bidsPlaced == 0 ? liveCurrentHighestBid : liveCurrentHighestBid + 2000;

    int bidAmount = bid['bidAmountNum'] ?? 0;
    if (bidAmount < minimumRequiredBid) {
      return BidResult.failure(
        'Your bid must be higher than the current highest bid of ₹${_formatCurrency(liveCurrentHighestBid)}. Minimum next bid: ₹${_formatCurrency(minimumRequiredBid)}'
      );
    }

    acceptedBids.insert(0, bid);
    _saveList('acceptedBids', acceptedBids);
    
    listing['currentBid'] = bidAmount;
    listing['bidsPlaced'] = (bidsPlaced + 1).toString();
    
    acceptedListings[index] = listing;
    _saveList('acceptedListings', acceptedListings);
    notifyListeners();

    return BidResult.success();
  }

  void addPendingPayment(Map<String, dynamic> payment) {
    pendingPayments.add(payment);
    _saveList('pendingPayments', pendingPayments);
    notifyListeners();
  }

  void updatePaymentStatus(String id, String status) {
    for (var p in pendingPayments) {
      if (p['id'] == id) {
        p['status'] = status;
      }
    }
    _saveList('pendingPayments', pendingPayments);
    notifyListeners();
  }
}
