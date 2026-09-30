class PaymentConfig {
  static const String razorpayTestKeyId = 'rzp_test_1DP5mmOlF5G5ag';
  static const bool kDemoPayments = bool.fromEnvironment('DEMO_PAYMENTS', defaultValue: false);
  
  static const upiId = 'wheels2drive@upi';   // TODO: replace with real merchant UPI ID
  static const payeeName = 'Wheels2Drive';
  static const tokenAmount = 25000;
  static const bankName = 'XXXX Bank';        // TODO: replace
  static const accountName = 'Wheels2Drive Pvt Ltd';
  static const accountNumber = 'XXXXXXXXXXXX';
  static const ifsc = 'XXXX0000000';
}
