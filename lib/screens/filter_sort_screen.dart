import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout_wrapper.dart';

class FilterSortScreen extends StatefulWidget {
  const FilterSortScreen({super.key});

  @override
  State<FilterSortScreen> createState() => _FilterSortScreenState();
}

class _FilterSortScreenState extends State<FilterSortScreen> {
  // Theme Colors
  static const Color navyBlue = Color(0xFF001128);
  static const Color orange = Color(0xFFFB7800);
  static const Color lightBlueGrey = Color(0xFFEEF1F7);

  // State Variables
  String _selectedCategoryTab = 'All';
  String _selectedSort = 'Ending Soonest';
  RangeValues _priceRange = const RangeValues(1.50, 22.50);
  final Set<String> _selectedFuelTypes = {'Petrol', 'Diesel'};
  String _selectedTransmission = 'Automatic';
  final Set<String> _selectedBodyTypes = {'Sedan'};
  final Set<String> _selectedStates = {'TN - Tamil Nadu'};
  bool _is140PtCertified = true;
  bool _isNonAccidental = true;
  String? _selectedPricePill;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayoutWrapper(
      mobileContent: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubHeader(),
                      const Divider(height: 1),
                      _buildCategoryTabs(),
                      const Divider(height: 1),
                      _buildSortSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildPriceRangeSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildFuelTypeSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildTransmissionSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildBodyTypeSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildStateHubSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildTrustVerificationSection(),
                      const SizedBox(height: 100), // Padding for bottom bar
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomSheet: _buildBottomBar(),
      ),
      desktopContent: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopHeader(),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSubHeader(),
                      const Divider(height: 1),
                      _buildCategoryTabs(),
                      const Divider(height: 1),
                      _buildSortSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildPriceRangeSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildFuelTypeSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildTransmissionSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildBodyTypeSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildStateHubSection(),
                      const Divider(height: 1, thickness: 8, color: lightBlueGrey),
                      _buildTrustVerificationSection(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomSheet: _buildBottomBar(),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: navyBlue),
          ),
          Row(
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
              const Text(
                'Filter & Sort',
                style: TextStyle(
                  color: navyBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24), // Placeholder to keep center alignment after removing share icon
        ],
      ),
    );
  }

  Widget _buildSubHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.only(top: 4.0, right: 12.0),
              child: Icon(Icons.close, color: navyBlue, size: 20),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Filter & Sort',
                  style: TextStyle(
                    color: navyBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Refining pan-India live lots',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategoryTab = 'All';
                _selectedSort = 'Ending Soonest';
                _priceRange = const RangeValues(1.50, 22.50);
                _selectedPricePill = null;
                _selectedFuelTypes.clear();
                _selectedTransmission = '';
                _selectedBodyTypes.clear();
                _selectedStates.clear();
                _is140PtCertified = false;
                _isNonAccidental = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.refresh, color: orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Clear All (3)',
                    style: const TextStyle(
                      color: orange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final tabs = ['All', 'Cars', 'Bikes/Scooters Commercial'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = _selectedCategoryTab == tab;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategoryTab = tab),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? navyBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? navyBlue : Colors.grey.shade300),
              ),
              child: Text(
                tab,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon, Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: navyBlue, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: navyBlue,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing,
        ]
      ],
    );
  }

  Widget _buildSortSection() {
    final sortOptions = [
      {
        'title': 'Ending Soonest',
        'subtitle': 'Real-time closing bids',
        'icon': Icons.timer_outlined,
        'badge': 'URGENT',
      },
      {'title': 'Lowest Current Bid', 'icon': Icons.arrow_downward},
      {'title': 'Highest Current Bid', 'icon': Icons.arrow_upward},
      {'title': 'Year: Newest to Oldest', 'icon': Icons.calendar_today},
      {'title': 'Kilometers: Low to High', 'icon': Icons.speed},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Sort Lots By',
            icon: Icons.swap_vert,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'PRIORITY',
                style: TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...sortOptions.map((option) {
            final isSelected = _selectedSort == option['title'];
            return InkWell(
              onTap: () => setState(() => _selectedSort = option['title'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isSelected ? orange : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Icon(option['icon'] as IconData, size: 18, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                option['title'] as String,
                                style: TextStyle(
                                  color: isSelected ? navyBlue : Colors.grey.shade800,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                              if (option['badge'] != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    option['badge'] as String,
                                    style: TextStyle(color: Colors.red.shade700, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ]
                            ],
                          ),
                          if (option['subtitle'] != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              option['subtitle'] as String,
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPriceRangeSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Bid / Price Range',
            icon: Icons.monetization_on_outlined,
            trailing: Text(
              'Pan-India Base',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPriceInputBox('Min Bid', '₹${_priceRange.start.toStringAsFixed(2)} Lakh'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPriceInputBox('Max Bid', '₹${_priceRange.end.toStringAsFixed(2)} Lakh'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          RangeSlider(
            values: _priceRange,
            min: 0.0,
            max: 50.0,
            activeColor: orange,
            inactiveColor: Colors.grey.shade300,
            onChanged: (RangeValues values) {
              setState(() {
                _priceRange = values;
                _selectedPricePill = null;
              });
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['Under ₹3L', '₹3L - ₹8L', '₹8L - ₹15L', '₹15L+'].map((label) {
              final isSelected = _selectedPricePill == label;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPricePill = label;
                    if (label == 'Under ₹3L') {
                      _priceRange = const RangeValues(0.0, 3.0);
                    } else if (label == '₹3L - ₹8L') {
                      _priceRange = const RangeValues(3.0, 8.0);
                    } else if (label == '₹8L - ₹15L') {
                      _priceRange = const RangeValues(8.0, 15.0);
                    } else if (label == '₹15L+') {
                      _priceRange = const RangeValues(15.0, 50.0);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? navyBlue : Colors.white,
                    border: Border.all(color: isSelected ? navyBlue : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey.shade700, 
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInputBox(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: lightBlueGrey,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: const TextStyle(color: navyBlue, fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildFuelTypeSection() {
    final fuelTypes = [
      {'name': 'Petrol', 'icon': Icons.local_gas_station},
      {'name': 'Diesel', 'icon': Icons.local_gas_station},
      {'name': 'CNG/LPG', 'icon': Icons.eco},
      {'name': 'Electric (EV)', 'icon': Icons.electric_car},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Fuel Type',
            icon: Icons.local_gas_station_outlined,
            trailing: Text(
              '${_selectedFuelTypes.length} Selected',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 3.5,
            physics: const NeverScrollableScrollPhysics(),
            children: fuelTypes.map((fuel) {
              final isSelected = _selectedFuelTypes.contains(fuel['name']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedFuelTypes.remove(fuel['name']);
                    } else {
                      _selectedFuelTypes.add(fuel['name'] as String);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? navyBlue : Colors.white,
                    border: Border.all(color: isSelected ? navyBlue : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        fuel['icon'] as IconData,
                        size: 16,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fuel['name'] as String,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade800,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected) const Icon(Icons.check, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTransmissionSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Transmission',
            icon: Icons.settings_outlined,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTransmissionToggle('Automatic'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTransmissionToggle('Manual'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransmissionToggle(String type) {
    final isSelected = _selectedTransmission == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedTransmission = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? navyBlue : Colors.white,
          border: Border.all(color: isSelected ? navyBlue : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Colors.white, size: 16),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBodyTypeSection() {
    final bodyTypes = [
      {'name': 'SUV / Compact', 'icon': Icons.directions_car_filled},
      {'name': 'Sedan', 'icon': Icons.directions_car},
      {'name': 'Hatchback', 'icon': Icons.airport_shuttle},
      {'name': 'MUV / 7-Seater', 'icon': Icons.directions_bus},
      {'name': 'Cruiser Bike', 'icon': Icons.two_wheeler},
      {'name': 'Commuter / EV', 'icon': Icons.electric_bike},
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Body Type',
            icon: Icons.directions_car_outlined,
            trailing: Text(
              'Cars & Bikes',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
            physics: const NeverScrollableScrollPhysics(),
            children: bodyTypes.map((body) {
              final isSelected = _selectedBodyTypes.contains(body['name']);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedBodyTypes.remove(body['name']);
                    } else {
                      _selectedBodyTypes.add(body['name'] as String);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? lightBlueGrey : Colors.white,
                    border: Border.all(color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        body['icon'] as IconData,
                        size: 32,
                        color: isSelected ? navyBlue : Colors.grey.shade500,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        body['name'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isSelected ? navyBlue : Colors.grey.shade700,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStateHubSection() {
    final states = [
      'TN - Tamil Nadu',
      'KA - Karnataka',
      'MH - Maharashtra',
      'DL - Delhi NCR',
      'HR - Haryana',
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'State & RTO Hub',
            icon: Icons.location_on_outlined,
            trailing: Text(
              'Pan-India Yards',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: states.map((state) {
              final isSelected = _selectedStates.contains(state);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedStates.remove(state);
                    } else {
                      _selectedStates.add(state);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? navyBlue : Colors.white,
                    border: Border.all(color: isSelected ? navyBlue : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        state,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey.shade800,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (isSelected) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check, color: Colors.white, size: 14),
                      ]
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustVerificationSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'Trust & Verification',
            icon: Icons.verified_user_outlined,
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            title: '140-Point Certified Lots',
            subtitle: 'Engine, chassis, and electronic health pass',
            value: _is140PtCertified,
            badge: 'Top 5%',
            onChanged: (val) => setState(() => _is140PtCertified = val),
          ),
          const SizedBox(height: 16),
          _buildToggleRow(
            title: 'No Accidental History',
            subtitle: 'Zero structural claim records',
            value: _isNonAccidental,
            onChanged: (val) => setState(() => _isNonAccidental = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? badge,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.shield_outlined, color: Colors.grey.shade600, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: navyBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  if (badge != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(color: orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.white,
          activeTrackColor: orange,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.grey.shade300,
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
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
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategoryTab = 'All';
                  _selectedSort = 'Ending Soonest';
                  _priceRange = const RangeValues(1.50, 22.50);
                  _selectedPricePill = null;
                  _selectedFuelTypes.clear();
                  _selectedTransmission = '';
                  _selectedBodyTypes.clear();
                  _selectedStates.clear();
                  _is140PtCertified = false;
                  _isNonAccidental = false;
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, {
                    'sort': _selectedSort,
                    'price': _priceRange,
                    'category': _selectedCategoryTab,
                  });
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
                  children: [
                    const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        '24 Lots Found',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
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
