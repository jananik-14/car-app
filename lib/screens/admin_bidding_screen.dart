// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides:
// GET /api/admin/bidding/stats (Total Bids/Active Bids/Members counts)
// GET /api/admin/bidding/lots (Total Bids tab data)
// GET /api/admin/bidding/live (Active Bids tab data)
// GET /api/admin/bidding/members (Members tab data)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';

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

  // --- Dummy Data ---
  final List<Map<String, dynamic>> _totalBids = [
    {
      'vehicle': '2023 Tesla Model Y',
      'lot': '#LOT-4410 • Long Range AWD',
      'img': 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=100&q=80',
      'bids': '24 bids',
      'trend': '+4 last hr',
      'trendColor': Colors.green,
      'highest': '₹40.25 Lakh',
      'secondary': '(\$48,500)',
      'status': 'Live Lot',
      'statusColor': Colors.green,
      'topMember': 'Rahul V.',
      'memberId': '#MB-104',
      'avatarColor': Colors.blue,
    },
    {
      'vehicle': '1998 Porsche 911 Carrera',
      'lot': '#LOT-4411 • Classic',
      'img': 'https://images.unsplash.com/photo-1542282088-fe8426682b8f?auto=format&fit=crop&w=100&q=80',
      'bids': '56 bids',
      'trend': 'Hot Lot',
      'trendColor': Colors.red,
      'highest': '₹82.50 Lakh',
      'secondary': '(\$98,200)',
      'status': 'Ending (14m)',
      'statusColor': Colors.orange,
      'topMember': 'Alex T.',
      'memberId': '#MB-082',
      'avatarColor': Colors.purple,
    },
    {
      'vehicle': '2022 Audi Q5 Prestige',
      'lot': '#LOT-4412 • SUV',
      'img': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?auto=format&fit=crop&w=100&q=80',
      'bids': '12 bids',
      'trend': 'Steady',
      'trendColor': Colors.grey,
      'highest': '₹42.00 Lakh',
      'secondary': '(\$50,000)',
      'status': 'Active (2h left)',
      'statusColor': Colors.blue,
      'topMember': 'Sarah V8',
      'memberId': '#MB-219',
      'avatarColor': Colors.orange,
    },
    {
      'vehicle': '2022 Ferrari F8 Tributo',
      'lot': '#LOT-4413 • Exotic',
      'img': 'https://images.unsplash.com/photo-1583121274602-3e2820c69888?auto=format&fit=crop&w=100&q=80',
      'bids': '8 bids',
      'trend': 'Top Tier',
      'trendColor': const Color(0xFFfb7800),
      'highest': '₹3.50 Cr',
      'secondary': '(\$420,000)',
      'status': 'Reserve Met',
      'statusColor': Colors.purple,
      'topMember': 'Vikram R.',
      'memberId': '#MB-005',
      'avatarColor': Colors.red,
    },
  ];

  final List<Map<String, dynamic>> _activeBids = [
    {
      'vehicle': '1998 Porsche 911 Carrera',
      'img': 'https://images.unsplash.com/photo-1542282088-fe8426682b8f?auto=format&fit=crop&w=100&q=80',
      'time': '00:14:22',
      'timeColor': Colors.red,
      'timeSub': 'Urgent: Final Bidding Phase',
      'highest': '\$89,200',
      'highestSub': 'Increment: +\$1,000',
      'highestSubColor': Colors.grey,
      'bidder': 'Alex T.',
      'bidderId': '#MB-082 • Delhi',
      'avatarColor': Colors.purple,
      'actionText': 'Accept/Close',
      'actionColor': const Color(0xFFfb7800),
    },
    {
      'vehicle': '2023 Tesla Model Y',
      'img': 'https://images.unsplash.com/photo-1560958089-b8a1929cea89?auto=format&fit=crop&w=100&q=80',
      'time': '01:45:08',
      'timeColor': Colors.blue,
      'timeSub': '24 bids placed',
      'highest': '\$48,500',
      'highestSub': 'Reserve Met',
      'highestSubColor': Colors.green,
      'bidder': 'Rahul V.',
      'bidderId': '#MB-104 • Mumbai',
      'avatarColor': Colors.blue,
      'actionText': 'Monitor Live',
      'actionColor': const Color(0xFF001128),
    },
    {
      'vehicle': '2022 Audi Q5 Prestige',
      'img': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?auto=format&fit=crop&w=100&q=80',
      'time': '02:15:30',
      'timeColor': Colors.blue,
      'timeSub': '12 bids placed',
      'highest': '\$50,000',
      'highestSub': 'Starting: \$42,000',
      'highestSubColor': Colors.grey,
      'bidder': 'Sarah V8',
      'bidderId': '#MB-219 • Pune',
      'avatarColor': Colors.orange,
      'actionText': 'Monitor Live',
      'actionColor': const Color(0xFF001128),
    },
  ];

  final List<Map<String, dynamic>> _members = [
    {
      'name': 'Alex Turbo',
      'badge': 'Tier 1 Dealer',
      'badgeColor': Colors.grey,
      'id': '#MB-082 • alex.t@speedcars.in',
      'bidsPlaced': '342',
      'bidsSub': 'across 45 lots',
      'won': '24 Won',
      'wonValue': '₹6.5 Cr Value',
      'deposit': 'Verified ₹50 Lakhs',
      'depositSub': 'VIP Guarantee',
      'avatarColor': Colors.purple,
    },
    {
      'name': 'Sarah V8',
      'badge': 'VIP Collector',
      'badgeColor': Colors.purple,
      'id': '#MB-219 • sarah@v8collect.com',
      'bidsPlaced': '142',
      'bidsSub': 'across 19 lots',
      'won': '8 Won',
      'wonValue': '₹2.1 Cr Value',
      'deposit': 'Verified ₹15 Lakhs',
      'depositSub': 'Escrow Active',
      'avatarColor': Colors.orange,
    },
    {
      'name': 'Rahul Verma',
      'badge': 'Verified Buyer',
      'badgeColor': Colors.blue,
      'id': '#MB-104 • rahul.v@mail.com',
      'bidsPlaced': '56',
      'bidsSub': 'across 12 lots',
      'won': '3 Won',
      'wonValue': '₹85 L Value',
      'deposit': 'Verified ₹5 Lakhs',
      'depositSub': 'Standard Deposit',
      'avatarColor': Colors.blue,
    },
  ];

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
      body: Column(
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
                _buildPagination(),
              ],
            ),
          ),
          _buildAlertBar(),
        ],
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
    List<Widget> cards = [
      _buildStatCard('TOTAL BIDS', '1,842', _navy, Icons.diamond_outlined),
      _buildStatCard('ACTIVE BIDS', '142', _orange, Icons.gavel, subtitle: '14 mins avg left', subtitleIcon: Icons.access_time),
      _buildStatCard('MEMBERS', '890', _navy, Icons.people_outline),
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
            _buildTab('Active Bids (142)', 1),
            const SizedBox(width: 8),
            _buildTab('Members (890)', 2),
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
          const SizedBox(width: 8),
          Text('Scroll horizontally →', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
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
        rows: _totalBids.map((row) {
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
        rows: _activeBids.map((row) {
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
        rows: _members.map((row) {
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
          child: Image.network(img, width: 60, height: 40, fit: BoxFit.cover),
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
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
                  decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
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
          decoration: BoxDecoration(color: _green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
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
      itemCount: _totalBids.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
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
      itemCount: _activeBids.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
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
      itemCount: _members.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
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

  Widget _buildPagination() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing 1-4 of 142 Active Bids',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          Row(
            children: [
              Icon(Icons.chevron_left, color: Colors.grey.shade400),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: _navy, borderRadius: BorderRadius.circular(4)),
                child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: _navy),
            ],
          )
        ],
      ),
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
