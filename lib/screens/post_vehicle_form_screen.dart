import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/local_listings_store.dart';
import '../services/admin_notification_store.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/responsive_layout_wrapper.dart';
import '../services/subscription_store.dart';
import '../utils/profile_storage_helper.dart';

class PostVehicleFormScreen extends StatefulWidget {
  final bool isEditMode;
  final Map<String, dynamic>? initialData;
  const PostVehicleFormScreen(
      {super.key, this.isEditMode = false, this.initialData});

  @override
  State<PostVehicleFormScreen> createState() => _PostVehicleFormScreenState();
}

class _PostVehicleFormScreenState extends State<PostVehicleFormScreen> {
  int _currentStep = 1; // Start at Step 1
  final int _totalSteps = 5;
  final Color navyBlue = const Color(0xFF001128);
  final Color orange = const Color(0xFFFB7800);

  // Step 1 State
  String? _selectedVehicleType;
  String? _selectedFuelType;
  String? _selectedTransmission;

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _variantController = TextEditingController();
  String? _selectedYear;

  bool _step1Submitted = false;

  // Step 2 State
  final TextEditingController _registrationController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  String? _selectedState;
  final TextEditingController _pincodeController = TextEditingController();
  bool _step2Submitted = false;

  final Map<String, String> _stateCodes = {
    'Andaman and Nicobar Islands': 'AN', 'Andhra Pradesh': 'AP', 'Arunachal Pradesh': 'AR', 'Assam': 'AS', 'Bihar': 'BR', 'Chandigarh': 'CH', 'Chhattisgarh': 'CG', 'Dadra and Nagar Haveli': 'DN', 'Daman and Diu': 'DD', 'Delhi': 'DL', 'Goa': 'GA', 'Gujarat': 'GJ', 'Haryana': 'HR', 'Himachal Pradesh': 'HP', 'Jammu and Kashmir': 'JK', 'Jharkhand': 'JH', 'Karnataka': 'KA', 'Kerala': 'KL', 'Lakshadweep': 'LD', 'Madhya Pradesh': 'MP', 'Maharashtra': 'MH', 'Manipur': 'MN', 'Meghalaya': 'ML', 'Mizoram': 'MZ', 'Nagaland': 'NL', 'Odisha': 'OR', 'Puducherry': 'PY', 'Punjab': 'PB', 'Rajasthan': 'RJ', 'Sikkim': 'SK', 'Tamil Nadu': 'TN', 'Telangana': 'TG', 'Tripura': 'TR', 'Uttar Pradesh': 'UP', 'Uttarakhand': 'UK', 'West Bengal': 'WB'
  };

  String get locationDisplay {
    if (_cityController.text.trim().isEmpty || _selectedState == null) return '';
    return '${_cityController.text.trim()}, ${_stateCodes[_selectedState] ?? ''}';
  }

  // Step 3 State
  final TextEditingController _kmController = TextEditingController();
  String? _selectedOwner;
  String? _selectedInsuranceType;
  DateTime? _insuranceExpiryDate;
  bool _step3Submitted = false;

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  // Step 5 State
  final TextEditingController _priceController = TextEditingController();
  String? _selectedDuration;
  bool _step5Submitted = false;

  String _formatIndianNumber(String s) {
    if (s.isEmpty) return s;
    int len = s.length;
    if (len <= 3) return s;
    String res = s.substring(len - 3);
    s = s.substring(0, len - 3);
    while (s.length > 2) {
      res = '${s.substring(s.length - 2)},$res';
      s = s.substring(0, s.length - 2);
    }
    if (s.isNotEmpty) {
      res = '$s,$res';
    }
    return res;
  }

