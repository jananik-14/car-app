import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../widgets/shared_bottom_nav.dart';
class PostVehicleFormScreen extends StatefulWidget {
  const PostVehicleFormScreen({super.key});

  @override
  State<PostVehicleFormScreen> createState() => _PostVehicleFormScreenState();
}

class _PostVehicleFormScreenState extends State<PostVehicleFormScreen> {
  int _currentStep = 1; // Start at Step 1
  final int _totalSteps = 5;
  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  // Step 1 State
  String _selectedVehicleType = 'Car / SUV';
  String _selectedFuelType = 'Petrol';
  String _selectedTransmission = 'Manual';

  // Step 3 State
  final TextEditingController _kmController = TextEditingController(text: '42,500');
  String _selectedOwner = '1st Owner';
  String _selectedInsuranceType = 'Comprehensive (Zero Dep)';
  DateTime _insuranceExpiryDate = DateTime(2025, 11, 24);

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // Step 5 State
  final TextEditingController _priceController = TextEditingController(text: '5,80,000');
  bool _enableReservePrice = true;
  String _selectedDuration = '48 Hours';

  // Step 4 State (Uploads)
  final ImagePicker _picker = ImagePicker();
  String? _leftRightPath;
  String? _interiorDashPath;
  String? _engineTyresPath;
  String? _rcInsurancePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
        ), // Logo
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Wheels2Drive', style: TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Post Sell', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            children: [
              // Progress Indicator section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                color: Colors.white,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.circle, color: orange, size: 10),
                            const SizedBox(width: 6),
                            Text('STEP $_currentStep OF $_totalSteps', style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                        Text(
                          _currentStep == 1 ? 'Vehicle Category' : _currentStep == 2 ? 'Vehicle Identity' : _currentStep == 3 ? 'Vehicle Health & Records' : _currentStep == 4 ? 'Upload Photos' : 'Pricing & Auction',
                          style: TextStyle(
                            color: _currentStep == 5 ? orange : Colors.grey, 
                            fontSize: 12, 
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: _currentStep / _totalSteps,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(orange),
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _currentStep == 1 
                      ? _buildStep1() 
                      : _currentStep == 2 
                          ? _buildStep2() 
                          : _currentStep == 3
                              ? _buildStep3()
                              : _currentStep == 4
                                  ? _buildStep4()
                                  : _currentStep == 5
                                      ? _buildStep5()
                                      : _buildPlaceholderStep(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const SharedBottomNav(
        currentIndex: 2, // Post/Sell is active
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of vehicle\nare you selling?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: navyBlue,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Select your vehicle type and fuel to help us find the best verified buyers.',
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 32),
        
        // Vehicle Type Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildVehicleTypeCard('Car / SUV', 'Sedan, Hatchback, SUV', Icons.directions_car),
            _buildVehicleTypeCard('Bike / Scooter', 'Motorcycles & Mopeds', Icons.two_wheeler),
            _buildVehicleTypeCard('Commercial', 'Van, Tempo, Rickshaw', Icons.local_shipping),
            _buildVehicleTypeCard('Electric (EV)', 'Battery powered 2W/4W', Icons.electric_car),
          ],
        ),
        const SizedBox(height: 32),
        
        // Fuel Type Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fuel Type', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
            Row(
              children: [
                const Text('Select one', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildFuelPill('Petrol'),
            _buildFuelPill('Diesel'),
            _buildFuelPill('CNG / Hybrid'),
            _buildFuelPill('Electric'),
          ],
        ),
        const SizedBox(height: 32),
        
        // Transmission Section
        Text('Transmission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTransmissionToggle('Manual', Icons.settings_suggest)),
            const SizedBox(width: 16),
            Expanded(child: _buildTransmissionToggle('Automatic', Icons.settings)), // fallback icon for gear
          ],
        ),
        const SizedBox(height: 32),
        
        // Info Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parivahan & Vahan Sync Enabled', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[900], fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('We\'ll fetch exact RTO registration specifications automatically.', style: TextStyle(color: Colors.blue[800], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Next Step Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 2; // Go to step 2
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next Step',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: InkWell(
            onTap: () {},
            child: Text(
              'Need help identifying your model?',
              style: TextStyle(
                color: navyBlue,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleTypeCard(String title, String subtitle, IconData icon) {
    bool isSelected = _selectedVehicleType == title;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedVehicleType = title;
          // Auto select Electric fuel if EV is selected
          if (title == 'Electric (EV)') {
            _selectedFuelType = 'Electric';
            _selectedTransmission = 'Automatic';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? orange.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? orange : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: isSelected ? orange : navyBlue, size: 32),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: navyBlue,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: orange,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              )
            else
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFuelPill(String fuel) {
    bool isSelected = _selectedFuelType == fuel;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFuelType = fuel;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? orange : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? orange : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, color: Colors.white, size: 16),
              const SizedBox(width: 8),
            ],
            Text(
              fuel,
              style: TextStyle(
                color: isSelected ? Colors.white : navyBlue,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransmissionToggle(String transmission, IconData icon) {
    bool isSelected = _selectedTransmission == transmission;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTransmission = transmission;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? navyBlue : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? navyBlue : Colors.grey, size: 28),
            const SizedBox(height: 8),
            Text(
              transmission,
              style: TextStyle(
                color: isSelected ? navyBlue : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is your vehicle\nregistration number?',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: navyBlue,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'We will auto-fetch maker, model, RTO, and year from Parivahan.',
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 32),
        
        // Registration Input
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Text('IND', style: TextStyle(color: Color(0xFF001128), fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(width: 4),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(width: 16, height: 10, color: Colors.white),
                              Column(
                                children: [
                                  Container(width: 16, height: 3.3, color: Colors.orange),
                                  Container(width: 16, height: 3.3, color: Colors.white),
                                  Container(width: 16, height: 3.3, color: Colors.green),
                                ],
                              ),
                              const Icon(Icons.circle, size: 3, color: Colors.blue),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('India', style: TextStyle(color: Color(0xFF001128), fontSize: 10)),
                    ],
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: Colors.grey[300]),
                Expanded(
                  child: TextField(
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: navyBlue, letterSpacing: 2),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      hintText: 'DL 01 AB 1234',
                      hintStyle: TextStyle(color: Colors.black26),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.shield_outlined, size: 16, color: Colors.green[700]),
            const SizedBox(width: 6),
            Text(
              'Instant verified lookup via Vahan Registry',
              style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        
        const SizedBox(height: 48),
        
        // Next Step Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 3;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next Step',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentStep = 1;
              });
            },
            child: Text(
              '← Back to Step 1',
              style: TextStyle(
                color: navyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehicle Health & Records',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: navyBlue,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Provide accurate mileage and active insurance details to fast-track buyer verification and maximize offer rates.',
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 32),
        
        // Vehicle Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                          child: Text('IND', style: TextStyle(color: navyBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text('DL 01 AB 4092', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue)),
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('2021 Hyundai i20 Asta 1.2 Petrol', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Kilometers Driven
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total Kilometers Driven', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Text('Parivahan Verified', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kmController,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navyBlue),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text('KM', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(width: 8),
                    Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Avg for 2021 models: ~35k-45k km', style: TextStyle(color: Colors.grey, fontSize: 12)),
            Text('Standard Range', style: TextStyle(color: Colors.green[700], fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 32),
        
        // Number of Owners
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Number of Previous Owners', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue)),
            const Text('RC Record', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildOwnerPill('1st Owner'),
              const SizedBox(width: 8),
              _buildOwnerPill('2nd Owner'),
              const SizedBox(width: 8),
              _buildOwnerPill('3rd Owner'),
              const SizedBox(width: 8),
              _buildOwnerPill('4+ Owners'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Insurance Details Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insurance Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue)),
                const SizedBox(height: 4),
                const Text('Protects transfer valuation', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
              child: const Text('HSRP', style: TextStyle(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Insurance Coverage Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedInsuranceType,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              style: TextStyle(fontSize: 14, color: navyBlue),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedInsuranceType = newValue;
                  });
                }
              },
              items: <String>[
                'Comprehensive (Zero Dep)',
                'Comprehensive (Standard)',
                'Third-Party Only',
                'Third-Party + Own Damage',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Insurance Till (Expiry Date)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            print('Date field tapped');
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _insuranceExpiryDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2030),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: orange,
                      onPrimary: Colors.white,
                      onSurface: navyBlue,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null && picked != _insuranceExpiryDate) {
              setState(() {
                _insuranceExpiryDate = picked;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDate(_insuranceExpiryDate), style: TextStyle(fontSize: 14, color: navyBlue)),
                const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Validity: Active & Verified', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green[800], fontSize: 14)),
                    const SizedBox(height: 2),
                    Text('Synced with Vahan Government Database', style: TextStyle(color: Colors.green[700], fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Odometer Photo Tip
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: navyBlue,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.speed_outlined, color: orange, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('ODOMETER PHOTO TIP', style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        const SizedBox(width: 4),
                        Icon(Icons.star, color: orange, size: 12),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Clear meter reading proof in Step 4 unlocks instant badge for 3x buyer trust.',
                      style: TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 48),
        
        // Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 4; // Go to step 4
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next Step',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentStep = 2; // Go back to step 2
              });
            },
            child: Text(
              '← Back to Step 2',
              style: TextStyle(
                color: navyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOwnerPill(String owner) {
    bool isSelected = _selectedOwner == owner;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOwner = owner;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? orange : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? orange : Colors.grey[300]!,
          ),
        ),
        child: Text(
          owner,
          style: TextStyle(
            color: isSelected ? Colors.white : navyBlue,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }



  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upload vehicle photos\n& documents',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: navyBlue,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        RichText(
          text: TextSpan(
            style: const TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
            children: [
              const TextSpan(text: 'Vehicles with 5+ high quality photos receive '),
              TextSpan(text: '3x more bids', style: TextStyle(color: orange, fontWeight: FontWeight.bold)),
              const TextSpan(text: ' and faster inquiries.'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Uploaded Photos Row
        Row(
          children: [
            Expanded(
              child: _buildUploadedPhotoCard(
                'Front View', 
                'https://images.unsplash.com/photo-1533473359331-0135ef1b58bf?auto=format&fit=crop&q=80&w=400'
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildUploadedPhotoCard(
                'Rear View', 
                'https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?auto=format&fit=crop&q=80&w=400'
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Upload Slots Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.1,
          children: [
            _buildUploadSlot('Left & Right', Icons.camera_alt_outlined, false, _leftRightPath, (path) => setState(() => _leftRightPath = path)),
            _buildUploadSlot('Interior & Dash', Icons.dashboard_outlined, false, _interiorDashPath, (path) => setState(() => _interiorDashPath = path)),
            _buildUploadSlot('Engine & Tyres', Icons.build_outlined, false, _engineTyresPath, (path) => setState(() => _engineTyresPath = path)),
            _buildUploadSlot('RC & Insurance', Icons.description_outlined, true, _rcInsurancePath, (path) => setState(() => _rcInsurancePath = path)),
          ],
        ),
        const SizedBox(height: 32),
        
        // Verification Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.verified, color: Colors.blue[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Want 100% verified badge?', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Book free doorstep inspection by certified Wheels2Drive technicians to fast-track buyer trust.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text('Schedule Free Inspection', style: TextStyle(color: orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_forward, color: orange, size: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Next Step Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _currentStep = 5; // Go to step 5
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Next Step',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentStep = 3; // Go back to step 3
              });
            },
            child: Text(
              '← Back to Step 3',
              style: TextStyle(
                color: navyBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadedPhotoCard(String label, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 120,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle, color: orange, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 12)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('Uploaded', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage(Function(String) onImagePicked) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Files'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    onImagePicked(image.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () async {
                  Navigator.of(context).pop();
                  final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
                  if (photo != null) {
                    onImagePicked(photo.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadSlot(String label, IconData icon, bool isOptional, String? imagePath, Function(String) onImagePicked) {
    if (imagePath != null) {
      return InkWell(
        onTap: () => _pickImage(onImagePicked),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(imagePath),
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check_circle, color: orange, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 12), overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Uploaded', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _pickImage(onImagePicked),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.grey, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            if (isOptional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('OPTIONAL', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            else
              const Text('Tap to Upload', style: TextStyle(color: Colors.grey, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildStep5() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set your expected price\n& auction timer',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: navyBlue,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Bidding will start from your reserve price. You can accept or decline final offers.',
          style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
        ),
        const SizedBox(height: 32),
        
        // Vehicle Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('2021 Hyundai Verna SX', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 14)),
                        const SizedBox(width: 8),
                        Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text('MH 02 FJ 9012 • 34,200 km • 1st Owner', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Expected Selling Price Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Expected Selling Price', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: orange, size: 12),
                  const SizedBox(width: 4),
                  Text('Hot Demand', style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('₹', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: navyBlue),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        // AI Valuation Info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[100]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue[700], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Market Valuation', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Estimated market value: ₹5,40,000 - ₹6,10,000 based on recent verified Indian bids in your RTO zone.', style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        
        // Reserve Price Toggle
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Switch(
              value: _enableReservePrice,
              onChanged: (val) {
                setState(() {
                  _enableReservePrice = val;
                });
              },
              activeColor: Colors.white,
              activeTrackColor: orange,
              inactiveThumbColor: Colors.grey[400],
              inactiveTrackColor: Colors.grey[200],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Set Minimum Reserve Price', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Text('Auto-reject buyer bids below ₹5,20,000 to guarantee baseline sale security.', style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        
        // Auction Duration Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Auction Duration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: navyBlue)),
            Text('Live countdown starts post-approval', style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDurationCard('24 Hours', 'Express', null)),
            const SizedBox(width: 8),
            Expanded(child: _buildDurationCard('48 Hours', 'Recommended', 'BEST BIDS')),
            const SizedBox(width: 8),
            Expanded(child: _buildDurationCard('72 Hours', 'Max Reach', null)),
          ],
        ),
        const SizedBox(height: 32),
        
        // Trust Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.shield, color: Colors.green[700], size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('100% Verified KYC Bidders', style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue, fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text('Zero seller commission for your first 2 sales. Direct encrypted escrow transfers.', style: TextStyle(color: Colors.grey, fontSize: 12, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 48),
        
        // Submit Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.push('/confirmation/listing');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Submit for Admin Verification',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: InkWell(
            onTap: () {
              setState(() {
                _currentStep = 4; // Go back to step 4
              });
            },
            child: const Text(
              '← Back to Step 4',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDurationCard(String duration, String subLabel, String? badge) {
    bool isSelected = _selectedDuration == duration;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = duration;
        });
      },
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? navyBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? navyBlue : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (badge != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? orange : orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: isSelected ? Colors.white : orange,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              duration,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : navyBlue,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: TextStyle(
                color: isSelected ? Colors.white70 : Colors.grey,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 100),
        Icon(Icons.construction, size: 64, color: navyBlue.withOpacity(0.5)),
        const SizedBox(height: 16),
        Text(
          'Step $_currentStep coming soon',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: navyBlue),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 48),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    if (_currentStep > 1) {
                      _currentStep--;
                    }
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (_currentStep < _totalSteps) {
                      _currentStep++;
                    } else {
                      context.push('/confirmation/listing');
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: Text(_currentStep < _totalSteps ? 'Next Step' : 'Submit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
