import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../widgets/primary_button.dart';
import '../widgets/custom_text_field.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _mobileController = TextEditingController();

  void _getOtp() {
    // Navigate to OTP screen
    context.push('/otp');
  }

  @override
  void dispose() {
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Brand Section
                Container(
                  width: 150,
                  height: 150,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.outlineVariant.withOpacity(0.6),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Center(
                        child: Text(
                          'Wheels 2 Drive',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                
                // Interaction Card
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enter your Mobile Number',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Mobile Number',
                      hintText: '98765 43210',
                      controller: _mobileController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 14),
                          // India flag emoji
                          const Text(
                            '🇮🇳',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+91',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  color: AppColors.onSurface,
                                ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 24,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Get OTP',
                      icon: Icons.arrow_forward,
                      onPressed: _getOtp,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildFeatureItem(Icons.flash_on, 'Instant Access'),
                        _buildDot(),
                        _buildFeatureItem(Icons.shield, 'Zero Spam'),
                        _buildDot(),
                        _buildFeatureItem(Icons.gavel, 'Verified Auctions'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                
                // Footer
                Text.rich(
                  TextSpan(
                    text: 'By continuing, you agree to our\n',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                    children: [
                      TextSpan(
                        text: 'Terms of Service',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ' & '),
                      TextSpan(
                        text: 'Privacy Policy',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );

    return ResponsiveLayoutWrapper(
      mobileContent: Center(
        child: SingleChildScrollView(
          child: content,
        ),
      ),
      desktopContent: content,
    );
  }

  Widget _buildFeatureItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.secondaryContainer),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildDot() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.outlineVariant,
        shape: BoxShape.circle,
      ),
    );
  }
}