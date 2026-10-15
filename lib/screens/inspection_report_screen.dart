import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import '../utils/local_listings_store.dart';
import '../services/share_service.dart';

class InspectionReportScreen extends StatelessWidget {
  final String vehicleId;

  const InspectionReportScreen({super.key, required this.vehicleId});

  @override
  Widget build(BuildContext context) {
    final allListings = [
      ...LocalListingsStore().pendingListings,
      ...LocalListingsStore().acceptedListings,
      ...LocalListingsStore().rejectedListings,
    ];

    final listing = allListings.firstWhere(
      (l) => l['id'] == vehicleId,
      orElse: () => {},
    );

    if (listing.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inspection Report'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/browse');
              }
            },
          ),
        ),
        body: const Center(child: Text('Listing not found')),
      );
    }

    final pdfBytes = listing['inspectionReportBytes'] as Uint8List?;

    if (pdfBytes == null || pdfBytes.length < 4 || pdfBytes[0] != 0x25 || pdfBytes[1] != 0x50 || pdfBytes[2] != 0x44 || pdfBytes[3] != 0x46) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Inspection Report', style: TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/browse');
              }
            },
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Inspection report not uploaded by seller',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/browse');
                  }
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB7800),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Inspection Report', style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(listing['title'] ?? 'Vehicle', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/browse');
            }
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: PdfPreview(
                      build: (format) => pdfBytes,
                      canChangeOrientation: false,
                      canChangePageFormat: false,
                      canDebug: false,
                      useActions: false,
                      pdfPreviewPageDecoration: const BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionBtn(
                          icon: Icons.download,
                          label: 'Download',
                          onTap: () => ShareService.downloadPdf(context, pdfBytes, listing['inspectionReportName'] ?? 'inspection-$vehicleId.pdf'),
                        ),
                        _buildActionBtn(
                          icon: Icons.print,
                          label: 'Print',
                          onTap: () async {
                            try {
                              await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Print failed: $e')));
                              }
                            }
                          },
                        ),
                        _buildActionBtn(
                          icon: Icons.share,
                          label: 'Share',
                          onTap: () => ShareService.shareListingPdf(context, pdfBytes, listing),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF001128)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Color(0xFF001128), fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
