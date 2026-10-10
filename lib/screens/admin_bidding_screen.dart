// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides:
// GET /api/admin/bidding/stats (Total Bids/Active Bids/Members counts)
// GET /api/admin/bidding/lots (Total Bids tab data)
// GET /api/admin/bidding/live (Active Bids tab data)
// GET /api/admin/bidding/members (Members tab data)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../utils/local_listings_store.dart';

class AdminBiddingScreen extends StatefulWidget {
  const AdminBiddingScreen({super.key});

  @override
  State<AdminBiddingScreen> createState() => _AdminBiddingScreenState();
}

class _AdminBiddingScreenState extends State<AdminBiddingScreen> {
  int _activeTabIndex = 0;
  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF22C55E);
  final Color _red = const Color(0xFFEF4444);

  String _formatPrice(dynamic amount) {
    if (amount == null) return 'N/A';
    if (amount is num) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    }
    if (amount is String) {
      final parsed = num.tryParse(amount.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (parsed != null) {
        return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(parsed);
      }
    }
    return amount.toString();
  }

  List<Map<String, dynamic>> get _totalBids {
    final listings = LocalListingsStore().acceptedListings;
    final allBids = LocalListingsStore().acceptedBids;
    final Map<String, List<Map<String, dynamic>>> bidsByVehicle = {};
    for (var bid in allBids) {
      final vId = bid['vehicleId'] ?? '';
      bidsByVehicle.putIfAbsent(vId, () => []).add(bid);
    }
    
    List<Map<String, dynamic>> result = [];
    for (var v in listings) {
      final vId = v['id'];
      if (!bidsByVehicle.containsKey(vId)) continue;
      final vehicleBids = bidsByVehicle[vId]!;
      final topBid = vehicleBids.first;
      int maxBid = 0;
      for (var b in vehicleBids) {
        int amt = b['bidAmountNum'] ?? b['bidAmount'] ?? 0;
        if (amt > maxBid) maxBid = amt;
      }
      
      result.add({
        'vehicle': v['title'] ?? 'Vehicle',
        'lot': '#LOT-${vId.hashCode.toString().substring(0, 4)}',
        'img': v['image'] ?? 'https://via.placeholder.com/150',
        'bids': '${vehicleBids.length} bids',
        'trend': 'Active',
        'trendColor': Colors.green,
        'highest': _formatPrice(maxBid > 0 ? maxBid : (topBid['bidAmountNum'] ?? topBid['bidAmount'] ?? '₹0')),
        'secondary': '',
        'status': v['status'] == 'live' ? 'Live Lot' : 'Ended',
        'statusColor': v['status'] == 'live' ? Colors.green : Colors.grey,
        'topMember': topBid['bidderName'] ?? 'Unknown',
        'memberId': topBid['bidderUsername'] ?? '',
        'avatarColor': Colors.blue,
      });
    }
    return result;
  }

  List<Map<String, dynamic>> get _activeBids {
    final listings = LocalListingsStore().acceptedListings;
    final allBids = LocalListingsStore().acceptedBids;
    final Map<String, List<Map<String, dynamic>>> bidsByVehicle = {};
    for (var bid in allBids) {
      final vId = bid['vehicleId'] ?? '';
      bidsByVehicle.putIfAbsent(vId, () => []).add(bid);
    }
    
    List<Map<String, dynamic>> result = [];
    for (var v in listings) {
      if (v['status'] != 'live') continue;
      final vId = v['id'];
      if (!bidsByVehicle.containsKey(vId)) continue;
      
      final vehicleBids = bidsByVehicle[vId]!;
      final topBid = vehicleBids.first;
      int maxBid = 0;
      for (var b in vehicleBids) {
        int amt = b['bidAmountNum'] ?? b['bidAmount'] ?? 0;
        if (amt > maxBid) maxBid = amt;
      }
      
      String timeStr = 'Live';
      if (v['endTime'] != null) {
        final end = DateTime.parse(v['endTime']);
        final diff = end.difference(DateTime.now());
        if (diff.isNegative) {
          timeStr = 'Ending';
        } else {
          timeStr = '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
        }
      }

      result.add({
        'vehicle': v['title'] ?? 'Vehicle',
        'img': v['image'] ?? 'https://via.placeholder.com/150',
        'time': timeStr,
        'timeColor': Colors.blue,
        'timeSub': '${vehicleBids.length} bids placed',
        'highest': _formatPrice(maxBid > 0 ? maxBid : (topBid['bidAmountNum'] ?? topBid['bidAmount'] ?? '₹0')),
        'highestSub': 'Leading Bid',
        'highestSubColor': Colors.green,
        'bidder': topBid['bidderName'] ?? 'Unknown',
        'bidderId': topBid['bidderUsername'] ?? '',
        'avatarColor': Colors.orange,
        'actionText': 'Monitor Live',
        'actionColor': const Color(0xFF001128),
      });
    }
    return result;
  }

  List<Map<String, dynamic>> get _members {
    final allBids = LocalListingsStore().acceptedBids;
    final Map<String, List<Map<String, dynamic>>> bidsByMember = {};
    for (var bid in allBids) {
      final mId = bid['bidderUsername'] ?? 'unknown';
      bidsByMember.putIfAbsent(mId, () => []).add(bid);
    }
    
    List<Map<String, dynamic>> result = [];
    bidsByMember.forEach((mId, bids) {
      final name = bids.first['bidderName'] ?? 'Unknown';
      result.add({
        'name': name,
        'badge': 'Verified Buyer',
        'badgeColor': Colors.blue,
        'id': mId,
        'bidsPlaced': bids.length.toString(),
        'bidsSub': 'Total Bids',
        'won': '0 Won',
        'wonValue': '₹0 Value',
        'deposit': 'Verified Deposit',
        'depositSub': 'Standard',
        'avatarColor': Colors.purple,
      });
    });
    return result;
  }

  void _showDummyAction(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    bool isWide = MediaQuery.of(context).size.width > 800;

    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 2,
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: const AdminAppBar(),
      body: ListenableBuilder(
        listenable: LocalListingsStore(),
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    _buildHeaderTitle(),
                    _buildStatCards(isWide),
                    _buildTabsRow(),
                    _buildSearchAndSort(),
                    _buildSectionLabel(),
                    _buildGridArea(isWide),
                  ],
                ),
              ),
              _buildAlertBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderTitle() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Bidding Data Grid',
        style: TextStyle(
          color: _navy,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatCards(bool isWide) {
    int totalBids = LocalListingsStore().acceptedBids.length;
    int activeBids = _activeBids.fold<int>(0, (sum, bidRow) => sum + int.parse(bidRow['timeSub'].toString().split(' ')[0]));
    int totalMembers = _members.length;

    List<Widget> cards = [
      _buildStatCard('TOTAL BIDS', '$totalBids', _navy, Icons.diamond_outlined),
      _buildStatCard('ACTIVE BIDS', '$activeBids', _orange, Icons.gavel, subtitle: 'Total bids on live lots', subtitleIcon: Icons.local_fire_department),
      _buildStatCard('MEMBERS', '$totalMembers', _navy, Icons.people_outline),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: isWide
          ? Row(
              children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 12), child: c))).toList()..removeLast()..add(Expanded(child: cards.last)),
            )
          : Column(
              children: cards.map((c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: c)).toList(),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor, IconData topIcon, {String? subtitle, IconData? subtitleIcon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Icon(topIcon, size: 18, color: Colors.grey.shade400),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                if (subtitleIcon != null) ...[
                  Icon(subtitleIcon, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                ],
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildTab('Total Bids', 0),
            const SizedBox(width: 8),
            _buildTab('Active Bids', 1),
            const SizedBox(width: 8),
            _buildTab('Members', 2),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _navy : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? _navy : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _navy,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndSort() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search vehicle, member ID (#MB), or amount...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, size: 18, color: _navy),
                const SizedBox(width: 8),
                Text('Sort', style: TextStyle(color: _navy, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel() {
    String label = '';
    if (_activeTabIndex == 0) label = 'Master Lots & Bid History Grid';
    if (_activeTabIndex == 1) label = 'Live Auctions & Timers Grid';
    if (_activeTabIndex == 2) label = 'Member Accounts & Deposit Ledger';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: _orange, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridArea(bool isWide) {
    return Container(
      color: Colors.white,
      child: isWide ? _buildDesktopGrid() : _buildMobileCards(),
    );
  }

  Widget _buildDesktopGrid() {
    if (_activeTabIndex == 0) return _buildTotalBidsDesktop();
    if (_activeTabIndex == 1) return _buildActiveBidsDesktop();
    if (_activeTabIndex == 2) return _buildMembersDesktop();
    return const SizedBox();
  }

  Widget _buildMobileCards() {
    if (_activeTabIndex == 0) return _buildTotalBidsMobile();
    if (_activeTabIndex == 1) return _buildActiveBidsMobile();
    if (_activeTabIndex == 2) return _buildMembersMobile();
    return const SizedBox();
  }

  // --- TAB 1 DESKTOP ---
  Widget _buildTotalBidsDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 60,
        dataRowMaxHeight: 70,
        columns: const [
          DataColumn(label: Text('LOT / VEHICLE', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TOTAL BIDS', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTIVE BID / HIGHEST', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TOP MEMBER', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _totalBids.isEmpty ? [const DataRow(cells: [DataCell(Text('No bids yet')), DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text(''))])] : _totalBids.map((row) {
          return DataRow(
            cells: [
              DataCell(_buildVehicleCell(row['vehicle'], row['lot'], row['img'])),
              DataCell(_buildCountCell(row['bids'], row['trend'], row['trendColor'])),
              DataCell(_buildHighestBidCell(row['highest'], row['secondary'], row['status'], row['statusColor'])),
              DataCell(_buildMemberCell(row['topMember'], row['memberId'], row['avatarColor'])),
              DataCell(_buildActionBtn('View Ledger', () => _showDummyAction('Ledger details coming soon'), outlined: true)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- TAB 2 DESKTOP ---
  Widget _buildActiveBidsDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 60,
        dataRowMaxHeight: 70,
        columns: const [
          DataColumn(label: Text('LIVE LOT VEHICLE', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('REMAINING TIME', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('CURRENT HIGHEST BID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('LEADING BIDDER', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('INSTANT ACTION', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _activeBids.isEmpty ? [const DataRow(cells: [DataCell(Text('No active bids')), DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text(''))])] : _activeBids.map((row) {
          return DataRow(
            cells: [
              DataCell(_buildVehicleCell(row['vehicle'], '', row['img'])),
              DataCell(_buildTimeCell(row['time'], row['timeSub'], row['timeColor'])),
              DataCell(_buildHighestBidCell(row['highest'], row['highestSub'], null, row['highestSubColor'], noSecondary: true)),
              DataCell(_buildMemberCell(row['bidder'], row['bidderId'], row['avatarColor'])),
              DataCell(_buildActionBtn(row['actionText'], () => _showDummyAction('${row['actionText']} details coming soon'), color: row['actionColor'])),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- TAB 3 DESKTOP ---
  Widget _buildMembersDesktop() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 60,
        dataRowMaxHeight: 70,
        columns: const [
          DataColumn(label: Text('MEMBER NAME & ID', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TOTAL BIDS PLACED', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTIVE BIDS WON', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('DEPOSIT STATUS', style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTION', style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: _members.isEmpty ? [const DataRow(cells: [DataCell(Text('No members yet')), DataCell(Text('')), DataCell(Text('')), DataCell(Text('')), DataCell(Text(''))])] : _members.map((row) {
          return DataRow(
            cells: [
              DataCell(_buildMemberFullCell(row['name'], row['badge'], row['badgeColor'], row['id'], row['avatarColor'])),
              DataCell(_buildCountCell(row['bidsPlaced'], row['bidsSub'], Colors.grey.shade600, large: true)),
              DataCell(_buildWonCell(row['won'], row['wonValue'])),
              DataCell(_buildDepositCell(row['deposit'], row['depositSub'])),
              DataCell(_buildActionBtn('Member Ledger', () => _showDummyAction('Member Ledger coming soon'), outlined: true)),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- CELL WIDGETS ---
  Widget _buildVehicleCell(String title, String subtitle, String img) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            img, 
            width: 60, 
            height: 40, 
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 40,
                color: Colors.grey.shade300,
                child: const Icon(Icons.directions_car, color: Colors.grey, size: 24),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
            if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildCountCell(String top, String bottom, Color bottomColor, {bool large = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: large ? 0 : 8, vertical: large ? 0 : 4),
          decoration: large ? null : BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(top, style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: large ? 16 : 14)),
        ),
        const SizedBox(height: 4),
        Text(bottom, style: TextStyle(color: bottomColor, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildHighestBidCell(String main, String sub, String? status, Color statusColor, {bool noSecondary = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Text(main, style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
            if (!noSecondary) ...[
              const SizedBox(width: 4),
              Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ]
          ],
        ),
        if (noSecondary) ...[
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
        if (status != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ]
      ],
    );
  }

  Widget _buildTimeCell(String time, String sub, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
          child: Text(time, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildMemberCell(String name, String id, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 14, backgroundColor: color, child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 12))),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 13)),
                const SizedBox(width: 4),
                const Icon(Icons.verified, color: Colors.blue, size: 12),
              ],
            ),
            Text(id, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildMemberFullCell(String name, String badge, Color badgeColor, String id, Color avatarColor) {
    return Row(
      children: [
        CircleAvatar(radius: 16, backgroundColor: avatarColor, child: Text(name[0], style: const TextStyle(color: Colors.white, fontSize: 14))),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: _navy)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(id, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildWonCell(String won, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Text(won, style: TextStyle(color: _green, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildDepositCell(String status, String sub) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Icon(Icons.check_circle, color: _green, size: 14),
            const SizedBox(width: 4),
            Text(status, style: TextStyle(color: _green, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        Text(sub, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildActionBtn(String text, VoidCallback onTap, {bool outlined = false, Color? color}) {
    if (outlined) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: _navy),
          foregroundColor: _navy,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(text),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? _navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text(text),
    );
  }

  // --- MOBILE CARDS ---
  Widget _buildTotalBidsMobile() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _totalBids.isEmpty ? 1 : _totalBids.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (_totalBids.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No bids yet', style: TextStyle(color: Colors.grey, fontSize: 16))));
        final row = _totalBids[i];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleCell(row['vehicle'], row['lot'], row['img']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCountCell(row['bids'], row['trend'], row['trendColor']),
                  _buildHighestBidCell(row['highest'], row['secondary'], row['status'], row['statusColor']),
                ],
              ),
              const SizedBox(height: 16),
              _buildMemberCell(row['topMember'], row['memberId'], row['avatarColor']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildActionBtn('View Ledger', () => _showDummyAction('Ledger details coming soon'), outlined: true),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveBidsMobile() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _activeBids.isEmpty ? 1 : _activeBids.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (_activeBids.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No active bids', style: TextStyle(color: Colors.grey, fontSize: 16))));
        final row = _activeBids[i];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleCell(row['vehicle'], '', row['img']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildTimeCell(row['time'], row['timeSub'], row['timeColor']),
                  _buildHighestBidCell(row['highest'], row['highestSub'], null, row['highestSubColor'], noSecondary: true),
                ],
              ),
              const SizedBox(height: 16),
              _buildMemberCell(row['bidder'], row['bidderId'], row['avatarColor']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildActionBtn(row['actionText'], () => _showDummyAction('${row['actionText']} coming soon'), color: row['actionColor']),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMembersMobile() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _members.isEmpty ? 1 : _members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        if (_members.isEmpty) return const Padding(padding: EdgeInsets.all(32), child: Center(child: Text('No members yet', style: TextStyle(color: Colors.grey, fontSize: 16))));
        final row = _members[i];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMemberFullCell(row['name'], row['badge'], row['badgeColor'], row['id'], row['avatarColor']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCountCell(row['bidsPlaced'], row['bidsSub'], Colors.grey.shade600, large: true),
                  _buildWonCell(row['won'], row['wonValue']),
                ],
              ),
              const SizedBox(height: 16),
              _buildDepositCell(row['deposit'], row['depositSub']),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _buildActionBtn('Member Ledger', () => _showDummyAction('Member Ledger coming soon'), outlined: true),
              ),
            ],
          ),
        );
      },
    );
  }



  Widget _buildAlertBar() {
    return Container(
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: _orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '4 pending bids require reserve approval',
              style: TextStyle(color: _navy, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              context.push('/admin-approval');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Review (4)'),
          ),
        ],
      ),
    );
  }
}
