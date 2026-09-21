// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides admin endpoints:
// GET /api/admin/clients (Total Clients tab)
// GET /api/admin/active-sessions (Active Logins tab)
// GET /api/admin/audit-logs (Client History tab)
// GET /api/admin/completed-profiles (Profile-Completed tab)

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/admin_app_bar.dart';

class AdminClientsDetailsScreen extends StatefulWidget {
  const AdminClientsDetailsScreen({super.key});

  @override
  State<AdminClientsDetailsScreen> createState() => _AdminClientsDetailsScreenState();
}

class _AdminClientsDetailsScreenState extends State<AdminClientsDetailsScreen> {
  int _activeTabIndex = 0;
  String _searchQuery = '';

  // Dummy data
  final List<Map<String, dynamic>> _dummyClients = [
    {'name': 'Vikram Rathore', 'email': 'vikram@example.com', 'date': '12 Sep 2026', 'status': 'Verified'},
    {'name': 'Priya Sharma', 'email': 'priya.s@example.com', 'date': '10 Sep 2026', 'status': 'Pending'},
    {'name': 'Amit Kumar', 'email': 'amit.k@example.com', 'date': '08 Sep 2026', 'status': 'Verified'},
    {'name': 'Sneha Patel', 'email': 'sneha.p@example.com', 'date': '05 Sep 2026', 'status': 'Verified'},
    {'name': 'Rahul Verma', 'email': 'rahul.v@example.com', 'date': '01 Sep 2026', 'status': 'Pending'},
    {'name': 'Neha Gupta', 'email': 'neha.g@example.com', 'date': '28 Aug 2026', 'status': 'Verified'},
  ];

  final List<Map<String, dynamic>> _dummyLogins = [
    {'name': 'Vikram Rathore', 'region': 'DL-01', 'status': 'Active Now', 'ip': '192.168.1.1', 'id': '45892'},
    {'name': 'Amit Kumar', 'region': 'MH-02', 'status': 'Active 2m ago', 'ip': '192.168.1.5', 'id': '45889'},
    {'name': 'Sneha Patel', 'region': 'GJ-01', 'status': 'Active Now', 'ip': '192.168.1.12', 'id': '45871'},
    {'name': 'Rahul Verma', 'region': 'KA-05', 'status': 'Active 5m ago', 'ip': '192.168.1.20', 'id': '45860'},
  ];

  final List<Map<String, dynamic>> _dummyHistory = [
    {'name': 'Vikram Rathore', 'action': 'updated KYC', 'time': 'Today, 10:30 AM', 'type': 'Success'},
    {'name': 'Priya Sharma', 'action': 'logged in', 'time': 'Today, 09:15 AM', 'type': 'Session'},
    {'name': 'Amit Kumar', 'action': 'placed bid on Audi Q5', 'time': 'Yesterday, 04:20 PM', 'type': 'Success'},
    {'name': 'Rahul Verma', 'action': 'failed login attempt', 'time': 'Yesterday, 11:10 AM', 'type': 'Session'},
    {'name': 'Neha Gupta', 'action': 'completed profile', 'time': '12 Sep, 02:45 PM', 'type': 'Success'},
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 0,
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: const AdminAppBar(),
      body: Column(
        children: [
          _buildSectionHeader(),
          _buildTabsRow(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader() {
    String badgeText = '';
    if (_activeTabIndex == 0) badgeText = '1,428 Total';
    else if (_activeTabIndex == 1) badgeText = '342 Active';
    else if (_activeTabIndex == 2) badgeText = '58 Logs';
    else if (_activeTabIndex == 3) badgeText = '1,210 Complete';

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Text(
            '1. Clients Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001128),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFfb7800),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabButton('1. Total Clients', 0),
          const SizedBox(width: 8),
          _buildTabButton('2. Active Logins', 1),
          const SizedBox(width: 8),
          _buildTabButton('3. Client History', 2),
          const SizedBox(width: 8),
          _buildTabButton('4. Profile-Completed', 3),
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
          _searchQuery = ''; // Reset search on tab change
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF001128) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : const Color(0xFF001128),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const SizedBox(height: 16),
          _buildSearchBar(),
          const SizedBox(height: 16),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    String title = '';
    String badgeText = '';
    Color badgeColor = Colors.grey.shade200;
    Color badgeTextColor = const Color(0xFF001128);

    if (_activeTabIndex == 0) {
      title = 'All Registered Clients';
      badgeText = '1,428 Total';
      badgeColor = const Color(0xFFfb7800);
      badgeTextColor = Colors.white;
    } else if (_activeTabIndex == 1) {
      title = 'Active Logins (342)';
      badgeText = 'Real-time';
    } else if (_activeTabIndex == 2) {
      title = 'Client Activity History';
      badgeText = 'Logs';
    } else if (_activeTabIndex == 3) {
      title = 'Profile-Completed Directory';
      badgeText = '1,210 Complete';
      badgeColor = const Color(0xFFfb7800);
      badgeTextColor = Colors.white;
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF001128),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    String hint = '';
    if (_activeTabIndex == 0) hint = 'Search total clients...';
    else if (_activeTabIndex == 1) hint = 'Search active sessions...';
    else if (_activeTabIndex == 2) hint = 'Search audit logs...';
    else if (_activeTabIndex == 3) hint = 'Search registered profiles...';

    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase();
        });
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: Colors.grey),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_activeTabIndex == 0 || _activeTabIndex == 3) {
      var filtered = _dummyClients.where((c) {
        if (_activeTabIndex == 3 && c['status'] != 'Verified') return false; // simulated profile complete filter
        return c['name'].toLowerCase().contains(_searchQuery) || c['email'].toLowerCase().contains(_searchQuery);
      }).toList();

      if (filtered.isEmpty) return _buildNotFound();

      return ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          var client = filtered[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(client['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001128))),
            subtitle: Text('${client['email']} • Reg: ${client['date']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: client['status'] == 'Verified' ? Colors.blueGrey.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                client['status'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: client['status'] == 'Verified' ? Colors.blueGrey.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          );
        },
      );
    } else if (_activeTabIndex == 1) {
      var filtered = _dummyLogins.where((c) {
        return c['name'].toLowerCase().contains(_searchQuery);
      }).toList();

      if (filtered.isEmpty) return _buildNotFound();

      return ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          var login = filtered[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.circle, color: Colors.green, size: 12),
            title: Text('${login['name']} (${login['region']})', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001128))),
            subtitle: Text('${login['status']} • IP: ${login['ip']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: Text('ID #${login['id']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          );
        },
      );
    } else if (_activeTabIndex == 2) {
      var filtered = _dummyHistory.where((c) {
        return c['name'].toLowerCase().contains(_searchQuery) || c['action'].toLowerCase().contains(_searchQuery);
      }).toList();

      if (filtered.isEmpty) return _buildNotFound();

      return ListView.separated(
        itemCount: filtered.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          var log = filtered[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            title: RichText(
              text: TextSpan(
                style: const TextStyle(color: Color(0xFF001128), fontSize: 14),
                children: [
                  TextSpan(text: '${log['name']} ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: log['action']),
                ],
              ),
            ),
            subtitle: Text('Timestamp: ${log['time']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: log['type'] == 'Success' ? Colors.green.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                log['type'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: log['type'] == 'Success' ? Colors.green.shade700 : Colors.blue.shade700,
                ),
              ),
            ),
          );
        },
      );
    }
    
    return const SizedBox();
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search query',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
