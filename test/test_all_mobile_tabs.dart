import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels2drive/screens/browse_vehicles_screen.dart';
import 'package:wheels2drive/screens/watchlist_screen.dart';
import 'package:wheels2drive/screens/post_vehicle_form_screen.dart';
import 'package:wheels2drive/screens/notifications_screen.dart';
import 'package:wheels2drive/screens/profile_screen.dart';
import 'package:wheels2drive/services/auth_service.dart';
import 'package:wheels2drive/services/subscription_store.dart';
import 'package:wheels2drive/utils/local_listings_store.dart';
import 'package:wheels2drive/utils/watchlist_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'current_logged_in_phone': '9876543210',
      'user_name_9876543210': 'Test User',
      'user_email_9876543210': 'test@example.com',
      'user_city_9876543210': 'Mumbai',
      'kyc_uploaded_9876543210': true,
      'subscription_end_9876543210': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      'subscription_plan_9876543210': 'yearly',
      'subscription_status_9876543210': 'active',
    });
    await AuthService().init();
    await AuthService().login('9876543210');
    await SubscriptionStore().init('9876543210');
  });

  testWidgets('Tab 0: Live Auctions renders with no error on mobile 393px', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: BrowseVehiclesScreen()));
    await tester.pumpAndSettle();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 0);
  });

  testWidgets('Tab 1: Watchlist renders with no error on mobile 393px', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: WatchlistScreen()));
    await tester.pumpAndSettle();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 1);
  });

  testWidgets('Tab 2: Post/Sell renders with no error on mobile 393px', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: PostVehicleFormScreen()));
    await tester.pumpAndSettle();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 2);
  });

  testWidgets('Tab 3: Alerts renders with no error on mobile 393px', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
    await tester.pumpAndSettle();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 3);
  });

  testWidgets('Tab 4: Profile renders with no error on mobile 393px', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pumpAndSettle();

    final nav = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
    expect(nav.currentIndex, 4);

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('+91 9876543210'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);
    expect(find.text('Mumbai'), findsOneWidget);
    expect(find.text('KYC Verified'), findsOneWidget);

    expect(find.text('My Activity'), findsOneWidget);
    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Terms & Privacy'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });
}
