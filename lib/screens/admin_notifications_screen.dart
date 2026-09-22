// TODO: TEMPORARY DUMMY DATA — Replace with real API calls once backend provides:
// GET /api/admin/notifications
// PATCH /api/admin/notifications/:id/read

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';

class AdminNotificationsScreen extends StatelessWidget {
  const AdminNotificationsScreen({super.key});

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);

  static final List<Map<String, dynamic>> _dummyNotifications = [
    {
      'id': 'n1',
      'type': 'bid',
      'icon': Icons.gavel,
      'color': const Color(0xFFfb7800),
      'message': 'New bid placed: ₹48,50,000 on 2022 BMW 530i by Marcus Vance',
      'time': '5 mins ago',
      'isRead': false,
      'route': '/admin/bidding',
    },
    {
      'id': 'n2',
      'type': 'listing',
      'icon': Icons.directions_car,
      'color': const Color(0xFF001128),
      'message': 'New listing submitted: 2023 Tesla Model Y by Ravi Sharma — awaiting approval',
      'time': '20 mins ago',
      'isRead': false,
      'route': '/admin-approval',
    },
    {
      'id': 'n3',
      'type': 'client',
      'icon': Icons.person_add,
      'color': Colors.blue,
      'message': 'New client registered: Priya Sundaram',
      'time': '1 hour ago',
      'isRead': false,
      'route': '/admin',
    },
    {
      'id': 'n4',
      'type': 'subscription',
      'icon': Icons.subscriptions,
      'color': Colors.purple,
      'message': 'New subscription request: Apex Motors Ltd (Pro Trader plan)',
      'time': '2 hours ago',
      'isRead': false,
      'route': '/admin-approval',
    },
    {
      'id': 'n5',
      'type': 'payment',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'message': 'Escrow payment confirmed: ₹48.70L for 2024 Mercedes-Benz C300',
      'time': '3 hours ago',
      'isRead': false,
      'route': '/admin/post-management',
    },
    {
      'id': 'n6',
      'type': 'bid',
      'icon': Icons.gavel,
      'color': const Color(0xFFfb7800),
      'message': 'New bid placed: ₹16,20,000 on 2021 Hyundai Creta by Neha Gupta',
      'time': '5 hours ago',
      'isRead': true,
      'route': '/admin/bidding',
    },
    {
      'id': 'n7',
      'type': 'listing',
      'icon': Icons.directions_car,
      'color': const Color(0xFF001128),
      'message': 'New listing submitted: 2019 Maruti Swift ZDi by Karan Mehta',
      'time': '1 day ago',
      'isRead': true,
      'route': '/admin-approval',
    },
  ];

  @override
  Widget build(BuildContext context) {
    int unreadCount = _dummyNotifications.where((n) => !n['isRead']).length;

    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 4, // Alerts tab index
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: AdminAppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: _navy),
            onPressed: () {},
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
          _buildHeader(unreadCount),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildHeader(int unreadCount) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Text(
            'Admin Notifications',
            style: TextStyle(
              color: _navy,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount Unread',
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

  Widget _buildListContent() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        itemCount: _dummyNotifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final notification = _dummyNotifications[index];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: (notification['color'] as Color).withOpacity(0.1),
              child: Icon(notification['icon'], color: notification['color']),
            ),
            title: Text(
              notification['message'],
              style: TextStyle(
                fontWeight: notification['isRead'] ? FontWeight.normal : FontWeight.bold,
                color: _navy,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                notification['time'],
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            trailing: !notification['isRead']
                ? Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _orange,
                      shape: BoxShape.circle,
                    ),
                  )
                : null,
            onTap: () {
              context.push(notification['route']);
            },
          );
        },
      ),
    );
  }
}
