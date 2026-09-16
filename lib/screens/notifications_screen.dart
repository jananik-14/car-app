import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../widgets/shared_bottom_nav.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isCleared = false;

  @override
  Widget build(BuildContext context) {
    final scrollableContent = Column(
      children: [
        _buildTopBar(),
        _buildHeader(),
        _buildNotificationList(),
      ],
    );

    return ResponsiveLayoutWrapper(
      mobileContent: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: scrollableContent,
            ),
          ),
          const SharedBottomNav(currentIndex: 3),
        ],
      ),
      desktopContent: Column(
        children: [
          scrollableContent,
          const SharedBottomNav(currentIndex: 3),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Wheels2Drive',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    const lightBlueGrey = Color(0xFFEEF1F7);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text(
                'Notifications',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              if (!_isCleared) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '4',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _isCleared = true;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: lightBlueGrey,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: const [
                  Icon(Icons.clear_all, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Clear all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    if (_isCleared) {
      return Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: const [
            Icon(Icons.notifications_off_outlined, size: 64, color: AppColors.outline),
            SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You\'re all caught up.',
              style: TextStyle(color: AppColors.outline),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildNotificationCard(
            iconData: Icons.gavel,
            iconColor: Colors.white,
            iconBgColor: AppColors.secondaryContainer,
            title: 'Outbid on ',
            boldHighlight: 'Audi Q5',
            highlightColor: AppColors.secondaryContainer,
            content: '. New highest bid is ₹39.00 Lakhs.',
            time: '10m ago',
            showDot: true,
            dotColor: AppColors.secondaryContainer,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            iconData: Icons.check,
            iconColor: Colors.white,
            iconBgColor: AppColors.primary,
            title: 'Listing Approved: ',
            boldHighlight: 'Tata Harrier',
            highlightColor: AppColors.primary,
            content: ' is now live in auction.',
            time: '1h ago',
            showDot: true,
            dotColor: AppColors.outline,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            iconData: Icons.notifications_active,
            iconColor: AppColors.primary,
            iconBgColor: const Color(0xFFEEF1F7),
            title: 'Auction starts in 15 mins for ',
            boldHighlight: 'BMW 3 Series',
            highlightColor: AppColors.primary,
            content: '.',
            time: '3h ago',
            showDot: false,
          ),
          const SizedBox(height: 16),
          _buildNotificationCard(
            iconData: Icons.account_balance_wallet,
            iconColor: AppColors.primary,
            iconBgColor: const Color(0xFFEEF1F7),
            title: 'Token deposit of ₹25,000 received successfully.',
            boldHighlight: '',
            highlightColor: AppColors.primary,
            content: '',
            time: 'Yesterday',
            showDot: false,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String boldHighlight,
    required Color highlightColor,
    required String content,
    required String time,
    required bool showDot,
    Color? dotColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      color: AppColors.onSurface,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(text: title),
                      if (boldHighlight.isNotEmpty)
                        TextSpan(
                          text: boldHighlight,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: highlightColor,
                          ),
                        ),
                      TextSpan(text: content),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (showDot) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: dotColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      time,
                      style: const TextStyle(
                        color: AppColors.outline,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
