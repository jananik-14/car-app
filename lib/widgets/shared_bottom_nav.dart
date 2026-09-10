import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class SharedBottomNav extends StatelessWidget {
  final int currentIndex;

  const SharedBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            context.go('/browse');
            break;
          case 1:
            context.push('/post_vehicle');
            break;
          case 2:
            context.go('/notifications');
            break;
          case 3:
            context.go('/subscription');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surfaceContainerLowest,
      selectedItemColor: AppColors.secondaryContainer,
      unselectedItemColor: AppColors.outline,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Browse',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle_outline),
          label: 'Post/Sell',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          activeIcon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
