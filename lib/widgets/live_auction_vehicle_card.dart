import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../router/app_router.dart';
import '../utils/local_listings_store.dart';
import '../utils/watchlist_store.dart';
import '../services/subscription_store.dart';
import '../services/auth_service.dart';
import '../utils/profile_storage_helper.dart';
import '../services/admin_notification_store.dart';
import 'custom_network_image.dart';
import 'countdown_timer.dart';
import 'listing_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/currency_formatter.dart';

class LiveAuctionVehicleCard extends StatefulWidget {
  final Map<String, dynamic> vehicle;
  final Color lightBlueGrey;

  const LiveAuctionVehicleCard({
    super.key,
    required this.vehicle,
    required this.lightBlueGrey,
  });

  @override
  State<LiveAuctionVehicleCard> createState() => _LiveAuctionVehicleCardState();
}

class _LiveAuctionVehicleCardState extends State<LiveAuctionVehicleCard> {
  late TextEditingController _offerController;
  final Color orange = const Color(0xFFFB7800);
  final Color navy = const Color(0xFF001128);

  Map<String, dynamic> get _liveVehicle {
    return LocalListingsStore().acceptedListings.firstWhere(
          (v) => v['id'] == widget.vehicle['id'],
          orElse: () => widget.vehicle,
        );
  }

  int get liveCurrentBid {
    final currentBidVal = _liveVehicle['currentBid'] ?? _liveVehicle['price'] ?? _liveVehicle['bid'] ?? '0';
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
    final priceVal = widget.vehicle['price'] ?? widget.vehicle['bid'] ?? '0';
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
    return '₹${CurrencyFormatter.formatCurrency(rupees)}';
  }

  int get minimumRequiredBid {
    int current = liveCurrentBid;
    return current + 2000;
  }

  bool get isBidValid {
    if (_offerController.text.isEmpty) return false;
    final entered = int.tryParse(_offerController.text.replaceAll(',', '')) ?? 0;
    return entered >= minimumRequiredBid;
  }

  @override
  void initState() {
    super.initState();
    _offerController = TextEditingController();
  }

  @override
  void dispose() {
    _offerController.dispose();
    super.dispose();
  }

