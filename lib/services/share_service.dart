import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' show File, Platform;

import '../utils/currency_formatter.dart';
import '../utils/web_download_helper.dart' if (dart.library.html) '../utils/web_download_helper_web.dart';

class ShareService {
  static const Color navyBlue = Color(0xFF001128);
  static const Color orange = Color(0xFFFB7800);

  static String _generateSummaryText(Map<String, dynamic> listing) {
    // Determine price
    var priceStr = listing['currentBid']?.toString() ?? listing['price']?.toString() ?? '0';
    int priceInt = int.tryParse(priceStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    String formattedPrice = CurrencyFormatter.formatCurrency(priceInt);

    // TODO: include public listing URL when backend provides one
    return '''
Wheels2Drive Listing: ${listing['title']}
Vehicle Type: ${listing['vehicleType'] ?? 'Car'}
Fuel: Petrol/Diesel
Registration: ${listing['registrationNumber'] ?? 'Unknown'}
KM Driven: ${listing['kmDriven'] ?? 'N/A'} km
Starting/Current Price: ₹$formattedPrice

Open the Wheels2Drive app for full details.
'''.trim();
  }

  static Future<void> shareListingPdf(
    BuildContext context,
    Uint8List bytes,
    Map<String, dynamic> listing,
  ) async {
    final String summary = _generateSummaryText(listing);
    final String fileName = 'listing-${listing['id']}.pdf';
    final BuildContext currentContext = context;

    try {
      final xFile = XFile.fromData(bytes, mimeType: 'application/pdf', name: fileName);
      
      // share_plus automatically uses Web Share API if supported (mobile Safari/Chrome).
      // On unsupported desktop browsers, it might throw.
      // ignore: deprecated_member_use
      await Share.shareXFiles(
        [xFile],
        text: summary,
        subject: 'Wheels2Drive Listing: ${listing['title']}',
      );
    } catch (e) {
      if (kIsWeb) {
        // Fallback for Web Desktop where Share API might fail or not support files
        _showWebShareBottomSheet(currentContext, summary, bytes, fileName);
      } else {
        if (currentContext.mounted) {
          ScaffoldMessenger.of(currentContext).showSnackBar(
            SnackBar(content: Text('Failed to share: $e')),
          );
        }
      }
    }
  }

  static Future<void> downloadPdf(BuildContext context, Uint8List bytes, String fileName) async {
    try {
      if (kIsWeb) {
        WebDownloadHelper.downloadBytes(bytes, fileName);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download started')),
        );
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saved to: ${file.path}')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download: $e')),
        );
      }
    }
  }

  static void _showWebShareBottomSheet(
    BuildContext context,
    String summary,
    Uint8List bytes,
    String fileName,
  ) {
    final encodedSummary = Uri.encodeComponent(summary);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Share listing',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: navyBlue,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    onTap: () {
                      _launchUrl('https://wa.me/?text=$encodedSummary', ctx);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.telegram,
                    label: 'Telegram',
                    onTap: () {
                      _launchUrl('https://t.me/share/url?url=&text=$encodedSummary', ctx);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.email,
                    label: 'Email',
                    onTap: () {
                      _launchUrl('mailto:?subject=Wheels2Drive Listing&body=$encodedSummary', ctx);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy,
                    label: 'Copy',
                    onTap: () async {
                      await Clipboard.setData(ClipboardData(text: summary));
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard')),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.download, color: orange),
                title: const Text('Download PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(ctx);
                  downloadPdf(context, bytes, fileName);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: lightBlueGrey,
              child: Icon(icon, color: navyBlue),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  static const Color lightBlueGrey = Color(0xFFEEF1F7);

  static Future<void> _launchUrl(String urlString, BuildContext context) async {
    final uri = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (context.mounted) Navigator.pop(context);
      } else {
        throw Exception('Cannot launch URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open app: $e')),
        );
      }
    }
  }
}
