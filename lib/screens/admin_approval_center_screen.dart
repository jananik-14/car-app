// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides admin approval endpoints:
// GET /api/admin/vehicle-posts?status=pending|accepted|rejected
// GET /api/admin/bids?status=pending|accepted|rejected
// GET /api/admin/subscriptions?status=pending|accepted|rejected
// PATCH /api/admin/vehicle-posts/:id (publish/reject)
// PATCH /api/admin/bids/:id (accept/reject)
// PATCH /api/admin/subscriptions/:id (approve/reject)

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../utils/local_listings_store.dart';
import '../utils/blob_storage.dart';
import '../services/subscription_store.dart';
import '../services/client_notification_store.dart';
import '../config/app_config.dart';

enum MainCategory { vehiclePosts, bidding, subscriptions, payments }

enum SubState { pending, accepted, rejected }

class AdminApprovalCenterScreen extends StatefulWidget {
  final MainCategory? initialCategory;
  final String? highlightId;

  const AdminApprovalCenterScreen(
      {super.key, this.initialCategory, this.highlightId});

  @override
  State<AdminApprovalCenterScreen> createState() =>
      _AdminApprovalCenterScreenState();
}

class _AdminApprovalCenterScreenState extends State<AdminApprovalCenterScreen> {
  String _s(dynamic v, [String f = '']) => v == null ? f : v.toString();
  int _i(dynamic v, [int f = 0]) => v is int ? v : (int.tryParse('$v') ?? f);
  bool _b(dynamic v, [bool f = false]) => v == true || v == 1 || v == 'true';
  bool _isProcessing = false;

