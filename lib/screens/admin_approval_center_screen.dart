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
import '../theme/app_theme.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../utils/global_store.dart';
import '../widgets/admin_app_bar.dart';
import '../utils/local_listings_store.dart';
import '../services/subscription_store.dart';
import '../services/client_notification_store.dart';
import '../config/subscription_plans.dart';

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
  late MainCategory _selectedCategory;
  SubState _selectedSubState = SubState.pending;

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF22C55E);
  final Color _red = const Color(0xFFEF4444);

  // --- Dummy Data ---




  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory ?? MainCategory.vehiclePosts;
  }

  int get totalPendingCount =>
      LocalListingsStore().pendingListings.length +
      LocalListingsStore().pendingBids.length +
      LocalListingsStore().pendingSubscriptions.length +
      LocalListingsStore()
          .pendingPayments
          .where((p) => p['status'] != 'PAID')
          .length;

  void _showDocumentViewerPlaceholder(String? imagePath) {
    if (imagePath != null && imagePath.isNotEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          child: Stack(
            children: [
              InteractiveViewer(
                child: Image.file(File(imagePath), fit: BoxFit.contain),
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
    setState(() {
      if (category == MainCategory.vehiclePosts) {
        final idx = LocalListingsStore().pendingListings.indexWhere((e) => e['id'] == id);
        if (idx != -1) {
          final item = LocalListingsStore().pendingListings.removeAt(idx);
          LocalListingsStore().acceptedListings.insert(0, {
            'id': item['id'],
            'title': item['title'],
            'price': item['price'],
            'sellerName': item['sellerName'],
            'ref':
                'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            'time': 'Approved just now',
          });
          final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
          ClientNotificationStore().addNotification(
            'Your listing "${item['title']}" was approved and is now live.',
            'listing_approved',
            sellerPhone,
          );
        } else {
          final item = LocalListingsStore()
              .pendingListings
              .firstWhere((e) => e['id'] == id);
          LocalListingsStore().acceptListing({
            ...item,
            'ref':
                'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
            'time': 'Approved just now',
          });
          final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
          ClientNotificationStore().addNotification(
            'Your listing "${item['title']}" has been approved and is now live!',
            'listing_approved',
            sellerPhone,
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
            'bid_accepted',
            bidderPhone,
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
            'bid_accepted',
            bidderPhone,
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
            'subscription_approved',
            requesterPhone,
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
            'subscription_approved',
            requesterPhone,
          );
        }
      } else if (category == MainCategory.payments) {
        final item = LocalListingsStore()
            .pendingPayments
            .firstWhere((e) => e['id'] == id);
        if (item['type'] == 'token') {
          LocalListingsStore().updatePaymentStatus(id, 'TOKEN CONFIRMED');
          final buyerPhone = item['phone'] ?? item['buyerPhone'] ?? '';
          ClientNotificationStore().addNotification(
            'Your payment of ₹${item['amount']} has been confirmed.',
            'payment_confirmed',
            buyerPhone,
          );
        } else {
          LocalListingsStore().updatePaymentStatus(id, 'PAID');
          final buyerPhone = item['phone'] ?? item['buyerPhone'] ?? '';
          ClientNotificationStore().addNotification(
            'Your payment of ₹${item['amount']} has been confirmed.',
            'payment_confirmed',
            buyerPhone,
          );
        }
      }
    });

    String msg = category == MainCategory.vehiclePosts
        ? "Vehicle published successfully"
        : category == MainCategory.bidding
            ? "Bid accepted"
            : category == MainCategory.payments
                ? "Payment confirmed"
                : "Subscription approved";
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _handleReject(String id, MainCategory category) {
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
    setState(() {
      if (category == MainCategory.vehiclePosts) {
        final idx = LocalListingsStore().pendingListings.indexWhere((e) => e['id'] == id);
        if (idx != -1) {
          final item = LocalListingsStore().pendingListings.removeAt(idx);
          LocalListingsStore().rejectedListings.insert(0, {
            'id': item['id'],
            'title': item['title'],
            'sellerName': item['sellerName'],
            'reason': reason,
            'time': 'Declined just now',
          });
          final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
          ClientNotificationStore().addNotification(
            'Your listing "${item['title']}" was rejected. Reason: $reason',
            'listing_rejected',
            sellerPhone,
          );
        } else {
          final item = LocalListingsStore()
              .pendingListings
              .firstWhere((e) => e['id'] == id);
          LocalListingsStore().rejectListing({
            ...item,
            'reason': reason,
            'time': 'Declined just now',
          });
          final sellerPhone = item['phone'] ?? item['sellerPhone'] ?? '';
          ClientNotificationStore().addNotification(
            'Your listing "${item['title']}" was rejected. Reason: $reason',
            'listing_rejected',
            sellerPhone,
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
            'bid_rejected',
            bidderPhone,
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
            'bid_rejected',
            bidderPhone,
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
          );
        }
      } else if (category == MainCategory.payments) {
        LocalListingsStore().updatePaymentStatus(id, 'PAYMENT REJECTED');
        final item = LocalListingsStore().pendingPayments.firstWhere((e) => e['id'] == id);
        final buyerPhone = item['phone'] ?? item['buyerPhone'] ?? '';
        ClientNotificationStore().addNotification(
          'Your payment of ₹${item['amount'] ?? ''} was rejected. Reason: $reason',
          'payment_rejected',
          buyerPhone,
        );
      }
    });
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
                  LocalListingsStore().pendingBids.length),
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
                      .where((p) => p['status'] != 'PAID')
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
            const SizedBox(width: 16),
            Row(
              children: [
                Icon(Icons.sync, color: Colors.grey.shade500, size: 14),
                const SizedBox(width: 4),
                Text('Live sync',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            )
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
    if (_selectedCategory == MainCategory.vehiclePosts)
      return _buildVehiclePostsContent();
    if (_selectedCategory == MainCategory.bidding)
      return _buildBiddingContent();
    if (_selectedCategory == MainCategory.subscriptions)
      return _buildSubscriptionsContent();
    if (_selectedCategory == MainCategory.payments)
      return _buildPaymentsContent();
    return const SizedBox();
  }

  // ==========================================
  // PAYMENTS
  // ==========================================
  Widget _buildPaymentsContent() {
    final allPayments = LocalListingsStore().pendingPayments;
    final pending = allPayments
        .where((p) =>
            p['status'] == 'TOKEN PENDING VERIFICATION' ||
            p['status'] == 'BALANCE PENDING VERIFICATION')
        .toList();
    final accepted = allPayments
        .where((p) => p['status'] == 'TOKEN CONFIRMED' || p['status'] == 'PAID')
        .toList();
    final rejected =
        allPayments.where((p) => p['status'] == 'PAYMENT REJECTED').toList();

    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'PENDING PAYMENTS',
        headerColor: _orange,
        count: pending.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: pending,
        itemBuilder: _buildPendingPaymentCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED PAYMENTS',
        headerColor: _green,
        count: accepted.length,
        countLabel: 'Item',
        countBadgeColor: _green.withOpacity(0.1),
        countTextColor: _green,
        items: accepted,
        itemBuilder: (item) => _buildHistoryCard(
          icon: Icons.check_circle,
          iconColor: _green,
          title: '${item['vehicle']} - ₹${item['amount']}',
          subtitle: 'Buyer: ${item['buyer']} • UTR: ${item['utr']}',
          statusLabel: 'Confirmed',
          statusColor: _green,
          time: 'Confirmed just now',
          itemId: item['id'],
        ),
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED PAYMENTS',
        headerColor: _red,
        count: rejected.length,
        countLabel: 'Item',
        countBadgeColor: _red.withOpacity(0.1),
        countTextColor: _red,
        items: rejected,
        itemBuilder: (item) => _buildHistoryCard(
          icon: Icons.cancel,
          iconColor: _red,
          title: '${item['vehicle']} - ₹${item['amount']}',
          subtitle: 'Buyer: ${item['buyer']} • UTR: ${item['utr']}',
          statusLabel: 'Declined',
          statusColor: _red,
          time: 'Declined just now',
        ),
      );
    }
  }

  Widget _buildPendingPaymentCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      itemId: item['id'],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(item['vehicle'],
                      style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 15))),
              Text('₹${item['amount']}',
                  style: TextStyle(
                      color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              'Buyer: ${item['buyer']} • Type: ${item['type'].toString().toUpperCase()}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          
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
                        Text(item['utr'],
                            style: TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: item['utr']));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                                content: Text('UTR Copied!'),
                                duration: Duration(seconds: 1)));
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
                    Text('STATUS',
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
                          child: Text('Awaiting Verification',
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
                    Text('TYPE',
                        style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(item['type'].toString().toUpperCase(),
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
                    onPressed: () => _handleReject(item['id'], MainCategory.payments),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withOpacity(0.5)),
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
                        content: 'Confirm you have verified this UTR (${item['utr']}) matches a real received payment of ₹${item['amount']} in your bank/UPI records?',
                        onConfirm: () => _handleApprove(item['id'], MainCategory.payments),
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
                    child: const Text('✓ Confirm Payment'),
                  ),
                ],
              )
            ],
          )
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
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED LIST (HISTORY)',
        headerColor: _green,
        count: allAcceptedVehicles.length,
        countLabel: 'Item',
        countBadgeColor: _green.withOpacity(0.1),
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
        countBadgeColor: _red.withOpacity(0.1),
        countTextColor: _red,
        items: allRejectedVehicles,
        itemBuilder: _buildRejectedVehicleCard,
      );
    }
  }

  Widget _buildPendingVehicleCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      itemId: item['id'],
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item['imageUrl'],
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
                            item['title'],
                            style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(item['price'],
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
                        child: Text(item['tag'],
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 10)),
                      ),
                    const SizedBox(height: 4),
                    Text(
                        'Seller: ${item['sellerName']} • ${item['location']} (${item['stateCode']})',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 12)),
                    Text('Submitted ${item['timeAgo']}',
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
                    Text(item['type'],
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
                    Text('● ${item['rcStatus']}',
                        style: TextStyle(
                            color: item['rcStatus'] == 'Clear' ? _green : _orange,
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
                    Text(item['inspection'],
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
                    onPressed: () => _handleReject(item['id'], MainCategory.vehiclePosts),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✕ Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleApprove(item['id'], MainCategory.vehiclePosts),
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
    return _buildHistoryCard(
      icon: Icons.check_circle,
      iconColor: _green,
      title: '${item['title']} (${item['price']})',
      subtitle: 'Seller: ${item['sellerName']} • Ref: #${item['ref']}',
      statusLabel: 'Approved',
      statusColor: _green,
      time: item['time'],
      itemId: item['id'],
    );
  }

  Widget _buildRejectedVehicleCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.cancel,
      iconColor: _red,
      title: item['title'],
      subtitle: 'Seller: ${item['sellerName']} • ${item['reason']}',
      statusLabel: 'Declined',
      statusColor: _red,
      time: item['time'],
    );
  }

  // ==========================================
  // BIDDING
  // ==========================================
  Widget _buildBiddingContent() {
    final allPendingBids = LocalListingsStore().pendingBids;
    final allAcceptedBids = LocalListingsStore().acceptedBids;
    final allRejectedBids = LocalListingsStore().rejectedBids;

    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'INCOMING / PENDING BIDS',
        headerColor: _orange,
        count: allPendingBids.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: allPendingBids,
        itemBuilder: _buildPendingBidCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED BIDS HISTORY',
        headerColor: _green,
        count: allAcceptedBids.length,
        countLabel: 'Item',
        countBadgeColor: _green.withOpacity(0.1),
        countTextColor: _green,
        items: allAcceptedBids,
        itemBuilder: _buildAcceptedBidCard,
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED BIDS HISTORY',
        headerColor: _red,
        count: allRejectedBids.length,
        countLabel: 'Item',
        countBadgeColor: _red.withOpacity(0.1),
        countTextColor: _red,
        items: allRejectedBids,
        itemBuilder: _buildRejectedBidCard,
      );
    }
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
                      item['title'],
                      style: TextStyle(
                          color: _navy,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                        'Bidder: ${item['bidderName']} (@${item['bidderUsername']}) • Dealer ID: ${item['dealerId']}',
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
                  Text(item['bidAmount'],
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
                      side: BorderSide(color: _red.withOpacity(0.5)),
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
      title: item['title'],
      subtitle: 'Bidder: ${item['bidderName']} • Ref: #${item['ref']}',
      statusLabel: 'Accepted',
      statusColor: _green,
      time: item['time'],
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
        countBadgeColor: _green.withOpacity(0.1),
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
        countBadgeColor: _red.withOpacity(0.1),
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
                  Text(item['price'] ?? 'N/A',
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
                      side: BorderSide(color: _red.withOpacity(0.5)),
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
                        content: 'Confirm you have verified this UTR (${item['payRef']}) matches a real received payment of ${item['price']} in your bank/UPI records?',
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
          '${item['businessName'] ?? 'Unknown'} (${item['tier'] ?? 'Unknown'} - ${item['price'] ?? 'N/A'})',
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
              color: Colors.black.withOpacity(0.02),
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
