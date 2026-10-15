import 'package:flutter_test/flutter_test.dart';
import 'package:wheels2drive/config/app_config.dart';
import 'package:wheels2drive/router/app_router.dart';
import 'package:wheels2drive/services/client_notification_store.dart';

void main() {
  group('Notification route mapping tests', () {
    test('ClientNotificationStore maps notification types to existing routes correctly', () {
      // Bids tab + won filter
      expect(ClientNotificationStore.routeForType('bid_won'), '/my_activity?tab=bids&filter=won');
      expect(ClientNotificationStore.routeForType('token_confirmed'), '/my_activity?tab=bids&filter=won');
      expect(ClientNotificationStore.routeForType('balance_paid'), '/my_activity?tab=bids&filter=won');
      expect(ClientNotificationStore.routeForType('payment_rejected'), '/my_activity?tab=bids&filter=won');
      expect(ClientNotificationStore.routeForType('payment'), '/my_activity?tab=bids&filter=won');

      // Listings tab
      expect(ClientNotificationStore.routeForType('listing_live'), '/my_activity?tab=listings');
      expect(ClientNotificationStore.routeForType('listing_approved'), '/my_activity?tab=listings');
      expect(ClientNotificationStore.routeForType('listing_rejected'), '/my_activity?tab=listings');
      expect(ClientNotificationStore.routeForType('sold'), '/my_activity?tab=listings');
      expect(ClientNotificationStore.routeForType('ended'), '/my_activity?tab=listings');

      // Outbid / bid lost -> my_activity bids
      expect(ClientNotificationStore.routeForType('outbid'), '/my_activity?tab=bids');
      expect(ClientNotificationStore.routeForType('bid_lost'), '/my_activity?tab=bids');

      // Subscription route
      expect(ClientNotificationStore.routeForType('subscription_active'), '/subscription');

      // Unknown type -> null (do nothing)
      expect(ClientNotificationStore.routeForType('unknown_foo'), isNull);
      expect(ClientNotificationStore.routeForType('random_status'), isNull);
      expect(ClientNotificationStore.routeForType(''), isNull);
    });

    test('inferType correctly handles missing or empty types from notification title', () {
      expect(ClientNotificationStore.inferType('', 'Your listing is now live'), 'listing_live');
      expect(ClientNotificationStore.inferType('', 'Listing approved by admin'), 'listing_live');
      expect(ClientNotificationStore.inferType('', 'Your listing was rejected'), 'listing_rejected');
      expect(ClientNotificationStore.inferType('', 'You won the auction!'), 'bid_won');
      expect(ClientNotificationStore.inferType('', 'Your token payment is confirmed'), 'token_confirmed');
      expect(ClientNotificationStore.inferType('', 'Vehicle sold for 500000'), 'sold');
      expect(ClientNotificationStore.inferType('', 'Your subscription is active'), 'subscription_active');
    });

    test('All target routes exist in AppRouter', () {
      final routes = AppRouter.router.configuration.routes
          .map((r) => r.toString())
          .toList();

      final paths = AppRouter.router.configuration.routes
          .whereType<dynamic>()
          .map((r) => (r.path as String))
          .toList();

      expect(paths.contains('/my_activity'), isTrue);
      expect(paths.contains('/subscription'), isTrue);
      expect(paths.contains('/payment'), isTrue);
    });

    test('Bank config constants exist in app_config.dart', () {
      expect(kBankName.isNotEmpty, isTrue);
      expect(kAccountName.isNotEmpty, isTrue);
      expect(kAccountNumber.isNotEmpty, isTrue);
      expect(kIfsc.isNotEmpty, isTrue);
    });
  });
}
