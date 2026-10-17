import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels2drive/screens/profile_screen.dart';
import 'package:wheels2drive/services/auth_service.dart';
import 'package:wheels2drive/widgets/shared_bottom_nav.dart';

void main() {
  testWidgets('ProfileScreen renders all required fields and menu items at 393px mobile width', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'current_logged_in_phone': '9876543210',
      'user_name_9876543210': 'Rajesh Kumar',
      'user_email_9876543210': 'rajesh@example.com',
      'user_city_9876543210': 'Bengaluru',
      'kyc_uploaded_9876543210': true,
    });

    await AuthService().init();
    await AuthService().login('9876543210');

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify User Details: Avatar, Name, Phone, Email, City, KYC status
    expect(find.text('Rajesh Kumar'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    expect(find.text('rajesh@example.com'), findsOneWidget);
    expect(find.text('Bengaluru'), findsOneWidget);
    expect(find.text('KYC Verified'), findsOneWidget);
    expect(find.text('R'), findsOneWidget); // Avatar initial

    // Verify Menu Items:
    // My Activity, Edit Profile, Subscription, Help & Support, Terms & Privacy, Logout
    expect(find.text('My Activity'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Terms & Privacy'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);

    // Verify Bottom Navigation keeps Profile selected (index 4)
    final bottomNavFinder = find.byType(BottomNavigationBar);
    expect(bottomNavFinder, findsOneWidget);
    final BottomNavigationBar bottomNav = tester.widget(bottomNavFinder);
    expect(bottomNav.currentIndex, 4);
  });

  testWidgets('ProfileScreen renders correctly when KYC is pending', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'current_logged_in_phone': '9876543210',
      'user_name_9876543210': 'Amit Patel',
      'user_email_9876543210': 'amit@example.com',
      'user_city_9876543210': 'Ahmedabad',
      'kyc_uploaded_9876543210': false,
    });

    await AuthService().init();
    await AuthService().login('9876543210');

    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: ProfileScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Amit Patel'), findsOneWidget);
    expect(find.text('KYC Pending'), findsOneWidget);
  });
}
