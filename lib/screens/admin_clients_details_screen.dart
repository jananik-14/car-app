import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/responsive_nav_scaffold.dart';
import '../widgets/admin_navigation_drawer.dart';
import '../widgets/admin_app_bar.dart';
import '../services/admin_clients_store.dart';
import '../utils/local_listings_store.dart';
import '../utils/profile_storage_helper.dart';
import '../utils/temp_admin_config.dart';
import '../utils/blob_storage.dart';
import '../config/subscription_plans.dart';

class AdminClientsDetailsScreen extends StatefulWidget {
  const AdminClientsDetailsScreen({super.key});

  @override
  State<AdminClientsDetailsScreen> createState() => _AdminClientsDetailsScreenState();
}

class _ClientItem {
  final String phone;
  final String name;
  final String email;
  final String city;
  final String dob;
  final bool hasKyc;
  final bool isBlocked;
  final String joinedDateStr;
  final DateTime joinedDate;
  final String planName;
  final String planExpiry;
  final bool hasActivePlan;
  final int listingsCount;
  final int bidsCount;

  _ClientItem({
    required this.phone,
    required this.name,
    required this.email,
    required this.city,
    required this.dob,
    required this.hasKyc,
    required this.isBlocked,
    required this.joinedDateStr,
    required this.joinedDate,
    required this.planName,
    required this.planExpiry,
    required this.hasActivePlan,
    required this.listingsCount,
    required this.bidsCount,
  });
}

class _AdminClientsDetailsScreenState extends State<AdminClientsDetailsScreen> {
  int _activeTabIndex = 0;
  String _searchQuery = '';
  String? _selectedClientPhone;

  List<_ClientItem> _clients = [];
  bool _isLoadingClients = true;

  final Color _navy = const Color(0xFF001128);
  final Color _orange = const Color(0xFFfb7800);
  final Color _cardBorder = const Color(0xFFEEEEEE);

  // Null-safe helpers
  String _s(dynamic v, [String fallback = '']) => v != null ? v.toString().trim() : fallback;
  int _i(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }
  bool _b(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    final str = v.toString().toLowerCase().trim();
    return str == 'true' || str == '1';
  }

  String _toTitleCase(String text) {
    if (text.trim().isEmpty) return '';
    return text.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
  }

