import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../utils/currency_formatter.dart';

class ListingDocumentService {
  static Future<Uint8List> generateListingPdf(Map<String, dynamic> listing) async {
    final pdf = pw.Document();

    final robotoRegular = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    final robotoBold = pw.Font.ttf(await rootBundle.load('assets/fonts/Roboto-Bold.ttf'));

    final theme = pw.ThemeData.withFont(
      base: robotoRegular,
      bold: robotoBold,
    );

    String formatPrice(dynamic val) {
      if (val == null || val == '') return 'Not provided';
      if (val is int) return '₹${CurrencyFormatter.formatCurrency(val)}';
      String numStr = val.toString().replaceAll(RegExp(r'[^0-9]'), '');
      int? parsed = int.tryParse(numStr);
      if (parsed != null) return '₹${CurrencyFormatter.formatCurrency(parsed)}';
      return '₹$val';
    }

    String displayVal(dynamic val) {
      if (val == null || val.toString().trim().isEmpty) return 'Not provided';
      return val.toString();
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (pw.Context context) {
          return pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 10),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount} | Generated on ${DateTime.now().toLocal().toString().split(' ')[0]}',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10),
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              decoration: const pw.BoxDecoration(),
              padding: pw.EdgeInsets.zero,
              margin: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Wheels2Drive Listing Report',
                      style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF001128))),
                  pw.Text('ID: ${displayVal(listing['id'])}',
                      style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                ],
              ),
            ),
            pw.Container(
              height: 1,
              color: const PdfColor.fromInt(0xFFFB7800), // Orange thin divider
              margin: const pw.EdgeInsets.only(bottom: 20),
            ),

            // Step 1: Vehicle Category
            _buildSectionTitle('Step 1: Vehicle Category'),
            _buildInfoTable([
              ['Title', displayVal(listing['title'])],
              ['Vehicle Type', displayVal(listing['vehicleType'])],
              ['Fuel Type', displayVal(listing['fuelType'])],
              ['Transmission', displayVal(listing['transmission'])],
            ]),
            
            // Step 2: Vehicle Identity
            _buildSectionTitle('Step 2: Vehicle Identity'),
            _buildInfoTable([
              ['Registration No.', displayVal(listing['registrationNumber'])],
            ]),

            // Step 3: Vehicle Health & Records
            _buildSectionTitle('Step 3: Vehicle Health & Records'),
            _buildInfoTable([
              ['Kilometers Driven', displayVal(listing['kilometersDriven'])],
              ['Previous Owners', displayVal(listing['owner'])],
              ['Insurance Type', displayVal(listing['insuranceType'])],
              ['Insurance Expiry', listing['insuranceExpiryDate'] != null ? displayVal(listing['insuranceExpiryDate']).split('T')[0] : 'Not provided'],
            ]),

            // Step 4: Upload Photos
            _buildSectionTitle('Step 4: Upload Photos'),
            if (listing['photos'] != null && (listing['photos'] as List).isNotEmpty)
              pw.Wrap(
                spacing: 10,
                runSpacing: 10,
                children: (listing['photos'] as List).take(6).map((photoData) {
                  if (photoData is List<dynamic>) {
                    photoData = Uint8List.fromList(photoData.cast<int>());
                  }
                  if (photoData is Uint8List) {
                    try {
                      final image = pw.MemoryImage(photoData);
                      return pw.Container(
                        width: 150,
                        height: 100,
                        child: pw.Image(image, fit: pw.BoxFit.cover),
                      );
                    } catch (e) {
                      return pw.Text('[Image error]', style: const pw.TextStyle(fontSize: 10));
                    }
                  }
                  return pw.Text('[Unsupported image]', style: const pw.TextStyle(fontSize: 10));
                }).toList(),
              )
            else
              pw.Text('Not provided', style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10)),
            
            pw.SizedBox(height: 20),
            
            // Step 5: Pricing & Auction
            _buildSectionTitle('Step 5: Pricing & Auction'),
            _buildInfoTable([
              ['Expected Price', formatPrice(listing['price'])],
              ['Reserve Price Enabled', listing['reservePriceEnabled'] == true ? 'Yes' : 'No'],
              ['Auction Duration (Hrs)', displayVal(listing['durationHours'])],
              ['Current Status', displayVal(listing['status']).toUpperCase()],
              ['Seller Name', displayVal(listing['sellerName'])],
              ['Seller Phone', displayVal(listing['sellerPhone'])],
            ]),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionTitle(String title) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 10, top: 10),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: const PdfColor.fromInt(0xFF001128)),
      ),
    );
  }

  static pw.Widget _buildInfoTable(List<List<String>> rows) {
    return pw.Table(
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: rows.map((row) {
        return pw.TableRow(
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
          ),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: pw.Text(row[0], style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: pw.Text(row[1], style: const pw.TextStyle(fontSize: 11, color: PdfColors.black)),
            ),
          ],
        );
      }).toList(),
    );
  }
}
