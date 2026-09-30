import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../widgets/responsive_secondary_scaffold.dart';
import '../widgets/upi_payment_section.dart';
import '../services/subscription_store.dart';
import '../services/admin_notification_store.dart';
import '../utils/local_listings_store.dart';
import '../config/subscription_plans.dart';
import '../services/payment_service.dart';
import 'package:image_picker/image_picker.dart';
import '../services/payment_records_store.dart';
import '../utils/profile_storage_helper.dart';
import '../services/auth_service.dart';

class SubscriptionCheckoutScreen extends StatefulWidget {
  final String planId;

  const SubscriptionCheckoutScreen({super.key, required this.planId});

  @override
  State<SubscriptionCheckoutScreen> createState() =>
      _SubscriptionCheckoutScreenState();
}

class _SubscriptionCheckoutScreenState
    extends State<SubscriptionCheckoutScreen> {
  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  bool _isLoading = false;
  bool _showManualUpi = false;
  bool _awaitingUpiReturn = false;

  final TextEditingController _utrController = TextEditingController();
  XFile? _screenshot;

  late SubscriptionPlan _plan;

  @override
  void initState() {
    super.initState();
    _plan = SubscriptionPlans.getPlanById(widget.planId)!;
  }

  @override
  void dispose() {
    _utrController.dispose();
    super.dispose();
  }

  Future<void> _openCheckout() async {
    final order = await PaymentService().createOrder(
      amountInRupees: _plan.price,
      purpose: 'Subscription: ${_plan.name}',
      referenceId: 'sub_${_plan.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    final result = await PaymentService().startCheckout(
      context,
      order,
      name: 'Wheels2Drive',
      description: 'Subscription: ${_plan.name}',
      prefillContact: '9999999999',
      prefillEmail: 'test@wheels2drive.com',
    );

    if (result.status == 'fallback_to_manual') {
      setState(() {
        _showManualUpi = true;
      });
      return;
    }

    if (result.status == 'success') {
      _submitPayment(result.paymentId ?? 'TXN_SUCCESS');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.errorMessage ??
                'Payment failed / cancelled, please try again')),
      );
    }
  }

  String _formatAmount(int amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(amount);
  }

  void _showVerificationForm() {
    _utrController.clear();
    _screenshot = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit Payment Details',
                    style: TextStyle(
                        color: navyBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: _utrController,
                  decoration: const InputDecoration(
                    labelText: 'Transaction/UTR ID (12 digits)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                ),
                if (_utrController.text.isNotEmpty &&
                    !RegExp(r'^[0-9]{12}$').hasMatch(_utrController.text))
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Enter a valid 12-digit UTR/Transaction ID',
                        style: TextStyle(color: Colors.red, fontSize: 12)),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setModalState(() => _screenshot = image);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label:
                            const Text('Upload payment screenshot (required)'),
                      ),
                    ),
                  ],
                ),
                if (_screenshot != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Screenshot attached: ${_screenshot!.name}',
                        style:
                            const TextStyle(color: Colors.green, fontSize: 12)),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!RegExp(r'^[0-9]{12}$')
                          .hasMatch(_utrController.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Please enter a valid 12-digit UTR/Transaction ID.')));
                        return;
                      }
                      if (_screenshot == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'Please upload a screenshot of your payment confirmation before submitting.')));
                        return;
                      }
                      if (PaymentRecordsStore()
                          .isUtrAlreadyUsed(_utrController.text)) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text(
                                'This transaction ID has already been used. Each payment must have a unique UTR. If you believe this is an error, contact support.')));
                        return;
                      }

                      Navigator.pop(context);
                      await _submitPayment(_utrController.text);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: orange,
                        padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: const Text('Submit',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitPayment(String utr) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    // TODO: Frontend can only check UTR format and duplicates, and require a screenshot —
    // it CANNOT cryptographically verify a real bank/UPI transaction occurred.
    // Real verification requires backend integration: Razorpay/NPCI transaction lookup API,
    // or bank statement reconciliation, replacing this manual admin cross-check step.

    await SubscriptionStore().submitRequest(_plan.id);

    final phone = AuthService().currentPhone;
    final realName =
        await ProfileStorageHelper.getProfileField(phone ?? '', 'user_name') ??
            (phone != null && phone.isNotEmpty ? phone : 'Unknown User');

    final subId = 's_new_${DateTime.now().millisecondsSinceEpoch}';
    LocalListingsStore().addPendingSubscription({
      'id': subId,
      'businessName': realName, // use actual user's name
      'tier': _plan.name,
      'tierColor': orange,
      'id1Label': 'GSTIN',
      'id1Value': 'Not Provided',
      'id2Label': 'PAN',
      'id2Value': 'Not Provided',
      'timeAgo': 'Just now',
      'price': _formatAmount(_plan.price),
      'payRef': utr,
      'screenshot': _screenshot?.path,
      'paymentStatus': 'Pending Verification',
      'gstStatus': 'N/A',
      'kycDocs': 'Not Attached',
      'dealerName': realName,
      'planId': _plan.id,
      'phone': phone,
    });

    AdminNotificationStore().addNotification(
        'New subscription request: ${_plan.name} ${_formatAmount(_plan.price)} by $realName, Ref $utr',
        'subscription',
        relatedItemId: subId);

    PaymentRecordsStore().recordUtr(utr);

    setState(() => _isLoading = false);

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Pending Verification'),
          content: const Text(
              'Submitted for verification. Our team will confirm your payment within 24 hours after checking your transaction ID and screenshot.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                context.go('/subscription');
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveSecondaryScaffold(
      currentIndex: 4,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: navyBlue),
          onPressed: () => context.pop(),
        ),
        titleTextStyle: TextStyle(
            color: navyBlue, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(),
              const SizedBox(height: 24),
              if (_showManualUpi)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pay via UPI',
                        style: TextStyle(
                            color: navyBlue,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    UpiPaymentSection(
                      amount: _plan.price,
                      transactionNote: 'Subscription ${_plan.name}',
                      onVerificationRequested: () {
                        _showVerificationForm();
                      },
                      onAwaitingUpiReturnChanged: (val) =>
                          _awaitingUpiReturn = val,
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _openCheckout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Proceed to Pay securely',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final now = DateTime.now();
    final end = now.add(Duration(days: _plan.durationDays));
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Subscription Plan',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 4),
          Text(_plan.name,
              style: TextStyle(
                  color: navyBlue, fontSize: 20, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Duration:', style: TextStyle(color: Colors.grey.shade600)),
              Text('${_plan.durationDays} Days',
                  style:
                      TextStyle(color: navyBlue, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Validity:', style: TextStyle(color: Colors.grey.shade600)),
              Text('${dateFormat.format(now)} - ${dateFormat.format(end)}',
                  style:
                      TextStyle(color: navyBlue, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Amount',
                  style: TextStyle(
                      color: navyBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(_formatAmount(_plan.price),
                  style: TextStyle(
                      color: orange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
