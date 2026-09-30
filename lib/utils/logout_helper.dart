import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

Future<void> confirmAndLogout(BuildContext context) async {
  print('LOGOUT DEBUG: menu tapped');
  final router = GoRouter.of(context);          // capture BEFORE any await
  print('LOGOUT DEBUG: dialog shown');
  final confirm = await showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Logout'),
      content: const Text('Are you sure you want to logout?'),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
      ],
    ),
  );
  if (confirm == true) {
    print('LOGOUT DEBUG: confirmed, context.mounted=${context.mounted}');
    await AuthService().logout();
    print('LOGOUT DEBUG: navigating to login');
    router.go('/login');                         // use the router captured earlier, not context
  }
}
