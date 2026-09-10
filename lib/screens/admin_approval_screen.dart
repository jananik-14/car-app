import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminApprovalScreen extends StatelessWidget {
  const AdminApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Approvals')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('2020 Honda Civic', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Base Price: \$15,000'),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Reject')),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () {
                        context.push('/notifications');
                      }, child: const Text('Approve')),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
