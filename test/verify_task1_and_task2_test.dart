import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels2drive/screens/post_vehicle_form_screen.dart';
import 'package:wheels2drive/screens/admin_approval_center_screen.dart';
import 'package:wheels2drive/utils/local_listings_store.dart';
import 'package:wheels2drive/utils/blob_storage.dart';
import 'package:wheels2drive/services/subscription_store.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'isLoggedIn': true,
      'user_phone': '9876543210',
      'user_role': 'seller',
      'user_name': 'Ramesh Kumar',
      'user_city': 'Chennai',
      'sub_status_9876543210': 'active',
      'sub_end_9876543210': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });
    await SubscriptionStore().init('9876543210');

    final store = LocalListingsStore();
    store.pendingListings.clear();
    store.acceptedListings.clear();
    store.rejectedListings.clear();

    // Create a mock inspection PDF (starts with %PDF)
    final mockPdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D, 0x31, 0x2E, 0x34]);
    await BlobStorage().put('9876543210/veh_1/inspection', mockPdfBytes);
    await BlobStorage().put('9876543210/veh_1/photo_0', Uint8List(0));
    await BlobStorage().put('9876543211/veh_2/photo_0', Uint8List(0));
    await BlobStorage().put('9876543212/veh_3/photo_0', Uint8List(0));

    store.pendingListings.add({
      'id': 'veh_1',
      'title': '2021 Hyundai Creta SX Opt',
      'year': 2021,
      'brand': 'Hyundai',
      'model': 'Creta',
      'variant': 'SX Opt',
      'registrationNumber': 'TN09BV1234',
      'kilometersDriven': '25000',
      'fuelType': 'Petrol',
      'transmission': 'Manual',
      'owner': '1st Owner',
      'insuranceType': 'Comprehensive',
      'insuranceExpiryDate': '2027-05-15T00:00:00.000',
      'price': 1350000,
      'durationHours': 48,
      'sellerName': 'Ramesh Kumar',
      'sellerPhone': '9876543210',
      'city': 'Chennai',
      'state': 'Tamil Nadu',
      'createdAt': '2026-10-15T10:30:00.000',
      'status': 'pending',
      'inspectionReportBytes': mockPdfBytes,
      'inspectionReportName': 'creta_inspection.pdf',
    });

    store.acceptedListings.add({
      'id': 'veh_2',
      'title': '2020 Honda City ZX',
      'year': 2020,
      'brand': 'Honda',
      'model': 'City',
      'variant': 'ZX',
      'registrationNumber': 'KA01MJ5678',
      'kilometersDriven': '32000',
      'fuelType': 'Petrol',
      'transmission': 'Automatic',
      'owner': '1st Owner',
      'price': 1100000,
      'durationHours': 24,
      'sellerName': 'Suresh Reddy',
      'sellerPhone': '9876543211',
      'city': 'Bengaluru',
      'state': 'Karnataka',
      'createdAt': '2026-10-14T09:15:00.000',
      'status': 'live',
      'publishedAt': '2026-10-16T12:00:00.000',
      'endTime': '2026-10-18T12:00:00.000',
    });

    store.rejectedListings.add({
      'id': 'veh_3',
      'title': '2018 Maruti Swift VXI',
      'year': 2018,
      'brand': 'Maruti',
      'model': 'Swift',
      'variant': 'VXI',
      'registrationNumber': 'DL04AB9999',
      'kilometersDriven': '65000',
      'fuelType': 'Diesel',
      'transmission': 'Manual',
      'owner': '2nd Owner',
      'price': 520000,
      'durationHours': 48,
      'sellerName': 'Amit Sharma',
      'sellerPhone': '9876543212',
      'city': 'Delhi',
      'state': 'Delhi',
      'createdAt': '2026-10-13T14:20:00.000',
      'status': 'rejected',
      'reason': 'Clear engine bay photos were not provided by the seller',
    });
  });

  group('TASK 1 - Post Vehicle Form Screen Overflows', () {
    testWidgets('Step 5 renders with no overflow at 393px width', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PostVehicleFormScreen(initialStep: 5)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Auction Duration'), findsOneWidget);
      expect(find.text('Live countdown starts post-approval'), findsOneWidget);
      expect(find.text('Recommended'), findsOneWidget);
      expect(find.text('48 Hours'), findsOneWidget);
    });

    testWidgets('Step 5 renders with no overflow at 320px width', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: PostVehicleFormScreen(initialStep: 5)),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Auction Duration'), findsOneWidget);
      expect(find.text('Live countdown starts post-approval'), findsOneWidget);
    });

    testWidgets('Steps 1 through 4 render at 320px, 360px without overflow', (tester) async {
      for (final step in [1, 2, 3, 4]) {
        for (final width in [320.0, 360.0]) {
          tester.view.physicalSize = Size(width, 700);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: PostVehicleFormScreen(initialStep: step)),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull, reason: 'Step $step at width $width had an error');
        }
      }
      tester.view.resetPhysicalSize();
    });
  });

  group('TASK 2 - Admin Approval Center Vehicle Posts Redesign', () {
    testWidgets('Pending card shows real data and no dummy fields', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminApprovalCenterScreen(
            initialCategory: MainCategory.vehiclePosts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Verify real data is present
      expect(find.text('2021 Hyundai Creta SX Opt'), findsWidgets);
      expect(find.text('TN09BV1234'), findsOneWidget);
      expect(find.text('25000 km'), findsOneWidget);
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text('1st Owner'), findsOneWidget);
      expect(find.textContaining('Chennai'), findsOneWidget);
      expect(find.textContaining('Ramesh Kumar'), findsOneWidget);

      // Verify dummy fields are NOT present
      expect(find.text('RC STATUS'), findsNothing);
      expect(find.text('LISTING TYPE'), findsNothing);
      expect(find.text('4.5 / 5.0'), findsNothing);
      expect(find.text('Submitted Just now'), findsNothing);
      expect(find.text('Just now'), findsNothing);
      expect(find.text('New'), findsNothing);

      // Verify buttons
      expect(find.textContaining('View Documents'), findsOneWidget);
      expect(find.text('✕ Reject'), findsOneWidget);
      expect(find.text('✓ Publish'), findsOneWidget);
    });

    testWidgets('Accepted tab shows live status and end time', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminApprovalCenterScreen(
            initialCategory: MainCategory.vehiclePosts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Accepted tab
      await tester.tap(find.text('Accepted'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2020 Honda City ZX'), findsWidgets);
      expect(find.text('● LIVE'), findsOneWidget);
      expect(find.text('End auction now (test)'), findsOneWidget);
    });

    testWidgets('Rejected tab shows rejection reason', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminApprovalCenterScreen(
            initialCategory: MainCategory.vehiclePosts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Rejected tab
      await tester.tap(find.text('Rejected'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('2018 Maruti Swift VXI'), findsWidgets);
      expect(find.textContaining('Clear engine bay photos were not provided'), findsOneWidget);
    });

    testWidgets('View Documents dialog opens and shows two clear buttons', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminApprovalCenterScreen(
            initialCategory: MainCategory.vehiclePosts,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap View Documents
      await tester.tap(find.textContaining('View Documents'));
      await tester.pumpAndSettle();

      expect(find.text('Listing Documents'), findsOneWidget);
      expect(find.text('Listing Details (5-step PDF)'), findsOneWidget);
      expect(find.text('Inspection Report (PDF)'), findsOneWidget);
    });

    testWidgets('No overflow across range 320px to 1920px', (tester) async {
      for (final width in [320.0, 360.0, 393.0, 768.0, 1280.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          const MaterialApp(
            home: AdminApprovalCenterScreen(
              initialCategory: MainCategory.vehiclePosts,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull, reason: 'Overflow occurred at width $width');
      }
      tester.view.resetPhysicalSize();
    });
  });
}
