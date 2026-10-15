import 'app_config.dart';

class PaymentConfig {
  static const String razorpayTestKeyId = 'rzp_test_1DP5mmOlF5G5ag';
  static const bool kDemoPayments = bool.fromEnvironment('DEMO_PAYMENTS', defaultValue: false);
  
  static const upiId = 'wheels2drive@upi';   // TODO: replace with real merchant UPI ID
  static const payeeName = 'Wheels2Drive';
  static const tokenAmount = 25000;
  static const bankName = kBankName;
  static const accountName = kAccountName;
  static const accountNumber = kAccountNumber;
  static const ifsc = kIfsc;
}
