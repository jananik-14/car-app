import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/subscription_store.dart';
import '../utils/profile_storage_helper.dart';
import '../utils/blob_storage.dart';
import '../widgets/responsive_nav_scaffold.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _name = '';
  String _phone = '';
  String _email = '';
  String _city = '';
  bool _isKycVerified = false;
  Uint8List? _avatarBytes;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final phone = AuthService().currentPhone ?? '';
    final normalizedPhone = ProfileStorageHelper.normalizePhone(phone);

    if (phone.isNotEmpty) {
      await SubscriptionStore().init(phone);
    }

    final name = await ProfileStorageHelper.getProfileField(phone, 'user_name') ?? '';
    final email = await ProfileStorageHelper.getProfileField(phone, 'user_email') ?? '';
    final city = await ProfileStorageHelper.getProfileField(phone, 'user_city') ?? '';

    final prefs = await SharedPreferences.getInstance();
    final hasKycPref = prefs.getBool('kyc_uploaded_$phone') ??
        prefs.getBool('kyc_uploaded_$normalizedPhone') ??
        false;

    final blob = BlobStorage();
    final kycBlob = await blob.get('$phone/kyc');
    final avatarBlob = await blob.get('$phone/avatar');

    final bool kycComplete = hasKycPref || (kycBlob != null);

    if (mounted) {
      setState(() {
        _phone = phone;
        _name = name.isNotEmpty ? name : 'Wheels2Drive User';
        _email = email.isNotEmpty ? email : 'Not provided';
        _city = city.isNotEmpty ? city : 'Not provided';
        _isKycVerified = kycComplete;
        _avatarBytes = avatarBlob;
        _isLoading = false;
      });
    }
  }

  String _toTitleCase(String text) {
    if (text.trim().isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _getSubscriptionSubtitle() {
    final store = SubscriptionStore();
    if (store.isActive && store.endDate != null) {
      final planName = store.activePlan?.name ?? 'Plan';
      final formattedDate = DateFormat('dd MMM yyyy').format(store.endDate!);
      return '$planName - Active until $formattedDate';
    }
    return 'No active plan';
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      if (!context.mounted) return;
      try {
        context.go('/login');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      currentIndex: 4,
      backgroundColor: AppColors.surface,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondaryContainer),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header title
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                        child: Text(
                          'Profile',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // User Info Card
                      _buildUserInfoCard(),
                      const SizedBox(height: 24),

                      // Menu Section
                      _buildMenuSection(),
                      const SizedBox(height: 24),

                      // Version text
                      const Center(
                        child: Text(
                          'Version 1.0.0',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard() {
    final String initial = _name.isNotEmpty ? _name.trim()[0].toUpperCase() : 'U';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _avatarBytes != null
                      ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 16),

              // Name & KYC Status Badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _toTitleCase(_name),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () async {
                            await context.push('/profile_edit');
                            _loadProfileData();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 13, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildKycBadge(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF0F2F6)),
          const SizedBox(height: 16),

          // Detail Rows: Phone, Email, City
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: _phone.isNotEmpty ? '+91 $_phone' : 'Not set',
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _email,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: 'City',
            value: _toTitleCase(_city),
          ),
        ],
      ),
    );
  }

  Widget _buildKycBadge() {
    final isVerified = _isKycVerified;
    final Color bgColor = isVerified ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final Color textColor = isVerified ? const Color(0xFF2E7D32) : const Color(0xFFE65100);
    final IconData icon = isVerified ? Icons.verified : Icons.pending_actions;
    final String label = isVerified ? 'KYC Verified' : 'KYC Pending';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FA),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.outline),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
    return Material(
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.history,
            title: 'My Activity',
            subtitle: 'Bids, posted listings & won auctions',
            onTap: () => context.push('/my_activity'),
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F6), indent: 56),
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            subtitle: 'Update personal details & KYC document',
            onTap: () async {
              await context.push('/profile_edit');
              _loadProfileData();
            },
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F6), indent: 56),
          ListenableBuilder(
            listenable: SubscriptionStore(),
            builder: (context, _) {
              return _buildMenuItem(
                icon: Icons.workspace_premium_outlined,
                title: 'Subscription',
                subtitle: _getSubscriptionSubtitle(),
                onTap: () async {
                  await context.push('/subscription');
                  if (mounted) setState(() {});
                },
              );
            },
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F6), indent: 56),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'FAQs, contact information & inquiries',
            onTap: () => context.push('/help_support'),
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F6), indent: 56),
          _buildMenuItem(
            icon: Icons.policy_outlined,
            title: 'Terms & Privacy',
            subtitle: 'User agreements and privacy policies',
            onTap: () => context.push('/terms'),
          ),
          const Divider(height: 1, color: Color(0xFFF0F2F6), indent: 56),
          _buildMenuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your Wheels2Drive account',
            isDestructive: true,
            onTap: () => _handleLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color mainColor = isDestructive ? const Color(0xFFD32F2F) : AppColors.primary;
    final Color iconBg = isDestructive ? const Color(0xFFFFEBEE) : const Color(0xFFF4F6FA);
    final Color iconColor = isDestructive ? const Color(0xFFD32F2F) : AppColors.primary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: mainColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.outline,
        ),
      ),
      trailing: isDestructive
          ? null
          : const Icon(Icons.chevron_right, size: 20, color: AppColors.outline),
      onTap: onTap,
    );
  }
}
