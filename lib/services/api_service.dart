import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.wheels2drive.placeholder/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    ),
  );

  // 1. Auth: OTP Login
  Future<bool> sendOtp(String mobileNumber) async {
    // Placeholder implementation
    await Future.delayed(const Duration(seconds: 1));
    return true; // Success
  }

  Future<String> verifyOtp(String mobileNumber, String otp) async {
    // Placeholder implementation
    await Future.delayed(const Duration(seconds: 1));
    return 'dummy_token_123'; 
  }

  // 2. Vehicle Listing
  Future<List<dynamic>> getVehicles() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {'id': '1', 'make': 'Honda', 'model': 'Civic', 'year': 2020, 'basePrice': 15000},
      {'id': '2', 'make': 'Toyota', 'model': 'Camry', 'year': 2021, 'basePrice': 18000},
    ];
  }

  // 3. Vehicle Detail
  Future<Map<String, dynamic>> getVehicleDetails(String id) async {
    await Future.delayed(const Duration(seconds: 1));
    return {'id': id, 'make': 'Honda', 'model': 'Civic', 'year': 2020, 'basePrice': 15000, 'currentBid': 16000};
  }

  // 4. Bidding
  Future<bool> placeBid(String vehicleId, double amount) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // 5. Post Vehicle
  Future<bool> postVehicle(Map<String, dynamic> vehicleData) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // 6. Admin Approval
  Future<List<dynamic>> getPendingVehicles() async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  Future<bool> approveVehicle(String vehicleId) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }

  // 7. Notifications
  Future<List<dynamic>> getNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  // 8. Subscriptions
  Future<bool> subscribeToPlan(String planId) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
