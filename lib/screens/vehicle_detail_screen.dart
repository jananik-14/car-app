import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../utils/watchlist_store.dart';
import 'package:share_plus/share_plus.dart';
import '../utils/blob_storage.dart';
import '../widgets/listing_image.dart';
import 'package:go_router/go_router.dart';
import '../widgets/responsive_secondary_scaffold.dart';
import '../services/admin_notification_store.dart';
import '../utils/local_listings_store.dart';
import '../services/subscription_store.dart';
import '../utils/profile_storage_helper.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Mock variables for testing banners
  bool hasUserBid = false;
  bool isHighestBidder = false;

  late TextEditingController _offerController;
  int _currentImageIndex = 0;

  Map<String, dynamic> get _vehicleData {
    final store = LocalListingsStore();
    final allListings = [...store.acceptedListings, ...store.pendingListings, ...store.rejectedListings];
    final liveData = allListings.firstWhere((l) => l['id'] == widget.vehicleId, orElse: () => <String, dynamic>{});
    if (liveData.isNotEmpty) return liveData;
    
    return widget.vehicleData ?? {
      'id': widget.vehicleId,
      'title': '2022 Audi Q5 45 TFSI Quattro',
      'year': '2022',
      'name': 'Audi Q5 45 TFSI Quattro',
      'currentBid': '38,50,000',
      'location': 'KA-01',
      'bidsPlaced': '18',
    };
  }

  int get liveCurrentBid {
    final currentBidVal = _vehicleData['currentBid'] ?? _vehicleData['price'] ?? _vehicleData['bid'] ?? '0';
    String str = currentBidVal.toString().trim();
    if (str.toUpperCase().contains('L')) {
      String numStr = str.replaceAll(RegExp(r'[^0-9.]'), '');
      double val = double.tryParse(numStr) ?? 0;
      return (val * 100000).toInt();
    }
    String currentBidStr = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(currentBidStr) ?? 0;
  }

  int get startingAmount {
    final priceVal = _vehicleData['price'] ?? _vehicleData['bid'] ?? '0';
    String str = priceVal.toString().trim();
    if (str.toUpperCase().contains('L')) {
      String numStr = str.replaceAll(RegExp(r'[^0-9.]'), '');
      double val = double.tryParse(numStr) ?? 0;
      return (val * 100000).toInt();
    }
    String priceStr = str.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(priceStr) ?? 0;
  }

  String formatAsLakh(int rupees) {
    if (rupees >= 100000) {
      return '₹${(rupees / 100000).toStringAsFixed(1)} L';
    }
    return '₹${_formatCurrency(rupees)}';
  }

  int get minimumRequiredBid {
    int current = liveCurrentBid;
    return current + 2000;
  }

  BidValidationState get bidState {
    if (_offerController.text.isEmpty) return BidValidationState.empty;
    final entered =
        int.tryParse(_offerController.text.replaceAll(',', '')) ?? 0;
    return entered >= minimumRequiredBid
        ? BidValidationState.valid
        : BidValidationState.invalid;
  }

  final PageController _pageController = PageController();
  int _photoCount = 1;

  @override
  void initState() {
    super.initState();
    _offerController = TextEditingController();
    _determinePhotoCount();
  }

  Future<void> _determinePhotoCount() async {
    final String id = widget.vehicleId;
    final String phone = _vehicleData['sellerPhone']?.toString() ?? _vehicleData['dealerPhone']?.toString() ?? 'unknown_phone';
    final baseKey = '$phone/$id';
    
    int count = 0;
    final blob = BlobStorage();
    for (int i = 0; i <= 5; i++) {
      final bytes = await blob.get('$baseKey/photo_$i');
      if (bytes != null) {
        count = i + 1;
      }
    }
    if (count == 0) count = 1;
    if (mounted) {
      setState(() {
        _photoCount = count;
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    String str = amount.toString();
    if (str.length <= 3) return str;
    String lastThree = str.substring(str.length - 3);
    String otherNumbers = str.substring(0, str.length - 3);
    if (otherNumbers.isNotEmpty) {
      lastThree = ',$lastThree';
    }
    String result = '';
    for (int i = otherNumbers.length - 1, count = 1; i >= 0; i--, count++) {
      result = otherNumbers[i] + result;
      if (count % 2 == 0 && i != 0) {
        result = ',$result';
      }
    }
    return result + lastThree;
  }

  void _incrementOffer(int amount) {
    _checkSubscriptionAndProceed(() {
      setState(() {
        String currentText = _offerController.text.replaceAll(',', '').replaceAll('₹', '').trim();
        int currentFieldValue = int.tryParse(currentText) ?? liveCurrentBid;
        int newAmount = currentFieldValue + amount;
        _offerController.text = _formatCurrency(newAmount);
        _onOfferChanged(_offerController.text);
      });
    });
  }

  void _onOfferChanged(String value) {
    setState(() {}); // Trigger rebuild to update validation colors
  }

  void _checkSubscriptionAndProceed(VoidCallback onProceed) {
    final store = SubscriptionStore();
    if (store.isActive) {
      onProceed();
    } else {
      _showSubscriptionRequiredSheet(store.isPending);
    }
  }

  void _showSubscriptionRequiredSheet(bool isPending) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 48, color: Color(0xFFFB7800)),
            const SizedBox(height: 16),
            const Text('Subscription required',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001128))),
            const SizedBox(height: 8),
            Text(
              isPending
                  ? 'Your subscription is pending approval.'
                  : 'Subscribe to place bids on live auctions',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFB7800),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View Plans',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  // Map<String, dynamic> get _vehicleData => ... removed, defined above

  Future<void> _shareVehicle() async {
    final vehicle = _vehicleData;
    final String message =
        "Check out this ${vehicle['year']} ${vehicle['name']} on Wheels2Drive!\n"
        "💰 Current Highest Bid: ${formatAsLakh(liveCurrentBid)}\n"
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

  Widget _buildImageGallery() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 250,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _photoCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return ListingImage(
                    listing: _vehicleData,
                    index: index,
                    height: 250,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                },
              ),
            ),
            if (_photoCount > 1) ...[
              Positioned(
                left: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: () {
                      if (_currentImageIndex > 0) {
                        _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                  ),
                ),
              ),
              Positioned(
                right: 16,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withValues(alpha: 0.5),
                  child: IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: () {
                      if (_currentImageIndex < _photoCount - 1) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_photoCount > 1)
          Container(
            height: 60,
            margin: const EdgeInsets.only(top: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _photoCount,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _currentImageIndex == index ? orange : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: ListingImage(
                        listing: _vehicleData,
                        index: index,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  String _buildSpecs(Map<String, dynamic> data) {
    List<String> parts = [];
    final loc = data['locationDisplay'] ?? data['location'] ?? data['city'];
    if (loc != null && loc.toString().isNotEmpty) parts.add(loc.toString());
    final reg = data['regNo'] ?? data['registrationNumber'];
    if (reg != null && reg.toString().isNotEmpty) parts.add(reg.toString());
    final km = data['kilometersDriven'];
    if (km != null && km.toString().isNotEmpty) parts.add('${km.toString()} KM');
    final fuel = data['fuelType'];
    final trans = data['transmission'];
    if (fuel != null && fuel.toString().isNotEmpty && trans != null && trans.toString().isNotEmpty) {
      parts.add('${fuel.toString()} ${trans.toString()}');
    } else if (fuel != null && fuel.toString().isNotEmpty) {
      parts.add(fuel.toString());
    } else if (trans != null && trans.toString().isNotEmpty) {
      parts.add(trans.toString());
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalListingsStore(),
      builder: (context, _) {
        final int enteredOffer =
            int.tryParse(_offerController.text.replaceAll(',', '')) ?? 0;
        int difference = enteredOffer - liveCurrentBid;
    int bidsPlaced = int.tryParse(_vehicleData['bidsPlaced']?.toString() ?? '0') ?? 0;

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
              context.go('/browse');
            }
          },
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_car, color: Colors.black, size: 20),
            SizedBox(width: 8),
            Text(
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
                _buildImageGallery(),
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
                          context.go('/browse');
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
                      child: const Row(
                        children: [
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
                else if (_vehicleData['status'] == 'sold')
                  Positioned(
                    top: 16,
                    right: 64,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: navy,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white, size: 10),
                          SizedBox(width: 6),
                          Text('SOLD',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  )
                else if (_vehicleData['status'] == 'ended' || _vehicleData['status'] == 'ended_no_bids' || _vehicleData['endProcessed'] == true)
                  Positioned(
                    top: 16,
                    right: 64,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.timer_off, color: Colors.white, size: 10),
                          SizedBox(width: 6),
                          Text('ENDED',
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
                      child: const Row(
                        children: [
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
                        bool isSaved = WatchlistStore().isSaved(_vehicleData['id']);
                        return IconButton(
                          icon: Icon(
                            isSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: isSaved ? orange : Colors.black,
                            size: 20,
                          ),
                          onPressed: () {
                            WatchlistStore().toggleSave(_vehicleData['id']);
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
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
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

              ],
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Vehicle Info
                  Text(
                    _buildSpecs(_vehicleData),
                    style: const TextStyle(
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
                                  : "You've been outbid! Current highest is ₹${_formatCurrency(liveCurrentBid)}",
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
                                    Text(formatAsLakh(liveCurrentBid),
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
                                  color: orange.withValues(alpha: 0.1),
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
                                  const Text('STARTING AMOUNT',
                                      style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(formatAsLakh(startingAmount),
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
                          const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Bidding Section
                  Builder(
                    builder: (context) {
                      final currentPhone = ProfileStorageHelper.normalizePhone(AuthService().currentPhone ?? '');
                      final sellerPhone = ProfileStorageHelper.normalizePhone(_vehicleData['phone'] ?? _vehicleData['sellerPhone'] ?? '');
                      final isActualOwner = widget.isOwner || (currentPhone.isNotEmpty && sellerPhone.isNotEmpty && currentPhone == sellerPhone);
                      if (isActualOwner) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Your listing',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }

                      final status = (_vehicleData['status'] ?? '').toString().toLowerCase();
                      final isEndedAuction = status == 'ended' || status == 'ended_no_bids' || status == 'sold' || _vehicleData['endProcessed'] == true;
                      if (isEndedAuction) {
                        final store = LocalListingsStore();
                        final bids = store.acceptedBids.where((b) => (b['vehicleId'] ?? b['listingId'])?.toString() == widget.vehicleId).toList();
                        int highest = 0;
                        String? winnerPhone = _vehicleData['winnerPhone'];
                        for (var b in bids) {
                          var rawAmt = b['bidAmountNum'];
                          int amt = rawAmt is int ? rawAmt : int.tryParse(rawAmt?.toString() ?? '') ?? 0;
                          if (amt > highest) {
                            highest = amt;
                            winnerPhone ??= b['bidderPhone'] ?? b['bidderUsername'];
                          }
                        }
                        
                        final normalizedWinner = ProfileStorageHelper.normalizePhone(winnerPhone ?? '');
                        final bool userWon = (status == 'sold' || highest > 0) && normalizedWinner.isNotEmpty && normalizedWinner == currentPhone;
                        
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: userWon ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: userWon ? Border.all(color: Colors.green) : null,
                          ),
                          child: Center(
                            child: Text(
                              userWon ? 'You won this auction' : 'Auction ended',
                              style: TextStyle(
                                color: userWon ? Colors.green : Colors.grey.shade600,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                              Text('Current Highest Bid: ₹${_formatCurrency(liveCurrentBid)}',
                                  style: TextStyle(
                                      color: Colors.grey.shade600, fontSize: 14, fontWeight: FontWeight.bold)),
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
                              decoration: InputDecoration(
                                hintText: _formatCurrency(minimumRequiredBid),
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: (bidState == BidValidationState.valid)
                                  ? () {
                                      _checkSubscriptionAndProceed(() async {
                                        final bidAmount = _offerController.text;
                                        final title = _vehicleData['title'] ?? 'Vehicle';
                                        final bidId = 'b_new_${DateTime.now().millisecondsSinceEpoch}';
        
                                        final phoneStr = AuthService().currentPhone;
                                        final normalizedPhone = phoneStr != null ? ProfileStorageHelper.normalizePhone(phoneStr) : 'unknown';
                                        final prefs = await SharedPreferences.getInstance();
                                        final realName = prefs.getString('user_name_$normalizedPhone') ?? 'Unknown Bidder';
        
                                        final entered = int.tryParse(bidAmount.replaceAll(',', '')) ?? 0;
        
                                        // Create the real bid object directly (no pending state)
                                        final bidObj = {
                                          'id': bidId,
                                          'auctionId': 'A-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                          'vehicleId': widget.vehicleId, // Link bid to vehicle
                                          'title': title,
                                          'bidAmount': '₹$bidAmount',
                                          'bidAmountNum': entered,
                                          'timeAgo': 'Just now',
                                          'time': DateTime.now().toIso8601String(),
                                          'bidderName': realName,
                                          'bidderUsername': phoneStr ?? 'Unknown',
                                          'dealerId': 'D-1234',
                                          'depositPaid': true,
                                          'depositAmount': '₹10,000',
                                          'escrow': 'Secured',
                                          'score': '4.5 / 5.0',
                                          'ref': 'BID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                                        };
        
                                        // Place bid instantly in the store
                                        final result = LocalListingsStore().placeLiveBid(bidObj, widget.vehicleId);
        
                                        if (result.isSuccess) {
                                          // Update local state variables if any
                                          setState(() {
                                            hasUserBid = true;
                                            isHighestBidder = true;
                                            _offerController.clear();
                                          });
        
                                          AdminNotificationStore().addNotification(
                                              'New live bid placed: ₹$bidAmount on $title by $realName',
                                              'bid',
                                              relatedItemId: bidId);
                                          if (mounted) {
                                            context.push('/confirmation/bid');
                                          }
                                        } else {
                                          setState(() {}); // trigger validation visual update
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(result.errorMessage ?? 'Bid too low'),
                                                backgroundColor: Colors.red,
                                                duration: const Duration(seconds: 4),
                                              )
                                            );
                                          }
                                        }
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orange,
                                disabledBackgroundColor: Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
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
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24), // Bottom padding
                ],
              ),
            ),
          ],
        ),
      ),
    );
    },
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
