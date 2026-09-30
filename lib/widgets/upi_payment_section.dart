import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import '../config/payment_config.dart';

class UpiPaymentSection extends StatefulWidget {
  final int amount;
  final String transactionNote;
  final VoidCallback onVerificationRequested;
  final Function(bool) onAwaitingUpiReturnChanged;

  const UpiPaymentSection({
    super.key,
    required this.amount,
    required this.transactionNote,
    required this.onVerificationRequested,
    required this.onAwaitingUpiReturnChanged,
  });

  @override
  State<UpiPaymentSection> createState() => _UpiPaymentSectionState();
}

class _UpiPaymentSectionState extends State<UpiPaymentSection> {
  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  Future<void> _launchUpi(String scheme) async {
    final String upiUrl = 'upi://pay?pa=${PaymentConfig.upiId}&pn=${Uri.encodeComponent(PaymentConfig.payeeName)}&am=${widget.amount}.00&cu=INR&tn=${Uri.encodeComponent(widget.transactionNote)}';
    final String fullUrl = scheme.isNotEmpty ? scheme + upiUrl.substring(6) : upiUrl;
    
    try {
      final Uri uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        widget.onAwaitingUpiReturnChanged(true);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (scheme.isNotEmpty) {
        final Uri genericUri = Uri.parse(upiUrl);
        if (await canLaunchUrl(genericUri)) {
          widget.onAwaitingUpiReturnChanged(true);
          await launchUrl(genericUri, mode: LaunchMode.externalApplication);
        } else {
          _showNoUpiAppError();
        }
      } else {
        _showNoUpiAppError();
      }
    } catch (e) {
      _showNoUpiAppError();
    }
  }

  void _showNoUpiAppError() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No UPI app found. Use the QR code or UPI ID.')));
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = !kIsWeb && (Theme.of(context).platform == TargetPlatform.iOS || Theme.of(context).platform == TargetPlatform.android);
    final bool useQr = kIsWeb || !isMobile;

    if (useQr) {
      return _buildQrSection();
    } else {
      return _buildMobileUpiSection();
    }
  }

  Widget _buildMobileUpiSection() {
    return Column(
      children: [
        _buildUpiAppButton('Google Pay', 'gpay://upi/pay?', Colors.white, Colors.black),
        const SizedBox(height: 12),
        _buildUpiAppButton('PhonePe', 'phonepe://pay?', const Color(0xFF5F259F), Colors.white),
        const SizedBox(height: 12),
        _buildUpiAppButton('Paytm', 'paytmmp://pay?', const Color(0xFF002970), Colors.white),
        const SizedBox(height: 12),
        _buildUpiAppButton('Other UPI apps', '', Colors.grey.shade200, Colors.black),
        const SizedBox(height: 24),
        TextButton(
          onPressed: widget.onVerificationRequested,
          child: const Text('Already Paid? Submit UTR'),
        ),
      ],
    );
  }

  Widget _buildUpiAppButton(String label, String scheme, Color bgColor, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _launchUpi(scheme),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQrSection() {
    return Center(
      child: Column(
        children: [
          QrImageView(
            data: 'upi://pay?pa=${PaymentConfig.upiId}&pn=${Uri.encodeComponent(PaymentConfig.payeeName)}&am=${widget.amount}.00&cu=INR&tn=${Uri.encodeComponent(widget.transactionNote)}',
            version: QrVersions.auto,
            size: 200.0,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(PaymentConfig.upiId, style: TextStyle(color: navyBlue, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.copy, size: 16, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: PaymentConfig.upiId));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('UPI ID Copied!'), duration: Duration(seconds: 1)));
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Scan with any UPI app on your phone', style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onVerificationRequested,
              style: ElevatedButton.styleFrom(backgroundColor: orange, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Submit UTR', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
