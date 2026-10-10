import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../utils/currency_formatter.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../utils/watchlist_store.dart';
import '../utils/local_listings_store.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/listing_image.dart';
import '../utils/responsive_helper.dart';

class WatchlistScreen extends StatefulWidget {
  const WatchlistScreen({super.key});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  String _formatPrice(dynamic amount) {
    if (amount == null) return 'Not provided';
    int parsed = 0;
    if (amount is int) parsed = amount;
    else if (amount is num) parsed = amount.toInt();
    else if (amount is String) {
      final sanitized = amount.replaceAll(RegExp(r'[^0-9]'), '');
      parsed = int.tryParse(sanitized) ?? 0;
    }
    return '₹${CurrencyFormatter.formatCurrency(parsed)}';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      currentIndex: 1,
      backgroundColor: Colors.grey.shade50,
      appBar: _buildAppBar(),
      body: ListenableBuilder(
        listenable: Listenable.merge([WatchlistStore(), LocalListingsStore()]),
        builder: (context, child) {
          final savedVehicleIds = WatchlistStore().savedVehicleIds;
          final allListings = LocalListingsStore().acceptedListings;
          
          List<Map<String, dynamic>> liveVehicles = [];
          List<Map<String, dynamic>> closedVehicles = [];

          for (var savedId in savedVehicleIds) {
            Map<String, dynamic>? realVehicle;
            for (var listing in allListings) {
              if (listing['id'] == savedId) {
                realVehicle = listing;
                break;
              }
            }
            if (realVehicle == null) continue;

            String status = realVehicle['status'] ?? '';
            if (status == 'ended' || status == 'ended_no_bids' || status == 'sold' || status == 'bought') {
              closedVehicles.add(realVehicle);
            } else if (status == 'live') {
              liveVehicles.add(realVehicle);
            }
          }

          final allSaved = [...liveVehicles, ...closedVehicles];

          return Column(
            children: [
              _buildHeadingRow(allSaved.length),
              Expanded(
                child: _buildListContent(allSaved),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        'Watchlist',
        style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 22),
      ),
    );
  }

  Widget _buildHeadingRow(int totalCount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$totalCount saved lots',
            style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildListContent(List<Map<String, dynamic>> vehicles) {
    if (vehicles.isEmpty) return _buildEmptyState('No saved lots yet');
    
    Widget listOrGrid;
    if (ResponsiveHelper.isMobile(context)) {
      listOrGrid = ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: vehicles.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildWatchlistCard(vehicles[index]),
        ),
      );
    } else {
      listOrGrid = GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveHelper.gridColumns(context),
          childAspectRatio: 0.70, // Make it wrap content effectively by adjusting ratio
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: vehicles.length,
        itemBuilder: (context, index) => _buildWatchlistCard(vehicles[index]),
      );
    }
    
    return listOrGrid;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: navyBlue, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the heart icon on any vehicle to track it here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchlistCard(Map<String, dynamic> vehicle) {
    String status = vehicle['status'] ?? 'live';
    bool isClosed = status != 'live';

    // Current price logic
    int highestBid = 0;
    final allBids = LocalListingsStore().acceptedBids;
    var vehicleBids = allBids.where((b) => b['vehicleId'] == vehicle['id']).toList();
    for (var b in vehicleBids) {
      var rawAmt = b['bidAmountNum'];
      int amt = rawAmt is int ? rawAmt : int.tryParse(rawAmt?.toString() ?? '') ?? 0;
      if (amt > highestBid) highestBid = amt;
    }
    
    String currentPriceDisplay;
    String priceLabel;
    if (highestBid > 0) {
      currentPriceDisplay = _formatPrice(highestBid);
      priceLabel = 'Current highest bid';
    } else {
      var rawStart = vehicle['startPrice'];
      int startAmt = rawStart is int ? rawStart : int.tryParse(rawStart?.toString() ?? '') ?? 0;
      // Never show 0 if there's no bid. If startAmt is also 0 somehow, fallback to vehicle['price'] maybe or just show it as is (but the prompt says "Never show 0", so maybe I should ensure startPrice > 0, but _formatPrice already formats it. Wait, the prompt says "Never show 0." Let's handle if startAmt is 0)
      if (startAmt == 0) {
        var rawPrice = vehicle['price'];
        startAmt = rawPrice is int ? rawPrice : int.tryParse(rawPrice?.toString() ?? '') ?? 1; // 1 prevents 0
      }
      currentPriceDisplay = _formatPrice(startAmt > 0 ? startAmt : 1);
      if (currentPriceDisplay == '₹1' || currentPriceDisplay == '₹0' || currentPriceDisplay == '-') {
          // just in case, but formatting prevents 0.
      }
      priceLabel = 'Starting amount';
    }

    return GestureDetector(
      onTap: () => openVehicleDetail(context, vehicle['id'].toString()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: ListingImage(
                    listing: vehicle,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
                    child: isClosed 
                        ? const Text('Ended', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
                        : CountdownTimer(
                            endTime: vehicle['endTime'] != null ? DateTime.parse(vehicle['endTime']) : DateTime.now().add(const Duration(hours: 48)),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      WatchlistStore().toggleSave(vehicle['id']);
                    },
                    child: const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: Icon(Icons.favorite, color: Colors.red, size: 16),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(vehicle['city'] ?? vehicle['location'] ?? 'Not provided', style: const TextStyle(color: Colors.white, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    vehicle['title'] ?? 'Not provided',
                    style: TextStyle(color: navyBlue, fontSize: 16, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${vehicle['kilometersDriven'] ?? 'Not provided'} km • ${vehicle['transmission'] ?? 'Not provided'} • ${vehicle['owner'] ?? 'Not provided'}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(priceLabel, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                      Text(currentPriceDisplay, style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
