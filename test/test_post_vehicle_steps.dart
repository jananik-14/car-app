import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wheels2drive/screens/post_vehicle_form_screen.dart';
import 'package:wheels2drive/services/subscription_store.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'sub_status_9876543210': 'active',
      'sub_end_9876543210': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
    });
    await SubscriptionStore().init('9876543210');
  });

  for (final width in [320.0, 360.0, 393.0]) {
    for (int step = 1; step <= 5; step++) {
      testWidgets('PostVehicleFormScreen Step $step at ${width.toInt()}px', (WidgetTester tester) async {
        tester.view.physicalSize = Size(width, 850);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(const MaterialApp(home: Scaffold(body: PostVehicleFormScreen())));
        await tester.pumpAndSettle();

        final state = tester.state(find.byType(PostVehicleFormScreen)) as dynamic;
        state.setState(() {
          state.setValue('_currentStep', step);
        });
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }
}