  @override
  void initState() {
    super.initState();
    _loadAllClients();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final uri = GoRouterState.of(context).uri;
      final phoneParam = uri.queryParameters['phone'] ?? uri.queryParameters['clientPhone'];
      final tabParam = uri.queryParameters['tab'];

      if (tabParam != null) {
        final tabIdx = int.tryParse(tabParam);
        if (tabIdx != null && tabIdx >= 0 && tabIdx <= 1) {
          _activeTabIndex = tabIdx;
        }
      }

      if (phoneParam != null && phoneParam.trim().isNotEmpty) {
        _selectedClientPhone = ProfileStorageHelper.normalizePhone(phoneParam);
      }
    } catch (_) {}
  }

  Future<void> _loadAllClients() async {
    setState(() => _isLoadingClients = true);
    final prefs = await SharedPreferences.getInstance();

    // 1. Gather all registered client phones
    final Set<String> registeredPhones = {};
    final savedList = prefs.getStringList('registered_client_phones') ?? [];
    for (final p in savedList) {
      final norm = ProfileStorageHelper.normalizePhone(p);
      if (_isValidClientPhone(norm)) registeredPhones.add(norm);
    }

    // 2. Scan SharedPreferences keys to migrate any existing profile data
    for (final key in prefs.getKeys()) {
      if (key.startsWith('user_name_')) {
        final norm = ProfileStorageHelper.normalizePhone(key.substring('user_name_'.length));
        if (_isValidClientPhone(norm)) registeredPhones.add(norm);
      } else if (key.startsWith('kyc_uploaded_')) {
        final norm = ProfileStorageHelper.normalizePhone(key.substring('kyc_uploaded_'.length));
        if (_isValidClientPhone(norm)) registeredPhones.add(norm);
      } else if (key.startsWith('user_email_')) {
        final norm = ProfileStorageHelper.normalizePhone(key.substring('user_email_'.length));
        if (_isValidClientPhone(norm)) registeredPhones.add(norm);
      }
    }

    // 3. Scan listings and bids for client phones
    final listingsStore = LocalListingsStore();
    final allListings = [
      ...listingsStore.acceptedListings,
      ...listingsStore.pendingListings,
      ...listingsStore.rejectedListings,
    ];
    for (final l in allListings) {
      final seller = ProfileStorageHelper.normalizePhone(_s(l['phone'] ?? l['sellerPhone']));
      if (_isValidClientPhone(seller)) registeredPhones.add(seller);

      final bids = l['bids'];
      if (bids is List) {
        for (final b in bids) {
          if (b is Map) {
            final bidder = ProfileStorageHelper.normalizePhone(_s(b['bidderPhone'] ?? b['bidderUsername']));
            if (_isValidClientPhone(bidder)) registeredPhones.add(bidder);
          }
        }
      }
    }

    // 4. Scan subscriptions for client phones
    final allSubscriptions = [
      ...listingsStore.pendingSubscriptions,
      ...listingsStore.acceptedSubscriptions,
      ...listingsStore.rejectedSubscriptions,
    ];
    for (final s in allSubscriptions) {
      final norm = ProfileStorageHelper.normalizePhone(_s(s['phone']));
      if (_isValidClientPhone(norm)) registeredPhones.add(norm);
    }

    // 5. Scan active logins
    for (final l in AdminClientsStore().activeLogins) {
      final norm = ProfileStorageHelper.normalizePhone(_s(l['phone']));
      if (_isValidClientPhone(norm)) registeredPhones.add(norm);
    }

    // Save back to registry list
    final sortedPhones = registeredPhones.toList();
    await prefs.setStringList('registered_client_phones', sortedPhones);

    // 6. Build client items
    final List<_ClientItem> loaded = [];
    final now = DateTime.now();

    for (final phone in sortedPhones) {
      final nameRaw = prefs.getString('user_name_$phone') ?? '';
      final name = nameRaw.isNotEmpty ? _toTitleCase(nameRaw) : 'Client ($phone)';
      final email = prefs.getString('user_email_$phone') ?? '';
      final cityRaw = prefs.getString('user_city_$phone') ?? '';
      final city = cityRaw.isNotEmpty ? _toTitleCase(cityRaw) : '';
      final dob = prefs.getString('user_dob_$phone') ?? '';
      final hasKyc = prefs.getBool('kyc_uploaded_$phone') ?? false;
      final isBlocked = prefs.getBool('client_blocked_$phone') ?? false;

      // Joined date
      String? joinedIso = prefs.getString('user_joined_$phone');
      DateTime joinedDate;
      if (joinedIso != null) {
        joinedDate = DateTime.tryParse(joinedIso) ?? now;
      } else {
        joinedDate = now;
        await prefs.setString('user_joined_$phone', joinedDate.toIso8601String());
      }
      final joinedStr = DateFormat('dd MMM yyyy').format(joinedDate);

      // Subscription info
      final subStatus = prefs.getString('sub_status_$phone') ?? 'none';
      final subPlanId = prefs.getString('sub_plan_$phone');
      final subEndStr = prefs.getString('sub_end_$phone');
      DateTime? subEnd = subEndStr != null ? DateTime.tryParse(subEndStr) : null;
      bool hasActivePlan = subStatus == 'active' && subEnd != null && subEnd.isAfter(now);
      String planName = 'No plan';
      String planExpiry = '';
      if (hasActivePlan && subPlanId != null) {
        final plan = SubscriptionPlans.getPlanById(subPlanId);
        planName = plan?.name ?? subPlanId.toUpperCase();
        planExpiry = DateFormat('dd MMM yyyy').format(subEnd);
      }

      // Listings count
      int listingsCount = 0;
      for (final l in allListings) {
        final seller = ProfileStorageHelper.normalizePhone(_s(l['phone'] ?? l['sellerPhone']));
        if (seller == phone) listingsCount++;
      }

      // Bids count
      int bidsCount = 0;
      for (final l in allListings) {
        final bids = l['bids'];
        if (bids is List) {
          for (final b in bids) {
            if (b is Map) {
              final bidder = ProfileStorageHelper.normalizePhone(_s(b['bidderPhone'] ?? b['bidderUsername']));
              if (bidder == phone) bidsCount++;
            }
          }
        }
      }

      loaded.add(_ClientItem(
        phone: phone,
        name: name,
        email: email,
        city: city,
        dob: dob,
        hasKyc: hasKyc,
        isBlocked: isBlocked,
        joinedDateStr: joinedStr,
        joinedDate: joinedDate,
        planName: planName,
        planExpiry: planExpiry,
        hasActivePlan: hasActivePlan,
        listingsCount: listingsCount,
        bidsCount: bidsCount,
      ));
    }

    // Sort by joinedDate desc
    loaded.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));

    if (mounted) {
      setState(() {
        _clients = loaded;
        _isLoadingClients = false;
      });
    }
  }

  bool _isValidClientPhone(String phone) {
    if (phone.isEmpty) return false;
    if (phone == '9999999999') return false;
    if (TempAdminConfig.isAdminNumber(phone)) return false;
    return true;
  }

  Future<void> _toggleBlockClient(_ClientItem client) async {
    final currentBlocked = client.isBlocked;
    final newBlocked = !currentBlocked;
    final actionLabel = newBlocked ? 'Block' : 'Unblock';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Client'),
        content: Text(
          newBlocked
              ? 'Are you sure you want to block ${client.name} (${client.phone})? They will not be able to log in, bid, or post vehicles.'
              : 'Are you sure you want to unblock ${client.name} (${client.phone})? Their account access will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: newBlocked ? Colors.red.shade700 : Colors.green.shade700,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('client_blocked_${client.phone}', newBlocked);

    // Audit log entry
    AdminClientsStore().addHistoryEntry(
      name: client.name,
      phone: client.phone,
      action: newBlocked ? 'client blocked by admin' : 'client unblocked by admin',
      type: 'profile updated',
      timestamp: DateTime.now(),
    );

    await _loadAllClients();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newBlocked
                ? 'Client blocked. Client cannot login, bid, or post.'
                : 'Client unblocked successfully.',
          ),
          backgroundColor: newBlocked ? Colors.red.shade700 : Colors.green.shade700,
        ),
      );
    }
  }

  Future<void> _handleForceLogout(Map<String, dynamic> session) async {
    final phone = _s(session['phone']);
    final name = _s(session['name'], 'Client');

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Force Logout Session'),
        content: Text('Are you sure you want to terminate the active session for $name ($phone)?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Force Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    AdminClientsStore().forceLogout(phone, name: name);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session terminated for $name ($phone)'),
          backgroundColor: Colors.black87,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavScaffold(
      isAdmin: true,
      currentIndex: 0,
      backgroundColor: const Color(0xFFF3F4F6),
      drawer: const AdminNavigationDrawer(),
      appBar: const AdminAppBar(),
      body: ListenableBuilder(
        listenable: AdminClientsStore(),
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(),
              if (_selectedClientPhone == null) _buildTabsRow(),
              Expanded(
                child: _selectedClientPhone != null
                    ? _buildClientDetailView()
                    : _buildTabContent(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader() {
    final store = AdminClientsStore();

    // Client-only active logins (exclude admin)
    final clientLogins = store.activeLogins.where((l) {
      final p = _s(l['phone']);
      return _isValidClientPhone(p);
    }).toList();

    String badgeText = '';
    if (_selectedClientPhone != null) {
      badgeText = 'Details';
    } else if (_activeTabIndex == 0) {
      badgeText = '${_clients.length} Total Clients';
    } else {
      badgeText = '${clientLogins.length} Active Logins';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 6,
        children: [
          Text(
            '1. Clients Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _orange,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabsRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildTabButton('1. Total Clients', 0),
          const SizedBox(width: 8),
          _buildTabButton('2. Active Logins', 1),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    bool isActive = _activeTabIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        setState(() {
          _activeTabIndex = index;
          _searchQuery = '';
          _selectedClientPhone = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _navy : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _navy,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(),
          const SizedBox(height: 14),
          _buildSearchBar(),
          const SizedBox(height: 14),
          Expanded(child: _buildListContent()),
        ],
      ),
    );
  }

  Widget _buildCardHeader() {
    String title = '';
    String badgeText = '';
    Color badgeColor = Colors.grey.shade100;
    Color badgeTextColor = _navy;

    final store = AdminClientsStore();
    final clientLogins = store.activeLogins.where((l) => _isValidClientPhone(_s(l['phone']))).toList();

    if (_activeTabIndex == 0) {
      title = 'All Registered Clients';
      badgeText = '${_clients.length} Total Clients';
      badgeColor = _orange;
      badgeTextColor = Colors.white;
    } else {
      title = 'Active Client Sessions (${clientLogins.length})';
      badgeText = '${clientLogins.length} Active Logins';
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            badgeText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeTextColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    String hint = '';
    if (_activeTabIndex == 0) {
      hint = 'Search by name, phone, or city...';
    } else {
      hint = 'Search active client sessions...';
    }

    return TextField(
      onChanged: (value) {
        setState(() {
          _searchQuery = value.toLowerCase().trim();
        });
      },
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildListContent() {
    if (_activeTabIndex == 0) {
      return _buildTotalClientsTab();
    } else {
      return _buildActiveLoginsTab();
    }
  }

  // TAB 1: TOTAL CLIENTS
  Widget _buildTotalClientsTab() {
    if (_isLoadingClients) {
      return const Center(child: CircularProgressIndicator());
    }

    var filtered = _clients.where((c) {
      if (_searchQuery.isEmpty) return true;
      return c.name.toLowerCase().contains(_searchQuery) ||
          c.phone.contains(_searchQuery) ||
          c.city.toLowerCase().contains(_searchQuery) ||
          c.email.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
        icon: Icons.people_outline,
        title: 'No registered clients found',
        subtitle: _searchQuery.isNotEmpty ? 'Try adjusting your search query' : 'Registered clients will appear here.',
      );
    }

    return ListView.separated(
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final client = filtered[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(_ClientItem client) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          setState(() {
            _selectedClientPhone = client.phone;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row: Avatar + Name + Blocked Chip + KYC Chip
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _navy.withValues(alpha: 0.08),
                    child: Text(
                      client.name.isNotEmpty ? client.name[0].toUpperCase() : 'C',
                      style: TextStyle(color: _navy, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                client.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _navy,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (client.isBlocked) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'Blocked',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: client.hasKyc ? Colors.green.shade50 : Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                client.hasKyc ? 'KYC Uploaded' : 'KYC Missing',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: client.hasKyc ? Colors.green.shade700 : Colors.orange.shade800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${client.phone}${client.city.isNotEmpty ? ' • ${client.city}' : ''}',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),
              const SizedBox(height: 10),

              // Metadata row: Email + Subscription + Joined
              Wrap(
                spacing: 16,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (client.email.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email_outlined, size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          client.email,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.card_membership, size: 14, color: client.hasActivePlan ? Colors.green : Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        client.hasActivePlan
                            ? '${client.planName} (Exp: ${client.planExpiry})'
                            : 'No plan',
                        style: TextStyle(
                          color: client.hasActivePlan ? Colors.green.shade800 : Colors.grey.shade700,
                          fontSize: 12,
                          fontWeight: client.hasActivePlan ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Joined: ${client.joinedDateStr}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Activity counts
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${client.listingsCount} Listings',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _navy),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${client.bidsCount} Bids',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _navy),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // CLIENT DETAIL VIEW
  Widget _buildClientDetailView() {
    final clientPhone = _selectedClientPhone!;
    final client = _clients.firstWhere(
      (c) => c.phone == clientPhone,
      orElse: () => _ClientItem(
        phone: clientPhone,
        name: 'Client ($clientPhone)',
        email: '',
        city: '',
        dob: '',
        hasKyc: false,
        isBlocked: false,
        joinedDateStr: 'Recently',
        joinedDate: DateTime.now(),
        planName: 'No plan',
        planExpiry: '',
        hasActivePlan: false,
        listingsCount: 0,
        bidsCount: 0,
      ),
    );

    final listingsStore = LocalListingsStore();
    final allListings = [
      ...listingsStore.acceptedListings,
      ...listingsStore.pendingListings,
      ...listingsStore.rejectedListings,
    ];

    // Client's listings
    final clientListings = allListings.where((l) {
      final p = ProfileStorageHelper.normalizePhone(_s(l['phone'] ?? l['sellerPhone']));
      return p == clientPhone;
    }).toList();

    // Client's bids
    final List<Map<String, dynamic>> clientBids = [];
    for (final l in allListings) {
      final bids = l['bids'];
      if (bids is List) {
        for (final b in bids) {
          if (b is Map) {
            final bidder = ProfileStorageHelper.normalizePhone(_s(b['bidderPhone'] ?? b['bidderUsername']));
            if (bidder == clientPhone) {
              clientBids.add({
                'vehicleTitle': _s(l['title'] ?? '${_s(l['year'])} ${_s(l['make'])} ${_s(l['model'])}'),
                'amount': _i(b['bidAmount'] ?? b['bidAmountNum'] ?? b['amount']),
                'time': _s(b['time'] ?? b['timestamp']),
                'isWinning': _b(b['isWinning'] ?? b['isTopBid']),
              });
            }
          }
        }
      }
    }

    // Client's payment records (from LocalListingsStore payments and SubscriptionStore)
    final allPayments = [
      ...listingsStore.pendingPayments,
      ...listingsStore.rejectedPayments,
    ];
    final clientPayments = allPayments.where((p) {
      final phone = ProfileStorageHelper.normalizePhone(_s(p['phone']));
      return phone == clientPhone;
    }).toList();

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detail Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: _navy),
                  onPressed: () => setState(() => _selectedClientPhone = null),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _toTitleCase(client.name),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _navy,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${client.phone}${client.city.isNotEmpty ? ' • ${client.city}' : ''}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                // Block / Unblock action button
                ElevatedButton.icon(
                  icon: Icon(
                    client.isBlocked ? Icons.check_circle_outline : Icons.block,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    client.isBlocked ? 'Unblock Client' : 'Block Client',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: client.isBlocked ? Colors.green.shade700 : Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onPressed: () => _toggleBlockClient(client),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),

          // Scrollable Sections
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. Profile Info Card
                _buildDetailCard(
                  title: 'Profile Information',
                  icon: Icons.person_outline,
                  child: Column(
                    children: [
                      _buildDetailRow('Full Name', client.name),
                      _buildDetailRow('Phone Number', client.phone),
                      _buildDetailRow('Email Address', client.email.isNotEmpty ? client.email : '-'),
                      _buildDetailRow('City', client.city.isNotEmpty ? client.city : '-'),
                      if (client.dob.isNotEmpty) _buildDetailRow('Date of Birth', client.dob),
                      _buildDetailRow('Joined Date', client.joinedDateStr),
                      _buildDetailRow(
                        'Account Status',
                        client.isBlocked ? 'Blocked (Login/Posting Restricted)' : 'Active',
                        color: client.isBlocked ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 2. KYC Document Card
                _buildDetailCard(
                  title: 'KYC Verification Document',
                  icon: Icons.verified_user_outlined,
                  child: FutureBuilder<Uint8List?>(
                    future: BlobStorage().get('${client.phone}/kyc'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final bytes = snapshot.data;
                      if (bytes != null && bytes.isNotEmpty) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'KYC Document Uploaded',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.fullscreen, size: 16),
                                  label: const Text('View Full Document'),
                                  onPressed: () => _showDocumentDialog(bytes, client.name),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                color: Colors.grey.shade100,
                                child: Image.memory(
                                  bytes,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.insert_drive_file, size: 48, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No KYC document uploaded for this client.',
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Subscription Status Card
                _buildDetailCard(
                  title: 'Subscription Status',
                  icon: Icons.subscriptions_outlined,
                  child: Column(
                    children: [
                      _buildDetailRow(
                        'Current Plan',
                        client.hasActivePlan ? client.planName : 'No active plan',
                        color: client.hasActivePlan ? Colors.green.shade800 : Colors.grey.shade700,
                      ),
                      if (client.hasActivePlan)
                        _buildDetailRow('Expiry Date', client.planExpiry),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 4. Client's Listings Card
                _buildDetailCard(
                  title: 'Listings (${clientListings.length})',
                  icon: Icons.directions_car_outlined,
                  child: clientListings.isEmpty
                      ? Text('No vehicle listings posted by this client.', style: TextStyle(color: Colors.grey.shade600))
                      : Column(
                          children: clientListings.map((l) {
                            final title = _s(l['title'] ?? '${_s(l['year'])} ${_s(l['make'])} ${_s(l['model'])}');
                            final price = _i(l['price'] ?? l['reservePrice']);
                            final status = _s(l['status'], 'Pending');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: _navy, fontSize: 14)),
                              subtitle: Text('₹${NumberFormat('#,##,###').format(price)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: status.toLowerCase() == 'accepted' || status.toLowerCase() == 'live' ? Colors.green.shade50 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _toTitleCase(status),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: status.toLowerCase() == 'accepted' || status.toLowerCase() == 'live' ? Colors.green.shade800 : _navy,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),

                // 5. Client's Bids Card
                _buildDetailCard(
                  title: 'Bids Placed (${clientBids.length})',
                  icon: Icons.gavel_outlined,
                  child: clientBids.isEmpty
                      ? Text('No bids placed by this client.', style: TextStyle(color: Colors.grey.shade600))
                      : Column(
                          children: clientBids.map((b) {
                            final vehicleTitle = _s(b['vehicleTitle']);
                            final amount = _i(b['amount']);
                            final isWinning = _b(b['isWinning']);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(vehicleTitle, style: TextStyle(fontWeight: FontWeight.w600, color: _navy, fontSize: 14)),
                              subtitle: Text('Bid: ₹${NumberFormat('#,##,###').format(amount)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isWinning ? Colors.green.shade50 : Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isWinning ? 'Winning' : 'Placed',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isWinning ? Colors.green.shade800 : Colors.blue.shade800,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),

                // 6. Payment Records Card
                _buildDetailCard(
                  title: 'Payment Records (${clientPayments.length})',
                  icon: Icons.account_balance_wallet_outlined,
                  child: clientPayments.isEmpty
                      ? Text('No payment records found.', style: TextStyle(color: Colors.grey.shade600))
                      : Column(
                          children: clientPayments.map((p) {
                            final ref = _s(p['paymentRef'] ?? p['utrNumber'] ?? p['id']);
                            final amt = _i(p['amount'] ?? p['planAmount']);
                            final status = _s(p['status'], 'Pending');
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('Ref: $ref', style: TextStyle(fontWeight: FontWeight.w600, color: _navy, fontSize: 13)),
                              subtitle: Text('Amount: ₹${NumberFormat('#,##,###').format(amt)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              trailing: Text(
                                _toTitleCase(status),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _navy),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _navy),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _navy),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color ?? _navy,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentDialog(Uint8List bytes, String clientName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KYC Document: $clientName',
                    style: TextStyle(fontWeight: FontWeight.bold, color: _navy, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: InteractiveViewer(
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Failed to load document image'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TAB 2: ACTIVE LOGINS
  Widget _buildActiveLoginsTab() {
    final store = AdminClientsStore();

    // CLIENT sessions ONLY (never admin)
    final clientLogins = store.activeLogins.where((l) {
      final p = _s(l['phone']);
      return _isValidClientPhone(p);
    }).where((l) {
      if (_searchQuery.isEmpty) return true;
      final name = _s(l['name']).toLowerCase();
      final phone = _s(l['phone']);
      return name.contains(_searchQuery) || phone.contains(_searchQuery);
    }).toList();

    if (clientLogins.isEmpty) {
      return _buildEmptyState(
        icon: Icons.devices,
        title: 'No active client sessions',
        subtitle: _searchQuery.isNotEmpty ? 'Try adjusting your search query' : 'Active client sessions will appear here in real-time.',
      );
    }

    return ListView.separated(
      itemCount: clientLogins.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = clientLogins[index];
        final name = _toTitleCase(_s(session['name'], 'Client'));
        final phone = _s(session['phone']);
        final device = _s(session['device'], 'Web');

        // Parse login time
        final timeRaw = _s(session['loginTime'] ?? session['time']);
        DateTime? loginTime = DateTime.tryParse(timeRaw);
        final formattedTime = loginTime != null
            ? DateFormat('HH:mm, dd MMM yyyy').format(loginTime)
            : timeRaw;

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.language, size: 12, color: Colors.blue.shade700),
                              const SizedBox(width: 4),
                              Text(
                                device,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$phone • Login: $formattedTime',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onPressed: () => _handleForceLogout(session),
                child: const Text('Force Logout', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
