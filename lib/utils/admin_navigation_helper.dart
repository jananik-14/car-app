import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminNavigationHelper {
  static Future<void> confirmAndSwitchToClient(BuildContext context) async {
    final router = GoRouter.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Switch to Client Account?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001128))),
        content: const Text('You will leave the Admin Dashboard and view the app as a regular customer. You can switch back anytime.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFfb7800)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Switch', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      router.go('/browse');
    }
  }
}
