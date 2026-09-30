import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../services/payment_service.dart';
import '../services/admin_notification_store.dart';
import '../widgets/responsive_secondary_scaffold.dart';
import '../widgets/upi_payment_section.dart';
import '../config/payment_config.dart';
import '../utils/local_listings_store.dart';
import '../services/payment_records_store.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/profile_storage_helper.dart';

// TODO: Payment status is NOT confirmed by the app. Real confirmation must come from backend (gateway webhook / bank reconciliation).
// Replace manual UTR verification with a payment gateway and backend-driven status once connected.

class PaymentScreen extends StatefulWidget {
  final String id;
  final String title;
  final String image;
  final int amount;
  final String seller;
  final String initialStep;

  const PaymentScreen({
    super.key,
    this.id = '',
    required this.title,
    required this.image,
    required this.amount,
    required this.seller,
    this.initialStep = 'token',
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  late String _currentStep;
  bool _isLoading = false;
  bool _awaitingUpiReturn = false;
  bool _showManualUpi = false;

  final TextEditingController _utrController = TextEditingController();
  XFile? _screenshot;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _utrController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _awaitingUpiReturn) {
      _awaitingUpiReturn = false;
      _showUpiCompletionDialog();
    }
  }

  String _formatAmount(int amount) {
    return NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
        .format(amount);
  }

  Future<void> _openCheckout() async {
    final order = await PaymentService().createOrder(
      amountInRupees: PaymentConfig.tokenAmount,
      purpose: 'Token for ${widget.title}',
      referenceId: 'tok_${widget.id}_${DateTime.now().millisecondsSinceEpoch}',
    );

    final result = await PaymentService().startCheckout(
      context,
      order,
      name: 'Wheels2Drive',
      description: 'Token for ${widget.title}',
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
      _submitPayment('token', result.paymentId ?? 'TXN_SUCCESS');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(result.errorMessage ??
                'Payment failed / cancelled, please try again')),
      );
    }
  }

  void _showUpiCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Did you complete the payment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not yet'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showVerificationForm('token');
            },
            child: const Text('Yes, I paid'),
          ),
        ],
      ),
    );
  }

  void _showVerificationForm(String type) {
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
                      await _submitPayment(type, _utrController.text);
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

  Future<void> _submitPayment(String type, String utr) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final amt = type == 'token'
        ? PaymentConfig.tokenAmount
        : (widget.amount - PaymentConfig.tokenAmount);

    // TODO: Frontend can only check UTR format and duplicates, and require a screenshot —
    // it CANNOT cryptographically verify a real bank/UPI transaction occurred.
    // Real verification requires backend integration: Razorpay/NPCI transaction lookup API,
    // or bank statement reconciliation, replacing this manual admin cross-check step.

    final phone = AuthService().currentPhone;
    final normalizedPhone = ProfileStorageHelper.normalizePhone(phone!);
    final prefs = await SharedPreferences.getInstance();
    final realName = prefs.getString('user_name_$normalizedPhone') ?? 'Unknown User';

    LocalListingsStore().addPendingPayment({
      'id': widget.id,
      'vehicle': widget.title,
      'buyer': realName,
      'type': type,
      'amount': amt,
      'utr': utr,
      'screenshot': _screenshot?.path,
      'status': 'Pending Verification',
    });

    PaymentRecordsStore().recordUtr(utr);

    AdminNotificationStore().addNotification(
        'Payment submitted: ${_formatAmount(amt)} ($type) for ${widget.title} by $realName, UTR $utr',
        'payment',
        relatedItemId: widget.id);

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
                context.pop(true);
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
      currentIndex: 3,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Complete Payment'),
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
              _buildInfoBanner(),
              const SizedBox(height: 16),
              _buildSummaryCard(),
              const SizedBox(height: 24),
              if (_currentStep == 'token')
                _buildTokenStep()
              else
                _buildBalanceStep(),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Payments are confirmed only after verification by Wheels2Drive.',
              style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final balanceAmt = widget.amount - PaymentConfig.tokenAmount;
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
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.image.startsWith('http')
                    ? Image.network(widget.image,
                        width: 60, height: 60, fit: BoxFit.cover)
                    : Image.asset(widget.image,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.directions_car))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            color: navyBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Total: ${_formatAmount(widget.amount)}',
                        style: TextStyle(
                            color: navyBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step 1 Token:',
                  style: TextStyle(
                      color: _currentStep == 'token'
                          ? orange
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold)),
              Text(_formatAmount(PaymentConfig.tokenAmount),
                  style: TextStyle(
                      color: _currentStep == 'token'
                          ? orange
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step 2 Balance:',
                  style: TextStyle(
                      color: _currentStep == 'balance'
                          ? orange
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold)),
              Text(_formatAmount(balanceAmt),
                  style: TextStyle(
                      color: _currentStep == 'balance'
                          ? orange
                          : Colors.grey.shade600,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Note: UPI has per-transaction limits, so the balance is paid by bank transfer (NEFT/RTGS).',
            style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 1: Pay Token Amount',
            style: TextStyle(
                color: navyBlue, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
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
                amount: PaymentConfig.tokenAmount,
                transactionNote: 'Token for ${widget.title}',
                onVerificationRequested: () => _showVerificationForm('token'),
                onAwaitingUpiReturnChanged: (val) => _awaitingUpiReturn = val,
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.security, size: 48, color: orange),
                const SizedBox(height: 16),
                Text(
                  'Pay the refundable token of ${_formatAmount(PaymentConfig.tokenAmount)} securely to participate in the auction.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 24),
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
                    child: const Text('Pay Securely',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBalanceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Step 2: Pay Balance via Bank Transfer',
            style: TextStyle(
                color: navyBlue, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('Use NEFT/RTGS and add reference ${widget.id}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200)),
          child: Column(
            children: [
              _buildBankDetailRow('Bank', PaymentConfig.bankName),
              const Divider(),
              _buildBankDetailRow('Account Name', PaymentConfig.accountName),
              const Divider(),
              _buildBankDetailRow('Account No.', PaymentConfig.accountNumber),
              const Divider(),
              _buildBankDetailRow('IFSC', PaymentConfig.ifsc),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showVerificationForm('balance'),
            style: ElevatedButton.styleFrom(
                backgroundColor: orange,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Submit UTR Details',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildBankDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
        Row(
          children: [
            Text(value,
                style: TextStyle(
                    color: navyBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$label Copied!'),
                    duration: const Duration(seconds: 1)));
              },
              child: const Icon(Icons.copy, size: 16, color: Colors.blue),
            ),
          ],
        ),
      ],
    );
  }
}