  void _onOfferChanged(String value) {
    String numericOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericOnly.isEmpty) {
      _offerController.value = const TextEditingValue(text: '');
      setState(() {});
      return;
    }
    int amount = int.parse(numericOnly);
    String formatted = CurrencyFormatter.formatCurrency(amount);
    _offerController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    setState(() {});
  }

  void _checkSubscriptionAndProceed(VoidCallback onProceed) {
    bool isSubscribed = SubscriptionStore().isActive;
    bool isPending = SubscriptionStore().isPending;

    if (!isSubscribed) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.lock, color: orange, size: 24),
              ),
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
                    backgroundColor: orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isPending ? 'View Status' : 'Subscribe Now',
                      style: const TextStyle(
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
    } else {
      onProceed();
    }
  }

  void _incrementOffer(int amount) {
    _checkSubscriptionAndProceed(() {
      setState(() {
        String currentText = _offerController.text.replaceAll(',', '').replaceAll('₹', '').trim();
        int currentFieldValue = int.tryParse(currentText) ?? liveCurrentBid;
        int newAmount = currentFieldValue + amount;
        _offerController.text = CurrencyFormatter.formatCurrency(newAmount);
        _onOfferChanged(_offerController.text);
      });
    });
  }

  Widget _buildIncrementButton(int amount) {
    return InkWell(
      onTap: () => _incrementOffer(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('+₹${CurrencyFormatter.formatCurrency(amount)}',
            style: const TextStyle(
                color: Color(0xFF001128),
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Future<void> _submitBid() async {
    final entered = int.tryParse(_offerController.text.replaceAll(',', '').replaceAll('₹', '').trim()) ?? 0;

    _checkSubscriptionAndProceed(() async {
      String bidAmount = _offerController.text;
      
      final phoneStr = AuthService().currentPhone;
      final normalizedPhone = ProfileStorageHelper.normalizePhone(phoneStr ?? '');
      final prefs = await SharedPreferences.getInstance();
      final realName = prefs.getString('user_name_$normalizedPhone') ?? 'Unknown Bidder';
      final title = widget.vehicle['title'] ?? 'Vehicle';

      final bidObj = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'auctionId': 'A-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        'vehicleId': widget.vehicle['id'],
        'bidder': realName,
        'amount': bidAmount,
        'bidAmountNum': entered,
        'time': DateTime.now().toIso8601String(),
        'status': 'Winning',
        
        'vehicle': title,
        'title': title,
        'image': widget.vehicle['image'] ?? widget.vehicle['imageUrl'],
        'auctionEnd': widget.vehicle['endTime'],
        
        'bidderName': realName,
        'bidderUsername': phoneStr ?? 'Unknown',
        'depositPaid': true,
        'depositAmount': '₹10,000',
        'escrow': 'Secured',
        'score': '4.5 / 5.0',
        'ref': 'BID-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
      };

      final result = LocalListingsStore().placeLiveBid(bidObj, widget.vehicle['id']);

      if (result.isSuccess) {
        AdminNotificationStore().addNotification(
            'New live bid placed: ₹$bidAmount on $title by $realName',
            'bid');

        if (mounted) {
          _offerController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bid of ₹$bidAmount placed successfully!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {}); // trigger validation visual update
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'Bid too low'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    });
  }

  String _getTopLine(Map<String, dynamic> vehicle) {
    String reg = (vehicle['regNo'] ?? vehicle['registrationNumber'] ?? '').toString();
    if (reg.length > 5) reg = reg.substring(0, 5);
    return reg.isNotEmpty ? reg : 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => openVehicleDetail(context, widget.vehicle['id'].toString()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: ListingImage(
                    listing: widget.vehicle,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.circle, color: Colors.white, size: 8),
                        SizedBox(width: 4),
                        Text(
                          'LIVE AUCTION',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  bottom: 12,
                  right: 12,
                  child: ListenableBuilder(
                    listenable: WatchlistStore(),
                    builder: (context, child) {
                      bool isSaved = WatchlistStore().isSaved(widget.vehicle['id']);
                      return GestureDetector(
                        onTap: () {
                          WatchlistStore().toggleSave(widget.vehicle['id']);
                        },
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSaved ? Icons.favorite : Icons.favorite_border,
                            color: isSaved ? Colors.red : AppColors.primary,
                            size: 18,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            // Details Area
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getTopLine(widget.vehicle),
                    style: const TextStyle(
                      color: AppColors.outline,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.vehicle['title'],
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        widget.vehicle['location'] ?? widget.vehicle['city'] ?? 'Location not provided',
                        style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListenableBuilder(
                    listenable: LocalListingsStore(),
                    builder: (context, _) {
                      final bidsPlaced = int.tryParse(_liveVehicle['bidsPlaced']?.toString() ?? '0') ?? int.tryParse(_liveVehicle['bids_placed']?.toString() ?? '0') ?? 0;
                      
                      final minRequired = minimumRequiredBid;
                      final isFieldEmpty = _offerController.text.isEmpty;
                      final isValid = isBidValid;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: widget.lightBlueGrey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Starting Amount',
                                      style: TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatAsLakh(startingAmount),
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '$bidsPlaced bids placed',
                                      style: const TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CountdownTimer(
                                          endTime: DateTime.parse(widget.vehicle['endTime']),
                                          style: const TextStyle(
                                            color: AppColors.secondaryContainer,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          endingSoonStyle: const TextStyle(
                                            color: Colors.red,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          onEnd: () {},
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          const SizedBox(height: 16),
                          
                          if (ProfileStorageHelper.normalizePhone(AuthService().currentPhone ?? '') == ProfileStorageHelper.normalizePhone(widget.vehicle['phone'] ?? widget.vehicle['sellerPhone'] ?? ''))
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                            )
                          else ...[
                            // Instant Increments
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildIncrementButton(2000),
                                _buildIncrementButton(5000),
                                _buildIncrementButton(10000),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Your Offer Input
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Your Offer',
                                    style: TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('Current Highest Bid: ₹${CurrencyFormatter.formatCurrency(liveCurrentBid)}',
                                    style: TextStyle(
                                        color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (!isFieldEmpty && !isValid)
                                      ? const Color(0xFFEF4444)
                                      : Colors.grey.shade300,
                                  width: (!isFieldEmpty && !isValid) ? 2 : 1,
                                ),
                              ),
                              child: TextField(
                                controller: _offerController,
                                keyboardType: TextInputType.number,
                                onChanged: _onOfferChanged,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF001128)),
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  prefixStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF001128)),
                                  hintText: CurrencyFormatter.formatCurrency(minRequired),
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
                                  isDense: true,
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            if (!isFieldEmpty && !isValid)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Row(
                                  children: [
                                    const Icon(Icons.cancel,
                                        color: Color(0xFFEF4444), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Bid too low - minimum is ₹${CurrencyFormatter.formatCurrency(minRequired)}',
                                      style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            
                            // Place Bid Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isValid ? _submitBid : null,
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
                                    Icon(Icons.gavel, color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text('Place Bid',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => context.push('/inspection-report/${widget.vehicle['id']}'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary, width: 1.0),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Inspection',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
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
