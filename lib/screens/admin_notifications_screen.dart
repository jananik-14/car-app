import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';
import '../services/admin_notification_store.dart';
import 'package:intl/intl.dart'; // Add this for time formatting if needed

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdminNotificationStore().markAllRead();
    });
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'login': return Icons.login;
      case 'bid': return Icons.gavel;
      case 'listing': return Icons.directions_car;
      case 'client': return Icons.person_add;
      case 'subscription': return Icons.subscriptions;
      case 'profile_edit': return Icons.edit;
      case 'payment': return Icons.account_balance_wallet;
      default: return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'login': return const Color(0xFF06B6D4);
      case 'bid': return const Color(0xFFfb7800);
      case 'listing': return const Color(0xFF001128);
      case 'client': return const Color(0xFF3B82F6);
      case 'subscription': return const Color(0xFF8B5CF6);
      case 'profile_edit': return const Color(0xFF64748B);
      case 'payment': return const Color(0xFF22C55E);
      default: return Colors.grey;
    }
  }

  void _onNotificationTap(AdminNotificationItem notification) {
    switch (notification.type) {
      case 'login':
      case 'client':
      case 'profile_edit':
        context.push('/admin');
        break;
      case 'bid':
        final bidId = notification.relatedItemId;
        final bidQuery = bidId != null ? '?category=bidding&highlightId=$bidId' : '?category=bidding';
        context.push('/admin-approval$bidQuery');
        break;
      case 'listing':
        final listId = notification.relatedItemId;
        final listQuery = listId != null ? '?category=vehiclePosts&highlightId=$listId' : '?category=vehiclePosts';
        context.push('/admin-approval$listQuery');
        break;
      case 'subscription':
        final subId = notification.relatedItemId;
        final subQuery = subId != null ? '?category=subscriptions&highlightId=$subId' : '?category=subscriptions';
        context.push('/admin-approval$subQuery');
        break;
      case 'payment':
        final payId = notification.relatedItemId;
        final payQuery = payId != null ? '?category=payments&highlightId=$payId' : '?category=payments';
        context.push('/admin-approval$payQuery');
        break;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 4, // Alerts tab index
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: AdminAppBar(
        actions: [
          ListenableBuilder(
            listenable: AdminNotificationStore(),
            builder: (context, _) {
              int unreadCount = AdminNotificationStore().unreadCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: _navy),
                    onPressed: () {},
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _orange,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
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
        listenable: AdminNotificationStore(),
        builder: (context, _) {
          final notifications = AdminNotificationStore().notifications;
          // Unread count is zero because we mark all read in initState, but let's calculate anyway if it updates
          int unreadCount = AdminNotificationStore().unreadCount;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(unreadCount),
              Expanded(child: _buildListContent(notifications)),
            ],
          );
        },
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

  Widget _buildListContent(List<AdminNotificationItem> notifications) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.separated(
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFEEEEEE)),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          final color = _colorForType(notification.type);
          
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Icon(_iconForType(notification.type), color: color),
            ),
            title: Text(
              notification.title,
              style: TextStyle(
                fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                color: _navy,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                _formatTime(notification.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
              ),
            ),
            trailing: !notification.isRead
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
              _onNotificationTap(notification);
            },
          );
        },
      ),
    );
  }
}