  // Step 4 State (Uploads)
  final ImagePicker _picker = ImagePicker();
  List<XFile> frontViewImages = [];
  List<XFile> rearViewImages = [];
  List<XFile> leftRightImages = [];
  List<XFile> interiorDashImages = [];
  List<XFile> engineTyresImages = [];
  List<XFile> rcInsuranceImages = [];
  PlatformFile? inspectionReportFile;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _registrationController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final d = widget.initialData!;
      _selectedVehicleType = d['vehicleType'];
      _selectedFuelType = d['fuelType'];
      _selectedTransmission = d['transmission'];
      _brandController.text = d['brand'] ?? '';
      _modelController.text = d['model'] ?? '';
      _variantController.text = d['variant'] ?? '';
      _selectedYear = d['year']?.toString();
      _cityController.text = d['city'] ?? '';
      _selectedState = d['state'];
      _pincodeController.text = d['pincode'] ?? '';
      _registrationController.text = d['registrationNumber'] ?? '';
      _kmController.text = d['kilometersDriven'] ?? '';
      _selectedOwner = d['owner'];
      _selectedInsuranceType = d['insuranceType'];
      if (d['insuranceExpiryDate'] != null) {
        _insuranceExpiryDate = DateTime.tryParse(d['insuranceExpiryDate']);
      }
      _priceController.text = d['price']?.toString() ?? '';
      if (d['durationHours'] != null) {
        _selectedDuration = '${d['durationHours']} Hours';
      }
    }
  }

  Future<void> _handleFinalSubmit() async {
    int? problematicStep;
    List<String> errors = [];

    if (_selectedVehicleType == null || _selectedFuelType == null || _selectedTransmission == null || _brandController.text.trim().isEmpty || _modelController.text.trim().isEmpty || _selectedYear == null) {
      if (problematicStep == null) problematicStep = 1;
      List<String> s1 = [];
      if (_selectedVehicleType == null) s1.add("Vehicle type");
      if (_selectedFuelType == null) s1.add("Fuel");
      if (_selectedTransmission == null) s1.add("Transmission");
      if (_brandController.text.trim().isEmpty) s1.add("Brand");
      if (_modelController.text.trim().isEmpty) s1.add("Model");
      if (_selectedYear == null) s1.add("Year");
      errors.add("Step 1: Missing ${s1.join(', ')}");
    }

    if (_registrationController.text.trim().isEmpty || _cityController.text.trim().isEmpty || _selectedState == null || (_pincodeController.text.trim().isNotEmpty && _pincodeController.text.trim().length != 6)) {
      if (problematicStep == null) problematicStep = 2;
      List<String> s2 = [];
      if (_registrationController.text.trim().isEmpty) s2.add("Registration number");
      if (_cityController.text.trim().isEmpty) s2.add("City");
      if (_selectedState == null) s2.add("State");
      if (_pincodeController.text.trim().isNotEmpty && _pincodeController.text.trim().length != 6) s2.add("Pincode must be 6 digits");
      errors.add("Step 2: Missing or invalid ${s2.join(', ')}");
    }

    final km = int.tryParse(_kmController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (km <= 0 || _selectedOwner == null || _selectedInsuranceType == null || _insuranceExpiryDate == null) {
      if (problematicStep == null) problematicStep = 3;
      List<String> s3 = [];
      if (km <= 0) s3.add("KM > 0");
      if (_selectedOwner == null) s3.add("Previous owners");
      if (_selectedInsuranceType == null) s3.add("Insurance type");
      if (_insuranceExpiryDate == null) s3.add("Insurance expiry");
      errors.add("Step 3: Missing or invalid ${s3.join(', ')}");
    }

    if (!widget.isEditMode && (frontViewImages.isEmpty || inspectionReportFile == null)) {
      if (problematicStep == null) problematicStep = 4;
      List<String> s4 = [];
      if (frontViewImages.isEmpty) s4.add("Front View photo");
      if (inspectionReportFile == null) s4.add("Inspection Report PDF");
      errors.add("Step 4: Missing ${s4.join(', ')}");
    }

    final priceInt = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (priceInt <= 0 || _selectedDuration == null) {
      if (problematicStep == null) problematicStep = 5;
      List<String> s5 = [];
      if (priceInt <= 0) s5.add("Price > 0");
      if (_selectedDuration == null) s5.add("Auction duration");
      errors.add("Step 5: Missing or invalid ${s5.join(', ')}");
    }

    if (problematicStep != null) {
      setState(() {
        _currentStep = problematicStep!;
        if (problematicStep == 1) _step1Submitted = true;
        if (problematicStep == 2) _step2Submitted = true;
        if (problematicStep == 3) _step3Submitted = true;
        if (problematicStep == 5) _step5Submitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fix errors:\n${errors.join('\n')}', style: const TextStyle(height: 1.4)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    setState(() { _isSubmitting = true; });
    try {
      final phone = AuthService().currentPhone;
      final normalizedPhone = phone != null ? ProfileStorageHelper.normalizePhone(phone) : '';
      final prefs = await SharedPreferences.getInstance();
      final realName = prefs.getString('user_name_$normalizedPhone') ?? (phone != null && phone.isNotEmpty ? phone : 'Unknown Seller');
      final sellerType = prefs.getString('user_type_$normalizedPhone') ?? '';
      final durationHrs = int.tryParse(_selectedDuration!.split(' ')[0]) ?? 48;

      List<XFile> allImages = [
        ...frontViewImages,
        ...rearViewImages,
        ...leftRightImages,
        ...interiorDashImages,
        ...engineTyresImages,
        ...rcInsuranceImages
      ];
      List<Uint8List> photosBytes = [];
      for (var file in allImages.take(6)) {
        photosBytes.add(await file.readAsBytes());
      }

      String finalTitle = '${_selectedYear ?? ''} ${_brandController.text.trim()} ${_modelController.text.trim()} ${_variantController.text.trim()}'.replaceAll(RegExp(r'\s+'), ' ').trim();
      String regNo = _registrationController.text.trim().toUpperCase();
      String stateCodeStr = regNo.length >= 5 ? regNo.substring(0, 5) : regNo;
      String locDisplay = locationDisplay;
      int priceInt = int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final listingData = {
        'id': widget.isEditMode ? widget.initialData!['id'] : DateTime.now().millisecondsSinceEpoch.toString(),
        'title': finalTitle,
        'brand': _brandController.text.trim(),
        'model': _modelController.text.trim(),
        'variant': _variantController.text.trim(),
        'year': int.tryParse(_selectedYear ?? ''),
        'city': _cityController.text.trim(),
        'state': _selectedState,
        'stateCode': stateCodeStr,
        'pincode': _pincodeController.text.trim(),
        'locationDisplay': locDisplay,
        'price': priceInt,
        'sellerName': realName,
        'sellerPhone': phone,
        'durationHours': durationHrs,
        'status': widget.isEditMode ? widget.initialData!['status'] : 'pending',
        'endProcessed': widget.isEditMode ? widget.initialData!['endProcessed'] : false,
        'location': locDisplay,
        'timeAgo': 'Just now',
        'type': sellerType,
        'rcStatus': 'Clear',
        'inspection': '4.5 / 5.0',
        'tag': 'New',
        'inspectionReportBytes': inspectionReportFile?.bytes ?? (widget.isEditMode ? widget.initialData!['inspectionReportBytes'] : null),
        'inspectionReportName': inspectionReportFile?.name ?? (widget.isEditMode ? widget.initialData!['inspectionReportName'] : null),
        'vehicleType': _selectedVehicleType,
        'fuelType': _selectedFuelType,
        'transmission': _selectedTransmission,
        'registrationNumber': regNo,
        'kilometersDriven': _kmController.text,
        'owner': _selectedOwner,
        'insuranceType': _selectedInsuranceType,
        'insuranceExpiryDate': _insuranceExpiryDate?.toIso8601String(),
        'photos': photosBytes.isNotEmpty ? photosBytes : (widget.isEditMode ? widget.initialData!['photos'] : []),
      };

      if (widget.isEditMode) {
        LocalListingsStore().updateListing(listingData);
      } else {
        await LocalListingsStore().addListing(listingData);
      }

      if (!widget.isEditMode) {
        AdminNotificationStore().addNotification('New listing submitted: $finalTitle by $realName — awaiting approval', 'listing');
      }
      
      if (mounted) {
        if (widget.isEditMode) {
           context.pop(true);
        } else {
           context.push('/confirmation/listing');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not save listing: $e. Try smaller photos.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() { _isSubmitting = false; });
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool required = false, String? errorText}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
            if (required) const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: errorText != null ? Colors.red : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  onChanged: (val) => setState(() {}),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: hint,
                    hintStyle: const TextStyle(color: Colors.black26),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Text(errorText, style: const TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      currentIndex: 2,
      body: ResponsiveLayoutWrapper(
        mobileContent: _buildBodyContent(),
        desktopContent: _buildBodyContent(),
        scrollableDesktop: false,
      ),
    );
  }

  Widget _buildBodyContent() {
    return ListenableBuilder(
        listenable: SubscriptionStore(),
        builder: (context, _) {
          final store = SubscriptionStore();
          if (!store.isActive) {
            return _buildSubscriptionRequiredState(store.isPending);
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SafeArea(
              child: Column(
                children: [
                  _buildProgressIndicator(),
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
          );
        });
  }

  Widget _buildSubscriptionRequiredState(bool isPending) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Color(0xFFFB7800)),
            const SizedBox(height: 24),
            const Text('Subscription required',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF001128))),
            const SizedBox(height: 12),
            Text(
              isPending
                  ? 'Your subscription is currently pending approval.'
                  : 'You need an active subscription to post or sell vehicles.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                onPressed: () => context.push('/subscription'),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    String stepTitle = '';
    switch (_currentStep) {
      case 1: stepTitle = 'Vehicle Category'; break;
      case 2: stepTitle = 'Vehicle Identity'; break;
      case 3: stepTitle = 'Vehicle Health & Records'; break;
      case 4: stepTitle = 'Upload Photos'; break;
      case 5: stepTitle = 'Pricing & Auction'; break;
      default: stepTitle = 'Step $_currentStep'; break;
    }
    return Container(
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
                  Text('STEP $_currentStep OF $_totalSteps',
                      style: TextStyle(
                          color: orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ],
              ),
              Text(
                stepTitle,
                style: const TextStyle(
                  color: Colors.grey,
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

        if (_step1Submitted && _selectedVehicleType == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Select vehicle type', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        // Vehicle Type Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio:
              MediaQuery.of(context).size.width < 400 ? 0.95 : 1.1,
          children: [
            _buildVehicleTypeCard(
                'Car / SUV', 'Sedan, Hatchback, SUV', Icons.directions_car),
            _buildVehicleTypeCard(
                'Bike / Scooter', 'Motorcycles & Mopeds', Icons.two_wheeler),
            _buildVehicleTypeCard(
                'Commercial', 'Van, Tempo, Rickshaw', Icons.local_shipping),
            _buildVehicleTypeCard(
                'Electric (EV)', 'Battery powered 2W/4W', Icons.electric_car),
          ],
        ),
        const SizedBox(height: 32),

        _buildTextField('Brand / Make', _brandController, 'e.g. Hyundai', required: true, errorText: _step1Submitted && _brandController.text.trim().isEmpty ? 'Enter brand' : null),
        _buildTextField('Model', _modelController, 'e.g. Creta', required: true, errorText: _step1Submitted && _modelController.text.trim().isEmpty ? 'Enter model' : null),
        _buildTextField('Variant', _variantController, 'e.g. SX'),
        
        Text('Manufacturing Year *', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _step1Submitted && _selectedYear == null ? Colors.red : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    menuMaxHeight: 280,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    itemHeight: 48,
                    value: _selectedYear,
                    hint: const Text('Select year'),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedYear = newValue;
                      });
                    },
                    items: List.generate(DateTime.now().year - 1989, (index) => (DateTime.now().year - index).toString())
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value, style: TextStyle(color: navyBlue, fontSize: 14)),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_step1Submitted && _selectedYear == null)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text('Select year', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        
        if (_brandController.text.trim().isNotEmpty && _modelController.text.trim().isNotEmpty && _selectedYear != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                const Icon(Icons.preview, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedYear} ${_brandController.text.trim()} ${_modelController.text.trim()} ${_variantController.text.trim()}'.replaceAll(RegExp(r'\s+'), ' ').trim(),
                    style: TextStyle(fontWeight: FontWeight.bold, color: navyBlue),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                  child: const Text('Listing title', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

        if (_step1Submitted && _selectedFuelType == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Select fuel type', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        // Fuel Type Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fuel Type',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: navyBlue)),
            const Row(
              children: [
                Text('Select one',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                SizedBox(width: 4),
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

        if (_step1Submitted && _selectedTransmission == null)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Select transmission', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        // Transmission Section
        Text('Transmission',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: navyBlue)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
                child:
                    _buildTransmissionToggle('Manual', Icons.settings_suggest)),
            const SizedBox(width: 16),
            Expanded(
                child: _buildTransmissionToggle(
                    'Automatic', Icons.settings)), // fallback icon for gear
          ],
        ),
        const SizedBox(height: 32),

        // Next Step Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _step1Submitted = true;
              });
              if (_selectedVehicleType != null && _selectedFuelType != null && _selectedTransmission != null && _brandController.text.trim().isNotEmpty && _modelController.text.trim().isNotEmpty && _selectedYear != null) {
                setState(() {
                  _currentStep = 2; // Go to step 2
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: (_selectedVehicleType != null && _selectedFuelType != null && _selectedTransmission != null && _brandController.text.trim().isNotEmpty && _modelController.text.trim().isNotEmpty && _selectedYear != null) ? orange : Colors.grey,
              disabledBackgroundColor: Colors.grey[300],
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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
          color: isSelected ? orange.withValues(alpha: 0.05) : Colors.white,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: isSelected ? orange : navyBlue, size: 32),
                const SizedBox(height: 4),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          const Text('IND',
                              style: TextStyle(
                                  color: Color(0xFF001128),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(width: 4),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                  width: 16, height: 10, color: Colors.white),
                              Column(
                                children: [
                                  Container(
                                      width: 16,
                                      height: 3.3,
                                      color: Colors.orange),
                                  Container(
                                      width: 16,
                                      height: 3.3,
                                      color: Colors.white),
                                  Container(
                                      width: 16,
                                      height: 3.3,
                                      color: Colors.green),
                                ],
                              ),
                              const Icon(Icons.circle,
                                  size: 3, color: Colors.blue),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text('India',
                          style: TextStyle(
                              color: Color(0xFF001128), fontSize: 10)),
                    ],
                  ),
                ),
                VerticalDivider(
                    width: 1, thickness: 1, color: Colors.grey[300]),
                Expanded(
                  child: TextField(
                    controller: _registrationController,
                    onChanged: (val) {
                      final upper = val.toUpperCase();
                      if (val != upper) {
                        _registrationController.value = _registrationController.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(offset: upper.length),
                        );
                      }
                      setState(() {});
                    },
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: navyBlue,
                        letterSpacing: 2),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      hintText: 'e.g. TN 38 AB 1234',
                      hintStyle: TextStyle(color: Colors.black26),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_step2Submitted && _registrationController.text.replaceAll(' ', '').trim().isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text('Enter registration number', style: TextStyle(color: Colors.red, fontSize: 12)),
          )
        else if (_step2Submitted && !RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$').hasMatch(_registrationController.text.replaceAll(' ', '').trim()))
          const Padding(
            padding: EdgeInsets.only(top: 4, left: 8),
            child: Text('Enter a valid registration number', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 24),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildTextField('City', _cityController, 'e.g. Chennai', required: true, errorText: _step2Submitted && _cityController.text.trim().isEmpty ? 'Enter city' : null),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('State', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
                      const Text(' *', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _step2Submitted && _selectedState == null ? Colors.red : Colors.grey[300]!),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        menuMaxHeight: 280,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        itemHeight: 48,
                        value: _selectedState,
                        hint: const Text('Select state'),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedState = newValue;
                          });
                        },
                        items: _stateCodes.keys.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: TextStyle(color: navyBlue, fontSize: 14)),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  if (_step2Submitted && _selectedState == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 4, left: 8),
                      child: Text('Select state', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ],
        ),
        
        _buildTextField('Pincode (Optional)', _pincodeController, '6 digit pincode', errorText: _step2Submitted && _pincodeController.text.trim().isNotEmpty && _pincodeController.text.trim().length != 6 ? 'Pincode must be 6 digits' : null),

        const SizedBox(height: 48),

        // Next Step Button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _step2Submitted = true;
              });
              bool validReg = RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$').hasMatch(_registrationController.text.replaceAll(' ', '').trim());
              bool validPincode = _pincodeController.text.trim().isEmpty || _pincodeController.text.trim().length == 6;
              if (validReg && _cityController.text.trim().isNotEmpty && _selectedState != null && validPincode) {
                setState(() {
                  _currentStep = 3;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: (RegExp(r'^[A-Z]{2}[0-9]{1,2}[A-Z]{0,3}[0-9]{4}$').hasMatch(_registrationController.text.replaceAll(' ', '').trim()) && _cityController.text.trim().isNotEmpty && _selectedState != null && (_pincodeController.text.trim().isEmpty || _pincodeController.text.trim().length == 6)) ? orange : Colors.grey,
              disabledBackgroundColor: Colors.grey[300],
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4)),
                          child: Text('IND',
                              style: TextStyle(
                                  color: navyBlue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        Text(_registrationController.text.trim().isEmpty ? 'Not entered' : _registrationController.text.trim(),
                            style: TextStyle(
                                fontWeight: FontWeight.bold, color: navyBlue)),
                        if (_registrationController.text.trim().isNotEmpty) ...[
                           const SizedBox(width: 8),
                           Icon(Icons.check_circle,
                               color: Colors.green[600], size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                        _selectedYear != null && _brandController.text.trim().isNotEmpty && _modelController.text.trim().isNotEmpty 
                        ? '$_selectedYear ${_brandController.text.trim()} ${_modelController.text.trim()} ${_variantController.text.trim()}'.replaceAll(RegExp(r'\s+'), ' ').trim() 
                        : 'Details not fully entered',
                        style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
            Row(
               children: [
                 Text('Total Kilometers Driven',
                     style: TextStyle(
                         fontSize: 16,
                         fontWeight: FontWeight.bold,
                         color: navyBlue)),
                 const Text(' *', style: TextStyle(color: Colors.red)),
               ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _step3Submitted && _kmController.text.trim().isEmpty ? Colors.red : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _kmController,
                  onChanged: (val) {
                    String digitsOnly = val.replaceAll(RegExp(r'[^0-9]'), '');
                    if (val != digitsOnly) {
                       _kmController.value = _kmController.value.copyWith(
                          text: digitsOnly,
                          selection: TextSelection.collapsed(offset: digitsOnly.length),
                       );
                    }
                    setState((){});
                  },
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: navyBlue),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 42500',
                    hintStyle: TextStyle(color: Colors.black26),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    const Text('KM',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey)),
                    if (_kmController.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_step3Submitted && _kmController.text.trim().isEmpty)
          const Padding(
             padding: EdgeInsets.only(top: 4, left: 8),
             child: Text('Enter KM driven', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 32),

        // Number of Owners
        Row(
          children: [
            Text('Number of Previous Owners',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyBlue)),
            const Text(' *', style: TextStyle(color: Colors.red)),
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
        if (_step3Submitted && _selectedOwner == null)
          const Padding(
             padding: EdgeInsets.only(top: 4, left: 8),
             child: Text('Select number of owners', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 32),

        // Insurance Details Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Insurance Details',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyBlue)),
            const SizedBox(height: 4),
            const Text('Protects transfer valuation',
                style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
             Text('Insurance Coverage Type',
                 style: TextStyle(
                     fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
             const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _step3Submitted && _selectedInsuranceType == null ? Colors.red : Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              menuMaxHeight: 280,
              value: _selectedInsuranceType,
              hint: const Text('Select insurance type', style: TextStyle(color: Colors.black26)),
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
        if (_step3Submitted && _selectedInsuranceType == null)
          const Padding(
             padding: EdgeInsets.only(top: 4, left: 8),
             child: Text('Select insurance type', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
             Text('Insurance Till (Expiry Date)',
                 style: TextStyle(
                     fontSize: 14, fontWeight: FontWeight.w600, color: navyBlue)),
             const Text(' *', style: TextStyle(color: Colors.red)),
          ],
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            FocusScope.of(context).unfocus();
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _insuranceExpiryDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
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
              border: Border.all(color: _step3Submitted && _insuranceExpiryDate == null ? Colors.red : Colors.grey[300]!),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_insuranceExpiryDate != null ? _formatDate(_insuranceExpiryDate!) : 'Select date',
                    style: TextStyle(fontSize: 14, color: _insuranceExpiryDate != null ? navyBlue : Colors.black26)),
                const Icon(Icons.calendar_today_outlined,
                    color: Colors.grey, size: 20),
              ],
            ),
          ),
        ),
        if (_step3Submitted && _insuranceExpiryDate == null)
          const Padding(
             padding: EdgeInsets.only(top: 4, left: 8),
             child: Text('Select expiry date', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 12),
        if (_insuranceExpiryDate != null)
          Builder(
            builder: (context) {
              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);
              final expiry = DateTime(_insuranceExpiryDate!.year, _insuranceExpiryDate!.month, _insuranceExpiryDate!.day);
              final diff = expiry.difference(today).inDays;
              
              Color bgColor;
              Color borderColor;
              Color iconColor;
              Color textColor;
              String text;
              IconData icon;
              
              if (diff < 0) {
                 bgColor = Colors.red[50]!;
                 borderColor = Colors.red[200]!;
                 iconColor = Colors.red[700]!;
                 textColor = Colors.red[800]!;
                 text = 'Insurance expired';
                 icon = Icons.warning_amber_rounded;
              } else if (diff <= 30) {
                 bgColor = Colors.orange[50]!;
                 borderColor = Colors.orange[200]!;
                 iconColor = Colors.orange[700]!;
                 textColor = Colors.orange[800]!;
                 text = 'Expires in $diff days';
                 icon = Icons.info_outline;
              } else {
                 bgColor = Colors.green[50]!;
                 borderColor = Colors.green[200]!;
                 iconColor = Colors.green[700]!;
                 textColor = Colors.green[800]!;
                 text = 'Valid for $diff more days';
                 icon = Icons.check_circle;
              }
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(text,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontSize: 14)),
                    ),
                  ],
                ),
              );
            }
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
                        Text('ODOMETER PHOTO TIP',
                            style: TextStyle(
                                color: orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        const SizedBox(width: 4),
                        Icon(Icons.star, color: orange, size: 12),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Clear meter reading proof in Step 4 unlocks instant badge for 3x buyer trust.',
                      style: TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.4),
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
                _step3Submitted = true;
              });
              if (_kmController.text.trim().isNotEmpty && int.tryParse(_kmController.text.replaceAll(RegExp(r'[^0-9]'), '')) != null && int.parse(_kmController.text.replaceAll(RegExp(r'[^0-9]'), '')) > 0 && _selectedOwner != null && _selectedInsuranceType != null && _insuranceExpiryDate != null) {
                setState(() {
                  _currentStep = 4; // Go to step 4
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: (_kmController.text.trim().isNotEmpty && int.tryParse(_kmController.text.replaceAll(RegExp(r'[^0-9]'), '')) != null && int.parse(_kmController.text.replaceAll(RegExp(r'[^0-9]'), '')) > 0 && _selectedOwner != null && _selectedInsuranceType != null && _insuranceExpiryDate != null) ? orange : Colors.grey,
              disabledBackgroundColor: Colors.grey[300],
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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
            color: isSelected ? orange : (_step3Submitted && _selectedOwner == null ? Colors.red : Colors.grey[300]!),
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

  Future<void> _pickImages(List<XFile> currentList) async {
    final List<XFile> pickedImages = await _picker.pickMultiImage(
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (pickedImages.isNotEmpty) {
      setState(() {
        currentList.addAll(pickedImages);
      });
    }
  }

  BoxDecoration _getTileDecoration(bool isUploaded) {
    return BoxDecoration(
      color: const Color(0xFFFFFFFF),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isUploaded ? const Color(0xFFFB7800) : const Color(0xFFE5E7EB),
        width: isUploaded ? 1.5 : 1.0,
      ),
    );
  }

  Widget _buildImageCategoryBox(
      String label, IconData icon, List<XFile> images) {
    if (images.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: _getTileDecoration(true),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, size: 16, color: orange),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: navyBlue,
                              fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Uploaded',
                      style: TextStyle(
                          color: orange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...images.asMap().entries.map((entry) {
                    int index = entry.key;
                    XFile image = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: const Color(0xFFF3F4F6),
                              child: FutureBuilder<Uint8List>(
                                future: image.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                          ConnectionState.done &&
                                      snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  }
                                  return const SizedBox(
                                    width: 60,
                                    height: 60,
                                  );
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  images.removeAt(index);
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                                child: Icon(Icons.close,
                                    color: navyBlue, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  GestureDetector(
                    onTap: () => _pickImages(images),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), style: BorderStyle.solid),
                      ),
                      child: Center(
                        child: Icon(Icons.add, color: navyBlue),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return InkWell(
      onTap: () => _pickImages(images),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _getTileDecoration(false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: navyBlue, size: 28),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: navyBlue, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(label == 'Front View' ? 'Tap to Upload (Required)' : 'Tap to Upload',
                style: TextStyle(color: label == 'Front View' ? orange : const Color(0xFF6B7280), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPdf() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result != null) {
      setState(() {
        inspectionReportFile = result.files.first;
      });
    }
  }

  Widget _buildPdfCategoryBox() {
    if (inspectionReportFile != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: _getTileDecoration(true),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.picture_as_pdf, color: orange, size: 28),
            const SizedBox(height: 4),
            Text(
              inspectionReportFile!.name,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: navyBlue,
                  fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text('${(inspectionReportFile!.size / 1024).toStringAsFixed(1)} KB',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 10)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1E6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Uploaded',
                  style: TextStyle(
                      color: orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: _pickPdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: Text('Replace', style: TextStyle(color: navyBlue, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      inspectionReportFile = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.all(Radius.circular(4)),
                    ),
                    child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    return InkWell(
      onTap: _pickPdf,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: _getTileDecoration(false),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.picture_as_pdf, color: navyBlue, size: 28),
            const SizedBox(height: 4),
            Text(
              'Inspection Report',
              style: TextStyle(
                  fontWeight: FontWeight.w500, color: navyBlue, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text('Upload PDF',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
          ],
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
            style:
                const TextStyle(color: Colors.grey, fontSize: 16, height: 1.4),
            children: [
              const TextSpan(
                  text: 'Vehicles with 5+ high quality photos receive '),
              TextSpan(
                  text: '3x more bids',
                  style: TextStyle(color: orange, fontWeight: FontWeight.bold)),
              const TextSpan(text: ' and faster inquiries.'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio:
              MediaQuery.of(context).size.width < 400 ? 0.95 : 1.1,
          children: [
            _buildImageCategoryBox(
                'Front View', Icons.directions_car_outlined, frontViewImages),
            _buildImageCategoryBox(
                'Rear View', Icons.directions_car_outlined, rearViewImages),
            _buildImageCategoryBox(
                'Left & Right', Icons.camera_alt_outlined, leftRightImages),
            _buildImageCategoryBox('Interior & Dash', Icons.dashboard_outlined,
                interiorDashImages),
            _buildImageCategoryBox(
                'Engine & Tyres', Icons.build_outlined, engineTyresImages),
            _buildImageCategoryBox(
                'RC', Icons.description_outlined, rcInsuranceImages),
            _buildPdfCategoryBox(),
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
                    Text('Want 100% verified badge?',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: navyBlue,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    const Text(
                        'Book free doorstep inspection by certified Wheels2Drive technicians to fast-track buyer trust.',
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () {},
                      child: Row(
                        children: [
                          Text('Schedule Free Inspection',
                              style: TextStyle(
                                  color: orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
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
              if (frontViewImages.isEmpty ||
                  rearViewImages.isEmpty ||
                  leftRightImages.isEmpty ||
                  interiorDashImages.isEmpty ||
                  engineTyresImages.isEmpty ||
                  rcInsuranceImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text(
                        'Please upload at least 1 photo for all 6 categories')));
                return;
              }
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
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
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
          'Buyers bid with confidence knowing they are verified profiles.',
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
                    Text(
                      '${_selectedYear ?? ''} ${_brandController.text.trim()} ${_modelController.text.trim()} ${_variantController.text.trim()}'.replaceAll(RegExp(r'\s+'), ' ').trim(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: navyBlue,
                          fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      [
                        _registrationController.text.trim(),
                        _kmController.text.trim().isNotEmpty ? '${_kmController.text.trim()} km' : null,
                        _selectedOwner,
                      ].where((e) => e != null && e.isNotEmpty).join(' • '),
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
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
            Text('Expected Selling Price',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyBlue)),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: (_step5Submitted && _priceController.text.trim().isEmpty) ? Colors.red : Colors.grey[300]!),
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 16.0),
                child: Text('₹',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey)),
              ),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: navyBlue),
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    setState(() {
                      String numStr = val.replaceAll(RegExp(r'[^0-9]'), '');
                      if (numStr.isNotEmpty) {
                        String formatted = _formatIndianNumber(numStr);
                        _priceController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(offset: formatted.length),
                        );
                      } else {
                        _priceController.text = '';
                      }
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter expected price',
                    hintStyle: TextStyle(fontSize: 20, color: Colors.black26),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              if (int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) != null && int.tryParse(_priceController.text.replaceAll(RegExp(r'[^0-9]'), ''))! > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Icon(Icons.check_circle, color: orange),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Deleted reserve toggle section
        const SizedBox(height: 12),

        // Auction Duration Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Auction Duration',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: navyBlue)),
            Text('Live countdown starts post-approval',
                style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildDurationCard('24 Hours', 'Express', null)),
            const SizedBox(width: 8),
            Expanded(
                child:
                    _buildDurationCard('48 Hours', 'Recommended', null)),
            const SizedBox(width: 8),
            Expanded(child: _buildDurationCard('72 Hours', 'Max Reach', null)),
          ],
        ),
        if (_step5Submitted && _selectedDuration == null)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text('Select auction duration', style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 48),

        const SizedBox(height: 48),

        // Submit Button
        Builder(
          builder: (context) {
            bool isStep5Valid = _priceController.text.trim().isNotEmpty && _selectedDuration != null;
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: isStep5Valid ? () async {
                  if (!SubscriptionStore().isActive) {
                    _showSubscriptionExpiredDialog();
                    return;
                  }
                  _handleFinalSubmit();
                } : () {
                  setState(() => _step5Submitted = true);
                  List<String> errors = [];
                  if (_priceController.text.trim().isEmpty) errors.add("Enter expected price");
                  if (_selectedDuration == null) errors.add("Select auction duration");
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(errors.join(', ')),
                    backgroundColor: Colors.red,
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isStep5Valid ? orange : Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isSubmitting
                      ? 'Saving...'
                      : (widget.isEditMode
                          ? 'Update Listing'
                          : 'Submit for Admin Verification'),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                if (_isSubmitting)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                else
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
            ),
          );
          },
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
          color: isSelected ? navyBlue.withValues(alpha: 0.05) : Colors.white,
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
                  color: orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: orange,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Text(
              duration,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: navyBlue,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subLabel,
              style: const TextStyle(
                color: Colors.grey,
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
        Icon(Icons.construction,
            size: 64, color: navyBlue.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(
          'Step $_currentStep coming soon',
          style: TextStyle(
              fontSize: 24, fontWeight: FontWeight.bold, color: navyBlue),
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
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                ),
                child: const Text('Go Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () async {
                  if (_currentStep < _totalSteps) {
                    setState(() {
                      _currentStep++;
                    });
                  } else {
                    _handleFinalSubmit();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: orange,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: Text(_currentStep < _totalSteps ? 'Next Step' : 'Submit',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showSubscriptionExpiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFB7800)),
            SizedBox(width: 8),
            Text('Subscription Expired'),
          ],
        ),
        content: const Text(
            'Your subscription has expired. You need an active subscription to publish this listing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFB7800),
            ),
            child:
                const Text('View Plans', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
