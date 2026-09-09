import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Conditions')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          '1. Introduction\nWelcome to Wheels2Drive. By using our app, you agree to these terms...\n\n'
          '2. Bidding Rules\nAll bids are final. Ensure you have the funds before placing a bid...\n\n'
          '3. Seller Responsibilities\nSellers must accurately describe their vehicles...',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ElevatedButton(
            onPressed: () => context.push('/browse'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
            child: const Text('Agree & Continue'),
          ),
        ),
      ),
    );
  }
}
