import 'dart:async';
import '../config/app_config.dart';

class AuthApi {
  // TODO replace with backend /auth/send-otp and /auth/verify-otp
  
  static Future<bool> sendOtp(String phone) async {
    // Fake implementation: sendOtp always succeeds
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request
    return true;
  }

  static Future<bool> verifyOtp(String phone, String otp) async {
    await Future.delayed(const Duration(seconds: 1)); // Simulate network request
    if (kDevMode && otp == kDevTestOtp) {
      return true;
    }
    return false;
  }
}
