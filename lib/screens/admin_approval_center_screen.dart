// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides admin approval endpoints:
// GET /api/admin/vehicle-posts?status=pending|accepted|rejected
// GET /api/admin/bids?status=pending|accepted|rejected
// GET /api/admin/subscriptions?status=pending|accepted|rejected
// PATCH /api/admin/vehicle-posts/:id (publish/reject)
// PATCH /api/admin/bids/:id (accept/reject)
// PATCH /api/admin/subscriptions/:id (approve/reject)

import 'package:flutter/material.dart';
import '../widgets/admin_navigation_drawer.dart';

enum MainCategory { vehiclePosts, bidding, subscriptions }
enum SubState { pending, accepted, rejected }

class AdminApprovalCenterScreen extends StatefulWidget {
  const AdminApprovalCenterScreen({super.key});

  @override
  State<AdminApprovalCenterScreen> createState() => _AdminApprovalCenterScreenState();
}

class _AdminApprovalCenterScreenState extends State<AdminApprovalCenterScreen> {
  MainCategory _selectedCategory = MainCategory.vehiclePosts;
  SubState _selectedSubState = SubState.pending;

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF22C55E);
  final Color _red = const Color(0xFFEF4444);

  // --- Dummy Data ---
  List<Map<String, dynamic>> pendingVehicles = [
    {
      'id': 'v1',
      'title': '2023 Tesla Model Y',
      'price': '₹55.0 L',
      'tag': 'Long Range',
      'sellerName': 'Ravi Sharma',
      'location': 'Mumbai',
      'stateCode': 'MH-01',
      'timeAgo': '2 hours ago',
      'type': 'Verified Seller',
      'rcStatus': 'Clear',
      'inspection': '4.9 / 5.0',
      'imageUrl': 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'v2',
      'title': '2022 BMW 530i M-Sport',
      'price': '₹48.5 L',
      'tag': null,
      'sellerName': 'Amit Kumar',
      'location': 'Delhi',
      'stateCode': 'DL-01',
      'timeAgo': '5 hours ago',
      'type': 'Dealer',
      'rcStatus': 'Pending',
      'inspection': '4.5 / 5.0',
      'imageUrl': 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': 'v3',
      'title': '2021 Mahindra Thar 4x4',
      'price': '₹15.2 L',
      'tag': 'Diesel MT',
      'sellerName': 'Rahul Verma',
      'location': 'Pune',
      'stateCode': 'MH-12',
      'timeAgo': '1 day ago',
      'type': 'Private',
      'rcStatus': 'Clear',
      'inspection': '4.2 / 5.0',
      'imageUrl': 'https://images.unsplash.com/photo-1620025792945-31ce1d94fc8b?auto=format&fit=crop&w=300&q=80',
    },
  ];

  List<Map<String, dynamic>> acceptedVehicles = [
    {
      'id': 'v4',
      'title': '2021 Hyundai Creta SX(O)',
      'price': '₹16.5 L',
      'sellerName': 'Priya Singh',
      'ref': 'V-9982',
      'time': 'Approved 2 days ago',
    },
  ];

  List<Map<String, dynamic>> rejectedVehicles = [
    {
      'id': 'v5',
      'title': '2019 Maruti Swift ZDi',
      'sellerName': 'Karan Mehta',
      'reason': 'Blurry RC scan',
      'time': 'Declined 3 days ago',
    },
  ];

  List<Map<String, dynamic>> pendingBids = [
    {
      'id': 'b1',
      'auctionId': 'A-108',
      'title': '2022 BMW 5 Series 530i',
      'bidAmount': '₹48,50,000',
      'timeAgo': 'Just now',
      'bidderName': 'Vikram Rathore',
      'bidderUsername': 'vikram_r',
      'dealerId': 'D-4091',
      'depositPaid': true,
      'depositAmount': '₹50,000',
      'escrow': 'Secured',
      'score': '4.8 / 5.0',
    },
    {
      'id': 'b2',
      'auctionId': 'A-112',
      'title': '2023 Ford Bronco Wildtrak',
      'bidAmount': '₹62,00,000',
      'timeAgo': '15 mins ago',
      'bidderName': 'Sneha Patel',
      'bidderUsername': 'sneha_p',
      'dealerId': 'D-3082',
      'depositPaid': true,
      'depositAmount': '₹1,00,000',
      'escrow': 'Secured',
      'score': '4.9 / 5.0',
    },
  ];

  List<Map<String, dynamic>> acceptedBids = [
    {
      'id': 'b3',
      'title': '2020 Audi A4 Technology',
      'price': '₹32.5 L',
      'bidderName': 'Rohan Shah',
      'ref': 'BID-1004',
      'time': 'Accepted yesterday',
    },
  ];

  List<Map<String, dynamic>> rejectedBids = [
    {
      'id': 'b4',
      'title': '2021 Jeep Compass Limited',
      'price': '₹21.0 L',
      'bidderName': 'Ankit Rao',
      'reason': 'Under-deposit',
      'time': 'Declined 2 days ago',
    },
  ];

  List<Map<String, dynamic>> pendingSubscriptions = [
    {
      'id': 's1',
      'businessName': 'Apex Motors Ltd',
      'tier': 'Pro Trader',
      'tierColor': Colors.purple,
      'id1Label': 'GSTIN',
      'id1Value': '27AADCA1234F1Z5',
      'id2Label': 'User ID',
      'id2Value': 'U-8821',
      'timeAgo': '45 mins ago',
      'price': '₹1,999/mo',
      'payRef': 'UPI-90823412',
      'paymentStatus': 'Verified',
      'gstStatus': 'Active',
    },
    {
      'id': 's2',
      'businessName': 'Kavita Autolink',
      'tier': 'Elite Dealer',
      'tierColor': Colors.blue,
      'id1Label': 'Business ID',
      'id1Value': 'B-9923',
      'id2Label': 'Dealer ID',
      'id2Value': 'D-2211',
      'timeAgo': '2 hours ago',
      'price': '₹4,999/mo',
      'payRef': 'NEFT-883921',
      'paymentStatus': 'Cleared',
      'gstStatus': 'Pending', // using KYC DOCS field for variety
      'kycDocs': 'Attached',
    },
  ];

  List<Map<String, dynamic>> acceptedSubscriptions = [
    {
      'id': 's3',
      'businessName': 'Metro Car Hub',
      'tier': 'Starter Dealer',
      'price': '₹999/mo',
      'id1Label': 'GSTIN',
      'id1Value': '27BBVCA9988C1Z2',
      'ref': 'SUB-1992',
      'time': 'Approved yesterday',
    },
  ];

  List<Map<String, dynamic>> rejectedSubscriptions = [
    {
      'id': 's4',
      'businessName': 'Royal Wheels Agency',
      'tier': 'Pro Trader',
      'dealerName': 'Rajiv Khanna',
      'reason': 'Invalid GSTIN',
      'time': 'Declined 2 days ago',
    },
  ];

  int get totalPendingCount => pendingVehicles.length + pendingBids.length + pendingSubscriptions.length;

  void _showDocumentViewerPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Document viewer coming soon')),
    );
  }

  void _handleApprove(String id, MainCategory category) {
    setState(() {
      if (category == MainCategory.vehiclePosts) {
        final item = pendingVehicles.firstWhere((e) => e['id'] == id);
        pendingVehicles.remove(item);
        acceptedVehicles.insert(0, {
          'id': item['id'],
          'title': item['title'],
          'price': item['price'],
          'sellerName': item['sellerName'],
          'ref': 'V-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'time': 'Approved just now',
        });
      } else if (category == MainCategory.bidding) {
        final item = pendingBids.firstWhere((e) => e['id'] == id);
        pendingBids.remove(item);
        acceptedBids.insert(0, {
          'id': item['id'],
          'title': item['title'],
          'price': item['bidAmount'], // approximation
          'bidderName': item['bidderName'],
          'ref': 'BID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'time': 'Accepted just now',
        });
      } else if (category == MainCategory.subscriptions) {
        final item = pendingSubscriptions.firstWhere((e) => e['id'] == id);
        pendingSubscriptions.remove(item);
        acceptedSubscriptions.insert(0, {
          'id': item['id'],
          'businessName': item['businessName'],
          'tier': item['tier'],
          'price': item['price'],
          'id1Label': item['id1Label'],
          'id1Value': item['id1Value'],
          'ref': 'SUB-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          'time': 'Approved just now',
        });
      }
    });

    String msg = category == MainCategory.vehiclePosts
        ? "Vehicle published successfully"
        : category == MainCategory.bidding
            ? "Bid accepted"
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _processRejection(id, category, reasonController.text.isEmpty ? 'Admin rejected' : reasonController.text);
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
        final item = pendingVehicles.firstWhere((e) => e['id'] == id);
        pendingVehicles.remove(item);
        rejectedVehicles.insert(0, {
          'id': item['id'],
          'title': item['title'],
          'sellerName': item['sellerName'],
          'reason': reason,
          'time': 'Declined just now',
        });
      } else if (category == MainCategory.bidding) {
        final item = pendingBids.firstWhere((e) => e['id'] == id);
        pendingBids.remove(item);
        rejectedBids.insert(0, {
          'id': item['id'],
          'title': item['title'],
          'price': item['bidAmount'],
          'bidderName': item['bidderName'],
          'reason': reason,
          'time': 'Declined just now',
        });
      } else if (category == MainCategory.subscriptions) {
        final item = pendingSubscriptions.firstWhere((e) => e['id'] == id);
        pendingSubscriptions.remove(item);
        rejectedSubscriptions.insert(0, {
          'id': item['id'],
          'businessName': item['businessName'],
          'tier': item['tier'],
          'dealerName': 'Dealer',
          'reason': reason,
          'time': 'Declined just now',
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHeaderSection(),
          _buildMainCategoryTabs(),
          _buildSubStateTabs(),
          Expanded(child: _buildContentArea()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu, color: _navy),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.asset(
              'assets/images/logo.png',
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (_,__,___) => Icon(Icons.directions_car, color: _navy, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wheels2Drive',
                style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'APPROVAL HUB',
                style: TextStyle(color: _orange, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.search, color: _navy),
          onPressed: () {},
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: _navy,
            child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
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
                style: TextStyle(color: _navy, fontSize: 20, fontWeight: FontWeight.bold),
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
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMainCategoryTab(MainCategory.vehiclePosts, Icons.directions_car, 'Vehicle Posts', pendingVehicles.length),
            const SizedBox(width: 12),
            _buildMainCategoryTab(MainCategory.bidding, Icons.gavel, 'Bidding', pendingBids.length),
            const SizedBox(width: 12),
            _buildMainCategoryTab(MainCategory.subscriptions, Icons.subscriptions, 'Subscriptions', pendingSubscriptions.length),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCategoryTab(MainCategory category, IconData icon, String label, int count) {
    bool isActive = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedCategory = category;
        _selectedSubState = SubState.pending; // Reset to pending when switching category
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
          Row(
            children: [
              Icon(Icons.sync, color: Colors.grey.shade500, size: 14),
              const SizedBox(width: 4),
              Text('Live sync', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
            ],
          )
        ],
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
          border: Border(bottom: BorderSide(color: isActive ? activeColor : Colors.transparent, width: 2)),
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
    if (_selectedCategory == MainCategory.vehiclePosts) return _buildVehiclePostsContent();
    if (_selectedCategory == MainCategory.bidding) return _buildBiddingContent();
    if (_selectedCategory == MainCategory.subscriptions) return _buildSubscriptionsContent();
    return const SizedBox();
  }

  // ==========================================
  // VEHICLE POSTS
  // ==========================================
  Widget _buildVehiclePostsContent() {
    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'PENDING REQUESTS',
        headerColor: _orange,
        count: pendingVehicles.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: pendingVehicles,
        itemBuilder: _buildPendingVehicleCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED LIST (HISTORY)',
        headerColor: _green,
        count: acceptedVehicles.length,
        countLabel: 'Item',
        countBadgeColor: _green.withOpacity(0.1),
        countTextColor: _green,
        items: acceptedVehicles,
        itemBuilder: _buildAcceptedVehicleCard,
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED LIST (HISTORY)',
        headerColor: _red,
        count: rejectedVehicles.length,
        countLabel: 'Item',
        countBadgeColor: _red.withOpacity(0.1),
        countTextColor: _red,
        items: rejectedVehicles,
        itemBuilder: _buildRejectedVehicleCard,
      );
    }
  }

  Widget _buildPendingVehicleCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item['imageUrl'], width: 80, height: 80, fit: BoxFit.cover,
                  errorBuilder: (_,__,___) => Container(width: 80, height: 80, color: Colors.grey.shade300, child: const Icon(Icons.car_crash)),
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
                          child: Text(item['title'], style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                        Text(item['price'], style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    if (item['tag'] != null)
                      Container(
                        margin: const EdgeInsets.only(top: 4, bottom: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        child: Text(item['tag'], style: TextStyle(color: Colors.grey.shade700, fontSize: 10)),
                      ),
                    const SizedBox(height: 4),
                    Text('Seller: ${item['sellerName']} • ${item['location']} (${item['stateCode']})', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    Text('Submitted ${item['timeAgo']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('LISTING TYPE', item['type']),
              _buildInfoColumn('RC STATUS', '● ${item['rcStatus']}', valueColor: item['rcStatus'] == 'Clear' ? _green : _orange),
              _buildInfoColumn('INSPECTION', item['inspection']),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: _showDocumentViewerPlaceholder,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text('View Documents', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(item['id'], MainCategory.vehiclePosts),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'INCOMING / PENDING BIDS',
        headerColor: _orange,
        count: pendingBids.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: pendingBids,
        itemBuilder: _buildPendingBidCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED BIDS HISTORY',
        headerColor: _green,
        count: acceptedBids.length,
        countLabel: 'Item',
        countBadgeColor: _green.withOpacity(0.1),
        countTextColor: _green,
        items: acceptedBids,
        itemBuilder: _buildAcceptedBidCard,
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED BIDS HISTORY',
        headerColor: _red,
        count: rejectedBids.length,
        countLabel: 'Item',
        countBadgeColor: _red.withOpacity(0.1),
        countTextColor: _red,
        items: rejectedBids,
        itemBuilder: _buildRejectedBidCard,
      );
    }
  }

  Widget _buildPendingBidCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(12)),
                child: Text('AUCTION #${item['auctionId']}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              Text(item['timeAgo'], style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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
                    Text(item['title'], style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Bidder: ${item['bidderName']} (@${item['bidderUsername']}) • Dealer ID: ${item['dealerId']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('SUBMITTED BID', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(item['bidAmount'], style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('TOKEN DEPOSIT', '✓ ${item['depositAmount']} Paid', valueColor: _green),
              _buildInfoColumn('ESCROW HOLD', item['escrow']),
              _buildInfoColumn('DEALER SCORE', item['score']),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: _showDocumentViewerPlaceholder,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text('View Audit Trail', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(item['id'], MainCategory.bidding),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    if (_selectedSubState == SubState.pending) {
      return _buildListScaffold(
        headerText: 'INCOMING/PENDING SUBSCRIPTIONS',
        headerColor: _orange,
        count: pendingSubscriptions.length,
        countLabel: 'to review',
        countBadgeColor: Colors.grey.shade200,
        countTextColor: Colors.grey.shade800,
        items: pendingSubscriptions,
        itemBuilder: _buildPendingSubscriptionCard,
      );
    } else if (_selectedSubState == SubState.accepted) {
      return _buildListScaffold(
        headerText: 'ACCEPTED SUBSCRIPTIONS HISTORY',
        headerColor: _green,
        count: acceptedSubscriptions.length,
        countLabel: 'Item',
        countBadgeColor: _green.withOpacity(0.1),
        countTextColor: _green,
        items: acceptedSubscriptions,
        itemBuilder: _buildAcceptedSubscriptionCard,
      );
    } else {
      return _buildListScaffold(
        headerText: 'REJECTED SUBSCRIPTIONS HISTORY',
        headerColor: _red,
        count: rejectedSubscriptions.length,
        countLabel: 'Item',
        countBadgeColor: _red.withOpacity(0.1),
        countTextColor: _red,
        items: rejectedSubscriptions,
        itemBuilder: _buildRejectedSubscriptionCard,
      );
    }
  }

  Widget _buildPendingSubscriptionCard(Map<String, dynamic> item) {
    return _buildCardWrapper(
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _navy, shape: BoxShape.circle),
                child: Icon(item['tier'] == 'Elite Dealer' ? Icons.stars : Icons.workspace_premium, color: const Color(0xFFFFD700), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(item['businessName'], style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: item['tierColor'] ?? Colors.blue, borderRadius: BorderRadius.circular(12)),
                          child: Text(item['tier'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: [
                        Text('${item['id1Label']}: ${item['id1Value']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        Text('•', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                        Text('${item['id2Label']}: ${item['id2Value']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                      ],
                    ),
                    Text('Submitted ${item['timeAgo']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('PLAN TIER', style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(item['price'], style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
                ],
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildInfoColumn('PAYMENT REF', item['payRef']),
              _buildInfoColumn('PAYMENT', '✓ ${item['paymentStatus']}', valueColor: _green),
              if (item.containsKey('gstStatus'))
                _buildInfoColumn('GST STATUS', item['gstStatus'])
              else
                _buildInfoColumn('KYC DOCS', item['kycDocs']),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 8,
            children: [
              GestureDetector(
                onTap: _showDocumentViewerPlaceholder,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility, color: Colors.blue, size: 16),
                    SizedBox(width: 4),
                    Text('View Documents', style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline, fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _handleReject(item['id'], MainCategory.subscriptions),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _red,
                      side: BorderSide(color: _red.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    child: const Text('✕ Reject'),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleApprove(item['id'], MainCategory.subscriptions),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
      title: '${item['businessName']} (${item['tier']} - ${item['price']})',
      subtitle: '${item['id1Label']}: ${item['id1Value']} • Ref: #${item['ref']}',
      statusLabel: 'Approved',
      statusColor: _green,
      time: item['time'],
    );
  }

  Widget _buildRejectedSubscriptionCard(Map<String, dynamic> item) {
    return _buildHistoryCard(
      icon: Icons.cancel,
      iconColor: _red,
      title: '${item['businessName']} (${item['tier']})',
      subtitle: 'Dealer: ${item['dealerName']} • ${item['reason']}',
      statusLabel: 'Declined',
      statusColor: _red,
      time: item['time'],
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, color: headerColor, size: 10),
                  const SizedBox(width: 8),
                  Text(headerText, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: countBadgeColor, borderRadius: BorderRadius.circular(12)),
                child: Text('$count $countLabel', style: TextStyle(color: countTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Text('No items found.', style: TextStyle(color: Colors.grey.shade500)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (ctx, idx) => itemBuilder(items[idx]),
                ),
        )
      ],
    );
  }

  Widget _buildCardWrapper({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
  }) {
    return _buildCardWrapper(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(statusLabel, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
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
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: valueColor ?? _navy, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
