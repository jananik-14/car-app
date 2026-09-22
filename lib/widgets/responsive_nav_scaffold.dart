import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/admin_navigation_helper.dart';
import '../utils/responsive_helper.dart';
import '../widgets/shared_bottom_nav.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../widgets/app_sidebar.dart';

class ResponsiveNavScaffold extends StatelessWidget {
  final int currentIndex;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  final bool isAdmin;
  final Widget? drawer;

  const ResponsiveNavScaffold({
    super.key,
    required this.currentIndex,
    required this.body,
    this.appBar,
    this.backgroundColor,
    this.isAdmin = false,
    this.drawer,
  });

  void _onDestinationSelected(BuildContext context, int index) async {
    if (index == currentIndex) return;

    if (isAdmin) {
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
        if (AuthService.currentUserRole == 'admin') {
          context.go('/admin');
        } else {
          context.go('/subscription');
        }
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktopOrTablet = ResponsiveHelper.isDesktop(context) ||
        ResponsiveHelper.isTablet(context);

    if (isDesktopOrTablet) {
      return Scaffold(
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.surface,
        drawer: drawer,
        body: Row(
          children: [
            AppSidebar(
              currentIndex: currentIndex,
              isAdmin: isAdmin,
              onDestinationSelected: (index) =>
                  _onDestinationSelected(context, index),
            ),
            Expanded(
              child: Column(
                children: [
                  if (appBar != null) appBar!,
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: appBar,
        backgroundColor:
            backgroundColor ?? Theme.of(context).colorScheme.surface,
        drawer: drawer,
        body: body,
        bottomNavigationBar:
            isAdmin ? null : SharedBottomNav(currentIndex: currentIndex),
      );
    }
  }
}
