import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../services/auth_api.dart';
import '../services/admin_notification_store.dart';
import '../utils/profile_storage_helper.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../services/subscription_store.dart';
import '../services/auth_service.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  const OtpVerificationScreen({super.key, this.phoneNumber = ''});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _controllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  
  bool _isVerifying = false;
  String _errorMessage = '';
  
  int _failedAttempts = 0;
  bool _isLocked = false;
  int _lockTimer = 0;
  Timer? _lockTimerObj;

  int _resendTimer = 30;
  Timer? _resendTimerObj;

  int _expiryTimer = 300; // 5 minutes
  Timer? _expiryTimerObj;
  bool _isExpired = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
      setState(() {});
    });

    for (var node in _focusNodes) {
      node.addListener(() {
        setState(() {});
      });
    }

    _startResendTimer();
    _startExpiryTimer();
  }

  void _startResendTimer() {
    _resendTimer = 30;
    _resendTimerObj?.cancel();
    _resendTimerObj = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _startExpiryTimer() {
    _expiryTimer = 300;
    _isExpired = false;
    _expiryTimerObj?.cancel();
    _expiryTimerObj = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_expiryTimer > 0) {
          _expiryTimer--;
        } else {
          _isExpired = true;
          timer.cancel();
        }
      });
    });
  }

  void _startLockTimer() {
    _isLocked = true;
    _lockTimer = 30;
    _lockTimerObj?.cancel();
    _lockTimerObj = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_lockTimer > 0) {
          _lockTimer--;
        } else {
          _isLocked = false;
          _failedAttempts = 0;
          _errorMessage = '';
          timer.cancel();
        }
      });
    });
  }

  void _handleResend() async {
    if (_resendTimer > 0) return;
    setState(() {
      _errorMessage = '';
      for (var c in _controllers) { c.clear(); }
    });
    await AuthApi.sendOtp(widget.phoneNumber);
    if (!mounted) return;
    _startResendTimer();
    _startExpiryTimer();
  }

  @override
  void dispose() {
    _resendTimerObj?.cancel();
    _expiryTimerObj?.cancel();
    _lockTimerObj?.cancel();
    for (var c in _controllers) { c.dispose(); }
    for (var f in _focusNodes) { f.dispose(); }
    super.dispose();
  }
  
  bool get _isComplete => _controllers.every((c) => c.text.isNotEmpty);
  String get _enteredOtp => _controllers.map((c) => c.text).join();

  Future<void> _handleVerify() async {
    if (!_isComplete || _isLocked || _isExpired) return;
    
    setState(() {
      _isVerifying = true;
      _errorMessage = '';
    });
    
    bool isValid = await AuthApi.verifyOtp(widget.phoneNumber, _enteredOtp);
    
    if (!mounted) return;
    
    if (isValid) {
      _expiryTimerObj?.cancel();
      _resendTimerObj?.cancel();
      
      await AuthService().login(widget.phoneNumber);
      await SubscriptionStore().init(widget.phoneNumber);
      
      final bool isProfileComplete = await ProfileStorageHelper.isProfileComplete(widget.phoneNumber);
      
      if (AuthService.currentUserRole == 'admin') {
        if (context.mounted) context.go('/admin');
        return;
      }
      
      final realName = await ProfileStorageHelper.getProfileField(widget.phoneNumber, 'user_name');
      final displayName = (realName != null && realName.isNotEmpty) ? realName : widget.phoneNumber;
      AdminNotificationStore().addNotification('Client login: $displayName logged in', 'login');
      
      if (!isProfileComplete) {
        if (context.mounted) context.go('/profile_creation');
      } else {
        if (context.mounted) context.go('/terms');
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 3) {
        _errorMessage = 'Too many failed attempts. Locked for 30s.';
        for (var c in _controllers) { c.clear(); }
        _startLockTimer();
      } else {
        _errorMessage = 'Invalid OTP';
        for (var c in _controllers) { c.clear(); }
        _focusNodes[0].requestFocus();
      }
      setState(() {
        _isVerifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const lightBlueGrey = Color(0xFFEEF1F7);
    
    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                  const SizedBox(width: 48), 
                ],
              ),
              const SizedBox(height: 48),
              
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: lightBlueGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user, 
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 24),
              
              Text(
                'Enter the 4-digit code sent to',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.outline,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
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
                      child: const Row(
                        children: [
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
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 0; i < 4; i++) ...[
                    _buildOtpBox(i),
                    if (i < 3) const SizedBox(width: 16),
                  ]
                ],
              ),
              
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                ),
              
              if (kDevMode)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    'Test OTP: $kDevTestOtp',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              
              const SizedBox(height: 48),
              
              ElevatedButton(
                onPressed: (_isComplete && !_isVerifying && !_isLocked && !_isExpired) ? _handleVerify : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, 
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade600,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isVerifying)
                      const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    else ...[
                      const Text(
                        'Verify & Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward),
                    ]
                  ],
                ),
              ),
              const SizedBox(height: 48),
              
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: lightBlueGrey,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time, 
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              
              if (_isExpired)
                GestureDetector(
                  onTap: _handleResend,
                  child: const Text(
                    'OTP expired, resend',
                    style: TextStyle(
                      color: AppColors.secondaryContainer,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.secondaryContainer,
                    ),
                  ),
                )
              else
                Text.rich(
                  TextSpan(
                    text: 'Didn\'t get the code? ',
                    style: const TextStyle(
                      color: AppColors.outline,
                      fontWeight: FontWeight.w500,
                    ),
                    children: [
                      if (_resendTimer > 0)
                        TextSpan(
                          text: 'Wait ${_resendTimer}s',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      else
                        WidgetSpan(
                          child: GestureDetector(
                            onTap: _handleResend,
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

  Widget _buildOtpBox(int index) {
    bool isActive = _focusNodes[index].hasFocus;
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.secondaryContainer : AppColors.outlineVariant.withValues(alpha: 0.6),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive ? [
          BoxShadow(
            color: AppColors.secondaryContainer.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Center(
        child: KeyboardListener(
          focusNode: FocusNode(), // Dummy focus node just to catch keyboard events
          onKeyEvent: (event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_controllers[index].text.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
                _controllers[index - 1].clear();
                setState(() {});
              }
            }
          },
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 4, // allow paste
            enabled: !_isLocked,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black, 
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              counterText: '',
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              if (value.length > 1) {
                // Paste detected
                String val = value.substring(0, value.length > 4 ? 4 : value.length);
                for (int i = 0; i < val.length; i++) {
                  _controllers[i].text = val[i];
                }
                _focusNodes[val.length < 4 ? val.length : 3].requestFocus();
                setState(() {});
              } else {
                if (value.isNotEmpty && index < 3) {
                  _focusNodes[index + 1].requestFocus();
                } else if (value.isEmpty && index > 0) {
                  _focusNodes[index - 1].requestFocus();
                }
                setState(() {});
              }
            },
          ),
        ),
      ),
    );
  }
}
