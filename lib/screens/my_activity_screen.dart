import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_secondary_scaffold.dart';
import '../utils/local_listings_store.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  @override
  void initState() {
    super.initState();
    LocalListingsStore().addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    LocalListingsStore().removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    setState(() {});
  }

  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  int _selectedTabIndex = 0;

  final List<Map<String, dynamic>> _myBids = [
    {
      'id': 'b1',
      'title': '2021 Hyundai Creta SX',
      'image': 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?auto=format&fit=crop&w=400&q=80',
      'user_bid': '14,20,000',
      'highest_bid': '14,50,000',
      'status': 'Outbid',
      'end_time': '02h 15m',
      'city': 'Chennai',
    },
    {
      'id': 'b2',
      'title': '2019 Maruti Suzuki Swift ZXi',
      'image': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=400&q=80',
      'user_bid': '5,40,000',
      'highest_bid': '5,40,000',
      'status': 'Won',
      'end_time': 'Ended',
      'city': 'Delhi',
    },
    {
      'id': 'b3',
      'title': '2018 Honda City V MT',
      'image': 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?auto=format&fit=crop&w=400&q=80',
      'user_bid': '7,10,000',
      'highest_bid': '7,50,000',
      'status': 'Lost',
      'end_time': 'Ended',
      'city': 'Pune',
    },
  ];

  final List<Map<String, dynamic>> _myListings = [
    {
      'id': 'l1',
      'title': '2020 Kia Seltos GTX+',
      'image': 'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b',
      'highest_bid': '15,00,000',
      'status': 'Live',
      'city': 'Mumbai',
    },
    {
      'id': 'l2',
      'title': '2022 Mahindra Thar LX',
      'image': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf',
      'highest_bid': '-',
      'status': 'Pending Approval',
      'city': 'Bangalore',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveSecondaryScaffold(
      currentIndex: 4,
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildTabRow(),
            _buildListContent(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: navyBlue),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', height: 24, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Wheels2Drive',
                style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Text(
                'My Activity',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabRow() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(child: _buildTab('My Bids', _myBids.length.toString(), 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab('My Listings', _myListings.length.toString(), 1)),
        ],
      ),
    );
  }

  Widget _buildTab(String title, String count, int tabIndex) {
    bool isSelected = _selectedTabIndex == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = tabIndex;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? navyBlue : Colors.transparent,
          border: Border.all(color: isSelected ? navyBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? orange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListContent() {
    List<Widget> items = [];
    if (_selectedTabIndex == 0) {
      for (var bid in _myBids) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildBidCard(bid),
        ));
      }
    } else {
      for (var listing in _myListings) {
        items.add(Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildListingCard(listing),
        ));
      }
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: items,
    );
  }

  Widget _buildBidCard(Map<String, dynamic> bid) {
    String currentStatus = bid['status'];
    for (var p in LocalListingsStore().pendingPayments) {
      if (p['id'] == bid['id']) {
        currentStatus = p['status'];
      }
    }

    Color statusColor;
    switch (currentStatus) {
      case 'TOKEN PENDING VERIFICATION':
      case 'BALANCE PENDING VERIFICATION':
        statusColor = Colors.orange;
        break;
      case 'TOKEN CONFIRMED':
        statusColor = Colors.blue;
        break;
      case 'PAID':
        statusColor = Colors.green;
        break;
      case 'Winning':
        statusColor = Colors.green;
        break;
      case 'Won':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'PAYMENT PENDING':
        statusColor = Colors.blue;
        break;
      case 'Outbid':
      case 'Lost':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CustomNetworkImage(
                  imageUrl: bid['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (bid['status'] == 'Won') ...[
                        const Icon(Icons.emoji_events, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        bid['status'].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(16)),
                  child: Text(
                    currentStatus == 'Won' || currentStatus == 'PAYMENT PENDING' || currentStatus == 'TOKEN PENDING VERIFICATION' || currentStatus == 'TOKEN CONFIRMED' || currentStatus == 'BALANCE PENDING VERIFICATION' || currentStatus == 'PAID' ? 'Auction Ended' : (bid['end_time'] == 'Ended' ? 'Ended' : 'Ends in ${bid['end_time']}'),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bid['title'],
                  style: TextStyle(color: navyBlue, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      bid['city'] ?? 'Unknown Location',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Bid', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₹${bid['user_bid']}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Highest Bid', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('₹${bid['highest_bid']}', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
                if (currentStatus == 'Won' || currentStatus == 'PAYMENT PENDING' || currentStatus == 'TOKEN PENDING VERIFICATION' || currentStatus == 'TOKEN CONFIRMED' || currentStatus == 'BALANCE PENDING VERIFICATION' || currentStatus == 'PAID') ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (currentStatus == 'PAYMENT PENDING' || currentStatus == 'TOKEN PENDING VERIFICATION' || currentStatus == 'BALANCE PENDING VERIFICATION' || currentStatus == 'PAID') ? null : () async {
                        final amountStr = bid['user_bid'].toString().replaceAll(',', '');
                        final int amount = int.tryParse(amountStr) ?? 0;
                        
                        String initialStep = 'token';
                        if (currentStatus == 'TOKEN CONFIRMED') initialStep = 'balance';

                        final result = await context.push(
                          '/payment',
                          extra: {
                            'id': bid['id'],
                            'title': bid['title'],
                            'image': bid['image'],
                            'amount': amount,
                            'seller': bid['seller'] ?? 'Verified Seller',
                            'initialStep': initialStep,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (currentStatus == 'PAYMENT PENDING' || currentStatus == 'TOKEN PENDING VERIFICATION' || currentStatus == 'BALANCE PENDING VERIFICATION' || currentStatus == 'PAID') ? Colors.grey : orange,
                        disabledBackgroundColor: Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        currentStatus == 'TOKEN PENDING VERIFICATION' ? 'Token Verification Pending' :
                        currentStatus == 'BALANCE PENDING VERIFICATION' ? 'Balance Verification Pending' :
                        currentStatus == 'PAID' ? 'Payment Complete' : 
                        currentStatus == 'TOKEN CONFIRMED' ? 'Pay Balance' : 'Pay Token', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    Color statusColor;
    switch (listing['status']) {
      case 'Live':
        statusColor = Colors.green;
        break;
      case 'Pending Approval':
        statusColor = orange;
        break;
      case 'Sold':
        statusColor = navyBlue;
        break;
      case 'Rejected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: CustomNetworkImage(
                  imageUrl: listing['image'],
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    listing['status'].toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing['title'],
                  style: TextStyle(color: navyBlue, fontSize: 16, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      listing['city'] ?? 'Unknown Location',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Highest Bid', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          listing['highest_bid'] == '-' ? '-' : '₹${listing['highest_bid']}',
                          style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.push('/vehicle_detail/${listing['id']}', extra: {
                            'vehicleData': {
                              'id': listing['id'],
                              'title': listing['title'],
                              'image': listing['image'],
                              'year': listing['title'].split(' ')[0],
                              'name': listing['title'].substring(listing['title'].indexOf(' ') + 1),
                              'currentBid': listing['highest_bid'] == '-' ? '0' : listing['highest_bid'],
                              'location': 'Local',
                              'bidsPlaced': listing['highest_bid'] == '-' ? '0' : '1',
                              'specs': '${listing['title'].split(' ')[0]} • Petrol',
                              'bid': listing['highest_bid'],
                              'bids_placed': listing['highest_bid'] == '-' ? '0' : '1',
                              'time_left': 'N/A'
                            },
                            'isOwner': true,
                            'isPending': listing['status'] == 'Pending Approval',
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: navyBlue,
                          side: BorderSide(color: navyBlue),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    if (listing['status'] == 'Pending Approval' || listing['status'] == 'Rejected') ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final result = await context.push('/post_vehicle', extra: {
                              'isEditMode': true,
                              'initialData': listing,
                            });
                            if (result == true) {
                              setState(() {
                                listing['title'] = listing['title'] + ' (Updated)';
                              });
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: navyBlue,
                            side: BorderSide(color: navyBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Edit Listing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
