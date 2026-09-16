import 'package:dio/dio.dart';
import 'auth_service.dart';

class ApiService {
  // Setup Dio with interceptor to attach JWT token
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (AuthService.token != null) {
            options.headers['Authorization'] = 'Bearer ${AuthService.token}';
          }
          return handler.next(options);
        },
      ),
    );

  // Microservice Base URLs (Use 10.0.2.2 instead of localhost if running on Android Emulator)
  static const String _authBaseUrl = 'http://localhost:5000/api/auth';
  static const String _vehicleBaseUrl = 'http://localhost:5001/api/vehicle';
  static const String _bidBaseUrl = 'http://localhost:5002/api/bid';

  // 1. Auth: OTP Login
  Future<bool> sendOtp(String mobileNumber) async {
    try {
      final response = await _dio.post('$_authBaseUrl/generate-otp', data: {
        'phoneNumber': mobileNumber,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error sending OTP: $e');
      return false;
    }
  }

  Future<String> verifyOtp(String mobileNumber, String otp) async {
    try {
      final response = await _dio.post('$_authBaseUrl/verify-otp', data: {
        'phoneNumber': mobileNumber,
        'otp': otp,
      });
      if (response.data['success'] == true) {
        String token = response.data['data']['token'];
        AuthService.token = token; // Store token in memory
        AuthService.phoneNumber = mobileNumber;
        return token;
      }
      throw Exception('OTP Verification failed');
    } catch (e) {
      print('Error verifying OTP: $e');
      throw Exception('Error verifying OTP');
    }
  }

  // 2. Vehicle Listing
  Future<List<dynamic>> getVehicles() async {
    try {
      final response = await _dio.get('$_vehicleBaseUrl/filter?status=live');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }

  // 3. Vehicle Detail
  Future<Map<String, dynamic>> getVehicleDetails(String id) async {
    try {
      final response = await _dio.get('$_vehicleBaseUrl/$id');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      throw Exception('Vehicle not found');
    } catch (e) {
      print('Error fetching vehicle details: $e');
      throw Exception('Error fetching vehicle details');
    }
  }

  // 4. Bidding
  Future<bool> placeBid(String vehicleId, double amount) async {
    try {
      final response = await _dio.post('$_bidBaseUrl/place', data: {
        'vehicleId': vehicleId,
        'bidderPhoneNumber': AuthService.phoneNumber ?? 'Unknown',
        'bidAmount': amount,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error placing bid: $e');
      return false;
    }
  }

  // 5. Post Vehicle
  Future<bool> postVehicle(Map<String, dynamic> vehicleData) async {
    try {
      vehicleData['ownerPhoneNumber'] = AuthService.phoneNumber ?? 'Unknown';
      final response = await _dio.post('$_vehicleBaseUrl/post', data: vehicleData);
      return response.data['success'] == true;
    } catch (e) {
      print('Error posting vehicle: $e');
      return false;
    }
  }

  // 6. Admin Approval
  Future<List<dynamic>> getPendingVehicles() async {
    try {
      final response = await _dio.get('$_vehicleBaseUrl/filter?status=pending');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Error fetching pending vehicles: $e');
      return [];
    }
  }

  Future<bool> approveVehicle(String vehicleId) async {
    try {
      final response = await _dio.post('$_vehicleBaseUrl/$vehicleId/approve', data: {
        'decision': 'approved'
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error approving vehicle: $e');
      return false;
    }
  }

  // 7. Notifications (Not yet implemented in backend)
  Future<List<dynamic>> getNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  // 8. Subscriptions (Not yet implemented in backend)
  Future<bool> subscribeToPlan(String planId) async {
    await Future.delayed(const Duration(seconds: 1));
    return true;
  }
}
