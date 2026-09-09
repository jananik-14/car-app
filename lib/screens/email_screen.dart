import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';

class EmailScreen extends StatelessWidget {
  const EmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send us an email', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            const CustomTextField(label: 'Your Email', hintText: 'example@domain.com', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            const CustomTextField(label: 'Message', hintText: 'Type your message here...'),
            const SizedBox(height: 32),
            PrimaryButton(text: 'Send Email', onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email Sent!')),
              );
              if (context.canPop()) {
                context.pop();
              }
            }),
          ],
        ),
      ),
    );
  }
}
