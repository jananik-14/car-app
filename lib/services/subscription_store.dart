import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/profile_storage_helper.dart';
import '../utils/temp_admin_config.dart';
import '../config/subscription_plans.dart';

// TODO: TEMPORARY local state. Backend must store subscription status/expiry and enforce it on bid and post APIs; never trust client-side checks.
class SubscriptionStore extends ChangeNotifier {
  static final SubscriptionStore _instance = SubscriptionStore._internal();
  factory SubscriptionStore() => _instance;

  SubscriptionStore._internal();

  bool _initialized = false;
  
  // Cache state for current phone
  String? _currentPhone;
  String _status = 'none'; // 'none', 'pending', 'active'
  String? _planId;
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> init(String phone) async {
    final normalized = ProfileStorageHelper.normalizePhone(phone);
    if (_initialized && _currentPhone == normalized) return;

    _currentPhone = normalized;
    final prefs = await SharedPreferences.getInstance();
    
    _status = prefs.getString('sub_status_$_currentPhone') ?? 'none';
    _planId = prefs.getString('sub_plan_$_currentPhone');
    
    final startStr = prefs.getString('sub_start_$_currentPhone');
    _startDate = startStr != null ? DateTime.parse(startStr) : null;
    
    final endStr = prefs.getString('sub_end_$_currentPhone');
    _endDate = endStr != null ? DateTime.parse(endStr) : null;

    _initialized = true;
    notifyListeners();
  }
  
  void resetSession() {
    _status = 'none';
    _planId = null;
    _startDate = null;
    _endDate = null;
    _currentPhone = null;
    _initialized = false;
    notifyListeners();
  }
  
  Future<void> reload() async {
    if (_currentPhone != null) {
      final oldPhone = _currentPhone!;
      _initialized = false;
      await init(oldPhone);
    }
  }

  bool get isActive {
    if (_currentPhone != null && TempAdminConfig.isAdminNumber(_currentPhone!)) {
      return true;
    }
    return _status == 'active' && _endDate != null && _endDate!.isAfter(DateTime.now());
  }

  bool get isPending => _status == 'pending';
  
  bool get isExpired {
    return _status == 'active' && _endDate != null && _endDate!.isBefore(DateTime.now());
  }

  String get status => _status;

  SubscriptionPlan? get activePlan {
    if (_planId == null) return null;
    return SubscriptionPlans.getPlanById(_planId!);
  }

  int get daysLeft {
    if (_endDate == null || !isActive) return 0;
    final diff = _endDate!.difference(DateTime.now());
    if (diff.isNegative) return 0;
    return diff.inHours > 0 ? (diff.inHours / 24).ceil() : 0;
  }
  
  DateTime? get endDate => _endDate;

  Future<void> submitRequest(String planId) async {
    if (_currentPhone == null) return;
    
    _status = 'pending';
    _planId = planId;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sub_status_$_currentPhone', 'pending');
    await prefs.setString('sub_plan_$_currentPhone', planId);
    
    notifyListeners();
  }

  Future<void> activate(String phone, String planId) async {
    final normalized = ProfileStorageHelper.normalizePhone(phone);
    final prefs = await SharedPreferences.getInstance();
    
    final plan = SubscriptionPlans.getPlanById(planId);
    if (plan == null) return;

    DateTime start = DateTime.now();
    DateTime end = start.add(Duration(days: plan.durationDays));

    // If already active on the same device, maybe extend?
    final currentEndStr = prefs.getString('sub_end_$normalized');
    if (currentEndStr != null) {
      final currentEnd = DateTime.parse(currentEndStr);
      final currentStatus = prefs.getString('sub_status_$normalized');
      if (currentStatus == 'active' && currentEnd.isAfter(DateTime.now())) {
        end = currentEnd.add(Duration(days: plan.durationDays));
      }
    }

    await prefs.setString('sub_status_$normalized', 'active');
    await prefs.setString('sub_plan_$normalized', planId);
    await prefs.setString('sub_start_$normalized', start.toIso8601String());
    await prefs.setString('sub_end_$normalized', end.toIso8601String());

    if (_currentPhone == normalized) {
      _status = 'active';
      _planId = planId;
      _startDate = start;
      _endDate = end;
      notifyListeners();
    }
  }

  Future<void> reject(String phone) async {
    final normalized = ProfileStorageHelper.normalizePhone(phone);
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('sub_status_$normalized', 'none');
    await prefs.remove('sub_plan_$normalized');
    await prefs.remove('sub_start_$normalized');
    await prefs.remove('sub_end_$normalized');

    if (_currentPhone == normalized) {
      _status = 'none';
      _planId = null;
      _startDate = null;
      _endDate = null;
      notifyListeners();
    }
  }
  
  // Used for testing to forcefully set endDate
  Future<void> debugSetEndDate(DateTime date) async {
     if (_currentPhone == null) return;
     _endDate = date;
     final prefs = await SharedPreferences.getInstance();
     await prefs.setString('sub_end_$_currentPhone', date.toIso8601String());
     notifyListeners();
  }
}
