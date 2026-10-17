import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_nav_scaffold.dart';
import '../utils/responsive_helper.dart';

import '../utils/local_listings_store.dart';
import 'filter_sort_screen.dart';
import '../widgets/live_auction_vehicle_card.dart';

class BrowseVehiclesScreen extends StatefulWidget {
  const BrowseVehiclesScreen({super.key});

  @override
  State<BrowseVehiclesScreen> createState() => _BrowseVehiclesScreenState();
}

class _BrowseVehiclesScreenState extends State<BrowseVehiclesScreen> {
  final int _bottomNavIndex = 0;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> get filteredVehicles {
    final store = LocalListingsStore();
    final now = DateTime.now();
    var liveListings = store.acceptedListings.where((v) {
      if ((v['status'] ?? '').toString().toLowerCase() != 'live') return false;
      if (v['endProcessed'] == true) return false;
      if (v['endTime'] == null) return false;
      final endTime = DateTime.tryParse(v['endTime'].toString());
      if (endTime == null || endTime.isBefore(now)) return false;
      return true;
    }).toList();

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      liveListings = liveListings.where((v) {
        final title = (v['title']?.toString() ?? '').toLowerCase();
        return title.contains(query);
      }).toList();
    }
    return liveListings;
  }

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _handleRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const lightBlueGrey = Color(0xFFEEF1F7);

    final scrollableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(
          builder: (innerContext) => _buildSearchBar(innerContext, lightBlueGrey),
        ),
        _buildSectionHeader(lightBlueGrey),
        ListenableBuilder(
          listenable: LocalListingsStore(),
          builder: (context, _) {
            final currentVehicles = filteredVehicles;
            if (currentVehicles.isEmpty && searchQuery.isNotEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 64.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.search_off, size: 60, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      "No vehicles found for '$searchQuery'",
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Try a different car, model, or city",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }
            return ResponsiveHelper.isMobile(context)
                ? ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: currentVehicles.length,
                    itemBuilder: (context, index) => LiveAuctionVehicleCard(vehicle: currentVehicles[index], lightBlueGrey: lightBlueGrey),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = ResponsiveHelper.gridColumns(context);
                        double crossAxisSpacing = 24;
                        double itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
                        
                        return Wrap(
                          spacing: crossAxisSpacing,
                          runSpacing: 24,
                          children: currentVehicles.map((vehicle) {
                            return SizedBox(
                              width: itemWidth,
                              child: LiveAuctionVehicleCard(vehicle: vehicle, lightBlueGrey: lightBlueGrey),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  );
          },
        ),
      ],
    );

    return ResponsiveNavScaffold(
      currentIndex: 0,
      body: SingleChildScrollView(
        child: scrollableContent,
      ),
    );
  }

  Widget _buildTopBar(Color lightBlueGrey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Wheels2Drive',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, Color lightBlueGrey) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  const Icon(Icons.search, color: AppColors.outline, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search car, model, city...',
                        hintStyle: const TextStyle(
                          color: AppColors.outline,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(bottom: 12, top: 12),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    searchQuery = '';
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (BuildContext context) => const FilterSortScreen(),
              ).then((result) {
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Filters applied!')),
                  );
                }
              });
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSectionHeader(Color lightBlueGrey) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Featured Live Lots',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: lightBlueGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on, size: 12, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Gurugram Hub',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              if (_isRefreshing)
                const Padding(
                  padding: EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  ),
                ),
              GestureDetector(
                onTap: _handleRefresh,
                child: const Row(
                  children: [
                    Text(
                      'Auto-refresh',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.outline,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.refresh, size: 14, color: AppColors.outline),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
