import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/client_notification_store.dart';
class AppSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isAdmin;

  const AppSidebar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
    this.isAdmin = false,
  });

  static const _items = [
    (icon: Icons.directions_car, label: 'Live Auctions'),
    (icon: Icons.favorite_border, label: 'Watchlist'),
    (icon: Icons.add_circle_outline, label: 'Post/Sell'),
    (icon: Icons.notifications_none, label: 'Alerts'),
    (icon: Icons.person_outline, label: 'Profile'),
  ];

  static const _adminItems = [
    (icon: Icons.people_outline, label: 'Clients'),
    (icon: Icons.post_add, label: 'Posts'),
    (icon: Icons.gavel, label: 'Bidding'),
    (icon: Icons.verified_outlined, label: 'Approvals'),
    (icon: Icons.notifications_outlined, label: 'Alerts'),
    (icon: Icons.swap_horiz, label: 'Client App'),
  ];

  @override
  Widget build(BuildContext context) {
    final items = isAdmin ? _adminItems : _items;

    return ListenableBuilder(
      listenable: ClientNotificationStore(),
      builder: (context, child) {
        final unreadCount = ClientNotificationStore().unreadCountFor(AuthService().currentPhone ?? '');
        return Container(
          width: 180,
          color: Colors.white,
          child: Column(
            children: [
          const SizedBox(height: 20),
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              'assets/images/logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Wheels2Drive',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Color(0xFF001128),
            ),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE), indent: 12, endIndent: 12),
          const SizedBox(height: 12),
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: InkWell(
                onTap: () => onDestinationSelected(i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: currentIndex == i
                        ? const Color(0xFFfb7800)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (!isAdmin && i == 3 && unreadCount > 0)
                        Badge(
                          label: Text('$unreadCount'),
                          child: Icon(
                            items[i].icon,
                            color: currentIndex == i
                                ? Colors.white
                                : const Color(0xFF001128),
                            size: 22,
                          ),
                        )
                      else
                        Icon(
                          items[i].icon,
                          color: currentIndex == i
                              ? Colors.white
                              : const Color(0xFF001128),
                          size: 22,
                        ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: currentIndex == i
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: currentIndex == i
                              ? Colors.white
                              : const Color(0xFF001128),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
      }
    );
  }
}
