import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';

class PostVehicleFormScreen extends StatelessWidget {
  const PostVehicleFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post a Vehicle')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Vehicle Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Make', hintText: 'e.g., Honda'),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Model', hintText: 'e.g., Civic'),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Year', hintText: 'e.g., 2020', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Base Price', hintText: '\$15,000', keyboardType: TextInputType.number),
            const SizedBox(height: 24),
            PrimaryButton(text: 'Submit for Approval', onPressed: () {
              context.push('/confirmation');
            }),
          ],
        ),
      ),
    );
  }
}
