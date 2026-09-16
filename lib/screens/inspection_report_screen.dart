import 'package:flutter/material.dart';
import '../widgets/custom_network_image.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout_wrapper.dart';

class InspectionReportScreen extends StatelessWidget {
  final String vehicleId;

  const InspectionReportScreen({super.key, required this.vehicleId});

  static const Color navyBlue = Color(0xFF001128);
  static const Color orange = Color(0xFFFB7800);
  static const Color lightBlueGrey = Color(0xFFEEF1F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: navyBlue),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vehicle_detail/$vehicleId');
            }
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.directions_car, size: 16, color: navyBlue),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                '140 Point Inspection Report',
                style: TextStyle(
                  color: navyBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 48), // Balance the leading back button
        ],
      ),
      body: ResponsiveLayoutWrapper(
        mobileContent: _buildBody(context),
        desktopContent: _buildBody(context),
      ),
      bottomNavigationBar: _buildBottomBar(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVehicleSummaryCard(),
          const Divider(height: 1, thickness: 8, color: lightBlueGrey),
          _buildAuditScoreCard(),
          const Divider(height: 1, thickness: 8, color: lightBlueGrey),
          _buildSystemsOverview(),
          const Divider(height: 1, thickness: 8, color: lightBlueGrey),
          _buildCosmeticBlueprint(),
          const Divider(height: 1, thickness: 8, color: lightBlueGrey),
          _buildDetailedCheckpoints(),
          const Divider(height: 1, thickness: 8, color: lightBlueGrey),
          _buildPhotoGallery(),
        ],
      ),
    );
  }

  Widget _buildVehicleSummaryCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.verified, color: orange, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Wheels2Drive Certified',
                    style: TextStyle(
                      color: navyBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '140-Point PASS',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '2021 Hyundai Creta SX (O) Turbo Petrol',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: navyBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'TN 09 BK 4521',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditScoreCard() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, color: orange, size: 10),
              const SizedBox(width: 6),
              Text(
                'INDEPENDENT AUDIT',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '9.4/10',
                    style: TextStyle(
                      color: navyBlue,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Excellent Condition',
                    style: TextStyle(
                      color: navyBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: 0.94,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      color: orange,
                    ),
                  ),
                  const Icon(Icons.security, color: orange, size: 32),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ready for transfer with zero major mechanical faults detected.',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoPill(Icons.water_drop_outlined, 'Non-Accidental - Zero flood dam...'),
          const SizedBox(height: 8),
          _buildInfoPill(Icons.check_circle_outline, 'RTO Verified - Parivahan clear'),
          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.work_outline, color: Colors.grey.shade500, size: 16),
              const SizedBox(width: 8),
              Text(
                'Lead Engineer: Ramesh K. (#W2D-4482) • 02 Oct 2024',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: lightBlueGrey,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: navyBlue),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: navyBlue,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemsOverview() {
    final systems = [
      {'title': 'Engine & Gearbox', 'score': '98%', 'desc': 'Zero smoke, smooth...', 'icon': Icons.settings},
      {'title': 'Exterior Body', 'score': '90%', 'desc': 'Minor scratch on...', 'icon': Icons.directions_car},
      {'title': 'Tyres & Struts', 'score': '88%', 'desc': '6.5mm healthy tread', 'icon': Icons.tire_repair},
      {'title': 'Electricals & AC', 'score': '96%', 'desc': '11.8°C blast, OBD zero', 'icon': Icons.electrical_services},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Systems Overview',
                style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '140/140 Evaluated',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: systems.map((sys) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(sys['icon'] as IconData, size: 20, color: navyBlue),
                        Text(
                          sys['score'] as String,
                          style: const TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      sys['title'] as String,
                      style: const TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sys['desc'] as String,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCosmeticBlueprint() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cosmetic Wear Blueprint',
                      style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2 pinpointed cosmetic findings on body shell',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '2 Imperfections',
                  style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Blueprint Diagram Placeholder
          Center(
            child: SizedBox(
              width: 140,
              height: 280,
              child: Stack(
                children: [
                  SizedBox(
                    width: 140,
                    height: 280,
                    child: CustomPaint(
                      painter: CarBlueprintPainter(
                        strokeColor: navyBlue,
                        fillColor: lightBlueGrey,
                      ),
                    ),
                  ),
                  // Pin 1 (Rear lower right)
                  Positioned(
                    bottom: 20,
                    right: 10,
                    child: _buildPin(1),
                  ),
                  // Pin 2 (Left rear quarter)
                  Positioned(
                    bottom: 60,
                    left: 5,
                    child: _buildPin(2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Tap pins to inspect noted scratches',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          _buildDamageDetailCard(
            number: 1,
            title: 'Rear Bumper (Lower Right)',
            tag: 'Surface Scuff',
            tagColor: orange,
            desc: '1.8 cm minor clear-coat abrasion. Does not pierce primer; dry buff recommended.',
          ),
          const SizedBox(height: 12),
          _buildDamageDetailCard(
            number: 2,
            title: 'Left Rear Quarter Panel',
            tag: 'Micro Stone Chip',
            tagColor: Colors.amber.shade700,
            desc: 'Small pebble mark (< 2mm). Original factory paint intact without dent.',
          ),
        ],
      ),
    );
  }

  Widget _buildPin(int number) {
    return Container(
      width: 20,
      height: 20,
      decoration: const BoxDecoration(
        color: orange,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDamageDetailCard({
    required int number,
    required String title,
    required String tag,
    required Color tagColor,
    required String desc,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPin(number),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: tagColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(color: tagColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  desc,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedCheckpoints() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detailed Checkpoints',
            style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 16),
          _buildCheckpointRow('Engine & Mechanical', '42 of 42 Items Passed', true, Icons.settings),
          _buildCheckpointRow('Exterior & Structure', '38 Points • 2 Cosmetic Notes', false, Icons.directions_car),
          _buildCheckpointRow('Interior & Electricals', '35 of 35 Items Passed', true, Icons.dashboard),
          _buildCheckpointRow('Tyres, Brakes & Battery', '25 of 25 Items Passed', true, Icons.tire_repair),
        ],
      ),
    );
  }

  Widget _buildCheckpointRow(String title, String subtitle, bool isPass, IconData icon) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        leading: Icon(icon, color: navyBlue),
        title: Text(title, style: const TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPass ? Icons.check_circle : Icons.warning,
              color: isPass ? Colors.green : orange,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Detailed checkpoint details for $title would appear here.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGallery() {
    final photos = [
      {'caption': 'Engine Bay', 'url': 'https://images.unsplash.com/photo-1541899481282-d53bffe3c35d?auto=format&fit=crop&w=400&q=80'},
      {'caption': 'Odo: 32,450 km', 'url': 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=400&q=80'},
      {'caption': 'Tread: 6.5 mm', 'url': 'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?auto=format&fit=crop&w=400&q=80'},
      {'caption': 'Interior Cabin', 'url': 'https://images.unsplash.com/photo-1494976388531-d1058494cdd8?auto=format&fit=crop&w=400&q=80'},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Photo Evidence Gallery',
                style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'Timestamped',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: photos.map((photo) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomNetworkImage(imageUrl: photo['url'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade300),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                        child: Text(
                          photo['caption'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.share_outlined, color: navyBlue),
                onPressed: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/vehicle_detail/$vehicleId');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Back to Live Auction & Bid',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CarBlueprintPainter extends CustomPainter {
  final Color strokeColor;
  final Color fillColor;

  CarBlueprintPainter({required this.strokeColor, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
      
    final Paint strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final Paint windowPaint = Paint()
      ..color = strokeColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final Paint mirrorPaint = Paint()
      ..color = const Color(0xFFFB7800)
      ..style = PaintingStyle.fill;

    final Paint tailLightPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    // Car Body Path
    final Path bodyPath = Path();
    bodyPath.moveTo(size.width * 0.25, size.height * 0.05); // top left curve
    bodyPath.quadraticBezierTo(size.width * 0.5, 0, size.width * 0.75, size.height * 0.05); // top center
    bodyPath.lineTo(size.width * 0.85, size.height * 0.2); // top right widen
    bodyPath.quadraticBezierTo(size.width, size.height * 0.5, size.width * 0.85, size.height * 0.8); // right side curve
    bodyPath.lineTo(size.width * 0.75, size.height * 0.95); // bottom right taper
    bodyPath.quadraticBezierTo(size.width * 0.5, size.height, size.width * 0.25, size.height * 0.95); // bottom center
    bodyPath.lineTo(size.width * 0.15, size.height * 0.8); // bottom left taper
    bodyPath.quadraticBezierTo(0, size.height * 0.5, size.width * 0.15, size.height * 0.2); // left side curve
    bodyPath.close();

    canvas.drawPath(bodyPath, fillPaint);
    canvas.drawPath(bodyPath, strokePaint);

    // Front Windshield
    final Path frontWindow = Path();
    frontWindow.moveTo(size.width * 0.25, size.height * 0.22);
    frontWindow.quadraticBezierTo(size.width * 0.5, size.height * 0.18, size.width * 0.75, size.height * 0.22);
    frontWindow.lineTo(size.width * 0.8, size.height * 0.35);
    frontWindow.quadraticBezierTo(size.width * 0.5, size.height * 0.32, size.width * 0.2, size.height * 0.35);
    frontWindow.close();
    canvas.drawPath(frontWindow, windowPaint);
    canvas.drawPath(frontWindow, strokePaint);

    // Rear Windshield
    final Path rearWindow = Path();
    rearWindow.moveTo(size.width * 0.25, size.height * 0.78);
    rearWindow.quadraticBezierTo(size.width * 0.5, size.height * 0.82, size.width * 0.75, size.height * 0.78);
    rearWindow.lineTo(size.width * 0.7, size.height * 0.65);
    rearWindow.quadraticBezierTo(size.width * 0.5, size.height * 0.68, size.width * 0.3, size.height * 0.65);
    rearWindow.close();
    canvas.drawPath(rearWindow, windowPaint);
    canvas.drawPath(rearWindow, strokePaint);
    
    // Left side window
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.14, size.height * 0.38, size.width * 0.2, size.height * 0.62), const Radius.circular(4)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.14, size.height * 0.38, size.width * 0.2, size.height * 0.62), const Radius.circular(4)), strokePaint);
    
    // Right side window
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.8, size.height * 0.38, size.width * 0.86, size.height * 0.62), const Radius.circular(4)), windowPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.8, size.height * 0.38, size.width * 0.86, size.height * 0.62), const Radius.circular(4)), strokePaint);

    // Side Mirrors (Orange)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.05, size.height * 0.32, size.width * 0.15, size.height * 0.35), const Radius.circular(3)), mirrorPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.85, size.height * 0.32, size.width * 0.95, size.height * 0.35), const Radius.circular(3)), mirrorPaint);

    // Tail Lights (Red)
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.18, size.height * 0.92, size.width * 0.35, size.height * 0.95), const Radius.circular(2)), tailLightPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(size.width * 0.65, size.height * 0.92, size.width * 0.82, size.height * 0.95), const Radius.circular(2)), tailLightPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
