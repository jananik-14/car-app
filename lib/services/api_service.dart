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
  static const String _subscriptionBaseUrl = 'http://localhost:5003/api/subscription';
  static const String _notificationBaseUrl = 'http://localhost:5004/api/notification';
  static const String _watchlistBaseUrl = 'http://localhost:5005/api/watchlist';

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

  // 7. Notifications
  Future<List<dynamic>> getNotifications() async {
    try {
      if (AuthService.phoneNumber == null) return [];
      final response = await _dio.get('$_notificationBaseUrl/${AuthService.phoneNumber}');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  Future<bool> markNotificationAsRead(String id) async {
    try {
      final response = await _dio.patch('$_notificationBaseUrl/$id/read');
      return response.data['success'] == true;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }

  // 8. Subscriptions
  Future<bool> subscribeToPlan(String planId) async {
    try {
      final response = await _dio.post('$_subscriptionBaseUrl/subscribe', data: {
        'phoneNumber': AuthService.phoneNumber ?? 'Unknown',
        'planId': planId,
        'durationInDays': 30, // Default duration
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error subscribing to plan: $e');
      return false;
    }
  }
  
  Future<Map<String, dynamic>?> getSubscriptionStatus() async {
    try {
      if (AuthService.phoneNumber == null) return null;
      final response = await _dio.get('$_subscriptionBaseUrl/status/${AuthService.phoneNumber}');
      if (response.data['success'] == true) {
        return response.data['data']; // Will be null if no active sub, which is fine
      }
      return null;
    } catch (e) {
      print('Error fetching subscription status: $e');
      return null;
    }
  }

  // 9. Watchlist
  Future<List<dynamic>> getWatchlist() async {
    try {
      if (AuthService.phoneNumber == null) return [];
      final response = await _dio.get('$_watchlistBaseUrl/${AuthService.phoneNumber}');
      if (response.data['success'] == true) {
        return response.data['data'];
      }
      return [];
    } catch (e) {
      print('Error fetching watchlist: $e');
      return [];
    }
  }

  Future<bool> addToWatchlist(String vehicleId) async {
    try {
      final response = await _dio.post('$_watchlistBaseUrl/add', data: {
        'phoneNumber': AuthService.phoneNumber ?? 'Unknown',
        'vehicleId': vehicleId,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error adding to watchlist: $e');
      return false;
    }
  }

  Future<bool> removeFromWatchlist(String vehicleId) async {
    try {
      final response = await _dio.delete('$_watchlistBaseUrl/remove', data: {
        'phoneNumber': AuthService.phoneNumber ?? 'Unknown',
        'vehicleId': vehicleId,
      });
      return response.data['success'] == true;
    } catch (e) {
      print('Error removing from watchlist: $e');
      return false;
    }
  }
}
