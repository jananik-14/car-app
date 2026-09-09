import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/primary_button.dart';

class SubscriptionPlansScreen extends StatelessWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Plans')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPlanCard('Basic Plan', '\$9.99/mo', 'Access to standard bidding.', context),
            const SizedBox(height: 16),
            _buildPlanCard('Pro Plan', '\$29.99/mo', 'Priority support and unlimited bids.', context),
            const SizedBox(height: 16),
            _buildPlanCard('Dealer Plan', '\$99.99/mo', 'Bulk listings and analytics.', context),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(String title, String price, String desc, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(desc),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Subscribe', onPressed: () {
              context.push('/email');
            }),
          ],
        ),
      ),
    );
  }
}
