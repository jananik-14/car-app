import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_secondary_scaffold.dart';
import '../utils/local_listings_store.dart';
import '../utils/profile_storage_helper.dart';
import '../services/auth_service.dart';
import '../widgets/listing_image.dart';
import '../widgets/countdown_timer.dart';
import '../utils/currency_formatter.dart';
import '../router/app_router.dart';
import 'dart:math' as math;

class MyActivityScreen extends StatefulWidget {
  final String? initialTab;
  final String? initialFilter;

  const MyActivityScreen({
    super.key,
    this.initialTab,
    this.initialFilter,
  });

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  int _selectedTab = 0; // 0 = My Bids, 1 = My Listings
  String _bidsFilter = 'All'; // All, Active, Won, Lost
  String _listingsFilter = 'All'; // All, Pending, Live, Sold, Ended

  @override
  void initState() {
    super.initState();
    _applyInitialRouteState();
  }

  @override
  void didUpdateWidget(covariant MyActivityScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab ||
        oldWidget.initialFilter != widget.initialFilter) {
      _applyInitialRouteState();
    }
  }

  void _applyInitialRouteState() {
    final tab = widget.initialTab?.toLowerCase();
    final filter = widget.initialFilter?.toLowerCase();

    if (filter == 'sold') {
      _selectedTab = 1;
      _listingsFilter = 'Sold';
    } else if (filter == 'won') {
      _selectedTab = 0;
      _bidsFilter = 'Won';
    } else if (tab == 'listings' || tab == '1') {
      _selectedTab = 1;
    } else if (tab == 'bids' || tab == '0') {
      _selectedTab = 0;
    }

    if (filter != null && filter.isNotEmpty && filter != 'sold' && filter != 'won') {
      if (_selectedTab == 0) {
        if (filter == 'active') {
          _bidsFilter = 'Active';
        } else if (filter == 'lost') {
          _bidsFilter = 'Lost';
        } else if (filter == 'all') {
          _bidsFilter = 'All';
        }
      } else {
        if (filter == 'pending') {
          _listingsFilter = 'Pending';
        } else if (filter == 'live') {
          _listingsFilter = 'Live';
        } else if (filter == 'ended') {
          _listingsFilter = 'Ended';
        } else if (filter == 'all') {
          _listingsFilter = 'All';
        }
      }
    }
  }

  final Color _navy = const Color(0xFF001128);

  String _s(dynamic val, [String fallback = '']) =>
      val == null || val.toString().trim().isEmpty ? fallback : val.toString().trim();
  int _i(dynamic val) => int.tryParse(val?.toString() ?? '0') ?? 0;
  bool _b(dynamic v) => v == true || v == 1 || v == 'true';
  String _formatAmt(int amt) => '₹${CurrencyFormatter.formatCurrency(amt)}';

  @override
  Widget build(BuildContext context) {
    return ResponsiveSecondaryScaffold(
      currentIndex: 4, // Profile tab index
      fullWidth: true,
      child: ListenableBuilder(
        listenable: LocalListingsStore(),
        builder: (context, _) {
          final store = LocalListingsStore();
          final currentPhone = ProfileStorageHelper.normalizePhone(AuthService().currentPhone ?? '');

          // --- Process My Listings ---
          final allMyListings = [
            ...store.pendingListings,
            ...store.acceptedListings,
            ...store.rejectedListings
          ].where((l) {
            final p = ProfileStorageHelper.normalizePhone(_s(l['phone'] ?? l['sellerPhone']));
            return p == currentPhone;
          }).toList();

          final pending = allMyListings.where((l) => _s(l['status']) == 'pending').toList();
          final live = allMyListings.where((l) => _s(l['status']) == 'live').toList();
          final sold = allMyListings.where((l) => _s(l['status']) == 'sold').toList();
          final ended = allMyListings.where((l) => _s(l['status']) == 'ended' || _s(l['status']) == 'ended_no_bids').toList();

          List<Map<String, dynamic>> filteredListings = [];
          if (_listingsFilter == 'All') filteredListings = allMyListings;
          if (_listingsFilter == 'Pending') filteredListings = pending;
          if (_listingsFilter == 'Live') filteredListings = live;
          if (_listingsFilter == 'Sold') filteredListings = sold;
          if (_listingsFilter == 'Ended') filteredListings = ended;

          // --- Process My Bids ---
          final myAcceptedBids = store.acceptedBids.where((b) {
            final bp = ProfileStorageHelper.normalizePhone(_s(b['bidderPhone'] ?? b['bidderUsername']));
            return bp == currentPhone;
          }).toList();

          // Group by listing ID to get highest bid per listing
          final Map<String, int> myMaxBids = {};
          for (var b in myAcceptedBids) {
            final lid = _s(b['listingId'] ?? b['vehicleId']);
            final amt = _i(b['bidAmountNum']);
            if (lid.isNotEmpty) {
              myMaxBids[lid] = math.max(myMaxBids[lid] ?? 0, amt);
            }
          }

          final List<Map<String, dynamic>> allMyBidsItems = [];
          for (var lid in myMaxBids.keys) {
            // Find the listing
            final listing = store.acceptedListings.firstWhere((l) => _s(l['id']) == lid, orElse: () => <String, dynamic>{});
            if (listing.isNotEmpty) {
              allMyBidsItems.add({
                'listing': listing,
                'myBid': myMaxBids[lid] ?? 0,
              });
            }
          }

          // Helper to check payment status from listing or pendingPayments
          String getEffectivePaymentStatus(Map<String, dynamic> listing) {
            final lid = _s(listing['id']);
            for (var p in store.pendingPayments) {
              if (_s(p['id']) == lid) {
                return _s(p['status']);
              }
            }
            return _s(listing['paymentStatus']);
          }

          final activeBids = allMyBidsItems.where((item) {
            final l = item['listing'];
            final s = _s(l['status']).toLowerCase();
            final isEnded = s == 'ended' || s == 'ended_no_bids' || s == 'sold' || _b(l['endProcessed']);
            return s == 'live' && !isEnded;
          }).toList();

          final wonBids = allMyBidsItems.where((item) {
            final l = item['listing'];
            final s = _s(l['status']).toLowerCase();
            final winnerPhone = ProfileStorageHelper.normalizePhone(_s(l['winnerPhone']));
            final isEnded = s == 'ended' || s == 'ended_no_bids' || s == 'sold' || _b(l['endProcessed']);
            final payStatus = getEffectivePaymentStatus(l);
            final hasPayment = payStatus.isNotEmpty;

            // Winner if winnerPhone matches current user, or if payment exists for this user / won state
            final bool isWinner = winnerPhone.isNotEmpty && winnerPhone == currentPhone;
            final highest = _i(l['finalPrice'] ?? l['currentBid'] ?? l['price']);
            final bool isHighest = item['myBid'] >= highest && highest > 0;

            return isEnded && (isWinner || isHighest || hasPayment);
          }).toList();

          final lostBids = allMyBidsItems.where((item) {
            final l = item['listing'];
            final s = _s(l['status']).toLowerCase();
            final winnerPhone = ProfileStorageHelper.normalizePhone(_s(l['winnerPhone']));
            final isEnded = s == 'ended' || s == 'ended_no_bids' || s == 'sold' || _b(l['endProcessed']);
            final payStatus = getEffectivePaymentStatus(l);

            final bool isWinner = winnerPhone.isNotEmpty && winnerPhone == currentPhone;
            final highest = _i(l['finalPrice'] ?? l['currentBid'] ?? l['price']);
            final bool isHighest = item['myBid'] >= highest && highest > 0;

            return isEnded && !isWinner && !isHighest && payStatus.isEmpty;
          }).toList();

          List<Map<String, dynamic>> filteredBids = [];
          if (_bidsFilter == 'All') filteredBids = allMyBidsItems;
          if (_bidsFilter == 'Active') filteredBids = activeBids;
          if (_bidsFilter == 'Won') filteredBids = wonBids;
          if (_bidsFilter == 'Lost') filteredBids = lostBids;

          return Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildTabs(allMyBidsItems.length, allMyListings.length),
                const SizedBox(height: 12),
                if (_selectedTab == 0)
                  _buildFilterChips(
                    filters: ['All', 'Active', 'Won', 'Lost'],
                    selected: _bidsFilter,
                    counts: [allMyBidsItems.length, activeBids.length, wonBids.length, lostBids.length],
                    onSelect: (val) => setState(() => _bidsFilter = val),
                  )
                else
                  _buildFilterChips(
                    filters: ['All', 'Pending', 'Live', 'Sold', 'Ended'],
                    selected: _listingsFilter,
                    counts: [allMyListings.length, pending.length, live.length, sold.length, ended.length],
                    onSelect: (val) => setState(() => _listingsFilter = val),
                  ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.topLeft,
                  child: _selectedTab == 0
                      ? _buildBidsGrid(filteredBids)
                      : _buildListingsGrid(filteredListings),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 600;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          color: _navy,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/browse');
            }
          },
        ),
        const SizedBox(width: 8),
        Text(
          'My Activity',
          style: TextStyle(
            color: _navy,
            fontSize: isMobile ? 20 : 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTabs(int bidsCount, int listingsCount) {
    return Row(
      children: [
        _buildTabButton('My Bids', bidsCount, 0),
        const SizedBox(width: 12),
        _buildTabButton('My Listings', listingsCount, 1),
      ],
    );
  }

  Widget _buildTabButton(String title, int count, int index) {
    bool isSelected = _selectedTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
          _bidsFilter = 'All';
          _listingsFilter = 'All';
        });
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navy : Colors.white,
          border: Border.all(color: isSelected ? _navy : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips({
    required List<String> filters,
    required String selected,
    required List<int> counts,
    required Function(String) onSelect,
  }) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(filters.length, (index) {
          String f = filters[index];
          int c = counts[index];
          bool isSelected = selected == f;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text('$f ($c)'),
              selected: isSelected,
              onSelected: (_) => onSelect(f),
              selectedColor: _navy.withValues(alpha: 0.1),
              checkmarkColor: _navy,
              labelStyle: TextStyle(
                color: isSelected ? _navy : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isSelected ? _navy : Colors.grey.shade300,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBidsGrid(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      String msg = 'No bids yet';
      if (_bidsFilter == 'Active') msg = 'No active bids';
      if (_bidsFilter == 'Won') msg = 'No won auctions yet';
      if (_bidsFilter == 'Lost') msg = 'No lost auctions';
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 380, // Approximate height for bids card
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildBidCard(items[index]);
      },
    );
  }

  Widget _buildListingsGrid(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      String msg = 'No listings yet';
      if (_listingsFilter == 'Pending') msg = 'No pending listings';
      if (_listingsFilter == 'Live') msg = 'No live listings';
      if (_listingsFilter == 'Sold') msg = 'No sold listings';
      if (_listingsFilter == 'Ended') msg = 'No ended listings';
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(msg, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 400,
        mainAxisExtent: 380, // Approximate height for listings card
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildListingCard(items[index]);
      },
    );
  }

  Widget _buildBidCard(Map<String, dynamic> item) {
    final listing = item['listing'];
    final myBid = item['myBid'];
    final lid = _s(listing['id']);
    final status = _s(listing['status']).toLowerCase();
    final highestBid = _i(listing['finalPrice'] ?? listing['currentBid'] ?? listing['price']);
    
    // Read payment state from existing payment store keyed by listing id
    final store = LocalListingsStore();
    String paymentStatus = _s(listing['paymentStatus']);
    for (var p in store.pendingPayments) {
      if (_s(p['id']) == lid) {
        paymentStatus = _s(p['status']);
        break;
      }
    }

    final currentPhone = ProfileStorageHelper.normalizePhone(AuthService().currentPhone ?? '');
    final winnerPhone = ProfileStorageHelper.normalizePhone(_s(listing['winnerPhone']));
    final endTime = _s(listing['endTime']);
    final title = _s(listing['title'], 'Untitled vehicle');
    final loc = _s(listing['location'] ?? listing['locationDisplay'], 'Location not provided');

    String semanticStatus = 'UNKNOWN';
    Color statusColor = Colors.grey;

    bool isClosed = status == 'ended' || status == 'ended_no_bids' || status == 'sold' || _b(listing['endProcessed']);
    bool isLive = status == 'live' && !isClosed;
    bool isHighest = myBid >= highestBid && highestBid > 0;
    bool isWinner = (winnerPhone.isNotEmpty && winnerPhone == currentPhone) || (isClosed && isHighest) || (isClosed && paymentStatus.isNotEmpty);

    if (isLive) {
      semanticStatus = isHighest ? 'WINNING' : 'OUTBID';
      statusColor = isHighest ? Colors.green : Colors.red;
    } else if (isClosed) {
      if (isWinner) {
        semanticStatus = 'WON';
        statusColor = Colors.orange;
      } else {
        semanticStatus = 'LOST';
        statusColor = Colors.grey;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: ListingImage(
                  listing: listing,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    semanticStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (isLive && endTime.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CountdownTimer(
                      endTime: DateTime.tryParse(endTime) ?? DateTime.now(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              if (isClosed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Auction Ended', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Bid', style: TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(_formatAmt(myBid), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(isClosed ? 'Final Price' : 'Highest Bid', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text(_formatAmt(highestBid), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (semanticStatus == 'WON')
                  _buildPaymentAction(listing, paymentStatus)
                else if (semanticStatus == 'LOST')
                  // Lost -> no button, show final price (already displayed above)
                  const SizedBox(height: 36)
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: _navy),
                      onPressed: () => openVehicleDetail(context, lid),
                      child: const Text('View Vehicle', style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentAction(Map<String, dynamic> listing, String paymentStatus) {
    final s = paymentStatus.toUpperCase().trim();
    if (s.isEmpty || s == 'PAYMENT PENDING') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _openPayment(listing, step: 'token'),
          child: const Text('Pay Token', style: TextStyle(color: Colors.white)),
        ),
      );
    } else if (s == 'TOKEN CONFIRMED') {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          onPressed: () => _openPayment(listing, step: 'balance'),
          child: const Text('Pay Balance', style: TextStyle(color: Colors.white)),
        ),
      );
    } else if (s == 'PAID') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.green.shade300),
        ),
        alignment: Alignment.center,
        child: const Text(
          'PAID',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    } else {
      // Handles TOKEN PENDING VERIFICATION, BALANCE PENDING VERIFICATION, etc.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          paymentStatus,
          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      );
    }
  }

  void _openPayment(Map<String, dynamic> listing, {String step = 'token'}) {
    context.push(
      '/payment',
      extra: {
        'id': _s(listing['id']),
        'title': _s(listing['title'], 'Untitled vehicle'),
        'amount': _i(listing['finalPrice'] ?? listing['currentBid'] ?? listing['price']),
        'seller': _s(listing['sellerPhone'] ?? listing['phone']),
        'initialStep': step,
      },
    );
  }

  Widget _buildListingCard(Map<String, dynamic> item) {
    final status = _s(item['status']);
    final title = _s(item['title'], 'Untitled vehicle');
    final loc = _s(item['location'] ?? item['locationDisplay'], 'Location not provided');
    final highestBid = _i(item['currentBid']);
    final price = _i(item['price']);
    final bidsPlaced = _i(item['bidsPlaced']);
    final endTime = _s(item['endTime']);

    String semanticStatus = 'UNKNOWN';
    Color statusColor = Colors.grey;
    if (status == 'pending') {
      semanticStatus = 'PENDING APPROVAL';
      statusColor = Colors.orange;
    } else if (status == 'live') {
      semanticStatus = 'LIVE';
      statusColor = Colors.green;
    } else if (status == 'sold') {
      semanticStatus = 'SOLD';
      statusColor = _navy;
    } else if (status == 'ended' || status == 'ended_no_bids') {
      semanticStatus = 'ENDED';
      statusColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: ListingImage(
                  listing: item,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    semanticStatus,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (status == 'live' && endTime.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CountdownTimer(
                      endTime: DateTime.tryParse(endTime) ?? DateTime.now(),
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(child: Text(loc, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 16),
                if (status == 'pending')
                  const Text('Awaiting approval', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                else if (status == 'sold')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Final Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(_formatAmt(_i(item['finalPrice'] ?? (highestBid > 0 ? highestBid : price))), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  )
                else if (status == 'ended' || status == 'ended_no_bids')
                  bidsPlaced == 0
                      ? const Text('Ended - no bids', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Final Price', style: TextStyle(color: Colors.grey, fontSize: 12)),
                            Text(_formatAmt(_i(item['finalPrice'] ?? (highestBid > 0 ? highestBid : price))), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Highest Bid', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      Text(highestBid > 0 ? _formatAmt(highestBid) : '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'pending' ? Colors.white : _navy,
                      foregroundColor: status == 'pending' ? _navy : Colors.white,
                      side: status == 'pending' ? BorderSide(color: _navy) : null,
                    ),
                    onPressed: () {
                      if (status == 'pending') {
                        context.push('/post_vehicle', extra: {'listingId': _s(item['id'])});
                      } else {
                        context.push('/listing-pdf/${_s(item['id'])}');
                      }
                    },
                    child: Text(status == 'pending' ? 'Edit Listing' : 'View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
