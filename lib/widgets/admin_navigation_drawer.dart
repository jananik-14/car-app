import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/admin_navigation_helper.dart';
import '../utils/logout_helper.dart';

class AdminNavigationDrawer extends StatelessWidget {
  const AdminNavigationDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 24,
              left: 24,
              right: 16,
              bottom: 24,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Admin Navigation',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001128),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFF001128)),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildNavItem(
                  context,
                  icon: Icons.people_outline,
                  label: '1. Clients Details',
                  badgeText: 'Active',
                  badgeColor: Colors.grey.shade200,
                  badgeTextColor: const Color(0xFF001128),
                  onTap: () {
                    Navigator.pop(context);
                    context.go('/admin');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.post_add,
                  label: '2. Post Management',
                  badgeText: '12 New',
                  badgeColor: const Color(0xFFfb7800),
                  badgeTextColor: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/post-management');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.gavel,
                  label: '3. Bidding & Bidders',
                  badgeText: 'Live',
                  badgeColor: Colors.grey.shade200,
                  badgeTextColor: const Color(0xFF001128),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/bidding');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.verified_outlined,
                  label: '4. Approvals Queue',
                  badgeText: '2 Pending',
                  badgeColor: Colors.red.shade700,
                  badgeTextColor: Colors.white,
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin-approval');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.notifications_outlined,
                  label: '5. Notifications & Alerts',
                  badgeText: '5 Unread',
                  badgeColor: Colors.grey.shade200,
                  badgeTextColor: const Color(0xFF001128),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/notifications');
                  },
                ),
                _buildNavItem(
                  context,
                  icon: Icons.swap_horiz,
                  label: '6. Switch to Client Dashboard',
                  onTap: () async {
                    Navigator.pop(context);
                    await AdminNavigationHelper.confirmAndSwitchToClient(context);
                  },
                  showChevron: true,
                ),
                _buildNavItem(
                  context,
                  icon: Icons.logout,
                  label: '7. Logout',
                  onTap: () {
                    Navigator.pop(context);
                    confirmAndLogout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    String? badgeText,
    Color? badgeColor,
    Color? badgeTextColor,
    bool showChevron = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          leading: Icon(icon, color: const Color(0xFF001128)),
          title: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF001128),
            ),
          ),
          trailing: badgeText != null
              ? Container(
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
                )
              : (showChevron ? const Icon(Icons.chevron_right, color: Color(0xFF001128)) : null),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Color(0xFFEEEEEE)),
      ],
    );
  }
}
