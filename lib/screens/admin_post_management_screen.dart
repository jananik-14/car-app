// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides:
// GET /api/admin/vehicles?status=all|pending|sold
// GET /api/admin/vehicles/stats (for TOTAL REG./UNSOLD-PEND./BOUGHT counts)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';

class AdminPostManagementScreen extends StatefulWidget {
  const AdminPostManagementScreen({super.key});

  @override
  State<AdminPostManagementScreen> createState() => _AdminPostManagementScreenState();
}

class _AdminPostManagementScreenState extends State<AdminPostManagementScreen> {
  int _activeTabIndex = 0;
  String _searchQuery = '';

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _green = const Color(0xFF22C55E);
  final Color _amber = Colors.amber.shade700;
  final Color _blue = Colors.blue.shade600;

  final List<Map<String, dynamic>> _dummyVehicles = [
    {
      'title': '2024 Mercedes-Benz C300',
      'status': 'Sold',
      'sellerName': 'Kunal Desai',
      'buyerName': 'Rajesh Sharma',
      'price': '₹48.70 L',
      'regNo': 'MH-01-BK-9988',
      'regDate': '12 Sep 2026',
      'imageUrl': 'https://images.unsplash.com/photo-1618843479313-40f8afb4b4d8?auto=format&fit=crop&w=300&q=80'
    },
    {
      'title': '2022 Audi Q5 45 TFSI',
      'status': 'Pending',
      'sellerName': 'Priya Singh',
      'price': '₹42.50 L',
      'regNo': 'DL-10-CD-1122',
      'regDate': '10 Sep 2026',
      'imageUrl': 'https://images.unsplash.com/photo-1606664515524-ed2f786a0bd6?auto=format&fit=crop&w=300&q=80'
    },
    {
      'title': '2023 Tata Harrier Dark',
      'status': 'Available',
      'sellerName': 'Amit Kumar',
      'price': '₹19.20 L',
      'regNo': 'MH-12-PQ-5544',
      'regDate': '08 Sep 2026',
      'imageUrl': 'https://images.unsplash.com/photo-1650392338271-9c60e3cc6c13?auto=format&fit=crop&w=300&q=80'
    },
    {
      'title': '2021 BMW X3 xDrive30i',
      'status': 'Sold',
      'sellerName': 'Rahul Verma',
      'buyerName': 'Sneha Patel',
      'price': '₹55.00 L',
      'regNo': 'KA-05-XY-8877',
      'regDate': '05 Sep 2026',
      'imageUrl': 'https://images.unsplash.com/photo-1555215695-3004980ad54e?auto=format&fit=crop&w=300&q=80'
    },
    {
      'title': '2022 Hyundai Creta SX(O)',
      'status': 'Pending',
      'sellerName': 'Neha Gupta',
      'price': '₹16.80 L',
      'regNo': 'UP-16-AB-3322',
      'regDate': '01 Sep 2026',
      'imageUrl': 'https://images.unsplash.com/photo-1620025792945-31ce1d94fc8b?auto=format&fit=crop&w=300&q=80'
    },
    {
      'title': '2020 Maruti Suzuki Swift ZXi',
      'status': 'Available',
      'sellerName': 'Vikram Rathore',
      'price': '₹6.50 L',
      'regNo': 'RJ-14-EF-9911',
      'regDate': '28 Aug 2026',
      'imageUrl': 'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&w=300&q=80'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 1, // Posts tab index
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: AdminAppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: _navy),
            onPressed: () => context.push('/admin/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.search, color: _navy),
            onPressed: () {},
          ),
          Container(
            margin: const EdgeInsets.only(right: 16, left: 8),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _navy,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'AD',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildStatsCards(),
          _buildTabs(),
          _buildSearchBar(),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        'Post Details',
        style: TextStyle(
          color: _navy,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('TOTAL REG.', '1,428', _navy)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('UNSOLD / PEND.', '312', _orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('BOUGHT', '1,116', _green)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          _buildTabButton('1. Total Vehicles', 0),
          const SizedBox(width: 8),
          _buildTabButton('2. Pending', 1),
          const SizedBox(width: 8),
          _buildTabButton('3. Bought', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeTabIndex = index;
          _searchQuery = '';
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _navy : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search by title, VIN, reg no, buyer or seller...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: const Icon(Icons.tune, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildListContent() {
    List<Map<String, dynamic>> filtered = _dummyVehicles.where((c) {
      if (_activeTabIndex == 1 && c['status'] != 'Pending') return false;
      if (_activeTabIndex == 2 && c['status'] != 'Sold') return false;
      
      String searchStr = "${c['title']} ${c['regNo']} ${c['sellerName']} ${c['buyerName'] ?? ''}".toLowerCase();
      return searchStr.contains(_searchQuery);
    }).toList();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildListHeader(),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            _buildNotFound()
          else
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
                itemBuilder: (context, index) => _buildVehicleCard(filtered[index]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListHeader() {
    String title = '';
    String badgeText = '';
    Color badgeColor = Colors.grey.shade200;
    Color badgeTextColor = _navy;

    if (_activeTabIndex == 0) {
      return const SizedBox.shrink(); // No header row for Total Vehicles tab, per requirements
    } else if (_activeTabIndex == 1) {
      // NOTE: 312 is the "real" count simulated, but we only have a small dummy list.
      title = '312 Pending Vehicles';
      badgeText = 'Pending Not Sold';
      badgeColor = _amber.withOpacity(0.15);
      badgeTextColor = _amber;
    } else if (_activeTabIndex == 2) {
      title = '1,116 Bought Vehicles';
      badgeText = 'Escrow Transferred';
      badgeColor = _green.withOpacity(0.15);
      badgeTextColor = _green;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: badgeTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> item) {
    Color statusColor = _navy;
    if (item['status'] == 'Sold') statusColor = _green;
    else if (item['status'] == 'Pending') statusColor = _amber;
    else if (item['status'] == 'Available') statusColor = _blue;

    bool isBoughtTab = _activeTabIndex == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
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
                child: const Icon(Icons.car_crash),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item['title'],
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        item['status'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isBoughtTab ? 'Buyer: ${item['buyerName'] ?? 'Unknown'}' : 'Seller: ${item['sellerName']}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      item['price'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['regNo'],
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reg: ${item['regDate']}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Vehicle details coming soon')),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'View Details',
                            style: TextStyle(
                              color: _orange,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.chevron_right, color: _orange, size: 16),
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
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
