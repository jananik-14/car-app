import 'package:go_router/go_router.dart';
import '../screens/login_screen.dart';
import '../screens/profile_creation_screen.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/terms_conditions_screen.dart';
import '../screens/browse_vehicles_screen.dart';
import '../screens/watchlist_screen.dart';
import '../screens/vehicle_detail_screen.dart';
import '../screens/inspection_report_screen.dart';
import '../screens/post_vehicle_form_screen.dart';
import '../screens/confirmation_screen.dart';
import '../screens/admin_approval_center_screen.dart';
import '../screens/admin_clients_details_screen.dart';
import '../screens/admin_post_management_screen.dart';
import '../screens/admin_bidding_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/subscription_plans_screen.dart';
import '../screens/email_screen.dart';
import '../screens/debug_menu_screen.dart';
import '../screens/my_activity_screen.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/help_support_screen.dart';

import '../services/auth_service.dart';

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
        builder: (context, state) {
          final phone = state.extra as String? ?? '';
          return OtpVerificationScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/profile_creation',
        builder: (context, state) => const ProfileCreationScreen(),
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
        path: '/watchlist',
        builder: (context, state) => const WatchlistScreen(),
      ),
      GoRoute(
        path: '/vehicle_detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return VehicleDetailScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/inspection/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return InspectionReportScreen(vehicleId: id);
        },
      ),
      GoRoute(
        path: '/post_vehicle',
        builder: (context, state) => const PostVehicleFormScreen(),
      ),
      GoRoute(
        path: '/confirmation/:type',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? 'listing';
          return ConfirmationScreen(type: type);
        },
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminClientsDetailsScreen(),
      ),
      GoRoute(
        path: '/admin-approval',
        builder: (context, state) => const AdminApprovalCenterScreen(),
      ),
      GoRoute(
        path: '/admin/post-management',
        builder: (context, state) => const AdminPostManagementScreen(),
      ),
      GoRoute(
        path: '/admin/bidding',
        builder: (context, state) => const AdminBiddingScreen(),
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
      GoRoute(
        path: '/my_activity',
        builder: (context, state) => const MyActivityScreen(),
      ),
      GoRoute(
        path: '/profile_edit',
        builder: (context, state) => const ProfileEditScreen(),
      ),
      GoRoute(
        path: '/help_support',
        builder: (context, state) => const HelpSupportScreen(),
      ),
    ],
  );
}
