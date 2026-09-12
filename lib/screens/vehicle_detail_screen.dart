import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class VehicleDetailScreen extends StatefulWidget {
  final String vehicleId;

  const VehicleDetailScreen({super.key, required this.vehicleId});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final Color navy = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);
  
  int currentBid = 3850000;
  int offerAmount = 3875000;
  
  late TextEditingController _offerController;

  @override
  void initState() {
    super.initState();
    _offerController = TextEditingController(text: _formatCurrency(offerAmount));
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
      offerAmount += amount;
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

  @override
  Widget build(BuildContext context) {
    int difference = offerAmount - currentBid;
    
    return Scaffold(
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
              style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.black),
            onPressed: () {},
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Section
                Stack(
                  children: [
                    Image.network(
                      'https://images.unsplash.com/photo-1519641471654-76ce0107ad1b?auto=format&fit=crop&w=800&q=80',
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
                          icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
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
                    // Live Auction badge
                    Positioned(
                      top: 16,
                      right: 64,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 6),
                            Text('LIVE AUCTION', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        child: IconButton(
                          icon: const Icon(Icons.bookmark_border, color: Colors.black, size: 20),
                          onPressed: () {},
                        ),
                      ),
                    ),
                    // Time left
                    Positioned(
                      bottom: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.access_time, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Ends in 04m 32s', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    // Inspected
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.check_circle, color: Colors.green, size: 16),
                            SizedBox(width: 6),
                            Text('140-Pt Inspected', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 13)),
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
                        style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '2022 Audi Q5 45 TFSI Quattro',
                        style: TextStyle(color: navy, fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                      ),
                      const SizedBox(height: 24),
                      
                      // Current Bid Card
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CURRENT HIGHEST BID', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text('₹38,50,000', style: TextStyle(color: navy, fontSize: 24, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const Text('18 Bids Placed', style: TextStyle(color: Color(0xFFFB7800), fontSize: 14, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.circle, color: Colors.green, size: 8),
                                const SizedBox(width: 8),
                                Text('Reserve met • Fast-track transfer verified', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Instant Increments
                      const Text('Instant Increments', style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildIncrementButton(25000)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildIncrementButton(50000)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildIncrementButton(100000)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Your Offer Input
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Your Offer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Min: ₹38,75,000', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _offerController,
                          keyboardType: TextInputType.number,
                          onChanged: _onOfferChanged,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            prefixText: '₹ ',
                            prefixStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Helper text
                      Row(
                        children: [
                          Icon(Icons.trending_up, color: orange, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Increases current bid by ₹${_formatCurrency(difference >= 0 ? difference : 0)}',
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Place Bid Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/confirmation/bid');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.gavel, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Place Bid', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
        ),
      ),
    );
  }

  Widget _buildIncrementButton(int amount) {
    return InkWell(
      onTap: () => _incrementOffer(amount),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            '+ ₹${_formatCurrency(amount)}',
            style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ),
    );
  }
}
