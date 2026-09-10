import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/terms_conditions_screen.dart';
import '../screens/browse_vehicles_screen.dart';
import '../screens/vehicle_detail_screen.dart';
import '../screens/post_vehicle_form_screen.dart';
import '../screens/confirmation_screen.dart';
import '../screens/admin_approval_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/email_screen.dart';
import '../screens/debug_menu_screen.dart';

// Dummy role for testing access control
String currentUserRole = 'admin'; // Change to 'user' to test access denied

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpVerificationScreen(),
      ),
      GoRoute(
        path: '/terms',
        builder: (context, state) => const TermsConditionsScreen(),
      ),
      GoRoute(
        path: '/browse',
        builder: (context, state) => const BrowseVehiclesScreen(),
      ),
      GoRoute(
        path: '/vehicle_detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/post_vehicle',
        builder: (context, state) => const PostVehicleFormScreen(),
      ),
      GoRoute(
        path: '/confirmation',
        builder: (context, state) => const ConfirmationScreen(),
      ),
      GoRoute(
        path: '/admin',
        redirect: (context, state) {
          if (currentUserRole != 'admin') {
            return '/notifications'; // Skip admin screen for non-admins
          }
          return null;
        },
        builder: (context, state) => const AdminApprovalScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/subscription',
        builder: (context, state) => const SubscriptionPlansScreen(),
      ),
      GoRoute(
        path: '/email/:plan',
        builder: (context, state) {
          final plan = state.pathParameters['plan'] ?? '';
          return EmailScreen(planName: plan);
        },
      ),
      GoRoute(
        path: '/debug',
        builder: (context, state) => const DebugMenuScreen(),
      ),
    ],
  );
}
