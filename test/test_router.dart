import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels2drive/router/app_router.dart';
import 'package:wheels2drive/services/auth_service.dart';

void main() {
  testWidgets('Simulate router flow', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await AuthService().init();
    
    print('--- Flow 1: New client ---');
    // We expect redirect for /login -> null (since not logged in)
    // Then OTP
    await AuthService().login('9876543210');
    // Then navigate to Profile creation
    // Then Terms
    print('AUTH DEBUG: terms accepted, loggedIn=${AuthService().isLoggedIn}');
    // Then Browse
  });
}
