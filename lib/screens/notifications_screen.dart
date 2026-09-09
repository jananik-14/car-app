import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView.builder(
        itemCount: 4,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.notifications),
            ),
            title: const Text('You were outbid!'),
            subtitle: const Text('Someone placed a higher bid on the 2021 Toyota Camry.'),
            trailing: const Text('2m ago'),
            onTap: () {
              context.push('/subscription');
            },
          );
        },
      ),
    );
  }
}
