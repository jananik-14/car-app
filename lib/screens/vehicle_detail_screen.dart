import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/primary_button.dart';

class VehicleDetailScreen extends StatelessWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vehicle Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              color: Colors.grey.shade300,
              child: const Icon(Icons.directions_car, size: 100),
            ),
            const SizedBox(height: 24),
            Text('2021 Toyota Camry', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text('Condition: Excellent • Mileage: 15,000 miles'),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Bid'),
                        Text('\$18,500', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Ends in'),
                        Text('2h 15m', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(text: 'Continue', onPressed: () {
              context.push('/post_vehicle');
            }),
          ],
        ),
      ),
    );
  }
}
