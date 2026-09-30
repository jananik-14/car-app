import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../utils/responsive_helper.dart';
import '../utils/logout_helper.dart';
import '../services/subscription_store.dart';
import '../config/subscription_plans.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  String _formatAmount(int amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SubscriptionStore(),
      builder: (context, _) {
        final scrollableContent = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            _buildStatusBanner(),
            _buildTrustBadge(),
            _buildHeading(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ResponsiveHelper.isDesktop(context)
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildPlanCard(SubscriptionPlans.plans[0])),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPlanCard(SubscriptionPlans.plans[1])),
                          const SizedBox(width: 16),
                          Expanded(child: _buildPlanCard(SubscriptionPlans.plans[2])),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildPlanCard(SubscriptionPlans.plans[0]),
                        const SizedBox(height: 16),
                        _buildPlanCard(SubscriptionPlans.plans[1]),
                        const SizedBox(height: 16),
                        _buildPlanCard(SubscriptionPlans.plans[2]),
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
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Profile', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Theme(
            data: Theme.of(context).copyWith(
              splashColor: const Color(0xFFFB7800).withValues(alpha: 0.1),
              highlightColor: const Color(0xFFFB7800).withValues(alpha: 0.1),
              hoverColor: const Color(0xFFFB7800).withValues(alpha: 0.1),
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) {
                if (value == 'activity') context.push('/my_activity');
                else if (value == 'edit_profile') context.push('/profile_edit');
                else if (value == 'help') context.push('/help_support');
                else if (value == 'logout') {
                   confirmAndLogout(context);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit_profile',
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.person, color: Color(0xFF001128)),
                      SizedBox(width: 12),
                      Text('Edit my profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF001128))),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'activity',
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.history, color: Color(0xFF001128)),
                      SizedBox(width: 12),
                      Text('My activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF001128))),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'help',
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.help_outline, color: Color(0xFF001128)),
                      SizedBox(width: 12),
                      Text('Help and support', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF001128))),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: Row(
                    children: [
                      Icon(Icons.logout, color: Color(0xFFFB7800)),
                      SizedBox(width: 12),
                      Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFFFB7800))),
                    ],
                  ),
                ),
              ],
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    final store = SubscriptionStore();
    Color bgColor;
    Color textColor;
    String message;
    IconData icon;

    if (store.isActive && store.endDate != null) {
      if (store.daysLeft <= 0) {
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade800;
        message = 'Your subscription has expired. Please renew to keep bidding.';
        icon = Icons.error_outline;
      } else if (store.daysLeft <= 7) {
        bgColor = Colors.amber.shade100;
        textColor = Colors.amber.shade900;
        message = 'Your plan expires in ${store.daysLeft} days. Renew to keep bidding.';
        icon = Icons.warning_amber_rounded;
      } else {
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        final dateFormat = DateFormat('dd MMM yyyy');
        final endStr = store.endDate != null ? dateFormat.format(store.endDate!) : '';
        message = 'Active: ${store.activePlan?.name ?? ''} • Valid till $endStr • ${store.daysLeft} days left';
        icon = Icons.check_circle_outline;
      }
    } else if (store.isActive && store.endDate == null) {
      // Admin case or permanent active
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      message = 'Active: Admin Access (Unlimited)';
      icon = Icons.check_circle_outline;
    } else if (store.isPending) {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
      message = 'Subscription pending approval. You\'ll be able to bid once it is approved.';
      icon = Icons.hourglass_empty;
    } else {
      bgColor = Colors.red.shade50;
      textColor = Colors.red.shade800;
      message = 'No active subscription. Subscribe to place bids and post vehicles.';
      icon = Icons.error_outline;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: textColor, fontWeight: FontWeight.w600))),
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
              Icon(Icons.verified, color: AppColors.secondaryContainer, size: 14),
              SizedBox(width: 6),
              Text('TRUSTED BY 25,000+ DEALERS', style: TextStyle(color: AppColors.secondaryContainer, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
          Text('Bidder Memberships', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.primary)),
          SizedBox(height: 4),
          Text('Choose your auction access plan', style: TextStyle(fontSize: 14, color: AppColors.outline, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final store = SubscriptionStore();
    final isCurrent = store.activePlan?.id == plan.id && store.isActive;
    final isPending = store.isPending;
    
    final bool isBestValue = plan.id == 'yearly';
    final Color mainColor = isBestValue ? AppColors.secondaryContainer : AppColors.primary;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBestValue ? mainColor.withOpacity(0.5) : AppColors.outlineVariant.withOpacity(0.3), width: isBestValue ? 1.5 : 1.0),
        boxShadow: [
          BoxShadow(
            color: isBestValue ? mainColor.withOpacity(0.1) : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 380),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          if (isBestValue) Container(height: 4, color: mainColor),
          Expanded(
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
                        if (plan.tagline.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: mainColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isBestValue) const Icon(Icons.star, color: AppColors.secondaryContainer, size: 10),
                                if (isBestValue) const SizedBox(width: 4),
                                Text(plan.tagline, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: mainColor, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                        Text(plan.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(_formatAmount(plan.price), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
                    Text('/${plan.name.toLowerCase()}', style: const TextStyle(fontSize: 14, color: AppColors.outline, fontWeight: FontWeight.w500)),
                  ],
                ),
                if (plan.durationDays > 30)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('≈ ${_formatAmount((plan.price / (plan.durationDays / 30)).round())}/month', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ),
                const SizedBox(height: 12),
                _buildChecklist(plan.features, mainColor),
                const Spacer(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isPending ? null : () => _handleSubscribe(plan.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrent ? Colors.white : mainColor,
                      foregroundColor: isCurrent ? mainColor : Colors.white,
                      disabledBackgroundColor: const Color(0xFFEEF1F7),
                      disabledForegroundColor: AppColors.outline,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isCurrent ? BorderSide(color: mainColor) : BorderSide.none,
                      ),
                    ),
                    child: Text(
                      isPending ? 'Pending Approval' : (isCurrent ? 'Renew Plan' : (store.isActive ? 'Switch to this plan' : 'Choose Plan')),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
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
              Expanded(
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w500),
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
      decoration: BoxDecoration(color: const Color(0xFFEEF1F7), borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.receipt_long, color: AppColors.primary, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '100% Tax Deductible Invoicing - GST receipts generated immediately. Upgrade or cancel anytime from account settings.',
              style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSubscribe(String planId) {
    context.push('/subscription_checkout?planId=$planId');
  }
}
