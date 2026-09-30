import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/client_notification_store.dart';
class SharedBottomNav extends StatelessWidget {
  final int currentIndex;

  const SharedBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ClientNotificationStore(),
      builder: (context, child) {
        final unreadCount = ClientNotificationStore().unreadCountFor(AuthService().currentPhone ?? '');
        return BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == currentIndex) return;
            switch (index) {
              case 0:
                context.go('/browse');
                break;
              case 1:
                context.go('/watchlist');
                break;
              case 2:
                context.go('/post_vehicle');
                break;
              case 3:
                context.go('/notifications');
                break;
              case 4:
                if (AuthService.currentUserRole == 'admin') {
                  context.go('/admin');
                } else {
                  context.go('/subscription');
                }
                break;
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceContainerLowest,
          selectedItemColor: AppColors.secondaryContainer,
          unselectedItemColor: AppColors.outline,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.directions_car),
              label: 'Live Auctions',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.favorite_border),
              activeIcon: Icon(Icons.favorite),
              label: 'Watchlist',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              label: 'Post/Sell',
            ),
            BottomNavigationBarItem(
              icon: unreadCount > 0 
                  ? Badge(
                      label: Text('$unreadCount'),
                      child: const Icon(Icons.notifications_none),
                    )
                  : const Icon(Icons.notifications_none),
              activeIcon: unreadCount > 0 
                  ? Badge(
                      label: Text('$unreadCount'),
                      child: const Icon(Icons.notifications),
                    )
                  : const Icon(Icons.notifications),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        );
      }
    );
  }
}
