import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:go_router/go_router.dart';
import '../services/listing_document_service.dart';
import '../utils/local_listings_store.dart';
import '../services/share_service.dart';

class ListingPdfScreen extends StatelessWidget {
  final String listingId;

  const ListingPdfScreen({super.key, required this.listingId});

  static bool _b(dynamic v) => v == true || v == 1 || v == 'true';

  @override
  Widget build(BuildContext context) {
    final allListings = [
      ...LocalListingsStore().pendingListings,
      ...LocalListingsStore().acceptedListings,
      ...LocalListingsStore().rejectedListings,
    ];

    final listing = allListings.firstWhere(
      (l) => l['id'] == listingId,
      orElse: () => {},
    );

    if (listing.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Listing PDF'),
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Listing PDF',
                style: TextStyle(fontSize: 14, color: Colors.grey)),
            Text(listing['title'] ?? 'Listing',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
            child: Column(
              children: [
                Expanded(
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
                    child: FutureBuilder<Uint8List>(
                      future: Future.value(
                          ListingDocumentService.generateListingPdf(listing)),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                              child: CircularProgressIndicator());
                        final pdfData = snapshot.data!;
                        return Column(
                          children: [
                            Expanded(
                              child: PdfPreview(
                                build: (format) => pdfData,
                                canChangeOrientation: false,
                                canChangePageFormat: false,
                                canDebug: false,
                                useActions: false,
                              ),
                            ),
                            Container(
                              color: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildActionBtn(
                                    icon: Icons.download,
                                    label: 'Download',
                                    onTap: () => ShareService.downloadPdf(
                                        context,
                                        pdfData,
                                        'listing-${listing['id']}.pdf'),
                                  ),
                                  _buildActionBtn(
                                    icon: Icons.print,
                                    label: 'Print',
                                    onTap: () async {
                                      try {
                                        await Printing.layoutPdf(
                                            onLayout: (format) async =>
                                                pdfData);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(
                                                      'Print failed: $e')));
                                        }
                                      }
                                    },
                                  ),
                                  _buildActionBtn(
                                    icon: Icons.share,
                                    label: 'Share',
                                    onTap: () => ShareService.shareListingPdf(
                                        context, pdfData, listing),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
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
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF001128),
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
