import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels2drive/screens/login_screen.dart';
import 'package:wheels2drive/screens/admin_clients_details_screen.dart';
import 'package:wheels2drive/screens/admin_approval_center_screen.dart';
import 'package:wheels2drive/utils/local_listings_store.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'registered_client_phones': ['9876543210', '9876543211'],
      'user_name_9876543210': 'Alice Smith',
      'user_email_9876543210': 'alice@example.com',
      'user_city_9876543210': 'Bengaluru',
      'user_name_9876543211': 'Bob Jones',
      'user_email_9876543211': 'bob@example.com',
      'user_city_9876543211': 'Mumbai',
    });
    final store = LocalListingsStore();
    store.pendingSubscriptions.clear();
    store.acceptedSubscriptions.clear();
    store.rejectedSubscriptions.clear();
    store.addPendingSubscription({
      'id': 'sub_pending_1',
      'businessName': 'Super Auto Dealer',
      'tier': '1 Year',
      'planId': 'yearly',
      'price': 4999,
      'payRef': 'UTR123456789012345678',
      'phone': '9876543210',
      'city': 'Bengaluru',
      'submittedAt': DateTime.now().toIso8601String(),
    });
    store.acceptSubscription({
      'id': 'sub_accepted_1',
      'businessName': 'Premier Motors',
      'tier': '1 Year',
      'planId': 'yearly',
      'price': 4999,
      'payRef': 'UTR987654321098765432',
      'phone': '9876543211',
      'city': 'Mumbai',
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
    });
    store.rejectSubscription({
      'id': 'sub_rejected_1',
      'businessName': 'Reject Motors',
      'tier': '3 Months',
      'planId': 'quarterly',
      'price': 1999,
      'payRef': 'UTR000000000000000000',
      'phone': '9876543210',
      'city': 'Delhi',
      'reason': 'Payment receipt could not be verified by admin bank records',
    });
  });

  testWidgets('Fix 1: LoginScreen renders without overflow at 320px width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Instant Access'), findsOneWidget);
    expect(find.text('Zero Spam'), findsNothing);
    expect(find.text('Verified Auctions'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Fix 2: AdminClientsDetailsScreen has no Client History tab', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: AdminClientsDetailsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('1. Total Clients'), findsOneWidget);
    expect(find.text('2. Active Logins'), findsOneWidget);
    expect(find.text('3. Client History'), findsNothing);
    expect(find.textContaining('Client History'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 360.0, 393.0, 768.0, 1280.0]) {
    testWidgets('Fix 3: AdminApprovalCenterScreen Subscriptions renders without overflow at ${width.toInt()}px', (WidgetTester tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AdminApprovalCenterScreen(initialCategory: MainCategory.subscriptions),
        ),
      ));
      await tester.pumpAndSettle();

      // Check plan label is not duplicated
      expect(find.textContaining('1 Year (1 Year'), findsNothing);
      expect(find.text('1 Year (365 days)'), findsWidgets);

      // Verify no overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Switch to Accepted tab
      final acceptedTab = find.text('Accepted');
      if (acceptedTab.evaluate().isNotEmpty) {
        await tester.ensureVisible(acceptedTab);
        await tester.tap(acceptedTab);
        await tester.pumpAndSettle();
        expect(find.textContaining('1 Year (1 Year'), findsNothing);
        expect(tester.takeException(), isNull);
      }

      // Switch to Rejected tab
      final rejectedTab = find.text('Rejected');
      if (rejectedTab.evaluate().isNotEmpty) {
        await tester.ensureVisible(rejectedTab);
        await tester.tap(rejectedTab);
        await tester.pumpAndSettle();
        expect(find.textContaining('3 Months (3 Months'), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  }
}
