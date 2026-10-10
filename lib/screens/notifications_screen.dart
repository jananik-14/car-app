import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../services/client_notification_store.dart';
import '../services/auth_service.dart';
import '../router/app_router.dart';
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      currentIndex: 3,
      body: ListenableBuilder(
        listenable: ClientNotificationStore(),
        builder: (context, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                _buildNotificationList(),
              ],
            ),
          );
        }
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
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          Expanded(
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (ClientNotificationStore().unreadCountFor(AuthService().currentPhone ?? '') > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${ClientNotificationStore().unreadCountFor(AuthService().currentPhone ?? '')}',
                      style: const TextStyle(
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
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  ClientNotificationStore().markAllAsReadFor(AuthService().currentPhone ?? '');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: lightBlueGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.done_all, size: 16, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Mark all read',
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  ClientNotificationStore().clearAllFor(AuthService().currentPhone ?? '');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: lightBlueGrey,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
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
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    final phone = AuthService().currentPhone ?? '';
    final notifs = ClientNotificationStore().forCurrentUser(phone);
    if (notifs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(48.0),
        child: Column(
          children: [
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
          ...notifs.map((notif) {
            IconData iconData = Icons.notifications;
            Color iconBgColor = AppColors.primary;
            if (notif.type.endsWith('_approved') || notif.type.endsWith('_accepted') || notif.type == 'payment_confirmed') {
              iconData = Icons.check_circle;
              iconBgColor = const Color(0xFF22C55E); // green
            } else if (notif.type.endsWith('_rejected')) {
              iconData = Icons.cancel;
              iconBgColor = const Color(0xFFEF4444); // red
            }

            return Column(
              children: [
                InkWell(
                  onTap: () {
                    ClientNotificationStore().markAsRead(notif);
                    if (notif.type == 'listing_live' || notif.type == 'listing_approved' || notif.type == 'listing_rejected' || notif.type == 'sold') {
                      if (notif.refId != null) openVehicleDetail(context, notif.refId!); else context.push('/my_activity');
                    } else if (notif.type == 'bid_won' || notif.type == 'bid_lost' || notif.type == 'outbid') {
                      if (notif.refId != null) openVehicleDetail(context, notif.refId!); else context.push('/my_activity');
                    } else if (notif.type == 'subscription_active') {
                      context.push('/subscription');
                    } else if (notif.type == 'payment' && notif.refId != null) {
                      context.push('/payment/${notif.refId}');
                    } else if (notif.type == 'payment') {
                      context.push('/payment');
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: _buildNotificationCard(
                    iconData: iconData,
                    iconColor: Colors.white,
                    iconBgColor: iconBgColor,
                    title: notif.title,
                    boldHighlight: '',
                    highlightColor: iconBgColor,
                    content: '', // content was absorbed into title
                    time: _formatTimeAgo(notif.timestamp),
                    showDot: !notif.isRead,
                    dotColor: const Color(0xFFFF9800), // Orange dot
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
                    style: TextStyle(
                      color: showDot ? AppColors.primary : AppColors.onSurface,
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: showDot ? FontWeight.bold : FontWeight.normal,
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
