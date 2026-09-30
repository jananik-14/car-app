// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides admin endpoints:
// GET /api/admin/clients (Total Clients tab)
// GET /api/admin/active-sessions (Active Logins tab)
// GET /api/admin/audit-logs (Client History tab)
// GET /api/admin/completed-profiles (Profile-Completed tab)

import 'package:flutter/material.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/admin_app_bar.dart';
import '../services/admin_clients_store.dart';

class AdminClientsDetailsScreen extends StatefulWidget {
  const AdminClientsDetailsScreen({super.key});

  @override
  State<AdminClientsDetailsScreen> createState() => _AdminClientsDetailsScreenState();
}

class _AdminClientsDetailsScreenState extends State<AdminClientsDetailsScreen> {
  int _activeTabIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 0,
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: const AdminAppBar(),
      body: ListenableBuilder(
        listenable: AdminClientsStore(),
        builder: (context, _) {
          return Column(
            children: [
              _buildSectionHeader(),
              _buildTabsRow(),
              Expanded(
                child: _buildTabContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    final store = AdminClientsStore();
    String badgeText = '';
    if (_activeTabIndex == 0) badgeText = '${store.clients.length} Total';
    else if (_activeTabIndex == 1) badgeText = '${store.activeLogins.length} Active';
    else if (_activeTabIndex == 2) badgeText = '${store.history.length} Logs';
    else if (_activeTabIndex == 3) badgeText = '${store.clients.where((c) => c['status'] == 'Verified').length} Complete';

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

    final store = AdminClientsStore();
    if (_activeTabIndex == 0) {
      title = 'All Registered Clients';
      badgeText = '${store.clients.length} Total';
      badgeColor = const Color(0xFFfb7800);
      badgeTextColor = Colors.white;
    } else if (_activeTabIndex == 1) {
      title = 'Active Logins (${store.activeLogins.length})';
      badgeText = 'Real-time';
    } else if (_activeTabIndex == 2) {
      title = 'Client Activity History';
      badgeText = 'Logs';
    } else if (_activeTabIndex == 3) {
      title = 'Profile-Completed Directory';
      badgeText = '${store.clients.where((c) => c['status'] == 'Verified').length} Complete';
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
    final store = AdminClientsStore();
    if (_activeTabIndex == 0 || _activeTabIndex == 3) {
      var filtered = store.clients.where((c) {
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
      var filtered = store.activeLogins.where((c) {
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
      var filtered = store.history.where((c) {
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
