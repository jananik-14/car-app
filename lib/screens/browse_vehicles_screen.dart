import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class BrowseVehiclesScreen extends StatelessWidget {
  const BrowseVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/subscription'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search make, model...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 80,
                      height: 60,
                      color: AppColors.primaryContainer,
                      child: const Icon(Icons.directions_car),
                    ),
                    title: const Text('2021 Toyota Camry', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Current Bid: \$18,500\nTime Left: 2h 15m'),
                    isThreeLine: true,
                    onTap: () => context.push('/vehicle_detail/1'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/post_vehicle'),
        backgroundColor: AppColors.secondaryContainer,
        child: const Icon(Icons.add),
      ),
    );
  }
}
