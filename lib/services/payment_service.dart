import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../config/payment_config.dart';

// TODO: Real payments need the backend: create Razorpay order, verify signature, handle webhooks, then activate subscription / confirm payment server-side.
// The app must never decide that a payment succeeded.

class PaymentOrder {
  final String? orderId;
  final int amountInRupees;
  final String purpose;
  final String referenceId;

  PaymentOrder({
    this.orderId,
    required this.amountInRupees,
    required this.purpose,
    required this.referenceId,
  });
}

class PaymentResult {
  final String status; // 'success', 'failed', 'cancelled'
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorMessage;
  final String? utr; // Used if we fallback to manual UPI verification

  PaymentResult({
    required this.status,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorMessage,
    this.utr,
  });
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  Future<PaymentOrder> createOrder({
    required int amountInRupees,
    required String purpose,
    required String referenceId,
  }) async {
    // Stub for now, returns a local order with orderId = null.
    // TODO: backend POST /api/payments/create-order → returns Razorpay order_id
    return PaymentOrder(
      orderId: null, // No real order_id without a backend
      amountInRupees: amountInRupees,
      purpose: purpose,
      referenceId: referenceId,
    );
  }

  Future<PaymentResult> startCheckout(
    BuildContext context,
    PaymentOrder order, {
    required String name,
    required String description,
    String? prefillContact,
    String? prefillEmail,
  }) async {
    if (!kReleaseMode && PaymentConfig.kDemoPayments) {
      return _runDemoMode(context, order);
    }

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      return _runRazorpay(context, order, name, description, prefillContact, prefillEmail);
    }

    // Web/Desktop fallback to manual UPI (returns a pseudo-cancelled result because we handle fallback UI externally, or we can handle it here)
    // Actually, the prompt says "fall back to the manual UPI QR + UPI ID + UTR submission flow already built (lib/widgets/upi_payment_section.dart)". 
    // Since UpiPaymentSection is a widget, we can't easily push it from a service unless we push a new route or show a bottom sheet.
    // We will return a specific status to let the UI know it should show the fallback widget.
    return PaymentResult(status: 'fallback_to_manual');
  }

  Future<PaymentResult> _runDemoMode(BuildContext context, PaymentOrder order) async {
    final result = await showDialog<PaymentResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('DEMO MODE — no real money moves', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        content: Text('Simulate payment for ${order.purpose} (₹${order.amountInRupees})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, PaymentResult(
              status: 'failed', 
              errorMessage: 'Simulated failure in Demo Mode'
            )),
            child: const Text('Simulate failure'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, PaymentResult(
              status: 'success',
              paymentId: 'demo_pay_123',
              orderId: order.orderId,
              signature: 'demo_sig_abc',
            )),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Simulate success', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? PaymentResult(status: 'cancelled');
  }

  Future<PaymentResult> _runRazorpay(
    BuildContext context,
    PaymentOrder order,
    String name,
    String description,
    String? prefillContact,
    String? prefillEmail,
  ) async {
    final Razorpay razorpay = Razorpay();
    PaymentResult? result;

    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      result = PaymentResult(
        status: 'success',
        paymentId: response.paymentId,
        orderId: response.orderId,
        signature: response.signature,
      );
    });

    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      result = PaymentResult(
        status: 'failed',
        errorMessage: response.message,
      );
    });

    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse response) {
      result = PaymentResult(
        status: 'failed',
        errorMessage: 'External wallet ${response.walletName} selected, not supported yet.',
      );
    });

    Map<String, dynamic> options = {
      'key': PaymentConfig.razorpayTestKeyId,
      'amount': order.amountInRupees * 100, // in paise
      'name': name,
      'description': description,
      'theme': {'color': '#fb7800'},
    };

    if (order.orderId != null) {
      options['order_id'] = order.orderId;
    }

    if (prefillContact != null || prefillEmail != null) {
      options['prefill'] = {};
      if (prefillContact != null) options['prefill']['contact'] = prefillContact;
      if (prefillEmail != null) options['prefill']['email'] = prefillEmail;
    }

    try {
      razorpay.open(options);
      // Wait for callback to complete
      while (result == null) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } catch (e) {
      result = PaymentResult(status: 'failed', errorMessage: e.toString());
    } finally {
      razorpay.clear();
    }

    return result!;
  }

  Future<bool> verifyPayment(String paymentId, String? orderId, String? signature) async {
    // Stub that returns false for now.
    // TODO: backend POST /api/payments/verify (server-side signature check) and a Razorpay webhook
    return false;
  }
}
