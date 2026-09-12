import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Menu')),
      body: ListView(
        children: [
          ListTile(title: const Text('1. Login Screen'), onTap: () => context.push('/login')),
          ListTile(title: const Text('2. OTP Verification'), onTap: () => context.push('/otp')),
          ListTile(title: const Text('3. Terms & Conditions'), onTap: () => context.push('/terms')),
          ListTile(title: const Text('4. Browse Vehicles'), onTap: () => context.push('/browse')),
          ListTile(title: const Text('5. Vehicle Detail'), onTap: () => context.push('/vehicle_detail/1')),
          ListTile(title: const Text('6. Post Vehicle Form'), onTap: () => context.push('/post_vehicle')),
          ListTile(title: const Text('7. Confirmation Screen'), onTap: () => context.push('/confirmation/listing')),
          ListTile(title: const Text('8. Admin Approval'), onTap: () => context.push('/admin')),
          ListTile(title: const Text('9. Notifications'), onTap: () => context.push('/notifications')),
          ListTile(title: const Text('10. Subscription Plans'), onTap: () => context.push('/subscription')),
          ListTile(title: const Text('11. Email Screen'), onTap: () => context.push('/email')),
        ],
      ),
    );
  }
}
