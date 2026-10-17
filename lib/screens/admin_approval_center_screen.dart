// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides admin approval endpoints:
// GET /api/admin/vehicle-posts?status=pending|accepted|rejected
// GET /api/admin/bids?status=pending|accepted|rejected
// GET /api/admin/subscriptions?status=pending|accepted|rejected
// PATCH /api/admin/vehicle-posts/:id (publish/reject)
// PATCH /api/admin/bids/:id (accept/reject)
// PATCH /api/admin/subscriptions/:id (approve/reject)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/listing_image.dart';
import '../services/listing_document_service.dart';
import '../services/share_service.dart';
import '../utils/local_listings_store.dart';
import '../utils/blob_storage.dart';
import '../services/subscription_store.dart';
import '../services/client_notification_store.dart';
import '../services/admin_clients_store.dart';
import '../config/subscription_plans.dart';
import '../utils/profile_storage_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _b(dynamic v, [bool f = false]) => v == null ? f : (v == true || v == 1 || v == 'true');
  bool _isProcessing = false;

  late MainCategory _selectedCategory;
  SubState _selectedSubState = SubState.pending;

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF22C55E);
  final Color _red = const Color(0xFFEF4444);

  final Map<String, String> _userCities = {};
  final Map<String, String> _userNames = {};
  final Map<String, DateTime> _activeClientExpiries = {};

  final Set<String> _viewedListingPdf = {};
  final Set<String> _viewedInspection = {};
  final Map<String, Uint8List?> _inspectionBytesCache = {};

  Future<void> _loadUserProfiles() async {
    final allSubs = [
      ...LocalListingsStore().pendingSubscriptions,
      ...LocalListingsStore().acceptedSubscriptions,
      ...LocalListingsStore().rejectedSubscriptions,
    ];
    final prefs = await SharedPreferences.getInstance();
    for (var sub in allSubs) {
      final phone = sub['phone']?.toString() ?? '';
      if (phone.isNotEmpty) {
        final normalized = ProfileStorageHelper.normalizePhone(phone);
        if (!_userCities.containsKey(phone)) {
          final city = prefs.getString('user_city_$normalized') ??
              prefs.getString('user_city_$phone');
          final name = prefs.getString('user_name_$normalized') ??
              prefs.getString('user_name_$phone');
          if (city != null && city.isNotEmpty) _userCities[phone] = city;
          if (name != null && name.isNotEmpty) _userNames[phone] = name;
        }

        final status = prefs.getString('sub_status_$normalized');
        final endStr = prefs.getString('sub_end_$normalized');
        if (status == 'active' && endStr != null) {
          try {
            final end = DateTime.parse(endStr);
            if (end.isAfter(DateTime.now())) {
              _activeClientExpiries[phone] = end;
              _activeClientExpiries[normalized] = end;
            }
          } catch (_) {}
        }
      }
    }

    for (var acc in LocalListingsStore().acceptedSubscriptions) {
      final phone = acc['phone']?.toString() ?? '';
      final endStr = acc['endDate']?.toString() ?? acc['expiryDate']?.toString();
      if (phone.isNotEmpty && endStr != null) {
        try {
          final end = DateTime.parse(endStr);
          if (end.isAfter(DateTime.now())) {
            _activeClientExpiries[phone] = end;
          }
        } catch (_) {}
      }
    }

    if (mounted) setState(() {});
  }

  String _formatPrice(dynamic amount) {
    if (amount == null) return '₹0';
    if (amount is num) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    }
    final str = amount.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(str);
    if (numVal != null) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(numVal);
    }
    return amount.toString();
  }

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? MainCategory.vehiclePosts;
    LocalListingsStore().addListener(_onStoreUpdate);
    _loadUserProfiles();
  }

  void _onStoreUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    LocalListingsStore().removeListener(_onStoreUpdate);
    super.dispose();
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
              'time': 'Approved recently',
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
              'time': 'Approved recently',
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
              'time': 'Accepted recently',
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
              'time': 'Accepted recently',
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
            final phone = _s(item['phone']);
            final planId = _s(item['planId'], 'yearly');
            if (phone.isNotEmpty) {
              SubscriptionStore().activate(phone, planId);
            }
            final plan = SubscriptionPlans.getPlanById(planId);
            final planName = plan?.name ?? _s(item['tier'], 'Subscription');
            final now = DateTime.now();
            final durationDays = plan?.durationDays ?? 365;
            final endDate = now.add(Duration(days: durationDays));
            LocalListingsStore().acceptedSubscriptions.insert(0, {
              ...item,
              'status': 'Approved',
              'startDate': now.toIso8601String(),
              'endDate': endDate.toIso8601String(),
              'approvedAt': now.toIso8601String(),
              'ref': 'SUB-${now.millisecondsSinceEpoch.toString().substring(8)}',
              'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
              'auditLog': 'Approved by admin on ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
            });
            if (phone.isNotEmpty) {
              ClientNotificationStore().addNotification(
                'Your $planName subscription is now active',
                'subscription_active',
                phone,
                refId: id,
              );
            }
            final clientName = _s(item['businessName'] ?? item['clientName'], 'Client');
            AdminClientsStore().history.insert(0, {
              'name': clientName,
              'action': 'subscription approved ($planName)',
              'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
              'type': 'Success',
            });
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
    String? validationError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reject Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: 'Reason for rejection (min 5 characters)',
                  errorText: validationError,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                onChanged: (_) {
                  if (validationError != null) {
                    setDialogState(() => validationError = null);
                  }
                },
              ),
              const SizedBox(height: 8),
              Text(
                'The seller will be notified with this reason.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _red, foregroundColor: Colors.white),
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.length < 5) {
                  setDialogState(() {
                    validationError = 'Reason must be at least 5 characters';
                  });
                  return;
                }
                Navigator.pop(ctx);
                _processRejection(id, category, reason);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
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
          'time': 'Declined recently',
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
              'time': 'Declined recently',
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
              'time': 'Declined recently',
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
              'time': 'Declined recently',
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
              'time': 'Declined recently',
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
            final phone = _s(item['phone']);
            if (phone.isNotEmpty) {
              SubscriptionStore().reject(phone);
            }
            final now = DateTime.now();
            LocalListingsStore().rejectedSubscriptions.insert(0, {
              ...item,
              'status': 'Rejected',
              'reason': reason,
              'rejectedAt': now.toIso8601String(),
              'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
              'auditLog': 'Rejected by admin on ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}. Reason: $reason',
            });
            if (phone.isNotEmpty) {
              ClientNotificationStore().addNotification(
                'Your subscription request was declined. Reason: $reason',
                'subscription_rejected',
                phone,
                refId: id,
              );
            }
            final clientName = _s(item['businessName'] ?? item['clientName'], 'Client');
            AdminClientsStore().history.insert(0, {
              'name': clientName,
              'action': 'subscription rejected: $reason',
              'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
              'type': 'Rejected',
            });
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Approval Center',
                  style: TextStyle(
                      color: _navy, fontSize: 20, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Verify & publish user submissions',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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

    int? pendingCount;
    int? acceptedCount;
    int? rejectedCount;

    if (_selectedCategory == MainCategory.subscriptions) {
      pendingCount = LocalListingsStore().pendingSubscriptions.length;
      acceptedCount = LocalListingsStore().acceptedSubscriptions.length;
      rejectedCount = LocalListingsStore().rejectedSubscriptions.length;
    } else if (_selectedCategory == MainCategory.vehiclePosts) {
      pendingCount = LocalListingsStore().pendingListings.length;
      acceptedCount = LocalListingsStore().acceptedListings.length;
      rejectedCount = LocalListingsStore().rejectedListings.length;
    } else if (_selectedCategory == MainCategory.payments) {
      pendingCount = LocalListingsStore().pendingPayments.where((p) => p['status'] == 'TOKEN PENDING VERIFICATION' || p['status'] == 'BALANCE PENDING VERIFICATION').length;
      acceptedCount = LocalListingsStore().pendingPayments.where((p) => p['status'] == 'TOKEN VERIFIED' || p['status'] == 'PAYMENT COMPLETED').length;
      rejectedCount = LocalListingsStore().rejectedPayments.length;
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
                _buildSubStateTab(SubState.pending, 'Pending Only', _orange, pendingCount),
                const SizedBox(width: 8),
                _buildSubStateTab(SubState.accepted, 'Accepted', _green, acceptedCount),
                const SizedBox(width: 8),
                _buildSubStateTab(SubState.rejected, 'Rejected', _red, rejectedCount),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubStateTab(SubState state, String label, Color activeColor, [int? count]) {
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? activeColor : Colors.grey.shade600,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive ? activeColor.withValues(alpha: 0.15) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: isActive ? activeColor : Colors.grey.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
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
          final time = _s(item['time'], 'Confirmed recently');
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
          final time = _s(item['time'], 'Declined recently');
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
  // VEHICLE POSTS HELPERS & DOCUMENT VIEWERS
  // ==========================================
  Future<Uint8List?> _getInspectionBytes(Map<String, dynamic> item) async {
    final id = _s(item['id']);
    if (_inspectionBytesCache.containsKey(id)) {
      return _inspectionBytesCache[id];
    }

    if (item['inspectionReportBytes'] is Uint8List) {
      final b = item['inspectionReportBytes'] as Uint8List;
      if (b.isNotEmpty) {
        _inspectionBytesCache[id] = b;
        return b;
      }
    }

    final phone = _s(item['sellerPhone'] ?? item['phone'], 'unknown_phone');
    try {
      final blob = BlobStorage();
      var bytes = await blob.get('$phone/$id/inspection');
      if (bytes == null || bytes.isEmpty) {
        bytes = await blob.get('$id/inspection');
      }
      if (bytes != null && bytes.isNotEmpty) {
        _inspectionBytesCache[id] = bytes;
        return bytes;
      }
    } catch (_) {}

    _inspectionBytesCache[id] = null;
    return null;
  }

  bool _hasInspectionSync(Map<String, dynamic> item) {
    final id = _s(item['id']);
    if (_inspectionBytesCache.containsKey(id)) {
      return _inspectionBytesCache[id] != null;
    }
    if (item['inspectionReportBytes'] is Uint8List) {
      final b = item['inspectionReportBytes'] as Uint8List;
      if (b.isNotEmpty) {
        _inspectionBytesCache[id] = b;
        return true;
      }
    }
    _getInspectionBytes(item).then((bytes) {
      if (mounted && bytes != null) setState(() {});
    });
    return false;
  }

  String _formatSubmittedTime(Map<String, dynamic> item) {
    final createdAtRaw = item['createdAt'];
    if (createdAtRaw != null && createdAtRaw.toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAtRaw.toString());
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {}
    }
    final idStr = _s(item['id']);
    final parsedMs = int.tryParse(idStr);
    if (parsedMs != null && parsedMs > 1000000000000) {
      try {
        final dt = DateTime.fromMillisecondsSinceEpoch(parsedMs);
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {}
    }
    return 'Recently';
  }

  Widget _buildDetailField(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.grey.shade500,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          value.isEmpty ? '—' : value,
          style: TextStyle(
            color: valueColor ?? _navy,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  void _openPhotoGallery(Map<String, dynamic> item) {
    final photoLabels = [
      'Front View',
      'Rear View',
      'Left / Right View',
      'Interior & Dashboard',
      'Engine & Tyres',
      'RC / Insurance Doc',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        int currentIndex = 0;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isNarrow = screenWidth < 600;

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: EdgeInsets.symmetric(
                horizontal: isNarrow ? 12 : 32,
                vertical: 24,
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _s(item['title'], 'Vehicle Photos'),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _navy,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Photo ${currentIndex + 1} of ${photoLabels.length}: ${photoLabels[currentIndex]}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ListingImage(
                                  listing: item,
                                  index: currentIndex,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            left: 8,
                            child: CircleAvatar(
                              backgroundColor: currentIndex > 0
                                  ? Colors.black.withValues(alpha: 0.6)
                                  : Colors.grey.withValues(alpha: 0.3),
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                                onPressed: currentIndex > 0
                                    ? () => setDialogState(() => currentIndex--)
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            child: CircleAvatar(
                              backgroundColor: currentIndex < photoLabels.length - 1
                                  ? Colors.black.withValues(alpha: 0.6)
                                  : Colors.grey.withValues(alpha: 0.3),
                              radius: 20,
                              child: IconButton(
                                icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                                onPressed: currentIndex < photoLabels.length - 1
                                    ? () => setDialogState(() => currentIndex++)
                                    : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      height: 72,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF9FAFB),
                        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: photoLabels.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final isSelected = idx == currentIndex;
                          return GestureDetector(
                            onTap: () => setDialogState(() => currentIndex = idx),
                            child: Container(
                              width: 60,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? _orange : Colors.grey.shade300,
                                  width: isSelected ? 2.5 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: ListingImage(
                                  listing: item,
                                  index: idx,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openListingPdfPreview(Map<String, dynamic> item) {
    final id = _s(item['id']);
    setState(() {
      _viewedListingPdf.add(id);
    });

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Listing Details (5-step PDF)',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  _s(item['title'], 'Listing PDF'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: FutureBuilder<Uint8List>(
                future: ListingDocumentService.generateListingPdf(item),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text('Failed to generate listing PDF: ${snapshot.error}'),
                    );
                  }
                  final pdfData = snapshot.data!;
                  return Column(
                    children: [
                      Expanded(
                        child: PdfPreview(
                          build: (format) => pdfData,
                          canChangeOrientation: false,
                          canChangePageFormat: false,
                          canDebug: false,
                          useActions: false,
                        ),
                      ),
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              icon: const Icon(Icons.download),
                              label: const Text('Download PDF'),
                              onPressed: () => ShareService.downloadPdf(
                                context,
                                pdfData,
                                'listing-$id.pdf',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openInspectionPdfPreview(Map<String, dynamic> item) async {
    final id = _s(item['id']);
    final pdfBytes = await _getInspectionBytes(item);
    if (!mounted) return;

    if (pdfBytes == null ||
        pdfBytes.length < 4 ||
        pdfBytes[0] != 0x25 ||
        pdfBytes[1] != 0x50 ||
        pdfBytes[2] != 0x44 ||
        pdfBytes[3] != 0x46) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection report not uploaded or invalid format'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _viewedInspection.add(id);
    });

    showDialog(
      context: context,
      builder: (ctx) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: const Color(0xFFF3F4F6),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.black),
              onPressed: () => Navigator.pop(ctx),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Inspection Report (PDF)',
                    style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  _s(item['title'], 'Inspection PDF'),
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                children: [
                  Expanded(
                    child: PdfPreview(
                      build: (format) => pdfBytes,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      useActions: false,
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                          ),
                          icon: const Icon(Icons.download),
                          label: const Text('Download Report'),
                          onPressed: () => ShareService.downloadPdf(
                            context,
                            pdfBytes,
                            _s(item['inspectionReportName'], 'inspection-$id.pdf'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showDocumentsDialog(Map<String, dynamic> item) {
    final id = _s(item['id']);
    final hasInspection = _hasInspectionSync(item);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final viewedListing = _viewedListingPdf.contains(id);
          final viewedInspection = _viewedInspection.contains(id);
          final bothViewed = viewedListing && viewedInspection;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.folder_shared_outlined, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Listing Documents',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _s(item['title'], 'Vehicle Details'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: bothViewed
                          ? _green.withValues(alpha: 0.1)
                          : _orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: bothViewed
                            ? _green.withValues(alpha: 0.3)
                            : _orange.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          bothViewed ? Icons.check_circle : Icons.info_outline,
                          size: 16,
                          color: bothViewed ? _green : _orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            bothViewed
                                ? 'Both documents reviewed. Publishing is enabled.'
                                : 'Review both documents to publish.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: bothViewed ? _green : _orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      _openListingPdfPreview(item);
                      setDialogState(() {});
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: viewedListing ? _green : Colors.grey.shade300,
                          width: viewedListing ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: viewedListing ? _green.withValues(alpha: 0.04) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.picture_as_pdf, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Listing Details (5-step PDF)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Generated in-app listing summary',
                                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: viewedListing
                                  ? _green.withValues(alpha: 0.12)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              viewedListing ? 'Viewed ✓' : 'Preview',
                              style: TextStyle(
                                color: viewedListing ? _green : Colors.grey.shade700,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: hasInspection
                        ? () {
                            _openInspectionPdfPreview(item);
                            setDialogState(() {});
                            setState(() {});
                          }
                        : null,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: !hasInspection
                              ? _red.withValues(alpha: 0.4)
                              : (viewedInspection ? _green : Colors.grey.shade300),
                          width: viewedInspection ? 1.5 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: !hasInspection
                            ? Colors.grey.shade50
                            : (viewedInspection ? _green.withValues(alpha: 0.04) : Colors.white),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: !hasInspection
                                  ? Colors.grey.shade200
                                  : _orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.verified_outlined,
                              color: !hasInspection ? Colors.grey : _orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Inspection Report (PDF)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  hasInspection
                                      ? 'Seller uploaded inspection certificate'
                                      : 'Not uploaded (Publish disabled)',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: hasInspection ? Colors.grey.shade600 : _red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: !hasInspection
                                  ? _red.withValues(alpha: 0.1)
                                  : (viewedInspection
                                      ? _green.withValues(alpha: 0.12)
                                      : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              !hasInspection
                                  ? 'Not uploaded'
                                  : (viewedInspection ? 'Viewed ✓' : 'Preview'),
                              style: TextStyle(
                                color: !hasInspection
                                    ? _red
                                    : (viewedInspection ? _green : Colors.grey.shade700),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmAndPublishVehicle(Map<String, dynamic> item) {
    if (_isProcessing) return;
    final id = _s(item['id']);
    final duration = _i(item['durationHours'] ?? item['duration'], 48);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Publish'),
        content: Text(
          'Are you sure you want to publish "${_s(item['title'])}" for auction duration of $duration Hours?\n\nBoth listing details and seller inspection report have been reviewed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              try {
                _handleApprove(id, MainCategory.vehiclePosts);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vehicle published successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error publishing vehicle: $e'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Publish Now'),
          ),
        ],
      ),
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
        emptyMessage: 'No pending vehicle posts',
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
        emptyMessage: 'No accepted vehicle posts',
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
        emptyMessage: 'No rejected vehicle posts',
      );
    }
  }

  Widget _buildPendingVehicleCard(Map<String, dynamic> item) {
    final id = _s(item['id']);
    final title = _s(item['title'], 'Untitled vehicle');
    final year = _s(item['year']);
    final brand = _s(item['brand']);
    final model = _s(item['model']);
    final variant = _s(item['variant']);
    final spec = [year, brand, model, variant].where((s) => s.isNotEmpty).join(' ');
    final vehicleSpec = spec.isNotEmpty ? spec : title;

    final regNo = _s(item['registrationNumber'] ?? item['regNo'], 'Not provided');
    final km = _s(item['kilometersDriven'] ?? item['km']);
    final kmDisplay = km.isNotEmpty ? '$km km' : 'Not provided';
    final fuel = _s(item['fuelType'] ?? item['fuel'], 'Not provided');
    final transmission = _s(item['transmission'], 'Not provided');
    final owners = _s(item['owner'] ?? item['owners'], 'Not provided');

    final insuranceType = _s(item['insuranceType'], 'Not specified');
    final expiryRaw = item['insuranceExpiryDate'] ?? item['insuranceExpiry'];
    String insuranceDisplay = insuranceType;
    if (expiryRaw != null) {
      try {
        final dt = DateTime.parse(expiryRaw.toString());
        insuranceDisplay += ' (Exp: ${DateFormat('dd MMM yyyy').format(dt)})';
      } catch (_) {
        insuranceDisplay += ' (Exp: $expiryRaw)';
      }
    }

    final priceDisplay = _formatPrice(item['price']);
    final durationDisplay = '${_s(item['durationHours'] ?? item['duration'], '48')} Hours';

    final sellerName = _s(item['sellerName'], 'Unknown');
    final sellerPhone = _s(item['sellerPhone'] ?? item['phone'], '');
    final sellerDisplay = sellerPhone.isNotEmpty ? '$sellerName • $sellerPhone' : sellerName;

    final city = _s(item['city']);
    final state = _s(item['state']);
    final locationDisplay = [city, state].where((s) => s.isNotEmpty).join(', ').isEmpty
        ? _s(item['location'], 'Not provided')
        : [city, state].where((s) => s.isNotEmpty).join(', ');

    final submittedDisplay = _formatSubmittedTime(item);

    final hasInspection = _hasInspectionSync(item);
    final viewedListing = _viewedListingPdf.contains(id);
    final viewedInspection = _viewedInspection.contains(id);
    final canPublish = hasInspection && viewedListing && viewedInspection;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final photoWidget = GestureDetector(
          onTap: () => _openPhotoGallery(item),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListingImage(
                  listing: item,
                  index: 0,
                  width: isMobile ? 120 : 160,
                  height: isMobile ? 90 : 120,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo_library, color: Colors.white, size: 10),
                      SizedBox(width: 3),
                      Text('Photos', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                Center(child: photoWidget),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      priceDisplay,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  vehicleSpec,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailField('Reg Number', regNo),
                          const SizedBox(height: 8),
                          _buildDetailField('KM Driven', kmDisplay),
                          const SizedBox(height: 8),
                          _buildDetailField('Fuel Type', fuel),
                          const SizedBox(height: 8),
                          _buildDetailField('Transmission', transmission),
                          const SizedBox(height: 8),
                          _buildDetailField('Owners', owners),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailField('Insurance', insuranceDisplay),
                          const SizedBox(height: 8),
                          _buildDetailField('Auction Duration', durationDisplay),
                          const SizedBox(height: 8),
                          _buildDetailField('Seller', sellerDisplay),
                          const SizedBox(height: 8),
                          _buildDetailField('City / State', locationDisplay),
                          const SizedBox(height: 8),
                          _buildDetailField('Submitted', submittedDisplay),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    photoWidget,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: _navy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      vehicleSpec,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                priceDisplay,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _orange,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailField('Reg Number', regNo),
                                    const SizedBox(height: 8),
                                    _buildDetailField('KM Driven', kmDisplay),
                                    const SizedBox(height: 8),
                                    _buildDetailField('Fuel Type', fuel),
                                    const SizedBox(height: 8),
                                    _buildDetailField('Transmission', transmission),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailField('Owners', owners),
                                    const SizedBox(height: 8),
                                    _buildDetailField('Insurance', insuranceDisplay),
                                    const SizedBox(height: 8),
                                    _buildDetailField('Auction Duration', durationDisplay),
                                    const SizedBox(height: 8),
                                    _buildDetailField('City / State', locationDisplay),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailField('Seller', sellerDisplay),
                                    const SizedBox(height: 8),
                                    _buildDetailField('Submitted', submittedDisplay),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
              ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showDocumentsDialog(item),
                    icon: const Icon(Icons.description_outlined, size: 16, color: Colors.blue),
                    label: Text(
                      'View Documents (${(viewedListing ? 1 : 0) + (viewedInspection ? 1 : 0)}/2 reviewed)',
                      style: const TextStyle(color: Colors.blue, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: () => _handleReject(id, MainCategory.vehiclePosts),
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
                      Tooltip(
                        message: !hasInspection
                            ? 'Inspection report not uploaded - cannot publish'
                            : (!canPublish ? 'Review both documents to publish' : ''),
                        child: ElevatedButton(
                          onPressed: canPublish
                              ? () => _confirmAndPublishVehicle(item)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        !hasInspection
                                            ? 'Inspection report not uploaded by seller'
                                            : 'Review both documents to publish',
                                      ),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canPublish ? _orange : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          child: const Text('✓ Publish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (!canPublish)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    !hasInspection
                        ? '• Inspection report not uploaded (Publish disabled)'
                        : '• Review both documents to publish',
                    style: TextStyle(
                      fontSize: 11,
                      color: !hasInspection ? _red : Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAcceptedVehicleCard(Map<String, dynamic> item) {
    final title = _s(item['title'], 'Untitled vehicle');
    final year = _s(item['year']);
    final brand = _s(item['brand']);
    final model = _s(item['model']);
    final variant = _s(item['variant']);
    final spec = [year, brand, model, variant].where((s) => s.isNotEmpty).join(' ');
    final vehicleSpec = spec.isNotEmpty ? spec : title;

    final regNo = _s(item['registrationNumber'] ?? item['regNo'], 'Not provided');
    final km = _s(item['kilometersDriven'] ?? item['km']);
    final kmDisplay = km.isNotEmpty ? '$km km' : 'Not provided';
    final fuel = _s(item['fuelType'] ?? item['fuel'], 'Not provided');
    final transmission = _s(item['transmission'], 'Not provided');

    final priceDisplay = _formatPrice(item['price']);
    final durationDisplay = '${_s(item['durationHours'] ?? item['duration'], '48')} Hours';

    final sellerName = _s(item['sellerName'], 'Unknown');
    final sellerPhone = _s(item['sellerPhone'] ?? item['phone'], '');
    final sellerDisplay = sellerPhone.isNotEmpty ? '$sellerName • $sellerPhone' : sellerName;

    final city = _s(item['city']);
    final state = _s(item['state']);
    final locationDisplay = [city, state].where((s) => s.isNotEmpty).join(', ').isEmpty
        ? _s(item['location'], 'Not provided')
        : [city, state].where((s) => s.isNotEmpty).join(', ');

    final statusStr = _s(item['status']).toLowerCase();
    final bool isLive = _b(item['isLive'], statusStr == 'live');

    String endTimeStr = 'Not set';
    if (item['endTime'] != null && item['endTime'].toString().isNotEmpty) {
      try {
        final dt = DateTime.parse(item['endTime'].toString());
        endTimeStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      } catch (_) {
        endTimeStr = item['endTime'].toString();
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _openPhotoGallery(item),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ListingImage(
                        listing: item,
                        index: 0,
                        width: isMobile ? 100 : 140,
                        height: isMobile ? 75 : 105,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
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
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _navy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isLive ? _green.withValues(alpha: 0.12) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isLive ? '● LIVE' : 'ENDED',
                                style: TextStyle(
                                  color: isLive ? _green : Colors.grey.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicleSpec,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$priceDisplay • Reg: $regNo • $sellerDisplay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFF3F4F6)),
              ),
              Wrap(
                spacing: 16,
                runSpacing: 6,
                children: [
                  _buildDetailField('End Time', endTimeStr, valueColor: isLive ? _green : Colors.grey.shade600),
                  _buildDetailField('Duration', durationDisplay),
                  _buildDetailField('KM', kmDisplay),
                  _buildDetailField('Fuel', fuel),
                  _buildDetailField('Transmission', transmission),
                  _buildDetailField('City/State', locationDisplay),
                ],
              ),
              if (isLive) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: _orange,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    ),
                    icon: const Icon(Icons.timer_off, size: 14),
                    label: const Text('End auction now (test)', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      try {
                        final String itemId = _s(item['id']);
                        item['endTime'] = DateTime.now().toIso8601String();
                        item['status'] = 'ended';
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
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildRejectedVehicleCard(Map<String, dynamic> item) {
    final title = _s(item['title'], 'Untitled vehicle');
    final year = _s(item['year']);
    final brand = _s(item['brand']);
    final model = _s(item['model']);
    final variant = _s(item['variant']);
    final spec = [year, brand, model, variant].where((s) => s.isNotEmpty).join(' ');
    final vehicleSpec = spec.isNotEmpty ? spec : title;

    final regNo = _s(item['registrationNumber'] ?? item['regNo'], 'Not provided');
    final priceDisplay = _formatPrice(item['price']);
    final sellerName = _s(item['sellerName'], 'Unknown');
    final sellerPhone = _s(item['sellerPhone'] ?? item['phone'], '');
    final sellerDisplay = sellerPhone.isNotEmpty ? '$sellerName • $sellerPhone' : sellerName;

    final reason = _s(item['rejectReason'] ?? item['reason'], 'No reason specified');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _openPhotoGallery(item),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: ListingImage(
                        listing: item,
                        index: 0,
                        width: isMobile ? 100 : 140,
                        height: isMobile ? 75 : 105,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: _navy,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'REJECTED',
                                style: TextStyle(
                                  color: _red,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          vehicleSpec,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$priceDisplay • Reg: $regNo • $sellerDisplay',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cancel_outlined, size: 16, color: _red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Rejection Reason: $reason',
                        style: TextStyle(
                          color: _red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      time: item['time'] ?? 'Recently',
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
        emptyMessage: 'No pending subscriptions',
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
        emptyMessage: 'No accepted subscriptions',
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
        emptyMessage: 'No rejected subscriptions',
      );
    }
  }

  Map<String, String> _getPlanDetails(Map<String, dynamic> item) {
    final planId = item['planId']?.toString() ?? '';
    final tier = item['tier']?.toString() ?? item['planName']?.toString() ?? '';
    SubscriptionPlan? plan;
    if (planId.isNotEmpty) {
      plan = SubscriptionPlans.getPlanById(planId);
    }
    if (plan == null && tier.isNotEmpty) {
      try {
        plan = SubscriptionPlans.plans.firstWhere(
          (p) =>
              p.name.toLowerCase() == tier.toLowerCase() ||
              p.id.toLowerCase() == tier.toLowerCase(),
        );
      } catch (_) {
        plan = null;
      }
    }

    String name = plan?.name ?? (tier.isNotEmpty ? tier : 'Subscription Plan');
    int days = plan?.durationDays ?? 0;
    if (days == 0) {
      final rawDays = item['durationDays'] ?? item['days'];
      if (rawDays != null) {
        days = int.tryParse(rawDays.toString()) ?? 0;
      }
    }
    if (days == 0 && item.containsKey('duration')) {
      final match = RegExp(r'\d+').firstMatch(item['duration'].toString());
      if (match != null) {
        days = int.tryParse(match.group(0)!) ?? 0;
      }
    }
    if (days == 0) {
      days = 30;
    }

    // Build the label once: "<planName> (<days> days)" without repeating the name;
    // if planName already contains parentheses, do not append again.
    String planLabel = name;
    if (!planLabel.contains('(')) {
      planLabel = '$name ($days days)';
    }

    dynamic price = item['price'] ?? plan?.price ?? 0;

    return {
      'name': name,
      'label': planLabel,
      'duration': '$days days',
      'price': price.toString(),
      'planId': plan?.id ?? (planId.isNotEmpty ? planId : 'yearly'),
    };
  }

  String _formatSubscriptionPrice(dynamic amount) {
    if (amount == null) return '₹0';
    if (amount is num) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    }
    final str = amount.toString().replaceAll(RegExp(r'[^0-9]'), '');
    final numVal = int.tryParse(str);
    if (numVal != null) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(numVal);
    }
    return amount.toString();
  }

  String _formatSubmittedDateTime(Map<String, dynamic> item) {
    final rawDate = item['submittedAt'] ?? item['createdAt'] ?? item['timestamp'] ?? item['date'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        return DateFormat('dd MMM yyyy, hh:mm a').format(rawDate);
      }
      try {
        final parsed = DateTime.parse(rawDate.toString());
        return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      } catch (_) {}
    }
    final idStr = item['id']?.toString() ?? '';
    final match = RegExp(r'(\d{10,13})').firstMatch(idStr);
    if (match != null) {
      final ms = int.tryParse(match.group(1)!);
      if (ms != null) {
        final dt = ms < 10000000000
            ? DateTime.fromMillisecondsSinceEpoch(ms * 1000)
            : DateTime.fromMillisecondsSinceEpoch(ms);
        return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    }
    final timeStr = item['time']?.toString() ?? '';
    if (timeStr.isNotEmpty &&
        !timeStr.toLowerCase().contains('ago') &&
        !timeStr.toLowerCase().contains('just')) {
      try {
        final parsed = DateTime.parse(timeStr);
        return DateFormat('dd MMM yyyy, hh:mm a').format(parsed);
      } catch (_) {
        return timeStr;
      }
    }
    return DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return DateFormat('dd MMM yyyy').format(DateTime.now());
    if (dateVal is DateTime) {
      return DateFormat('dd MMM yyyy').format(dateVal);
    }
    try {
      final parsed = DateTime.parse(dateVal.toString());
      return DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {
      return dateVal.toString();
    }
  }

  Widget _buildScreenshotThumbnail(dynamic screenshotKey) {
    final key = screenshotKey?.toString().trim() ?? '';
    final bool hasKey = key.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          clipBehavior: Clip.antiAlias,
          child: !hasKey
              ? Center(
                  child: Icon(
                    Icons.receipt_long_outlined,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                )
              : FutureBuilder<Uint8List?>(
                  future: BlobStorage().get(key),
                  builder: (context, snapshot) {
                    final bytes = snapshot.data;
                    if (bytes != null && bytes.isNotEmpty) {
                      return Image.memory(
                        bytes,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                      );
                    }
                    bool isLocalFile = false;
                    try {
                      isLocalFile = File(key).existsSync();
                    } catch (_) {
                      isLocalFile = false;
                    }
                    if (isLocalFile) {
                      return Image.file(
                        File(key),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildThumbPlaceholder(),
                      );
                    }
                    return _buildThumbPlaceholder();
                  },
                ),
        ),
        const SizedBox(width: 6),
        TextButton.icon(
          onPressed: hasKey ? () => _showDocumentViewerPlaceholder(key) : null,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: Colors.blue.shade700,
          ),
          icon: const Icon(Icons.visibility_outlined, size: 14),
          label: const Text(
            'View',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbPlaceholder() {
    return Center(
      child: Icon(
        Icons.image_outlined,
        color: Colors.grey.shade400,
        size: 22,
      ),
    );
  }

  Widget _buildStatusChip(SubState subState) {
    Color color;
    String label;
    switch (subState) {
      case SubState.pending:
        color = _orange;
        label = 'Pending';
        break;
      case SubState.accepted:
        color = _green;
        label = 'Approved';
        break;
      case SubState.rejected:
        color = _red;
        label = 'Rejected';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(Map<String, dynamic> item, SubState subState) {
    final phone = _s(item['phone'] ?? item['clientPhone']);
    final clientName = _s(
      item['clientName'] ??
          item['businessName'] ??
          item['dealerName'] ??
          (phone.isNotEmpty ? _userNames[phone] : null),
      'Client',
    );
    final city = _s(
      item['city'] ??
          item['userCity'] ??
          item['location'] ??
          (phone.isNotEmpty ? _userCities[phone] : null),
      'Bengaluru',
    );

    final planDetails = _getPlanDetails(item);
    final utr = _s(item['payRef'] ?? item['utr']);

    final existingExpiry = phone.isNotEmpty ? _activeClientExpiries[phone] : null;
    final bool isRenewal = existingExpiry != null && existingExpiry.isAfter(DateTime.now());

    return _buildCardWrapper(
      itemId: item['id'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar + Client Name, Phone, City + Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _navy,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    clientName.isNotEmpty ? clientName[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: TextStyle(
                        color: _navy,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (phone.isNotEmpty) '+91 $phone', if (city.isNotEmpty) city].join(' • '),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(subState),
            ],
          ),

          // Renewal / Active Plan Indicator
          if (isRenewal) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Renewal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Active until ${DateFormat('dd MMM yyyy').format(existingExpiry)}',
                      style: const TextStyle(
                        color: Color(0xFF1D4ED8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Plan Name + Duration and Amount Row (Expanded with ellipsis)
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  planDetails['label'] ?? planDetails['name'] ?? '',
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              IntrinsicWidth(
                child: Text(
                  _formatSubscriptionPrice(planDetails['price']),
                  maxLines: 1,
                  style: TextStyle(
                    color: _navy,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          ),

          // UTR, Date & Screenshot Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 500;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'UTR: ${utr.isNotEmpty ? utr : 'Pending'}',
                                style: TextStyle(
                                  color: _navy,
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (utr.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              InkWell(
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
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _formatSubmittedDateTime(item),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isWide) const Spacer(),
                  const SizedBox(width: 8),
                  _buildScreenshotThumbnail(item['screenshot']),
                ],
              );
            },
          ),

          // State specifics: Accepted start/expiry or Rejected reason
          if (subState == SubState.accepted) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Start: ${_formatDate(item['startDate'] ?? item['approvedAt'])} • Expiry: ${_formatDate(item['endDate'])}',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (subState == SubState.rejected) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_outlined, size: 14, color: Color(0xFFDC2626)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${_s(item['reason'], 'Declined by admin')}',
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons for Pending
          if (subState == SubState.pending) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _isProcessing ? null : () => _handleSubscriptionReject(item),
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
                    onPressed: _isProcessing ? null : () => _handleSubscriptionApprove(item),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _green,
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
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleSubscriptionApprove(Map<String, dynamic> item) async {
    if (_isProcessing) return;

    final planDetails = _getPlanDetails(item);
    final clientName = _s(
      item['clientName'] ?? item['businessName'] ?? item['dealerName'],
      'Client',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text(
          'Confirm activation of ${planDetails['name']} subscription for $clientName?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final phone = _s(item['phone']);
      final planId = planDetails['planId'] ?? 'yearly';
      if (phone.isNotEmpty) {
        await SubscriptionStore().activate(phone, planId);
      }

      final plan = SubscriptionPlans.getPlanById(planId);
      final durationDays = plan?.durationDays ?? 365;
      final now = DateTime.now();
      final startDate = now;
      final endDate = now.add(Duration(days: durationDays));

      LocalListingsStore().acceptSubscription({
        ...item,
        'status': 'Approved',
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'approvedAt': now.toIso8601String(),
        'ref': 'SUB-${now.millisecondsSinceEpoch.toString().substring(8)}',
        'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
        'auditLog': 'Approved by admin on ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}',
      });

      if (phone.isNotEmpty) {
        ClientNotificationStore().addNotification(
          'Your ${planDetails['name']} subscription is now active',
          'subscription_active',
          phone,
          refId: item['id'],
        );
      }

      AdminClientsStore().history.insert(0, {
        'name': clientName,
        'action': 'subscription approved (${planDetails['name']})',
        'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
        'type': 'Success',
      });

      await _loadUserProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription approved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving subscription: $e'),
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

  Future<void> _handleSubscriptionReject(Map<String, dynamic> item) async {
    if (_isProcessing) return;

    final clientName = _s(
      item['clientName'] ?? item['businessName'] ?? item['dealerName'],
      'Client',
    );
    final reasonController = TextEditingController();
    String? errorText;

    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reject Subscription'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provide a reason for rejecting $clientName\'s subscription (min 5 chars):'),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                autofocus: true,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                ),
                onChanged: (val) {
                  if (errorText != null && val.trim().length >= 5) {
                    setDialogState(() => errorText = null);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final trimmed = reasonController.text.trim();
                if (trimmed.length < 5) {
                  setDialogState(() {
                    errorText = 'Reason must be at least 5 characters';
                  });
                  return;
                }
                Navigator.pop(ctx, trimmed);
              },
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );

    if (reason == null || reason.trim().length < 5) return;
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final phone = _s(item['phone']);
      if (phone.isNotEmpty) {
        await SubscriptionStore().reject(phone);
      }

      final now = DateTime.now();
      LocalListingsStore().rejectSubscription({
        ...item,
        'status': 'Rejected',
        'reason': reason,
        'rejectedAt': now.toIso8601String(),
        'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
        'auditLog': 'Rejected by admin on ${DateFormat('dd MMM yyyy, hh:mm a').format(now)}. Reason: $reason',
      });

      if (phone.isNotEmpty) {
        ClientNotificationStore().addNotification(
          'Your subscription request was declined. Reason: $reason',
          'subscription_rejected',
          phone,
          refId: item['id'],
        );
      }

      AdminClientsStore().history.insert(0, {
        'name': clientName,
        'action': 'subscription rejected: $reason',
        'time': DateFormat('dd MMM yyyy, hh:mm a').format(now),
        'type': 'Rejected',
      });

      await _loadUserProfiles();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Subscription rejected')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting subscription: $e'),
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

  Widget _buildPendingSubscriptionCard(Map<String, dynamic> item) {
    return _buildSubscriptionCard(item, SubState.pending);
  }

  Widget _buildAcceptedSubscriptionCard(Map<String, dynamic> item) {
    return _buildSubscriptionCard(item, SubState.accepted);
  }

  Widget _buildRejectedSubscriptionCard(Map<String, dynamic> item) {
    return _buildSubscriptionCard(item, SubState.rejected);
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
    String? emptyMessage,
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
                  child: Text(emptyMessage ?? 'No items found.',
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
