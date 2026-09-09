import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/primary_button.dart';
import '../theme/app_theme.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle_outline, size: 100, color: AppColors.secondaryContainer),
              const SizedBox(height: 32),
              Text(
                'Success!',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your action has been completed successfully.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Back to Home',
                onPressed: () => context.push('/admin'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
