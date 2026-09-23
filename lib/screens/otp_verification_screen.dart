import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../utils/temp_admin_config.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../services/api_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, this.phoneNumber = ''});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  @override
  void initState() {
    super.initState();
    
    // Focus the 1st box automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      setState(() {});
    });

    for (var node in _focusNodes) {
      node.addListener(() {
        setState(() {}); // Rebuild to update border colors based on focus
      });
    }
  }

  @override
  void dispose() {
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const lightBlueGrey = Color(0xFFEEF1F7);
    
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: lightBlueGrey,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Verify Phone',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  // Placeholder to balance the back button to keep title centered
                  const SizedBox(width: 48), 
                ],
              ),
              const SizedBox(height: 48),
              
              // Shield Icon
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: lightBlueGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user, // Shield with checkmark
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              
              // Subtitle Text
              Text(
                'Enter the 4-digit code sent to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Phone Number Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: lightBlueGrey,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.phoneNumber.isNotEmpty ? widget.phoneNumber : '+91 98765 43210',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Row(
                        children: const [
                          Text(
                            'Change',
                            style: TextStyle(
                              color: AppColors.secondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.edit,
                            color: AppColors.secondaryContainer,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // OTP Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    _buildOtpBox(i),
                    if (i < 3) const SizedBox(width: 16),
                  ]
                ],
              ),
              const SizedBox(height: 48),
              
              // Primary Button
              ElevatedButton(
                onPressed: () => _handleOtpVerified(widget.phoneNumber),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Dark Navy
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Verify & Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              // Resend Section
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: lightBlueGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time, // clock/timer icon
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: 'Didn\'t get the code? ',
                  style: const TextStyle(
                    color: AppColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          // resend logic
                        },
                        child: const Text(
                          'Resend via SMS',
                          style: TextStyle(
                            color: AppColors.secondaryContainer,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.secondaryContainer,
                          ),
                        ),
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
      mobileContent: SingleChildScrollView(
        child: content,
      ),
      desktopContent: content,
      desktopMaxWidth: 480,
    );
  }

  Future<void> _handleOtpVerified(String enteredPhoneNumber) async {
    // 1. Get OTP from boxes
    String otp = _controllers.map((c) => c.text).join('');
    if (otp.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 4-digit OTP')));
      return;
    }

    try {
      final api = ApiService();
      // 2. Verify OTP
      await api.verifyOtp(enteredPhoneNumber, otp);
      
      // 3. Fetch Profile
      final profile = await api.getProfile();
      
      if (profile == null) {
        // No profile exists yet
        if (context.mounted) {
          context.go('/profile_creation');
        }
        return;
      }

      // 4. Role-based Navigation
      final role = profile['role'];
      final isProfileComplete = profile['isProfileComplete'] == true;

      if (role == 'admin') {
        if (context.mounted) {
          context.go('/admin');
        }
      } else {
        if (!isProfileComplete) {
          if (context.mounted) {
            context.go('/profile_creation');
          }
        } else {
          if (context.mounted) {
            context.go('/terms');
          }
        }
      }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  Widget _buildOtpBox(int index) {
    bool isActive = _focusNodes[index].hasFocus;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest, // white
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.secondaryContainer : AppColors.outlineVariant.withOpacity(0.6),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppColors.secondaryContainer.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black, // bold black text
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.isNotEmpty && index < 3) {
              _focusNodes[index + 1].requestFocus();
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
