import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../services/auth_service.dart';
import '../utils/responsive_helper.dart';
import '../utils/global_store.dart';

// Simple global state for demonstration purposes
String currentSubscriptionPlan = 'Starter';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  @override
  Widget build(BuildContext context) {
    final scrollableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(),
        _buildTrustBadge(),
        _buildHeading(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: ResponsiveHelper.isDesktop(context)
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildStarterPlan()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildProTraderPlan()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDealershipElitePlan()),
                  ],
                )
              : Column(
                  children: [
                    _buildStarterPlan(),
                    const SizedBox(height: 16),
                    _buildProTraderPlan(),
                    const SizedBox(height: 16),
                    _buildDealershipElitePlan(),
                    const SizedBox(height: 24),
                    _buildFooterNote(),
                    const SizedBox(height: 32),
                  ],
                ),
        ),
        if (ResponsiveHelper.isDesktop(context))
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildFooterNote(),
                const SizedBox(height: 32),
              ],
            ),
          ),
      ],
    );

    return ResponsiveNavScaffold(
      currentIndex: 4,
      body: SingleChildScrollView(
        child: scrollableContent,
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: const Color(0xFFFB7800).withValues(alpha: 0.1),
              highlightColor: const Color(0xFFFB7800).withValues(alpha: 0.1),
              hoverColor: const Color(0xFFFB7800).withValues(alpha: 0.1),
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) {
                if (value == 'activity') {
                  context.push('/my_activity');
                } else if (value == 'edit_profile') {
                  context.push('/profile_edit');
                } else if (value == 'help') {
                  context.push('/help_support');
                } else if (value == 'logout') {
                  _showLogoutDialog(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'activity',
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.history, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('My Activity',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'edit_profile',
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.person_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Edit My Profile',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'help',
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.help_outline, color: AppColors.primary),
                      SizedBox(width: 12),
                      Text('Help & Support',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary)),
                    ],
                  ),
                ),
                const PopupMenuDivider(height: 1),
                PopupMenuItem<String>(
                  value: 'logout',
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: const [
                      Icon(Icons.logout, color: Color(0xFFFB7800)),
                      SizedBox(width: 12),
                      Text('Logout',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFFB7800))),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadge() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.verified,
                  color: AppColors.secondaryContainer, size: 14),
              SizedBox(width: 6),
              Text(
                'TRUSTED BY 25,000+ DEALERS',
                style: TextStyle(
                  color: AppColors.secondaryContainer,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Bidder Memberships',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose your auction access plan',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.outline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarterPlan() {
    final isCurrent = currentSubscriptionPlan == 'Starter';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PLAN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.outline,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Starter',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.directions_car,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '₹0',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '/month',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildChecklist(
                ['3 Live Bids/month', 'Standard support'], AppColors.primary),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent ? null : () => _handleSubscribe('Starter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primaryContainer.withValues(alpha: 0.1),
                  foregroundColor: AppColors.primaryContainer,
                  disabledBackgroundColor: const Color(0xFFEEF1F7),
                  disabledForegroundColor: AppColors.outline,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isCurrent ? 'Current Plan' : 'Select Starter',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProTraderPlan() {
    final isCurrent = currentSubscriptionPlan == 'Pro Trader';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
            width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 4,
            color: AppColors.secondaryContainer,
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.star,
                                  color: AppColors.secondaryContainer,
                                  size: 10),
                              SizedBox(width: 4),
                              Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.secondaryContainer,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pro Trader',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            AppColors.secondaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.bolt,
                          color: AppColors.secondaryContainer, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: const [
                    Text(
                      '₹1,999',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      '/mo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.outline,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildChecklist([
                  'Unlimited Bids',
                  'Instant RTO verification',
                  'Priority lot alerts'
                ], AppColors.secondaryContainer),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        isCurrent ? null : () => _handleSubscribe('Pro Trader'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondaryContainer,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFEEF1F7),
                      disabledForegroundColor: AppColors.outline,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCurrent ? 'Current Plan' : 'Upgrade to Pro',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isCurrent) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealershipElitePlan() {
    final isCurrent = currentSubscriptionPlan == 'Dealership Elite';
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'COMMERCIAL',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.outline,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Dealership Elite',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.business_center,
                      color: AppColors.primary, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: const [
                Text(
                  '₹4,999',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '/mo',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildChecklist([
              'Zero transaction fees',
              'Dedicated Account Manager',
              'API Access for bulk bidding'
            ], AppColors.primary),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCurrent
                    ? null
                    : () => _handleSubscribe('Dealership Elite'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFEEF1F7),
                  disabledForegroundColor: AppColors.outline,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isCurrent ? 'Current Plan' : 'Contact Sales',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isCurrent) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.headset_mic, size: 18),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklist(List<String> items, Color iconColor) {
    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Text(
                item,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooterNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '100% Tax Deductible Invoicing - GST receipts generated immediately. Upgrade or cancel anytime from account settings.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(String planId) async {
    final emailController = TextEditingController();
    emailController.text = 'user@example.com'; // Simulate saved email
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm your email to proceed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(
              labelText: 'Email Address',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.outline)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm & Send Request'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade request sent! We\'ll notify you once approved.'),
            backgroundColor: Color(0xFFFB7800),
          ),
        );
      }
      
      // We will integrate GlobalStore for Notifications and Admin Subscriptions later
      importGlobalStoreAndAddData(planId);
    }
  }

  void importGlobalStoreAndAddData(String planId) {
    GlobalStore.notifications.insert(0, {
      'iconData': Icons.pending_actions,
      'iconColor': Colors.white,
      'iconBgColor': const Color(0xFFFB7800),
      'title': 'Upgrade request submitted for ',
      'boldHighlight': planId,
      'highlightColor': const Color(0xFFFB7800),
      'content': '. Awaiting approval.',
      'time': 'Just now',
      'showDot': true,
      'dotColor': const Color(0xFFFB7800),
    });

    GlobalStore.pendingSubscriptions.insert(0, {
      'id': 's_new_${DateTime.now().millisecondsSinceEpoch}',
      'businessName': 'Your Dealership', // Placeholder since user profile name isn't fully wired here
      'tier': planId,
      'tierColor': planId == 'Pro Trader' ? AppColors.secondaryContainer : AppColors.primary,
      'id1Label': 'GSTIN',
      'id1Value': 'PENDING',
      'id2Label': 'PAN',
      'id2Value': 'PENDING',
      'requestTime': 'Just now',
      'timeAgo': 'Just now',
      'price': 'N/A',
      'payRef': 'Pending',
      'paymentStatus': 'Awaiting Verification',
      'gstStatus': 'N/A',
      'kycDocs': 'Not Attached',
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  AuthService.currentUserRole = 'customer';
                });
                context.go('/login');
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }
}
