import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/admin_navigation_helper.dart';
import '../utils/responsive_helper.dart';
import '../widgets/app_sidebar.dart';
import '../services/auth_service.dart';

class ResponsiveSecondaryScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;

  const ResponsiveSecondaryScaffold({
    super.key,
    required this.currentIndex,
    required this.child,
    this.appBar,
    this.backgroundColor,
    this.bottomNavigationBar,
  });

  void _onDestinationSelected(BuildContext context, int index) async {
    if (index == currentIndex) return;

    if (AuthService.currentUserRole == 'admin') {
      switch (index) {
        case 0:
          context.go('/admin');
          break;
        case 1:
          context.push('/admin/post-management');
          break;
        case 2:
          context.push('/admin/bidding');
          break;
        case 3:
          context.push('/admin-approval');
          break;
        case 4:
          context.push('/admin/notifications');
          break;
        case 5:
          await AdminNavigationHelper.confirmAndSwitchToClient(context);
          break;
      }
      return;
    }

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
        context.go('/subscription');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveHelper.isDesktop(context) || ResponsiveHelper.isTablet(context)) {
      return Scaffold(
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
        body: Row(
          children: [
            AppSidebar(
              currentIndex: currentIndex,
              isAdmin: AuthService.currentUserRole == 'admin',
              onDestinationSelected: (index) => _onDestinationSelected(context, index),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        if (appBar != null) appBar!,
                        child,
                        if (bottomNavigationBar != null) bottomNavigationBar!,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
        appBar: appBar,
        body: child,
        bottomNavigationBar: bottomNavigationBar,
      );
    }
  }
}
