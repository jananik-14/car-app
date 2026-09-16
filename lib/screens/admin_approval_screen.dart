import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import '../widgets/shared_bottom_nav.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key});

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  final Color navy = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  List<Map<String, String>> pendingVehicles = [
    {
      'id': '1',
      'title': '2023 Tata Harrier Dark Edition',
      'seller': 'Rajesh Sharma',
      'rto': 'DL-01',
      'bid': '18.50',
      'image': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=300&q=80',
    },
    {
      'id': '2',
      'title': '2021 Hyundai Creta SX',
      'seller': 'Amit K.',
      'rto': 'HR-26',
      'bid': '12.20',
      'image': 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=300&q=80',
    },
  ];

  void _handleAction(String id, String actionName) {
    setState(() {
      pendingVehicles.removeWhere((v) => v['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Vehicle $actionName successfully.'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: Icon(Icons.drive_eta, color: navy), // Small logo icon
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wheels2Drive', style: TextStyle(color: navy, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Profile', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.grey), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: navy,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              // Heading Row
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text('Pending Verifications', style: TextStyle(color: navy, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                          child: Text('${pendingVehicles.length} New', style: TextStyle(color: orange, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.tune, color: navy),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              
              // List of Vehicles
              Expanded(
                child: pendingVehicles.isEmpty
                    ? Center(
                        child: Text(
                          'No pending verifications.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: pendingVehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = pendingVehicles[index];
                          return _buildVehicleCard(vehicle);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SharedBottomNav(currentIndex: 4), // Profile active
    );
  }

  Widget _buildVehicleCard(Map<String, String> vehicle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomNetworkImage(imageUrl: vehicle['image']!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle['title']!,
                      style: TextStyle(color: navy, fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        children: [
                          const TextSpan(text: 'Seller: '),
                          TextSpan(text: vehicle['seller'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w500)),
                          TextSpan(text: ' (${vehicle['rto']})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Base Bid: ₹${vehicle['bid']} L',
                      style: TextStyle(color: navy, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleAction(vehicle['id']!, 'rejected'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade700,
                    side: BorderSide(color: Colors.blue.shade100),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleAction(vehicle['id']!, 'accepted'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Accept', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
