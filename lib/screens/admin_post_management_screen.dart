// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides:
// GET /api/admin/vehicles?status=all|pending|sold
// GET /api/admin/vehicles/stats (for TOTAL REG./UNSOLD-PEND./BOUGHT counts)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../widgets/listing_image.dart';
import '../utils/local_listings_store.dart';

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

  String _formatPrice(dynamic amount) {
    if (amount == null) return 'N/A';
    if (amount is num) {
      return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
    }
    return amount.toString();
  }
  final Color _green = const Color(0xFF22C55E);
  final Color _amber = Colors.amber.shade700;
  final Color _blue = Colors.blue.shade600;

  List<Map<String, dynamic>> _getAllVehicles() {
    final store = LocalListingsStore();
    List<Map<String, dynamic>> list = [];
    for (var v in store.pendingListings) {
      list.add({...v, 'uiStatus': 'Pending'});
    }
    for (var v in store.acceptedListings) {
      String st = (v['status'] ?? '').toString().toLowerCase();
      String uiStatus = 'Available';
      if (st == 'sold' || st == 'bought') uiStatus = 'Sold';
      else if (st == 'pending') uiStatus = 'Pending';
      list.add({...v, 'uiStatus': uiStatus});
    }
    return list;
  }

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
      body: ListenableBuilder(
        listenable: LocalListingsStore(),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildStatsCards(),
              _buildTabs(),
              _buildSearchBar(),
              Expanded(child: _buildListContent()),
            ],
          );
        }
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
    final all = _getAllVehicles();
    final total = all.length;
    final pend = all.where((v) => v['uiStatus'] == 'Pending').length;
    final bought = all.where((v) => v['uiStatus'] == 'Sold').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('TOTAL REG.', '$total', _navy)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('UNSOLD / PEND.', '$pend', _orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('BOUGHT', '$bought', _green)),
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
    final allVehicles = _getAllVehicles();
    List<Map<String, dynamic>> filtered = allVehicles.where((c) {
      if (_activeTabIndex == 1 && c['uiStatus'] != 'Pending') return false;
      if (_activeTabIndex == 2 && c['uiStatus'] != 'Sold') return false;
      
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
          _buildListHeader(filtered.length),
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

  Widget _buildListHeader(int currentCount) {
    String title = '';
    String badgeText = '';
    Color badgeColor = Colors.grey.shade200;
    Color badgeTextColor = _navy;

    if (_activeTabIndex == 0) {
      return const SizedBox.shrink(); // No header row for Total Vehicles tab, per requirements
    } else if (_activeTabIndex == 1) {
      title = '$currentCount Pending Vehicles';
      badgeText = 'Pending Not Sold';
      badgeColor = _amber.withValues(alpha: 0.15);
      badgeTextColor = _amber;
    } else if (_activeTabIndex == 2) {
      title = '$currentCount Bought Vehicles';
      badgeText = 'Escrow Transferred';
      badgeColor = _green.withValues(alpha: 0.15);
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
    if (item['uiStatus'] == 'Sold') {
      statusColor = _green;
    } else if (item['uiStatus'] == 'Pending') statusColor = _amber;
    else if (item['uiStatus'] == 'Available') statusColor = _blue;

    bool isBoughtTab = _activeTabIndex == 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: ListingImage(
              listing: item,
              height: 80,
              width: 80,
              fit: BoxFit.cover,
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
                        item['title'] ?? 'Vehicle Title',
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
                        item['uiStatus'] ?? item['status'] ?? 'Available',
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
                  isBoughtTab ? 'Buyer: ${item['buyerName'] ?? 'Unknown Buyer'}' : 'Seller: ${item['sellerName'] ?? 'Unknown Seller'}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _formatPrice(item['price']),
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
                        item['regNo'] ?? item['stateCode'] ?? 'Unknown Reg',
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
                      'Reg: ${item['regDate'] ?? 'Unknown Date'}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if ((item['status'] ?? '').toString().toLowerCase() == 'live') ...[
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () {
                              try {
                                final String itemId = (item['id'] ?? '').toString();
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
                            child: const Text('End auction now (test)', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 4),
                        ],
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
