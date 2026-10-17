import 'dart:async';
import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import '../config/subscription_plans.dart';
import '../services/admin_clients_store.dart';
import '../services/client_notification_store.dart';
import '../utils/local_listings_store.dart';
import '../utils/profile_storage_helper.dart';
import '../utils/web_download_helper.dart' if (dart.library.html) '../utils/web_download_helper_web.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/listing_image.dart';
import '../widgets/responsive_nav_scaffold.dart';

enum LotStatus { live, sold, endedNoBids, cancelled }

class LotStatusInfo {
  final LotStatus status;
  final String label;
  final Color color;
  final Color bg;

  const LotStatusInfo({
    required this.status,
    required this.label,
    required this.color,
    required this.bg,
  });
}

enum BidResultType { leading, outbid, won, lost, cancelled }

class _BidderSummary {
  final String name;
  final String phone;
  final int totalBids;
  final int lotsWon;
  final int totalWonValue;
  final String planName;
  final String planExpiry;
  final DateTime? planExpiryDate;
  final bool hasActivePlan;

  _BidderSummary({
    required this.name,
    required this.phone,
    required this.totalBids,
    required this.lotsWon,
    required this.totalWonValue,
    required this.planName,
    required this.planExpiry,
    this.planExpiryDate,
    required this.hasActivePlan,
  });
}

class AdminBiddingScreen extends StatefulWidget {
  const AdminBiddingScreen({super.key});

  @override
  State<AdminBiddingScreen> createState() => _AdminBiddingScreenState();
}

