import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../utils/watchlist_store.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/custom_network_image.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_secondary_scaffold.dart';

enum BidValidationState { empty, valid, invalid }

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;
  final Map<String, dynamic>? vehicleData;
  final bool isOwner;
  final bool isPending;

  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    this.vehicleData,
    this.isOwner = false,
    this.isPending = false,
  });

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final Color navy = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  int currentBid = 3850000;
  int offerAmount = 3875000;

  // Mock variables for testing banners
  bool hasUserBid = false;
  bool isHighestBidder = false;

  late TextEditingController _offerController;

  int get minimumRequiredBid {
    int bidsPlaced = int.tryParse(_vehicleData['bidsPlaced'].toString()) ?? 0;
    if (bidsPlaced == 0) return currentBid;
    return currentBid + 5000; // Mock minimum increment
  }

  BidValidationState get bidState {
    if (_offerController.text.isEmpty) return BidValidationState.empty;
    final entered =
        int.tryParse(_offerController.text.replaceAll(',', '')) ?? 0;
    return entered >= minimumRequiredBid
        ? BidValidationState.valid
        : BidValidationState.invalid;
  }

  @override
  void initState() {
    super.initState();
    _offerController =
        TextEditingController(text: _formatCurrency(offerAmount));
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    String str = amount.toString();
    if (str.length <= 3) return str;
    String lastThree = str.substring(str.length - 3);
    String otherNumbers = str.substring(0, str.length - 3);
    if (otherNumbers.isNotEmpty) {
      lastThree = ',' + lastThree;
    }
    String result = '';
    for (int i = otherNumbers.length - 1, count = 1; i >= 0; i--, count++) {
      result = otherNumbers[i] + result;
      if (count % 2 == 0 && i != 0) {
        result = ',' + result;
      }
    }
    return result + lastThree;
  }

  void _incrementOffer(int amount) {
    setState(() {
      int baseAmount = offerAmount;
      if (offerAmount == 0) {
        final entered =
            int.tryParse(_offerController.text.replaceAll(',', '')) ?? 0;
        baseAmount = entered > 0 ? entered : currentBid;
      }
      offerAmount = baseAmount + amount;
      _offerController.text = _formatCurrency(offerAmount);
    });
  }

  void _onOfferChanged(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanValue.isNotEmpty) {
      setState(() {
        offerAmount = int.parse(cleanValue);
      });
    } else {
      setState(() {
        offerAmount = 0;
      });
    }
  }

  Map<String, dynamic> get _vehicleData =>
      widget.vehicleData ??
      {
        'id': widget.vehicleId,
        'title': '2022 Audi Q5 45 TFSI Quattro',
        'image':
            'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=800&q=80',
        'year': '2022',
        'name': 'Audi Q5 45 TFSI Quattro',
        'currentBid': _formatCurrency(currentBid),
        'location': 'KA-01',
        'bidsPlaced': '18',
      };

  Future<void> _shareVehicle() async {
    final vehicle = _vehicleData;
    final String message =
        "Check out this ${vehicle['year']} ${vehicle['name']} on Wheels2Drive!\n"
        "💰 Current Bid: ₹${vehicle['currentBid']}\n"
        "📍 Location: ${vehicle['location']}\n"
        "⏱ ${vehicle['bidsPlaced']} Bids Placed\n"
        "🔗 View details: https://wheels2drive.app/vehicle/${vehicle['id']}";

    try {
      if (kIsWeb) {
        try {
          await Share.share(message);
        } catch (e) {
          await Clipboard.setData(ClipboardData(text: message));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      "Vehicle details copied! Paste it in WhatsApp or wherever you want to share.")),
            );
          }
        }
      } else {
        await Share.share(message);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sharing vehicle: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int enteredOffer =
        int.tryParse(_offerController.text.replaceAll(',', '')) ?? 0;
    int difference = enteredOffer - currentBid;
    int bidsPlaced = int.tryParse(_vehicleData['bidsPlaced'].toString()) ?? 0;

    return ResponsiveSecondaryScaffold(
      currentIndex: 0,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car, color: Colors.black, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Vehicle Detai...',
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: _shareVehicle,
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Color(0xFF001128),
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Stack(
              children: [
                CustomNetworkImage(
                  imageUrl: _vehicleData['image'],
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                ),
                // Back Arrow overlay on image
                Positioned(
                  top: 16,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.black, size: 20),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/');
                        }
                      },
                    ),
                  ),
                ),
                if (widget.isPending)
                  Positioned(
                    top: 16,
                    right: 64,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.hourglass_empty,
                              color: Colors.white, size: 12),
                          SizedBox(width: 6),
                          Text('PENDING APPROVAL',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else
                  Positioned(
                    top: 16,
                    right: 64,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 6),
                          Text('LIVE AUCTION',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                // Bookmark
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: ListenableBuilder(
                      listenable: WatchlistStore(),
                      builder: (context, child) {
                        bool isSaved = WatchlistStore().isSaved(_vehicleData);
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? orange : Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            WatchlistStore().toggleSave(_vehicleData);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isSaved
                                    ? 'Removed from Watchlist'
                                    : 'Added to Watchlist'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
                // Time left
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.access_time, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text('Ends in 04m 32s',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
                // Inspected
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 6),
                        Text('140-Pt Inspected',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info
                  const Text(
                    'KA-01 • DL3849 • 24,800 KM • Petrol Automatic',
                    style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _vehicleData['title'] ?? 'Vehicle Title',
                    style: TextStyle(
                        color: navy,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2),
                  ),
                  const SizedBox(height: 24),

                  // Banners
                  if (hasUserBid)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isHighestBidder
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isHighestBidder
                                ? Icons.check_circle
                                : Icons.warning_amber,
                            color: isHighestBidder
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHighestBidder
                                  ? "You're currently the highest bidder!"
                                  : "You've been outbid! Current highest is ₹${_formatCurrency(currentBid)}",
                              style: TextStyle(
                                color: isHighestBidder
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFDC2626),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Current Bid Card
                  if (bidsPlaced == 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          left: BorderSide(color: orange, width: 4),
                          top: BorderSide(color: Colors.grey.shade300),
                          right: BorderSide(color: Colors.grey.shade300),
                          bottom: BorderSide(color: Colors.grey.shade300),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Starting Price',
                                        style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('₹${_vehicleData['currentBid']}',
                                        style: TextStyle(
                                            color: navy,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '🏁 First Bid Opportunity',
                                  style: TextStyle(
                                      color: orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(Icons.flag_circle, color: orange, size: 24),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('No Bids Yet',
                                      style: TextStyle(
                                          color: navy,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  const Text(
                                      'Be the first to bid on this vehicle!',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            runSpacing: 8,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('CURRENT HIGHEST BID',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('₹${_vehicleData['currentBid']}',
                                      style: TextStyle(
                                          color: navy,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Text('${_vehicleData['bidsPlaced']} Bids Placed',
                                  style: const TextStyle(
                                      color: Color(0xFFFB7800),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.circle,
                                  color: Colors.green, size: 8),
                              const SizedBox(width: 8),
                              Text('Reserve met • Fast-track transfer verified',
                                  style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Instant Increments
                  const Text('Instant Increments',
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildIncrementButton(2000),
                      _buildIncrementButton(5000),
                      _buildIncrementButton(10000),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Your Offer Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Your Offer',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Min: ₹${_formatCurrency(minimumRequiredBid)}',
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: bidState == BidValidationState.valid
                            ? const Color(0xFF22C55E) // Green
                            : bidState == BidValidationState.invalid
                                ? const Color(0xFFEF4444) // Red
                                : Colors.grey.shade300, // Neutral
                        width: bidState == BidValidationState.empty ? 1 : 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _offerController,
                      keyboardType: TextInputType.number,
                      onChanged: _onOfferChanged,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Validation Helper text
                  if (bidState == BidValidationState.empty)
                    Row(
                      children: [
                        const SizedBox(width: 4),
                        Text(
                          'Enter an amount of at least ₹${_formatCurrency(minimumRequiredBid)}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    )
                  else if (bidState == BidValidationState.valid)
                    Row(
                      children: [
                        const Icon(Icons.check_circle,
                            color: Color(0xFF22C55E), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Valid bid — increases current bid by ₹${_formatCurrency(difference)}',
                          style: const TextStyle(
                              color: Color(0xFF16A34A),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.cancel,
                            color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Bid too low — minimum is ₹${_formatCurrency(minimumRequiredBid)}',
                          style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),

                  // Place Bid Button
                  if (widget.isOwner)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: null, // Disabled for owner
                        style: ElevatedButton.styleFrom(
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('You cannot bid on your own listing',
                            style: TextStyle(
                                color: Colors.black54,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: (bidState == BidValidationState.valid)
                            ? () {
                                context.push('/confirmation/bid');
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: orange,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.gavel, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Place Bid',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncrementButton(int amount) {
    return InkWell(
      onTap: () => _incrementOffer(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '+ ₹${_formatCurrency(amount)}',
            style: TextStyle(
                color: navy, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