  late MainCategory _selectedCategory;
  SubState _selectedSubState = SubState.pending;

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF22C55E);
  final Color _red = const Color(0xFFEF4444);

  String _formatPrice(dynamic amount) {
    if (amount == null) return 'N/A';
    if (amount is num) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    }
    return amount.toString();
  }

  // --- Dummy Data ---




  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? MainCategory.vehiclePosts;
  }

  int get totalPendingCount =>
      LocalListingsStore().pendingListings.length +
      LocalListingsStore().pendingSubscriptions.length +
      LocalListingsStore()
          .pendingPayments
          .where((p) =>
              p['status'] == 'TOKEN PENDING VERIFICATION' ||
              p['status'] == 'BALANCE PENDING VERIFICATION')
          .length;

  void _showDocumentViewerPlaceholder(String? imagePath) {
    final path = _s(imagePath).trim();
    if (path.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Stack(
            children: [
              FutureBuilder<Uint8List?>(
                future: BlobStorage().get(path),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const SizedBox(
                      height: 250,
                      width: 300,
                      child: Center(
                        child: Text('Document preview not available'),
                      ),
                    );
                  }
                  if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                    return InteractiveViewer(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(
                          height: 250,
                          width: 300,
                          child: Center(
                            child: Text('Document preview not available'),
                          ),
                        ),
                      ),
                    );
                  }
                  bool fileExists = false;
                  try {
                    fileExists = File(path).existsSync();
                  } catch (_) {
                    fileExists = false;
                  }
                  if (fileExists) {
                    return InteractiveViewer(
                      child: Image.file(
                        File(path),
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(
                          height: 250,
                          width: 300,
                          child: Center(
                            child: Text('Document preview not available'),
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(
                    height: 250,
                    width: 300,
                    child: Center(
                      child: Text('Document preview not available'),
                    ),
                  );
                },
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No document/screenshot attached.')),
      );
    }
  }

  void _showConfirmationDialog(
      {required String title,
      required String content,
      required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _orange, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              onConfirm();
            },
            child: const Text('Yes, Confirm'),
          ),
        ],
      ),
    );
  }

  void _handleApprove(String id, MainCategory category) {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (category == MainCategory.payments) {
        final store = LocalListingsStore();
        final pendingSnapshot = List<Map<String, dynamic>>.from(store.pendingPayments);
        final item = pendingSnapshot.firstWhere(
          (e) => _s(e['id']) == _s(id) || _s(e['listingId']) == _s(id),
          orElse: () => <String, dynamic>{},
        );

        final allListings = [
          ...store.acceptedListings,
          ...store.pendingListings,
          ...store.rejectedListings,
        ];
        final listing = allListings.firstWhere(
          (l) => _s(l['id']) == _s(id),
          orElse: () => <String, dynamic>{},
        );

        final sellerPhone = _s(listing['sellerPhone'] ?? listing['phone']);
        final vehicleTitle = _s(item['vehicle'] ?? item['title'] ?? listing['title'], 'Vehicle');
        final buyerPhone = _s(item['buyerPhone'] ?? item['phone'] ?? listing['winnerPhone']);
        final itemType = _s(item['type'], 'token').toLowerCase();
        final amount = _i(item['amount']);

        final String newStatus = itemType == 'token' ? 'TOKEN CONFIRMED' : 'PAID';

        // Update status exactly once, which notifies listeners
        store.updatePaymentStatus(id, newStatus);

        if (itemType == 'token') {
          if (buyerPhone.isNotEmpty) {
            ClientNotificationStore().addNotification(
              'Your token payment of ₹$amount for $vehicleTitle has been confirmed. You can now pay the remaining balance.',
              'token_confirmed',
              buyerPhone,
              refId: id,
              recipientRole: 'buyer',
            );
          }
          if (sellerPhone.isNotEmpty) {
            ClientNotificationStore().addNotification(
              'Token payment of ₹$amount for $vehicleTitle has been confirmed.',
              'token_confirmed',
              sellerPhone,
              refId: id,
              recipientRole: 'seller',
            );
          }
        } else {
          if (buyerPhone.isNotEmpty) {
            ClientNotificationStore().addNotification(
              'Your balance payment of ₹$amount for $vehicleTitle has been confirmed. Payment completed.',
              'balance_paid',
              buyerPhone,
              refId: id,
              recipientRole: 'buyer',
            );
          }
          if (sellerPhone.isNotEmpty) {
            ClientNotificationStore().addNotification(
              'Full payment of ₹$amount for $vehicleTitle has been confirmed. Payment completed.',
              'balance_paid',
              sellerPhone,
              refId: id,
              recipientRole: 'seller',
            );
          }
        }

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment confirmed')),
          );
        }
        return;
      }

      setState(() {
        if (category == MainCategory.vehiclePosts) {
          final idx = LocalListingsStore().pendingListings.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            final item = LocalListingsStore().pendingListings[idx]; // Don't remove here, acceptListing does it
            final durationHours = item['durationHours'] ?? 48;
            final publishedAt = DateTime.now();
            final endTime = publishedAt.add(Duration(hours: durationHours));
            
            LocalListingsStore().acceptListing({
              ...item,
              'status': 'live',
              'publishedAt': publishedAt.toIso8601String(),
              'endTime': endTime.toIso8601String(),
              'endProcessed': false,
              'ref':
                  'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              'time': 'Approved just now',
            });
            final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your listing "${item['title']}" is now live. Auction ends on ${endTime.toString().substring(0, 16)} ($durationHours hrs)',
              'listing_live',
              sellerPhone,
              refId: id,
              recipientRole: 'seller',
            );
          } else {
            final item = LocalListingsStore()
                .pendingListings
                .firstWhere((e) => e['id'] == id);
            final durationHours = item['durationHours'] ?? 48;
            final publishedAt = DateTime.now();
            final endTime = publishedAt.add(Duration(hours: durationHours));

            LocalListingsStore().acceptListing({
              ...item,
              'status': 'live',
              'publishedAt': publishedAt.toIso8601String(),
              'endTime': endTime.toIso8601String(),
              'endProcessed': false,
              'ref':
                  'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              'time': 'Approved just now',
            });
            final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your listing "${item['title']}" is now live. Auction ends on ${endTime.toString().substring(0, 16)} ($durationHours hrs)',
              'listing_live',
              sellerPhone,
              refId: id,
              recipientRole: 'seller',
            );
          }
        } else if (category == MainCategory.bidding) {
          final idx = LocalListingsStore().pendingBids.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            final item = LocalListingsStore().pendingBids.removeAt(idx);
            LocalListingsStore().acceptedBids.insert(0, {
              'id': item['id'],
              'title': item['title'],
              'price': item['bidAmount'], // approximation
              'bidderName': item['bidderName'],
              'ref':
                  'BID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              'time': 'Accepted just now',
            });
            final bidderPhone = item['phone'] ?? item['bidderUsername'] ?? '';
            ClientNotificationStore().addNotification(
              'Your bid on "${item['title']}" was accepted!',
              'bid_won',
              bidderPhone,
              refId: item['vehicleId'] ?? item['id'],
              recipientRole: 'buyer',
            );
          } else {
            final item =
                LocalListingsStore().pendingBids.firstWhere((e) => e['id'] == id);
            LocalListingsStore().acceptBid({
              ...item,
              'ref':
                  'BID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              'time': 'Accepted just now',
            });
            final bidderPhone = item['phone'] ?? item['bidderUsername'] ?? '';
            ClientNotificationStore().addNotification(
              'Your bid on "${item['title']}" was accepted!',
              'bid_won',
              bidderPhone,
              refId: item['vehicleId'] ?? item['id'],
              recipientRole: 'buyer',
            );
          }
        } else if (category == MainCategory.subscriptions) {
          final idx = LocalListingsStore().pendingSubscriptions.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            final item = LocalListingsStore().pendingSubscriptions.removeAt(idx);
            if (item['phone'] != null && item['planId'] != null) {
              SubscriptionStore().activate(item['phone'], item['planId']);
            }
            LocalListingsStore().acceptedSubscriptions.insert(0, {
              'id': item['id'],
              'businessName': item['businessName'],
              'tier': item['tier'],
              'price': item['price'],
              'id1Label': item['id1Label'],
              'id1Value': item['id1Value'],
              'ref':
                  'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              'time': 'Approved just now',
            });
            final requesterPhone = item['phone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your ${item['tier']} subscription is now active!',
              'subscription_active',
              requesterPhone,
              refId: id,
            );
          } else {
            final item = LocalListingsStore().pendingSubscriptions
                .firstWhere((e) => e['id'] == id);
            if (item['phone'] != null && item['planId'] != null) {
              SubscriptionStore().activate(item['phone'], item['planId']);
            }
            LocalListingsStore().acceptSubscription({
              ...item,
              'ref':
                  'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
              'time': 'Approved just now',
            });
            final requesterPhone = item['phone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your ${item['tier']} subscription is now active! Valid until 1 Year.',
              'subscription_active',
              requesterPhone,
              refId: id,
            );
          }
        }
      });

      String msg = category == MainCategory.vehiclePosts
          ? "Vehicle published successfully"
          : category == MainCategory.bidding
              ? "Bid accepted"
              : "Subscription approved";
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e, stack) {
      debugPrint('PAYMENT APPROVE ERROR: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving item: $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
      }
    }
  }

  void _handleReject(String id, MainCategory category) {
    if (_isProcessing) return;
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Item'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for rejection (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _processRejection(
                  id,
                  category,
                  reasonController.text.isEmpty
                      ? 'Admin rejected'
                      : reasonController.text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _processRejection(String id, MainCategory category, String reason) {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      if (category == MainCategory.payments) {
        final store = LocalListingsStore();
        final pendingSnapshot = List<Map<String, dynamic>>.from(store.pendingPayments);
        final item = pendingSnapshot.firstWhere(
          (e) => _s(e['id']) == _s(id) || _s(e['listingId']) == _s(id),
          orElse: () => <String, dynamic>{},
        );

        final allListings = [
          ...store.acceptedListings,
          ...store.pendingListings,
          ...store.rejectedListings,
        ];
        final listing = allListings.firstWhere(
          (l) => _s(l['id']) == _s(id),
          orElse: () => <String, dynamic>{},
        );

        final sellerPhone = _s(listing['sellerPhone'] ?? listing['phone']);
        final vehicleTitle = _s(item['vehicle'] ?? item['title'] ?? listing['title'], 'Vehicle');
        final buyerPhone = _s(item['buyerPhone'] ?? item['phone'] ?? listing['winnerPhone']);
        final amount = _i(item['amount']);

        // Reject: back to 'PAYMENT PENDING' with reason
        store.updatePaymentStatus(id, 'PAYMENT PENDING');

        store.rejectPayment({
          ...item,
          'status': 'PAYMENT REJECTED',
          'rejectionReason': reason,
          'reason': reason,
          'time': 'Declined just now',
        });

        if (buyerPhone.isNotEmpty) {
          ClientNotificationStore().addNotification(
            'Your payment of ₹$amount for $vehicleTitle was rejected. Reason: $reason',
            'payment_rejected',
            buyerPhone,
            refId: id,
            recipientRole: 'buyer',
          );
        }
        if (sellerPhone.isNotEmpty) {
          ClientNotificationStore().addNotification(
            'Payment of ₹$amount for $vehicleTitle was rejected by admin. Reason: $reason',
            'payment_rejected',
            sellerPhone,
            refId: id,
            recipientRole: 'seller',
          );
        }

        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment rejected')),
          );
        }
        return;
      }

      setState(() {
        if (category == MainCategory.vehiclePosts) {
          final idx = LocalListingsStore().pendingListings.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            final item = LocalListingsStore().pendingListings[idx]; // Don't remove here, rejectListing does it
            
            LocalListingsStore().rejectListing({
              ...item,
              'status': 'rejected',
              'rejectReason': reason,
              'reason': reason,
              'time': 'Declined just now',
            });
            final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your listing "${item['title']}" was rejected. Reason: $reason',
              'listing_rejected',
              sellerPhone,
              refId: id,
              recipientRole: 'seller',
            );
          } else {
            final item = LocalListingsStore()
                .pendingListings
                .firstWhere((e) => e['id'] == id);
            LocalListingsStore().rejectListing({
              ...item,
              'status': 'rejected',
              'rejectReason': reason,
              'reason': reason,
              'time': 'Declined just now',
            });
            final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your listing "${item['title']}" was rejected. Reason: $reason',
              'listing_rejected',
              sellerPhone,
              refId: id,
              recipientRole: 'seller',
            );
          }
        } else if (category == MainCategory.bidding) {
          final idx = LocalListingsStore().pendingBids.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            final item = LocalListingsStore().pendingBids.removeAt(idx);
            LocalListingsStore().rejectedBids.insert(0, {
              'id': item['id'],
              'title': item['title'],
              'price': item['bidAmount'],
              'bidderName': item['bidderName'],
              'reason': reason,
              'time': 'Declined just now',
            });
            final bidderPhone = item['phone'] ?? item['bidderUsername'] ?? '';
            ClientNotificationStore().addNotification(
              'Your bid on "${item['title']}" was not accepted.',
              'bid_lost',
              bidderPhone,
              refId: item['vehicleId'] ?? item['id'],
              recipientRole: 'buyer',
            );
          } else {
            final item =
                LocalListingsStore().pendingBids.firstWhere((e) => e['id'] == id);
            LocalListingsStore().rejectBid({
              ...item,
              'reason': reason,
              'time': 'Declined just now',
            });
            final bidderPhone = item['phone'] ?? item['bidderUsername'] ?? '';
            ClientNotificationStore().addNotification(
              'Your bid on "${item['title']}" was not accepted.',
              'bid_lost',
              bidderPhone,
              refId: item['vehicleId'] ?? item['id'],
              recipientRole: 'buyer',
            );
          }
        } else if (category == MainCategory.subscriptions) {
          final idx = LocalListingsStore().pendingSubscriptions.indexWhere((e) => e['id'] == id);
          if (idx != -1) {
            final item = LocalListingsStore().pendingSubscriptions.removeAt(idx);
            if (item['phone'] != null) {
              SubscriptionStore().reject(item['phone']);
            }
            LocalListingsStore().rejectedSubscriptions.insert(0, {
              'id': item['id'],
              'businessName': item['businessName'],
              'tier': item['tier'],
              'dealerName': 'Dealer',
              'reason': reason,
              'time': 'Declined just now',
            });
            final requesterPhone = item['phone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your subscription request was declined. Reason: $reason',
              'subscription_rejected',
              requesterPhone,
              refId: id,
            );
          } else {
            final item = LocalListingsStore().pendingSubscriptions
                .firstWhere((e) => e['id'] == id);
            if (item['phone'] != null) {
              SubscriptionStore().reject(item['phone']);
            }
            LocalListingsStore().rejectSubscription({
              ...item,
              'dealerName': item['dealerName'] ?? 'Dealer',
              'reason': reason,
              'time': 'Declined just now',
            });
            final requesterPhone = item['phone'] ?? '';
            ClientNotificationStore().addNotification(
              'Your subscription request was declined. Reason: $reason',
              'subscription_rejected',
              requesterPhone,
              refId: id,
            );
          }
        }
      });
    } catch (e, stack) {
      debugPrint('PAYMENT APPROVE ERROR: $e\n$stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting item: $e'),
            backgroundColor: _red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      } else {
        _isProcessing = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 3,
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: const AdminAppBar(),
      body: ListenableBuilder(
          listenable: LocalListingsStore(),
          builder: (context, _) {
            return Column(
              children: [
                _buildHeaderSection(),
                _buildMainCategoryTabs(),
                _buildSubStateTabs(),
                Expanded(child: _buildContentArea()),
              ],
            );
          }),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approval Center',
                style: TextStyle(
                    color: _navy, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Verify & publish user submissions',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$totalPendingCount Pending',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryTabs() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMainCategoryTab(
                  MainCategory.vehiclePosts,
                  Icons.directions_car,
                  'Vehicle Posts',
                  LocalListingsStore().pendingListings.length),
              const SizedBox(width: 12),
              _buildMainCategoryTab(
                  MainCategory.bidding,
                  Icons.gavel,
                  'Bidding',
                  0),
              const SizedBox(width: 12),
              _buildMainCategoryTab(
                  MainCategory.subscriptions,
                  Icons.subscriptions,
                  'Subscriptions',
                  LocalListingsStore().pendingSubscriptions.length),
              const SizedBox(width: 12),
              _buildMainCategoryTab(
                  MainCategory.payments,
                  Icons.payment,
                  'Payments',
                  LocalListingsStore()
                      .pendingPayments
                      .where((p) =>
                          p['status'] == 'TOKEN PENDING VERIFICATION' ||
                          p['status'] == 'BALANCE PENDING VERIFICATION')
                      .length),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainCategoryTab(
      MainCategory category, IconData icon, String label, int count) {
    bool isActive = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = category;
        _selectedSubState =
            SubState.pending; // Reset to pending when switching category
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _navy : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : _navy, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : _navy,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    color: isActive ? _navy : _navy,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSubStateTabs() {
    if (_selectedCategory == MainCategory.bidding) {
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSubStateTab(SubState.pending, 'All Active Bids', _navy), // Reuse pending state visually for "All"
            ],
          ),
        ),
      );
    }
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Row(
              children: [
                _buildSubStateTab(SubState.pending, 'Pending Only', _orange),
                const SizedBox(width: 8),
                _buildSubStateTab(SubState.accepted, 'Accepted', _green),
                const SizedBox(width: 8),
                _buildSubStateTab(SubState.rejected, 'Rejected', _red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStateTab(SubState state, String label, Color activeColor) {
    bool isActive = _selectedSubState == state;
    return GestureDetector(
      onTap: () => setState(() => _selectedSubState = state),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                  color: isActive ? activeColor : Colors.transparent,
                  width: 2)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? activeColor : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    if (_selectedCategory == MainCategory.vehiclePosts) {
      return _buildVehiclePostsContent();
    }
    if (_selectedCategory == MainCategory.bidding) {
      return _buildBiddingContent();
    }
    if (_selectedCategory == MainCategory.subscriptions) {
      return _buildSubscriptionsContent();
    }
    if (_selectedCategory == MainCategory.payments) {
      return _buildPaymentsContent();
    }
    return const SizedBox();
  }

  // ==========================================
  // PAYMENTS
  // ==========================================
  Widget _buildPaymentsContent() {
    final allPayments = List<Map<String, dynamic>>.from(
      LocalListingsStore().pendingPayments.map((p) => Map<String, dynamic>.from(p)),
    );
    final pending = allPayments
        .where((p) {
          final s = _s(p['status']);
          return s == 'TOKEN PENDING VERIFICATION' || s == 'BALANCE PENDING VERIFICATION';
        })
        .toList();
    final accepted = allPayments
        .where((p) {
          final s = _s(p['status']);
          return s == 'TOKEN CONFIRMED' || s == 'PAID';
        })
        .toList();
    final rejectedStore = List<Map<String, dynamic>>.from(
      LocalListingsStore().rejectedPayments.map((p) => Map<String, dynamic>.from(p)),
    );
    final rejected = [
      ...rejectedStore,
      ...allPayments.where((p) {
        final s = _s(p['status']);
        final rejectionReason = _s(p['rejectionReason']);
        final reason = _s(p['reason']);
        final hasReason = rejectionReason.isNotEmpty || reason.isNotEmpty;
        return s == 'PAYMENT REJECTED' ||
            (hasReason &&
                s != 'TOKEN PENDING VERIFICATION' &&
                s != 'BALANCE PENDING VERIFICATION' &&
                s != 'TOKEN CONFIRMED' &&
                s != 'PAID');
      }),
    ];

    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'PENDING PAYMENTS',
        headerColor: _orange,
        count: pending.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: pending,
        itemBuilder: (item) => _buildPendingPaymentCard(item),
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED PAYMENTS',
        headerColor: _green,
        count: accepted.length,
        countLabel: 'Item',
        countBadgeColor: _green.withValues(alpha: 0.1),
        countTextColor: _green,
        items: accepted,
        itemBuilder: (item) {
          final vehicle = _s(item['vehicle'] ?? item['title'], 'Vehicle');
          final amount = _i(item['amount']);
          final buyerName = _s(item['buyerName'] ?? item['buyer'], 'Buyer');
          final buyerPhone = _s(item['buyerPhone'] ?? item['phone']);
          final type = _s(item['type']).toUpperCase();
          final utr = _s(item['utr']);
          final status = _s(item['status']);
          final time = _s(item['time'], 'Confirmed just now');
          final id = _s(item['id']);
          return _buildHistoryCard(
            icon: Icons.check_circle,
            iconColor: _green,
            title: '$vehicle - ₹$amount',
            subtitle: 'Buyer: $buyerName ($buyerPhone) • Type: $type • UTR: $utr',
            statusLabel: status == 'PAID' ? 'Paid' : 'Confirmed',
            statusColor: _green,
            time: time,
            itemId: id,
          );
        },
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED PAYMENTS',
        headerColor: _red,
        count: rejected.length,
        countLabel: 'Item',
        countBadgeColor: _red.withValues(alpha: 0.1),
        countTextColor: _red,
        items: rejected,
        itemBuilder: (item) {
          final vehicle = _s(item['vehicle'] ?? item['title'], 'Vehicle');
          final amount = _i(item['amount']);
          final buyerName = _s(item['buyerName'] ?? item['buyer'], 'Buyer');
          final buyerPhone = _s(item['buyerPhone'] ?? item['phone']);
          final type = _s(item['type']).toUpperCase();
          final rejectionReason = _s(item['rejectionReason']);
          final reasonFallback = _s(item['reason']);
          final reason = rejectionReason.isNotEmpty
              ? rejectionReason
              : (reasonFallback.isNotEmpty ? reasonFallback : 'Declined by admin');
          final time = _s(item['time'], 'Declined just now');
          final id = _s(item['id']);
          return _buildHistoryCard(
            icon: Icons.cancel,
            iconColor: _red,
            title: '$vehicle - ₹$amount',
            subtitle: 'Buyer: $buyerName ($buyerPhone) • Type: $type • Reason: $reason',
            statusLabel: 'Declined',
            statusColor: _red,
            time: time,
            itemId: id,
          );
        },
      );
    }
  }

  Widget _buildPendingPaymentCard(Map<String, dynamic> item) {
    final id = _s(item['id']);
    final vehicleTitle = _s(item['vehicle'] ?? item['title'], 'Vehicle');
    final buyerName = _s(item['buyerName'] ?? item['buyer'], 'Buyer');
    final buyerPhone = _s(item['buyerPhone'] ?? item['phone']);
    final amount = _i(item['amount']);
    final typeRaw = _s(item['type'], 'TOKEN');
    final type = typeRaw.toUpperCase();
    final utrRaw = _s(item['utr']);
    final utr = utrRaw.isNotEmpty ? utrRaw : 'N/A';
    final status = _s(item['status']);
    final screenshot = _s(item['screenshot']);

    return _buildCardWrapper(
      itemId: id,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  vehicleTitle,
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '₹$amount',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Buyer: $buyerName ($buyerPhone) • Type: $type',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT REF',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            utr,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _navy,
                              fontSize: 13,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: utr));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('UTR Copied!'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Icon(Icons.copy, size: 14, color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STATUS',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: _green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            status.isNotEmpty ? status : 'Awaiting Verification',
                            style: TextStyle(
                              color: _green,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TYPE',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      type,
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildScreenshotPreview(screenshot),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              GestureDetector(
                onTap: () => _showDocumentViewerPlaceholder(screenshot),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'View Documents',
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: _isProcessing
                        ? null
                        : () => _handleReject(id, MainCategory.payments),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✕ Reject'),
                  ),
                  ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () {
                            _showConfirmationDialog(
                              title: 'Confirm Payment Verification',
                              content:
                                  'Confirm you have verified this UTR ($utr) matches a real received payment of ₹$amount in your bank/UPI records?',
                              onConfirm: () => _handleApprove(id, MainCategory.payments),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✓ Approve'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotPlaceholder() {
    return Container(
      width: 72,
      height: 72,
      color: Colors.grey.shade200,
      child: const Icon(Icons.receipt_long, color: Colors.grey, size: 28),
    );
  }

  Widget _buildScreenshotPreview(String? screenshotKey) {
    final key = _s(screenshotKey);
    if (key.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 6),
            Text('No screenshot attached', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCREENSHOT PREVIEW',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        FutureBuilder<Uint8List?>(
          future: BlobStorage().get(key),
          builder: (context, snapshot) {
            final bytes = snapshot.data;
            Widget previewImg;
            if (bytes != null && bytes.isNotEmpty) {
              previewImg = Image.memory(
                bytes,
                fit: BoxFit.cover,
                width: 72,
                height: 72,
                errorBuilder: (context, error, stackTrace) => _buildScreenshotPlaceholder(),
              );
            } else {
              bool isLocalFile = false;
              try {
                isLocalFile = File(key).existsSync();
              } catch (_) {
                isLocalFile = false;
              }

              if (isLocalFile) {
                previewImg = Image.file(
                  File(key),
                  fit: BoxFit.cover,
                  width: 72,
                  height: 72,
                  errorBuilder: (context, error, stackTrace) => _buildScreenshotPlaceholder(),
                );
              } else {
                previewImg = _buildScreenshotPlaceholder();
              }
            }

            return GestureDetector(
              onTap: () => _showDocumentViewerPlaceholder(key),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    previewImg,
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        color: Colors.black54,
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: const Text(
                          'Preview',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ==========================================
  // VEHICLE POSTS
  // ==========================================
  Widget _buildVehiclePostsContent() {
    final allPendingVehicles = LocalListingsStore().pendingListings;
    final allAcceptedVehicles = LocalListingsStore().acceptedListings;
    final allRejectedVehicles = LocalListingsStore().rejectedListings;

    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'PENDING REQUESTS',
        headerColor: _orange,
        count: allPendingVehicles.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: allPendingVehicles,
        itemBuilder: _buildPendingVehicleCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED LIST (HISTORY)',
        headerColor: _green,
        count: allAcceptedVehicles.length,
        countLabel: 'Item',
        countBadgeColor: _green.withValues(alpha: 0.1),
        countTextColor: _green,
        items: allAcceptedVehicles,
        itemBuilder: _buildAcceptedVehicleCard,
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED LIST (HISTORY)',
        headerColor: _red,
        count: allRejectedVehicles.length,
        countLabel: 'Item',
        countBadgeColor: _red.withValues(alpha: 0.1),
        countTextColor: _red,
        items: allRejectedVehicles,
        itemBuilder: _buildRejectedVehicleCard,
      );
    }
  }

  Widget _buildPendingVehicleCard(Map<String, dynamic> item) {
    String reg = _s(item['registrationNumber'] ?? item['regNo'], 'Not provided');
    String displayReg = reg.length >= 5 ? reg.substring(0, 5) : reg;

    return _buildCardWrapper(
      itemId: _s(item['id']),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _s(item['imageUrl'], ''),
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.car_crash)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _s(item['title'], 'Untitled vehicle'),
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(_formatPrice(item['price']),
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ],
                    ),
                    if (item['tag'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 2),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(_s(item['tag']),
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 10)),
                      ),
                    const SizedBox(height: 4),
                    Text(
                        'Seller: ${_s(item['sellerName'], 'Unknown seller')} • ${_s(item['location'], 'Location not provided')} ($displayReg)',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    Text('Submitted ${_s(item['timeAgo'])}',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('LISTING TYPE',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_s(item['type']),
                        style: TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RC STATUS',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('● ${_s(item['rcStatus'])}',
                        style: TextStyle(
                            color: _s(item['rcStatus']) == 'Clear' ? _green : _orange,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('INSPECTION',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_s(item['inspection']),
                        style: TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              GestureDetector(
                onTap: () => _showDocumentViewerPlaceholder(item['id'] != null ? _s(item['id']) : null),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text('View Documents',
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(_s(item['id']), MainCategory.vehiclePosts),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✕ Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleApprove(_s(item['id']), MainCategory.vehiclePosts),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✓ Publish'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAcceptedVehicleCard(Map<String, dynamic> item) {
    String reg = _s(item['registrationNumber'] ?? item['regNo'], 'Not provided');
    String displayReg = reg.length >= 5 ? reg.substring(0, 5) : reg;

    Widget card = _buildHistoryCard(
      icon: Icons.check_circle,
      iconColor: _green,
      title: '${_s(item['title'], 'Untitled vehicle')} (${_formatPrice(item['price'])})',
      subtitle: 'Seller: ${_s(item['sellerName'], 'Unknown seller')} • Ref: #${_s(item['ref'], displayReg)}',
      statusLabel: 'Approved',
      statusColor: _green,
      time: _s(item['timeAgo'] ?? item['time']),
      itemId: _s(item['id']),
    );
    
    final itemStatus = _s(item['status']).toLowerCase();
    if (itemStatus == 'live') {
      return Column(
        children: [
          card,
          TextButton(
            onPressed: () {
              try {
                final String itemId = _s(item['id']);
                item['endTime'] = DateTime.now().toIso8601String();
                LocalListingsStore().endAuction(itemId);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Auction ended')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error ending auction: $e')),
                );
              }
            },
            child: const Text("End auction now (test)"),
          )
        ],
      );
    }
    return card;
  }

  Widget _buildRejectedVehicleCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.cancel,
      iconColor: _red,
      title: _s(item['title'], 'Untitled vehicle'),
      subtitle: 'Seller: ${_s(item['sellerName'], 'Unknown seller')} • ${_s(item['reason'])}',
      statusLabel: 'Declined',
      statusColor: _red,
      time: _s(item['timeAgo'] ?? item['time']),
    );
  }

  // ==========================================
  // BIDDING
  // ==========================================
  Widget _buildBiddingContent() {
    final allBids = LocalListingsStore().acceptedBids;
    
    return _buildListScaffold(
      headerText: 'ALL ACTIVE BIDS',
      headerColor: _navy,
      count: allBids.length,
      countLabel: 'Total Bids',
      countBadgeColor: _navy.withValues(alpha: 0.1),
      countTextColor: _navy,
      items: allBids,
      itemBuilder: _buildAcceptedBidCard,
    );
  }

  Widget _buildPendingBidCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      itemId: item['id'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: _navy, borderRadius: BorderRadius.circular(12)),
                child: Text('AUCTION #${item['auctionId']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
              Text(item['timeAgo'],
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title'] ?? item['vehicle'] ?? 'Unknown Vehicle',
                      style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Bidder: ${item['bidderName'] ?? item['bidder'] ?? 'Unknown'} (@${item['bidderUsername'] ?? 'unknown'}) • Dealer ID: ${item['dealerId'] ?? 'N/A'}',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('SUBMITTED BID',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(_formatPrice(item['bidAmount']),
                      style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              )
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TOKEN DEPOSIT',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: _green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text('${item['depositAmount']} Paid',
                              style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ESCROW HOLD',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item['escrow'],
                        style: TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEALER SCORE',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item['score'],
                        style: TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              GestureDetector(
                onTap: () => _showDocumentViewerPlaceholder(null),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text('View Audit Trail',
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(item['id'], MainCategory.bidding),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✕ Reject Bid'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleApprove(item['id'], MainCategory.bidding),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✓ Accept Bid'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAcceptedBidCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.check_circle,
      iconColor: _green,
      title: item['title'] ?? item['vehicle'] ?? 'Unknown Vehicle',
      subtitle: 'Bidder: ${item['bidderName'] ?? item['bidder'] ?? 'Unknown'} • Ref: #${item['ref'] ?? 'N/A'}',
      statusLabel: 'Accepted',
      statusColor: _green,
      time: item['time'] ?? 'Just now',
      itemId: item['id'],
    );
  }

  Widget _buildRejectedBidCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.cancel,
      iconColor: _red,
      title: item['title'],
      subtitle: 'Bidder: ${item['bidderName']} • ${item['reason']}',
      statusLabel: 'Declined',
      statusColor: _red,
      time: item['time'],
    );
  }

  // ==========================================
  // SUBSCRIPTIONS
  // ==========================================
  Widget _buildSubscriptionsContent() {
    final allPendingSubs = LocalListingsStore().pendingSubscriptions;
    final allAcceptedSubs = LocalListingsStore().acceptedSubscriptions;
    final allRejectedSubs = LocalListingsStore().rejectedSubscriptions;

    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'INCOMING/PENDING SUBSCRIPTIONS',
        headerColor: _orange,
        count: allPendingSubs.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: allPendingSubs,
        itemBuilder: _buildPendingSubscriptionCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED SUBSCRIPTIONS HISTORY',
        headerColor: _green,
        count: allAcceptedSubs.length,
        countLabel: 'Item',
        countBadgeColor: _green.withValues(alpha: 0.1),
        countTextColor: _green,
        items: allAcceptedSubs,
        itemBuilder: _buildAcceptedSubscriptionCard,
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED SUBSCRIPTIONS HISTORY',
        headerColor: _red,
        count: allRejectedSubs.length,
        countLabel: 'Item',
        countBadgeColor: _red.withValues(alpha: 0.1),
        countTextColor: _red,
        items: allRejectedSubs,
        itemBuilder: _buildRejectedSubscriptionCard,
      );
    }
  }

  Widget _buildPendingSubscriptionCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      itemId: item['id'],
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _navy, shape: BoxShape.circle),
                child: Icon(
                    item['tier'] == 'Elite Dealer'
                        ? Icons.stars
                        : Icons.workspace_premium,
                    color: const Color(0xFFFFD700),
                    size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['businessName'] ?? 'Unknown Business',
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: item['tierColor'] ?? Colors.blue,
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(item['tier'] ?? 'Unknown Tier',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        Text(
                            '${item['id1Label'] ?? 'ID'}: ${item['id1Value'] ?? 'N/A'}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)),
                        Text('•',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)),
                        Text(
                            '${item['id2Label'] ?? 'ID'}: ${item['id2Value'] ?? 'N/A'}',
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                    Text('Submitted ${item['timeAgo'] ?? 'Recently'}',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                            fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PLAN TIER',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                  Text(_formatPrice(item['price']),
                      style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              )
            ],
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT REF',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(item['payRef'] ?? 'Pending',
                            style: TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600)),
                        if (item['payRef'] != null) ...[
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: item['payRef']));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                  content: Text('UTR Copied!'),
                                  duration: Duration(seconds: 1)));
                            },
                            child: const Icon(Icons.copy, size: 14, color: Colors.blue),
                          ),
                        ]
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PAYMENT STATUS',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: _green),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(item['paymentStatus'] ?? 'Awaiting Verification',
                              style: TextStyle(color: _green, fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.containsKey('gstStatus') && item['gstStatus'] != null ? 'GST STATUS' : 'KYC DOCS',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item.containsKey('gstStatus') && item['gstStatus'] != null ? item['gstStatus'] : (item['kycDocs'] ?? 'Not Attached'),
                        style: TextStyle(color: _navy, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),
          
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              GestureDetector(
                onTap: () => _showDocumentViewerPlaceholder(item['screenshot']),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 6),
                    Text('View Documents',
                        style: TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(item['id'], MainCategory.subscriptions),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✕ Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(
                        title: 'Confirm Payment Verification',
                        content: 'Confirm you have verified this UTR (${item['payRef']}) matches a real received payment of ${_formatPrice(item['price'])} in your bank/UPI records?',
                        onConfirm: () => _handleApprove(item['id'], MainCategory.subscriptions),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✓ Approve Plan'),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildAcceptedSubscriptionCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.check_circle,
      iconColor: _green,
      title:
          '${item['businessName'] ?? 'Unknown'} (${item['tier'] ?? 'Unknown'} - ${_formatPrice(item['price'])})',
      subtitle:
          '${item['id1Label'] ?? 'ID'}: ${item['id1Value'] ?? 'N/A'} • Ref: #${item['ref'] ?? 'N/A'}',
      statusLabel: 'Approved',
      statusColor: _green,
      time: item['time'] ?? 'Just now',
      itemId: item['id'],
    );
  }

  Widget _buildRejectedSubscriptionCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.cancel,
      iconColor: _red,
      title:
          '${item['businessName'] ?? 'Unknown'} (${item['tier'] ?? 'Unknown'})',
      subtitle:
          'Dealer: ${item['dealerName'] ?? 'Unknown'} • ${item['reason'] ?? 'Rejected'}',
      statusLabel: 'Declined',
      statusColor: _red,
      time: item['time'] ?? 'Just now',
      itemId: item['id'],
    );
  }

  // ==========================================
  // SHARED HELPERS
  // ==========================================

  Widget _buildListScaffold({
    required String headerText,
    required Color headerColor,
    required int count,
    required String countLabel,
    required Color countBadgeColor,
    required Color countTextColor,
    required List<dynamic> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.circle, color: headerColor, size: 10),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        headerText,
                        style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: countBadgeColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Text('$count $countLabel',
                    style: TextStyle(
                        color: countTextColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Text('No items found.',
                      style: TextStyle(color: Colors.grey.shade500)))
              : ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) => itemBuilder(items[idx]),
                ),
        )
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child, String? itemId}) {
    bool isHighlighted =
        widget.highlightId != null && widget.highlightId == itemId;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighlighted ? const Color(0xFFFFF7ED) : Colors.white,
        border: isHighlighted ? Border.all(color: _orange, width: 2) : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHistoryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String statusLabel,
    required Color statusColor,
    required String time,
    String? itemId,
  }) {
    return _buildCardWrapper(
      itemId: itemId,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(statusLabel,
                  style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
              const SizedBox(height: 4),
              Text(time,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 10,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                color: valueColor ?? _navy,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}
