import 'package:flutter/material.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_app_bar.dart';

class AdminAlertsScreen extends StatelessWidget {
  const AdminAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 4,
      appBar: const AdminAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications_none, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text('Admin Alerts', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF001128))),
            SizedBox(height: 8),
            Text('Coming Soon', style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
