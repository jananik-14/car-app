import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'How do I place a bid?',
      'answer': 'To place a bid, go to the Browse section, select a live auction vehicle, and tap the "Place Bid" button. You can enter your custom bid amount or choose the next incremental value. Ensure you have sufficient EMD balance.',
    },
    {
      'question': 'What is EMD (Earnest Money Deposit)?',
      'answer': 'EMD is a refundable security deposit required to participate in live auctions. It ensures serious bidding. If you don\'t win the auction, your EMD is fully refunded or can be reused for other bids.',
    },
    {
      'question': 'How does vehicle inspection work?',
      'answer': 'Every vehicle on Wheels2Drive goes through a rigorous 140-point inspection by certified mechanics. You can view the detailed inspection report on the vehicle details page before placing a bid.',
    },
    {
      'question': 'How do I list my vehicle?',
      'answer': 'Go to the Profile area and select "My Activity" or use the quick action menu to "Post Vehicle". Fill in the details, upload clear photos, and submit. Our team will review and approve it within 24 hours.',
    },
    {
      'question': 'What are the subscription plans?',
      'answer': 'We offer Starter, Pro Trader, and Dealership Elite plans. Starter is free with limited bids, while Pro Trader provides unlimited bids and priority alerts. Elite is for large commercial dealerships.',
    },
    {
      'question': 'Can I cancel my bid?',
      'answer': 'No, once a bid is placed, it cannot be canceled. This maintains fairness in the auction process. Please be absolutely sure before confirming your bid amount.',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          ..._faqs.map((faq) => _buildFaqItem(faq)),
          const SizedBox(height: 32),
          const Text(
            'Still need help?',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          _buildContactCard(context),
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, String> faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.grey.shade50,
      child: ExpansionTile(
        title: Text(
          faq['question']!,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: Colors.grey.shade600,
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            faq['answer']!,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryContainer.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.support_agent, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Us',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'We\'re available 24/7',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.phone, size: 16, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                '1800-123-4567',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email, size: 16, color: AppColors.primary),
              const SizedBox(width: 12),
              Text(
                'support@wheels2drive.com',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Chat with Support coming soon!'),
                  ),
                );
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Chat with Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