class _AdminBiddingScreenState extends State<AdminBiddingScreen> {
  int _activeTabIndex = 0; // 0 = Lots, 1 = Bid Ledger, 2 = Bidders

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF16A34A);
  final Color _red = const Color(0xFFEF4444);
  final Color _grey = const Color(0xFF6B7280);

  // Search, filter, sort state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _lotsFilter = 'All'; // All, Live, Ended, Sold
  String _ledgerFilter = 'All'; // All, Leading, Outbid, Won, Lost
  String _lotsSort = 'Newest'; // Newest, Highest Bid, Most Bids
  String _ledgerSort = 'Newest'; // Newest, Highest Bid
  String _biddersSort = 'Most Bids'; // Most Bids, Highest Won Value, Most Won
  DateTimeRange? _selectedDateRange;

  Timer? _countdownTimer;
  Map<String, Map<String, String>> _bidderSubscriptions = {};

  // Null-safe helpers
  String _s(dynamic v, [String fallback = '']) =>
      v != null ? v.toString().trim() : fallback;

  int _i(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().replaceAll(RegExp(r'[^0-9]'), '')) ??
        fallback;
  }

  bool _b(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final str = v.toString().toLowerCase().trim();
    return str == 'true' || str == '1';
  }

  String _formatPrice(dynamic amount) {
    if (amount == null) return '₹0';
    int val = _i(amount);
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    ).format(val);
  }

  String _formatDateTime(dynamic timeVal) {
    if (timeVal == null) return '—';
    DateTime? dt;
    if (timeVal is DateTime) {
      dt = timeVal;
    } else {
      dt = DateTime.tryParse(timeVal.toString());
    }
    if (dt == null) return timeVal.toString();
    return DateFormat('dd MMM yyyy, hh:mm:ss a').format(dt);
  }

  @override
  void initState() {
    super.initState();
    _loadBidderSubscriptions();
    // 1-second ticker for real-time countdown updates
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBidderSubscriptions() async {
    final prefs = await SharedPreferences.getInstance();
    final allBids = LocalListingsStore().acceptedBids;
    final now = DateTime.now();
    final Map<String, Map<String, String>> map = {};

    for (final bid in allBids) {
      final phone = ProfileStorageHelper.normalizePhone(
        _s(bid['bidderPhone'] ?? bid['bidderUsername'] ?? bid['phone']),
      );
      if (phone.isEmpty || map.containsKey(phone)) continue;

      final subStatus = prefs.getString('sub_status_$phone') ?? 'none';
      final subPlanId = prefs.getString('sub_plan_$phone');
      final subEndStr = prefs.getString('sub_end_$phone');
      DateTime? subEnd = subEndStr != null ? DateTime.tryParse(subEndStr) : null;
      bool hasActive =
          subStatus == 'active' && subEnd != null && subEnd.isAfter(now);

      String planName = 'No active plan';
      String planExpiry = '';
      if (hasActive && subPlanId != null) {
        final plan = SubscriptionPlans.getPlanById(subPlanId);
        planName = plan?.name ?? subPlanId.toUpperCase();
        planExpiry = DateFormat('dd MMM yyyy').format(subEnd);
      }

      final profileName = prefs.getString('user_name_$phone') ?? '';
      map[phone] = {
        'plan': planName,
        'expiry': planExpiry,
        'hasActive': hasActive ? 'true' : 'false',
        'savedName': profileName,
        'subEnd': subEndStr ?? '',
      };
    }

    if (mounted) {
      setState(() {
        _bidderSubscriptions = map;
      });
    }
  }

  // Real lot status computation
  LotStatusInfo _computeLotStatus(Map<String, dynamic> lot, int bidsCount) {
    final rawStatus = _s(lot['status']).toLowerCase();
    if (rawStatus == 'cancelled') {
      return LotStatusInfo(
        status: LotStatus.cancelled,
        label: 'Cancelled',
        color: _red,
        bg: const Color(0xFFFEE2E2),
      );
    }

    final endProcessed = _b(lot['endProcessed']);
    final endTimeStr = lot['endTime']?.toString();
    DateTime? endDt = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;
    final now = DateTime.now();
    final isExpired = endDt != null && endDt.isBefore(now);

    final isEnded = endProcessed ||
        isExpired ||
        rawStatus == 'ended' ||
        rawStatus == 'sold' ||
        rawStatus == 'ended_no_bids';

    if (!isEnded && rawStatus == 'live') {
      return LotStatusInfo(
        status: LotStatus.live,
        label: 'Live',
        color: _green,
        bg: const Color(0xFFDCFCE7),
      );
    }

    if (bidsCount > 0 || rawStatus == 'sold') {
      return LotStatusInfo(
        status: LotStatus.sold,
        label: 'Sold',
        color: _navy,
        bg: const Color(0xFFE2E8F0),
      );
    } else {
      return LotStatusInfo(
        status: LotStatus.endedNoBids,
        label: 'Ended - no bids',
        color: _grey,
        bg: const Color(0xFFF3F4F6),
      );
    }
  }

  List<Map<String, dynamic>> _bidsForLot(String lotId) {
    return LocalListingsStore().acceptedBids.where((b) {
      final vId = _s(b['vehicleId'] ?? b['listingId']);
      return vId == lotId;
    }).toList();
  }

  int _getHighestBid(List<Map<String, dynamic>> lotBids) {
    int max = 0;
    for (final b in lotBids) {
      final amt = _i(b['bidAmountNum'] ?? b['bidAmount']);
      if (amt > max) max = amt;
    }
    return max;
  }

  Map<String, dynamic>? _getLeadingBid(List<Map<String, dynamic>> lotBids) {
    if (lotBids.isEmpty) return null;
    Map<String, dynamic>? leading;
    int max = -1;
    for (final b in lotBids) {
      final amt = _i(b['bidAmountNum'] ?? b['bidAmount']);
      if (amt > max) {
        max = amt;
        leading = b;
      }
    }
    return leading;
  }

  Map<String, dynamic>? _findLot(String lotId) {
    for (final l in LocalListingsStore().acceptedListings) {
      if (_s(l['id']) == lotId) return l;
    }
    return null;
  }

  BidResultType _computeBidResult(
    Map<String, dynamic> bid,
    Map<String, dynamic>? lot,
    int highestBidAmount,
  ) {
    final lotBids = lot != null ? _bidsForLot(_s(lot['id'])) : <Map<String, dynamic>>[];
    final lotStatus = lot != null ? _computeLotStatus(lot, lotBids.length) : null;
    final bidAmt = _i(bid['bidAmountNum'] ?? bid['bidAmount']);
    final isHighest = bidAmt >= highestBidAmount && highestBidAmount > 0;

    if (lotStatus != null && lotStatus.status == LotStatus.cancelled) {
      return BidResultType.cancelled;
    }

    if (lotStatus == null || lotStatus.status == LotStatus.live) {
      return isHighest ? BidResultType.leading : BidResultType.outbid;
    }

    return isHighest ? BidResultType.won : BidResultType.lost;
  }

  String _bidResultLabel(BidResultType type) {
    switch (type) {
      case BidResultType.leading:
        return 'Leading';
      case BidResultType.outbid:
        return 'Outbid';
      case BidResultType.won:
        return 'Won';
      case BidResultType.lost:
        return 'Lost';
      case BidResultType.cancelled:
        return 'Cancelled';
    }
  }

  Color _bidResultColor(BidResultType type) {
    switch (type) {
      case BidResultType.leading:
        return const Color(0xFF10B981);
      case BidResultType.outbid:
        return const Color(0xFFF59E0B);
      case BidResultType.won:
        return const Color(0xFF16A34A);
      case BidResultType.lost:
        return _grey;
      case BidResultType.cancelled:
        return _red;
    }
  }

  Color _bidResultBg(BidResultType type) {
    switch (type) {
      case BidResultType.leading:
        return const Color(0xFFD1FAE5);
      case BidResultType.outbid:
        return const Color(0xFFFEF3C7);
      case BidResultType.won:
        return const Color(0xFFDCFCE7);
      case BidResultType.lost:
        return const Color(0xFFF3F4F6);
      case BidResultType.cancelled:
        return const Color(0xFFFEE2E2);
    }
  }

  String _formatCountdown(DateTime? endDt) {
    if (endDt == null) return 'Live';
    final now = DateTime.now();
    final diff = endDt.difference(now);
    if (diff.isNegative) return 'Ending...';

    if (diff.inDays > 0) {
      final h = diff.inHours % 24;
      final m = diff.inMinutes % 60;
      return '${diff.inDays}d ${h}h ${m}m';
    }
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  bool _matchesDateFilter(dynamic dateVal) {
    if (_selectedDateRange == null) return true;
    if (dateVal == null) return true;
    DateTime? dt;
    if (dateVal is DateTime) {
      dt = dateVal;
    } else {
      dt = DateTime.tryParse(dateVal.toString());
    }
    if (dt == null) return true;
    final start = DateTime(
      _selectedDateRange!.start.year,
      _selectedDateRange!.start.month,
      _selectedDateRange!.start.day,
    );
    final end = DateTime(
      _selectedDateRange!.end.year,
      _selectedDateRange!.end.month,
      _selectedDateRange!.end.day,
      23,
      59,
      59,
    );
    return !dt.isBefore(start) && !dt.isAfter(end);
  }

  // Filtered Lots
  List<Map<String, dynamic>> _getFilteredLots() {
    final listings = LocalListingsStore().acceptedListings;
    final query = _searchQuery.toLowerCase().trim();

    final filtered = listings.where((lot) {
      final lotBids = _bidsForLot(_s(lot['id']));
      final statusInfo = _computeLotStatus(lot, lotBids.length);

      // Status chip filter: All, Live, Ended, Sold
      if (_lotsFilter == 'Live' && statusInfo.status != LotStatus.live) return false;
      if (_lotsFilter == 'Sold' && statusInfo.status != LotStatus.sold) return false;
      if (_lotsFilter == 'Ended') {
        if (statusInfo.status != LotStatus.sold &&
            statusInfo.status != LotStatus.endedNoBids) {
          return false;
        }
      }

      // Date filter
      if (!_matchesDateFilter(lot['publishedAt'] ?? lot['createdAt'] ?? lot['endTime'])) {
        return false;
      }

      // Search filter
      if (query.isNotEmpty) {
        final title = _s(lot['title']).toLowerCase();
        final seller = _s(lot['sellerName'] ?? lot['name']).toLowerCase();
        final phone = _s(lot['sellerPhone'] ?? lot['phone']).toLowerCase();
        final price = _s(lot['price'] ?? lot['startingPrice']).toLowerCase();
        final leading = _getLeadingBid(lotBids);
        final bidderName = _s(leading?['bidderName']).toLowerCase();
        final bidderPhone = _s(leading?['bidderPhone'] ?? leading?['bidderUsername']).toLowerCase();

        final matches = title.contains(query) ||
            seller.contains(query) ||
            phone.contains(query) ||
            price.contains(query) ||
            bidderName.contains(query) ||
            bidderPhone.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      final aBids = _bidsForLot(_s(a['id']));
      final bBids = _bidsForLot(_s(b['id']));

      if (_lotsSort == 'Highest Bid') {
        final aHigh = _getHighestBid(aBids);
        final bHigh = _getHighestBid(bBids);
        return bHigh.compareTo(aHigh);
      } else if (_lotsSort == 'Most Bids') {
        return bBids.length.compareTo(aBids.length);
      } else {
        // Newest
        final aDt = DateTime.tryParse(_s(a['publishedAt'] ?? a['createdAt'])) ??
            DateTime(2020);
        final bDt = DateTime.tryParse(_s(b['publishedAt'] ?? b['createdAt'])) ??
            DateTime(2020);
        return bDt.compareTo(aDt);
      }
    });

    return filtered;
  }

  // Filtered Bids (Bid Ledger)
  List<Map<String, dynamic>> _getFilteredBids() {
    final allBids = LocalListingsStore().acceptedBids;
    final query = _searchQuery.toLowerCase().trim();

    final filtered = allBids.where((bid) {
      final vId = _s(bid['vehicleId'] ?? bid['listingId']);
      final lot = _findLot(vId);
      final lotBids = _bidsForLot(vId);
      final highest = _getHighestBid(lotBids);
      final resultType = _computeBidResult(bid, lot, highest);
      final resultLabel = _bidResultLabel(resultType);

      // Ledger filter
      if (_ledgerFilter != 'All' && resultLabel != _ledgerFilter) {
        return false;
      }

      // Date filter
      if (!_matchesDateFilter(bid['time'] ?? bid['timestamp'])) {
        return false;
      }

      // Search filter
      if (query.isNotEmpty) {
        final lotTitle = _s(lot?['title'] ?? bid['vehicleTitle']).toLowerCase();
        final bidderName = _s(bid['bidderName']).toLowerCase();
        final bidderPhone = _s(bid['bidderPhone'] ?? bid['bidderUsername'] ?? bid['phone']).toLowerCase();
        final amount = _s(bid['bidAmountNum'] ?? bid['bidAmount']).toLowerCase();

        final matches = lotTitle.contains(query) ||
            bidderName.contains(query) ||
            bidderPhone.contains(query) ||
            amount.contains(query);
        if (!matches) return false;
      }

      return true;
    }).toList();

    // Sort
    filtered.sort((a, b) {
      if (_ledgerSort == 'Highest Bid') {
        final aAmt = _i(a['bidAmountNum'] ?? a['bidAmount']);
        final bAmt = _i(b['bidAmountNum'] ?? b['bidAmount']);
        return bAmt.compareTo(aAmt);
      } else {
        // Newest
        final aTime = DateTime.tryParse(_s(a['time'] ?? a['timestamp'])) ?? DateTime(2020);
        final bTime = DateTime.tryParse(_s(b['time'] ?? b['timestamp'])) ?? DateTime(2020);
        return bTime.compareTo(aTime);
      }
    });

    return filtered;
  }

  // Bidders List
  List<_BidderSummary> _getFilteredBidders() {
    final allBids = LocalListingsStore().acceptedBids;
    final listings = LocalListingsStore().acceptedListings;
    final query = _searchQuery.toLowerCase().trim();

    final Map<String, List<Map<String, dynamic>>> bidsByBidder = {};
    for (final bid in allBids) {
      final phone = ProfileStorageHelper.normalizePhone(
        _s(bid['bidderPhone'] ?? bid['bidderUsername'] ?? bid['phone']),
      );
      if (phone.isEmpty) continue;
      bidsByBidder.putIfAbsent(phone, () => []).add(bid);
    }

    // Determine won lots for each bidder
    final Map<String, int> lotsWonCount = {};
    final Map<String, int> wonTotalValue = {};

    for (final lot in listings) {
      final lotId = _s(lot['id']);
      final lotBids = _bidsForLot(lotId);
      final statusInfo = _computeLotStatus(lot, lotBids.length);

      if (statusInfo.status == LotStatus.sold && lotBids.isNotEmpty) {
        final leading = _getLeadingBid(lotBids);
        if (leading != null) {
          final winnerPhone = ProfileStorageHelper.normalizePhone(
            _s(leading['bidderPhone'] ?? leading['bidderUsername'] ?? leading['phone']),
          );
          if (winnerPhone.isNotEmpty) {
            final winAmt = _i(leading['bidAmountNum'] ?? leading['bidAmount']);
            lotsWonCount[winnerPhone] = (lotsWonCount[winnerPhone] ?? 0) + 1;
            wonTotalValue[winnerPhone] = (wonTotalValue[winnerPhone] ?? 0) + winAmt;
          }
        }
      }
    }

    final List<_BidderSummary> list = [];
    bidsByBidder.forEach((phone, bList) {
      final cachedSub = _bidderSubscriptions[phone];
      final firstBid = bList.first;
      String name = cachedSub?['savedName'] ?? '';
      if (name.isEmpty) {
        name = _s(firstBid['bidderName'], 'Bidder');
      }
      final planName = cachedSub?['plan'] ?? 'No active plan';
      final planExpiry = cachedSub?['expiry'] ?? '';
      final subEndStr = cachedSub?['subEnd'];
      final DateTime? planExpiryDate = (subEndStr != null && subEndStr.isNotEmpty)
          ? DateTime.tryParse(subEndStr)
          : null;
      final hasActive = cachedSub?['hasActive'] == 'true';

      final summary = _BidderSummary(
        name: name,
        phone: phone,
        totalBids: bList.length,
        lotsWon: lotsWonCount[phone] ?? 0,
        totalWonValue: wonTotalValue[phone] ?? 0,
        planName: planName,
        planExpiry: planExpiry,
        planExpiryDate: planExpiryDate,
        hasActivePlan: hasActive,
      );

      // Search filter
      if (query.isNotEmpty) {
        final matches = summary.name.toLowerCase().contains(query) ||
            summary.phone.toLowerCase().contains(query) ||
            summary.planName.toLowerCase().contains(query);
        if (!matches) return;
      }

      list.add(summary);
    });

    // Sort
    list.sort((a, b) {
      if (_biddersSort == 'Highest Won Value') {
        return b.totalWonValue.compareTo(a.totalWonValue);
      } else if (_biddersSort == 'Most Won') {
        return b.lotsWon.compareTo(a.lotsWon);
      } else {
        // Most Bids
        return b.totalBids.compareTo(a.totalBids);
      }
    });

    return list;
  }

  // Real Top Stat Cards calculations
  Widget _buildRealStatCards(bool isWide, bool isMobile) {
    final listings = LocalListingsStore().acceptedListings;
    final allBids = LocalListingsStore().acceptedBids;

    final totalBids = allBids.length;

    int liveAuctions = 0;
    int endedAuctions = 0;
    int totalBidValue = 0;

    for (final lot in listings) {
      final lotBids = _bidsForLot(_s(lot['id']));
      final statusInfo = _computeLotStatus(lot, lotBids.length);

      if (statusInfo.status == LotStatus.live) {
        liveAuctions++;
      } else if (statusInfo.status == LotStatus.sold ||
          statusInfo.status == LotStatus.endedNoBids) {
        endedAuctions++;
      }

      final highestBid = _getHighestBid(lotBids);
      if (highestBid > 0) {
        totalBidValue += highestBid;
      }
    }

    final uniqueBidders = allBids
        .map((b) => ProfileStorageHelper.normalizePhone(
              _s(b['bidderPhone'] ?? b['bidderUsername'] ?? b['phone']),
            ))
        .where((p) => p.isNotEmpty)
        .toSet()
        .length;

    final statItems = [
      _StatCardData(
        title: 'TOTAL BIDS',
        value: '$totalBids',
        icon: Icons.gavel,
        color: _navy,
      ),
      _StatCardData(
        title: 'LIVE AUCTIONS',
        value: '$liveAuctions',
        icon: Icons.timer_outlined,
        color: _green,
      ),
      _StatCardData(
        title: 'ENDED AUCTIONS',
        value: '$endedAuctions',
        icon: Icons.check_circle_outline,
        color: _grey,
      ),
      _StatCardData(
        title: 'UNIQUE BIDDERS',
        value: '$uniqueBidders',
        icon: Icons.people_outline,
        color: _orange,
      ),
      _StatCardData(
        title: 'TOTAL BID VALUE',
        value: _formatPrice(totalBidValue),
        icon: Icons.currency_rupee,
        color: _navy,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: statItems
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _buildStatCardWidget(item),
                      ),
                    ),
                  )
                  .toList(),
            );
          } else {
            // Below 768px / mobile: stacked cards in 2 columns
            final cardWidth = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: statItems
                  .map(
                    (item) => SizedBox(
                      width: cardWidth,
                      child: _buildStatCardWidget(item),
                    ),
                  )
                  .toList(),
            );
          }
        },
      ),
    );
  }

  Widget _buildStatCardWidget(_StatCardData data) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(data.icon, size: 16, color: data.color),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: data.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Tabs Header
  Widget _buildTabsHeader() {
    final lotsCount = LocalListingsStore().acceptedListings.length;
    final ledgerCount = LocalListingsStore().acceptedBids.length;
    final biddersCount = _getFilteredBidders().length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTabButton(0, 'Lots ($lotsCount)'),
                const SizedBox(width: 4),
                _buildTabButton(1, 'Bid Ledger ($ledgerCount)'),
                const SizedBox(width: 4),
                _buildTabButton(2, 'Bidders ($biddersCount)'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(int index, String title) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _navy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // Search, Filter chips, Sort, Date Picker, CSV Export
  Widget _buildControlsBar(bool isMobile) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search bar + CSV Export + Date Filter
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: _activeTabIndex == 0
                          ? 'Search lot title, seller, amount...'
                          : _activeTabIndex == 1
                              ? 'Search lot title, bidder, amount...'
                              : 'Search bidder name, phone...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _orange, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Date Filter button
              OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: _selectedDateRange != null ? _orange : Colors.grey.shade700,
                ),
                label: Text(
                  _selectedDateRange != null ? 'Filtered' : 'Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: _selectedDateRange != null ? _orange : Colors.grey.shade800,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: BorderSide(
                    color: _selectedDateRange != null ? _orange : Colors.grey.shade300,
                  ),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 8),
              // CSV Export button
              ElevatedButton.icon(
                onPressed: _exportCurrentTabCsv,
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Export CSV', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          // Date active indicator
          if (_selectedDateRange != null) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(
                  label: Text(
                    'Date: ${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFFFEF3C7),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.clear, size: 14, color: Colors.red),
                  label: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                  backgroundColor: const Color(0xFFFEE2E2),
                  side: BorderSide(color: Colors.red.shade200),
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                  },
                ),
              ],
            ),
          ],

          const SizedBox(height: 8),

          // Row 2: Filter chips + Sort Dropdown
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _buildFilterChips(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSortDropdown(),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFilterChips() {
    if (_activeTabIndex == 0) {
      final options = ['All', 'Live', 'Ended', 'Sold'];
      return options.map((opt) {
        final isSelected = _lotsFilter == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(opt, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey.shade800)),
            selected: isSelected,
            selectedColor: _orange,
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            onSelected: (val) {
              if (val) setState(() => _lotsFilter = opt);
            },
          ),
        );
      }).toList();
    } else if (_activeTabIndex == 1) {
      final options = ['All', 'Leading', 'Outbid', 'Won', 'Lost'];
      return options.map((opt) {
        final isSelected = _ledgerFilter == opt;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: ChoiceChip(
            label: Text(opt, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey.shade800)),
            selected: isSelected,
            selectedColor: _orange,
            backgroundColor: Colors.white,
            visualDensity: VisualDensity.compact,
            onSelected: (val) {
              if (val) setState(() => _ledgerFilter = opt);
            },
          ),
        );
      }).toList();
    } else {
      return const [
        Chip(
          label: Text('All Registered Bidders', style: TextStyle(fontSize: 11)),
          backgroundColor: Colors.white,
          visualDensity: VisualDensity.compact,
        ),
      ];
    }
  }

  Widget _buildSortDropdown() {
    List<String> items;
    String currentValue;
    ValueChanged<String?> onChanged;

    if (_activeTabIndex == 0) {
      items = ['Newest', 'Highest Bid', 'Most Bids'];
      currentValue = _lotsSort;
      onChanged = (val) {
        if (val != null) setState(() => _lotsSort = val);
      };
    } else if (_activeTabIndex == 1) {
      items = ['Newest', 'Highest Bid'];
      currentValue = _ledgerSort;
      onChanged = (val) {
        if (val != null) setState(() => _ledgerSort = val);
      };
    } else {
      items = ['Most Bids', 'Highest Won Value', 'Most Won'];
      currentValue = _biddersSort;
      onChanged = (val) {
        if (val != null) setState(() => _biddersSort = val);
      };
    }

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentValue,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Select date range',
      saveText: 'Apply',
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 30)),
            end: DateTime.now(),
          ),
      builder: (BuildContext context, Widget? child) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: _orange,
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: _navy,
                ),
              ),
              child: child!,
            ),
          ),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  String _formatCsvDate(dynamic timeVal) {
    if (timeVal == null) return '';
    DateTime? dt;
    if (timeVal is DateTime) {
      dt = timeVal;
    } else {
      dt = DateTime.tryParse(timeVal.toString());
    }
    if (dt == null) return timeVal.toString();
    return DateFormat('dd-MM-yyyy HH:mm').format(dt);
  }

  // CSV Exporter
  void _exportCurrentTabCsv() {
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    if (_activeTabIndex == 0) {
      final lots = _getFilteredLots();
      final headers = [
        'Lot ID',
        'Vehicle Title',
        'Seller Name',
        'Seller Phone',
        'Bids Count',
        'Starting Price',
        'Highest Bid',
        'Leading Bidder Name',
        'Leading Bidder Phone',
        'End Date',
        'Status',
      ];
      final rows = <List<String>>[];
      for (final lot in lots) {
        final lotBids = _bidsForLot(_s(lot['id']));
        final statusInfo = _computeLotStatus(lot, lotBids.length);
        final highestBid = _getHighestBid(lotBids);
        final leading = _getLeadingBid(lotBids);

        rows.add([
          _s(lot['id']),
          _s(lot['title'], 'Vehicle'),
          _s(lot['sellerName'] ?? lot['name'], 'Seller'),
          _s(lot['sellerPhone'] ?? lot['phone']),
          '${lotBids.length}',
          '${_i(lot['price'] ?? lot['startingPrice'])}',
          '${highestBid > 0 ? highestBid : 0}',
          _s(leading?['bidderName'], 'None'),
          _s(leading?['bidderPhone'] ?? leading?['bidderUsername']),
          _formatCsvDate(lot['endTime']),
          statusInfo.label,
        ]);
      }
      _exportCsvFile('lots_$dateStr.csv', headers, rows);
    } else if (_activeTabIndex == 1) {
      final bids = _getFilteredBids();
      final headers = [
        'Lot Title',
        'Bidder Name',
        'Bidder Phone',
        'Amount',
        'Date Time',
        'Result',
      ];
      final rows = <List<String>>[];
      for (final bid in bids) {
        final vId = _s(bid['vehicleId'] ?? bid['listingId']);
        final lot = _findLot(vId);
        final lotBids = _bidsForLot(vId);
        final highest = _getHighestBid(lotBids);
        final resultType = _computeBidResult(bid, lot, highest);
        final resultLabel = _bidResultLabel(resultType);

        rows.add([
          _s(lot?['title'] ?? bid['vehicleTitle'], 'Lot'),
          _s(bid['bidderName'], 'Bidder'),
          _s(bid['bidderPhone'] ?? bid['bidderUsername'] ?? bid['phone']),
          '${_i(bid['bidAmountNum'] ?? bid['bidAmount'])}',
          _formatCsvDate(bid['time'] ?? bid['timestamp']),
          resultLabel,
        ]);
      }
      _exportCsvFile('ledger_$dateStr.csv', headers, rows);
    } else {
      final bidders = _getFilteredBidders();
      final headers = [
        'Bidder Name',
        'Phone',
        'Total Bids',
        'Lots Won',
        'Total Won Value',
        'Subscription Plan',
        'Plan Expiry',
      ];
      final rows = <List<String>>[];
      for (final b in bidders) {
        rows.add([
          b.name,
          b.phone,
          '${b.totalBids}',
          '${b.lotsWon}',
          '${b.totalWonValue}',
          b.planName,
          _formatCsvDate(b.planExpiryDate),
        ]);
      }
      _exportCsvFile('bidders_$dateStr.csv', headers, rows);
    }
  }

  Future<void> _exportCsvFile(
    String filename,
    List<String> headers,
    List<List<String>> rows,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));
    for (final row in rows) {
      buffer.writeln(row.map((c) => '"${c.replaceAll('"', '""')}"').join(','));
    }
    final csvString = buffer.toString();
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csvString)]);

    try {
      if (kIsWeb) {
        WebDownloadHelper.downloadBytes(bytes, filename);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'text/csv', name: filename)],
          subject: filename,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exported ${rows.length} rows'),
            backgroundColor: _navy,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export CSV: $e'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  // BUILD METHOD
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    final isMobile = screenWidth < 768;

    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 2,
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: const AdminNavigationDrawer(),
      appBar: const AdminAppBar(),
      body: ListenableBuilder(
        listenable: LocalListingsStore(),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderTitle(),
              _buildRealStatCards(isWide, isMobile),
              _buildTabsHeader(),
              _buildControlsBar(isMobile),
              const SizedBox(height: 8),
              Expanded(
                child: _buildActiveTabContent(isWide, isMobile),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        'Bidding Management & Live Auctions',
        style: TextStyle(
          color: _navy,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isWide, bool isMobile) {
    if (_activeTabIndex == 0) {
      return _buildLotsTab(isWide, isMobile);
    } else if (_activeTabIndex == 1) {
      return _buildBidLedgerTab(isWide, isMobile);
    } else {
      return _buildBiddersTab(isWide, isMobile);
    }
  }

  // TAB 0: LOTS
  Widget _buildLotsTab(bool isWide, bool isMobile) {
    final lots = _getFilteredLots();

    if (lots.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No lots found matching criteria',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      // Mobile stacked cards
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: lots.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final lot = lots[i];
          final lotBids = _bidsForLot(_s(lot['id']));
          final statusInfo = _computeLotStatus(lot, lotBids.length);
          final highestBid = _getHighestBid(lotBids);
          final leading = _getLeadingBid(lotBids);

          return _buildLotMobileCard(lot, lotBids, statusInfo, highestBid, leading);
        },
      );
    } else {
      // Web sticky data table
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                headingTextStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _navy,
                ),
                dataRowMinHeight: 64,
                dataRowMaxHeight: 76,
                columns: const [
                  DataColumn(label: Text('VEHICLE')),
                  DataColumn(label: Text('SELLER')),
                  DataColumn(label: Text('BIDS')),
                  DataColumn(label: Text('STARTING PRICE')),
                  DataColumn(label: Text('HIGHEST BID')),
                  DataColumn(label: Text('LEADING BIDDER')),
                  DataColumn(label: Text('TIME LEFT / END DATE')),
                  DataColumn(label: Text('STATUS')),
                  DataColumn(label: Text('ACTIONS')),
                ],
                rows: lots.map((lot) {
                  final lotBids = _bidsForLot(_s(lot['id']));
                  final statusInfo = _computeLotStatus(lot, lotBids.length);
                  final highestBid = _getHighestBid(lotBids);
                  final leading = _getLeadingBid(lotBids);
                  final endTimeStr = lot['endTime']?.toString();
                  DateTime? endDt = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;
                  final timeStr = statusInfo.status == LotStatus.live
                      ? _formatCountdown(endDt)
                      : _formatDateTime(endDt);

                  return DataRow(
                    cells: [
                      // Thumbnail + Title
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: ListingImage(
                                listing: lot,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 160,
                              child: Text(
                                _s(lot['title'], 'Vehicle'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Seller
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _s(lot['sellerName'] ?? lot['name'], 'Seller'),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              _s(lot['sellerPhone'] ?? lot['phone']),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      // Bids count
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${lotBids.length} bids',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      // Starting price
                      DataCell(
                        Text(
                          _formatPrice(lot['price'] ?? lot['startingPrice']),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      // Highest bid
                      DataCell(
                        Text(
                          highestBid > 0 ? _formatPrice(highestBid) : '—',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: highestBid > 0 ? _green : Colors.grey,
                          ),
                        ),
                      ),
                      // Leading bidder
                      DataCell(
                        leading != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _s(leading['bidderName'], 'Bidder'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    _s(leading['bidderPhone'] ?? leading['bidderUsername']),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              )
                            : const Text('—', style: TextStyle(color: Colors.grey)),
                      ),
                      // Time Left / End date
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (statusInfo.status == LotStatus.live)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.timer_outlined, size: 14, color: Color(0xFF16A34A)),
                              ),
                            Text(
                              timeStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: statusInfo.status == LotStatus.live ? FontWeight.bold : FontWeight.normal,
                                color: statusInfo.status == LotStatus.live ? _green : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status Chip
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusInfo.bg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusInfo.label,
                            style: TextStyle(
                              color: statusInfo.color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      // Row Actions
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            OutlinedButton(
                              onPressed: () => _showBidHistoryDialog(context, lot, lotBids),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text('View Bids', style: TextStyle(fontSize: 11)),
                            ),
                            if (statusInfo.status == LotStatus.live) ...[
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () => _showExtendTimeDialog(context, lot),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  side: BorderSide(color: _orange),
                                  foregroundColor: _orange,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Extend', style: TextStyle(fontSize: 11)),
                              ),
                              const SizedBox(width: 6),
                              OutlinedButton(
                                onPressed: () => _showCancelAuctionDialog(context, lot),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  side: BorderSide(color: _red),
                                  foregroundColor: _red,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                              ),
                              if (kDevMode) ...[
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  onPressed: () => _showEndAuctionNowDialog(context, lot),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _red,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                  ),
                                  child: const Text('End Now', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildLotMobileCard(
    Map<String, dynamic> lot,
    List<Map<String, dynamic>> lotBids,
    LotStatusInfo statusInfo,
    int highestBid,
    Map<String, dynamic>? leading,
  ) {
    final endTimeStr = lot['endTime']?.toString();
    DateTime? endDt = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;
    final timeStr = statusInfo.status == LotStatus.live
        ? _formatCountdown(endDt)
        : _formatDateTime(endDt);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Image + Title + Status
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ListingImage(
                  listing: lot,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _s(lot['title'], 'Vehicle'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Seller: ${_s(lot['sellerName'] ?? lot['name'], 'Seller')} • ${_s(lot['sellerPhone'] ?? lot['phone'])}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusInfo.bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusInfo.label,
                  style: TextStyle(
                    color: statusInfo.color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),

          // Pricing and bids info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Start Price', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(
                    _formatPrice(lot['price'] ?? lot['startingPrice']),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Total Bids', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(
                    '${lotBids.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Highest Bid', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  Text(
                    highestBid > 0 ? _formatPrice(highestBid) : '—',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: highestBid > 0 ? _green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (leading != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Leading: ${_s(leading['bidderName'])} (${_s(leading['bidderPhone'] ?? leading['bidderUsername'])})',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                statusInfo.status == LotStatus.live ? Icons.timer_outlined : Icons.event_available,
                size: 14,
                color: statusInfo.status == LotStatus.live ? _green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                statusInfo.status == LotStatus.live ? 'Time Left: $timeStr' : 'Ended: $timeStr',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: statusInfo.status == LotStatus.live ? FontWeight.bold : FontWeight.normal,
                  color: statusInfo.status == LotStatus.live ? _green : Colors.grey.shade700,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          // Actions
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton(
                onPressed: () => _showBidHistoryDialog(context, lot, lotBids),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: const Text('View Bids', style: TextStyle(fontSize: 11)),
              ),
              if (statusInfo.status == LotStatus.live) ...[
                OutlinedButton(
                  onPressed: () => _showExtendTimeDialog(context, lot),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    side: BorderSide(color: _orange),
                    foregroundColor: _orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Extend', style: TextStyle(fontSize: 11)),
                ),
                OutlinedButton(
                  onPressed: () => _showCancelAuctionDialog(context, lot),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    side: BorderSide(color: _red),
                    foregroundColor: _red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                ),
                if (kDevMode)
                  ElevatedButton(
                    onPressed: () => _showEndAuctionNowDialog(context, lot),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: const Text('End Now', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // TAB 1: BID LEDGER
  Widget _buildBidLedgerTab(bool isWide, bool isMobile) {
    final bids = _getFilteredBids();

    if (bids.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.gavel_outlined, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No bids recorded yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: bids.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final bid = bids[i];
          final vId = _s(bid['vehicleId'] ?? bid['listingId']);
          final lot = _findLot(vId);
          final lotBids = _bidsForLot(vId);
          final highest = _getHighestBid(lotBids);
          final resultType = _computeBidResult(bid, lot, highest);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _s(lot?['title'] ?? bid['vehicleTitle'], 'Lot'),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _bidResultBg(resultType),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _bidResultLabel(resultType),
                        style: TextStyle(
                          color: _bidResultColor(resultType),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_s(bid['bidderName'], 'Bidder')} (${_s(bid['bidderPhone'] ?? bid['bidderUsername'] ?? bid['phone'])})',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    Text(
                      _formatPrice(bid['bidAmountNum'] ?? bid['bidAmount']),
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _navy),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDateTime(bid['time'] ?? bid['timestamp']),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          );
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _navy),
                      columns: const [
                        DataColumn(label: Text('LOT TITLE')),
                        DataColumn(label: Text('BIDDER')),
                        DataColumn(label: Text('AMOUNT')),
                        DataColumn(label: Text('DATE TIME')),
                        DataColumn(label: Text('RESULT')),
                      ],
                      rows: bids.map((bid) {
                        final vId = _s(bid['vehicleId'] ?? bid['listingId']);
                        final lot = _findLot(vId);
                        final lotBids = _bidsForLot(vId);
                        final highest = _getHighestBid(lotBids);
                        final resultType = _computeBidResult(bid, lot, highest);

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                _s(lot?['title'] ?? bid['vehicleTitle'], 'Lot'),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                            DataCell(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _s(bid['bidderName'], 'Bidder'),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    _s(bid['bidderPhone'] ?? bid['bidderUsername'] ?? bid['phone']),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatPrice(bid['bidAmountNum'] ?? bid['bidAmount']),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _navy),
                              ),
                            ),
                            DataCell(
                              Text(
                                _formatDateTime(bid['time'] ?? bid['timestamp']),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _bidResultBg(resultType),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _bidResultLabel(resultType),
                                  style: TextStyle(
                                    color: _bidResultColor(resultType),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // TAB 2: BIDDERS
  Widget _buildBiddersTab(bool isWide, bool isMobile) {
    final bidders = _getFilteredBidders();

    if (bidders.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline, size: 48, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'No bidders recorded yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    if (isMobile) {
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: bidders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final b = bidders[i];
          return InkWell(
            onTap: () {
              context.push('/admin-clients?phone=${b.phone}');
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          b.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                    ],
                  ),
                  Text(b.phone, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Bids: ${b.totalBids}', style: const TextStyle(fontSize: 12)),
                      Text('Won: ${b.lotsWon}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text('Won Value: ${_formatPrice(b.totalWonValue)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _green)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: b.hasActivePlan ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      b.hasActivePlan
                          ? '${b.planName} • Exp: ${b.planExpiry}'
                          : 'No active plan',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: b.hasActivePlan ? _green : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      return LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
                      headingTextStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _navy),
                      columns: const [
                        DataColumn(label: Text('BIDDER NAME')),
                        DataColumn(label: Text('PHONE')),
                        DataColumn(label: Text('TOTAL BIDS')),
                        DataColumn(label: Text('LOTS WON')),
                        DataColumn(label: Text('TOTAL WON VALUE')),
                        DataColumn(label: Text('ACTIVE SUBSCRIPTION')),
                        DataColumn(label: Text('ACTIONS')),
                      ],
                      rows: bidders.map((b) {
                        return DataRow(
                          cells: [
                            DataCell(
                              Text(b.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ),
                            DataCell(
                              Text(b.phone, style: const TextStyle(fontSize: 12)),
                            ),
                            DataCell(
                              Text('${b.totalBids}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            DataCell(
                              Text('${b.lotsWon}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            DataCell(
                              Text(
                                _formatPrice(b.totalWonValue),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: b.totalWonValue > 0 ? _green : Colors.grey,
                                ),
                              ),
                            ),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: b.hasActivePlan ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  b.hasActivePlan
                                      ? '${b.planName} • Exp: ${b.planExpiry}'
                                      : 'No active plan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: b.hasActivePlan ? _green : Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              OutlinedButton(
                                onPressed: () {
                                  context.push('/admin-clients?phone=${b.phone}');
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                ),
                                child: const Text('View Profile', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
  }

  // DIALOGS
  void _showBidHistoryDialog(
    BuildContext context,
    Map<String, dynamic> lot,
    List<Map<String, dynamic>> lotBids,
  ) {
    final highestAmt = _getHighestBid(lotBids);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Bid History: ${_s(lot['title'], 'Vehicle')}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _navy),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: lotBids.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No bids placed on this lot yet',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: lotBids.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final b = lotBids[i];
                      final amt = _i(b['bidAmountNum'] ?? b['bidAmount']);
                      final isHighest = amt == highestAmt && highestAmt > 0;

                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isHighest ? const Color(0xFFF0FDF4) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isHighest ? const Color(0xFF86EFAC) : Colors.grey.shade200,
                            width: isHighest ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            if (isHighest)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.star, size: 16, color: Color(0xFF16A34A)),
                              ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _s(b['bidderName'], 'Bidder'),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      if (isHighest) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text(
                                            'HIGHEST',
                                            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    _s(b['bidderPhone'] ?? b['bidderUsername'] ?? b['phone']),
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDateTime(b['time'] ?? b['timestamp']),
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatPrice(amt),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: isHighest ? _green : _navy,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
    );
  }

  void _showExtendTimeDialog(BuildContext context, Map<String, dynamic> lot) {
    final hoursController = TextEditingController(text: '24');
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Extend Auction Time', style: TextStyle(color: _navy, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lot: ${_s(lot['title'], 'Vehicle')}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    const Text('Hours to extend:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: hoursController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter hours (e.g. 24)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: [1, 6, 12, 24, 48].map((h) {
                        return ActionChip(
                          label: Text('+${h}h', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              hoursController.text = h.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    const Text('Reason for extension:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Requested by seller due to weekend bank holidays',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final hours = int.tryParse(hoursController.text.trim()) ?? 0;
                    final reason = reasonController.text.trim();
                    if (hours <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid positive hours')),
                      );
                      return;
                    }
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a reason')),
                      );
                      return;
                    }

                    Navigator.pop(ctx);
                    _executeExtendTime(lot, hours, reason);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Extend Auction'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _executeExtendTime(Map<String, dynamic> lot, int hours, String reason) {
    try {
      final currentEndStr = lot['endTime']?.toString();
      DateTime baseTime = currentEndStr != null
          ? (DateTime.tryParse(currentEndStr) ?? DateTime.now())
          : DateTime.now();
      if (baseTime.isBefore(DateTime.now())) {
        baseTime = DateTime.now();
      }
      final newEnd = baseTime.add(Duration(hours: hours));

      final updatedLot = Map<String, dynamic>.from(lot);
      updatedLot['endTime'] = newEnd.toIso8601String();
      updatedLot['endProcessed'] = false;
      updatedLot['status'] = 'live';

      LocalListingsStore().updateListing(updatedLot);

      final sellerPhone = _s(lot['sellerPhone'] ?? lot['phone']);
      final lotTitle = _s(lot['title'], 'Vehicle');
      final lotId = _s(lot['id']);

      if (sellerPhone.isNotEmpty) {
        ClientNotificationStore().addNotification(
          'Auction for $lotTitle extended by $hours hour(s). Reason: $reason',
          'auction_extended',
          sellerPhone,
          refId: lotId,
          recipientRole: 'seller',
        );
      }

      final bidderPhones = LocalListingsStore()
          .acceptedBids
          .where((b) => _s(b['vehicleId'] ?? b['listingId']) == lotId)
          .map((b) => ProfileStorageHelper.normalizePhone(
                _s(b['bidderPhone'] ?? b['bidderUsername'] ?? b['phone']),
              ))
          .where((p) => p.isNotEmpty)
          .toSet();

      for (final bPhone in bidderPhones) {
        ClientNotificationStore().addNotification(
          'Auction for $lotTitle extended by $hours hour(s).',
          'auction_extended',
          bPhone,
          refId: lotId,
          recipientRole: 'buyer',
        );
      }

      AdminClientsStore().addHistoryEntry(
        name: 'Admin',
        phone: 'Admin',
        action: 'Extended auction for "$lotTitle" by $hours hour(s). Reason: $reason',
        type: 'auction',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auction extended by $hours hour(s) successfully'),
            backgroundColor: _green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to extend auction: $e'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  void _showCancelAuctionDialog(BuildContext context, Map<String, dynamic> lot) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Cancel Auction', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to cancel the auction for "${_s(lot['title'], 'Vehicle')}"?'),
              const SizedBox(height: 12),
              const Text('Reason for cancellation (required):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Enter reason for cancellation',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Dismiss'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                if (reason.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a cancellation reason')),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _executeCancelAuction(lot, reason);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
              child: const Text('Cancel Auction'),
            ),
          ],
        );
      },
    );
  }

  void _executeCancelAuction(Map<String, dynamic> lot, String reason) {
    try {
      final updatedLot = Map<String, dynamic>.from(lot);
      updatedLot['status'] = 'cancelled';
      updatedLot['cancellationReason'] = reason;
      updatedLot['endProcessed'] = true;

      LocalListingsStore().updateListing(updatedLot);

      final sellerPhone = _s(lot['sellerPhone'] ?? lot['phone']);
      final lotTitle = _s(lot['title'], 'Vehicle');
      final lotId = _s(lot['id']);

      if (sellerPhone.isNotEmpty) {
        ClientNotificationStore().addNotification(
          'Auction for $lotTitle was cancelled by Admin. Reason: $reason',
          'auction_cancelled',
          sellerPhone,
          refId: lotId,
          recipientRole: 'seller',
        );
      }

      final bidderPhones = LocalListingsStore()
          .acceptedBids
          .where((b) => _s(b['vehicleId'] ?? b['listingId']) == lotId)
          .map((b) => ProfileStorageHelper.normalizePhone(
                _s(b['bidderPhone'] ?? b['bidderUsername'] ?? b['phone']),
              ))
          .where((p) => p.isNotEmpty)
          .toSet();

      for (final bPhone in bidderPhones) {
        ClientNotificationStore().addNotification(
          'Auction for $lotTitle was cancelled by Admin. Reason: $reason',
          'auction_cancelled',
          bPhone,
          refId: lotId,
          recipientRole: 'buyer',
        );
      }

      AdminClientsStore().addHistoryEntry(
        name: 'Admin',
        phone: 'Admin',
        action: 'Cancelled auction for "$lotTitle". Reason: $reason',
        type: 'auction',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auction cancelled for "$lotTitle"'),
            backgroundColor: _red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel auction: $e'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }

  void _showEndAuctionNowDialog(BuildContext context, Map<String, dynamic> lot) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('End Auction Now?', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          content: Text(
            'This will immediately end the auction for "${_s(lot['title'], 'Vehicle')}". The leading bidder (if any) will be marked as winner and token payment will be initialized.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _executeEndAuctionNow(lot);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _red, foregroundColor: Colors.white),
              child: const Text('End Auction Now'),
            ),
          ],
        );
      },
    );
  }

  void _executeEndAuctionNow(Map<String, dynamic> lot) {
    try {
      final lotId = _s(lot['id']);
      final lotTitle = _s(lot['title'], 'Vehicle');

      LocalListingsStore().endAuction(lotId);

      AdminClientsStore().addHistoryEntry(
        name: 'Admin',
        phone: 'Admin',
        action: 'Ended auction early for "$lotTitle"',
        type: 'auction',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Auction ended early for "$lotTitle"'),
            backgroundColor: _green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to end auction: $e'),
            backgroundColor: _red,
          ),
        );
      }
    }
  }
}

class _StatCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatCardData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}
