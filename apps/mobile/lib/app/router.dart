import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/providers/app_providers.dart';
import '../core/utils/role_nav.dart';
import '../features/admin/admin_panel_screen.dart';
import '../features/auth/auth_screen.dart';
import '../features/auth/blocked_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/profile_setup_screen.dart';
import '../features/catalog/merchant_catalog_screen.dart';
import '../features/catalog/menu_customizer_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/driver/driver_active_job_screen.dart';
import '../features/driver/driver_radar_screen.dart';
import '../features/driver/driver_registration_screen.dart';
import '../features/driver/driver_wallet_screen.dart';
import '../features/home/consumer_home_screen.dart';
import '../features/landmarks/landmark_picker_screen.dart';
import '../features/merchant/menu_management_screen.dart';
import '../features/merchant/merchant_dashboard_screen.dart';
import '../features/merchant/merchant_orders_screen.dart';
import '../features/merchant/store_settings_screen.dart';
import '../features/orders/order_history_screen.dart';
import '../features/orders/order_receipt_screen.dart';
import '../features/orders/rating_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/support/dispute_center_screen.dart';
import '../features/tracking/tracking_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (_, _) => notifyListeners());
  }
}

/// Router dengan guard peran (docs/Rules.md §2, PRD M02).
///
/// - Belum login → `/auth`
/// - NIM/WhatsApp belum lengkap → `/auth/profile`
/// - `/driver/*` wajib `roles` berisi `driver` dan status `approved`
/// - `/merchant/*` wajib `merchant`
/// - `/admin/*` wajib `admin`
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: refresh,
    redirect: (context, state) {
      final user = ref.read(authStateProvider).value;
      final location = state.matchedLocation;

      const publicRoutes = {'/onboarding', '/auth', '/auth/profile'};

      if (user == null) {
        return publicRoutes.contains(location) ? null : '/auth';
      }

      if (user.suspended) {
        return location == '/blocked' || location == '/support'
            ? null
            : '/blocked';
      }

      if (!user.profileComplete) {
        return location == '/auth/profile' ? null : '/auth/profile';
      }

      if (location == '/onboarding' ||
          location == '/auth' ||
          location == '/auth/profile') {
        return homePathForRole(user.role);
      }

      if (location.startsWith('/driver/') && !user.isDriverApproved) {
        return user.isDriver ? '/register-driver' : '/home';
      }
      if (location.startsWith('/merchant') && !user.isMerchant) {
        return '/home';
      }
      if (location.startsWith('/admin') && !user.isAdmin) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (context, state) => '/onboarding'),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/auth/profile',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) => const BlockedScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const ConsumerHomeScreen(),
      ),
      GoRoute(
        path: '/landmarks',
        builder: (context, state) => LandmarkPickerScreen(
          service: state.uri.queryParameters['service'] ?? 'numpang',
        ),
      ),
      GoRoute(
        path: '/catalog',
        builder: (context, state) => const MerchantCatalogScreen(),
      ),
      GoRoute(
        path: '/menu/:merchantId/:productId',
        builder: (context, state) => MenuCustomizerScreen(
          merchantId: state.pathParameters['merchantId']!,
          productId: state.pathParameters['productId']!,
        ),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => CheckoutScreen(
          extra: state.extra is Map<String, dynamic>
              ? state.extra as Map<String, dynamic>
              : null,
        ),
      ),
      GoRoute(
        path: '/tracking/:orderId',
        builder: (context, state) =>
            TrackingScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/chat/:orderId',
        builder: (context, state) =>
            ChatScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (context, state) =>
            OrderReceiptScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/orders/:orderId/rating',
        builder: (context, state) =>
            RatingScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/register-driver',
        builder: (context, state) => const DriverRegistrationScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const DisputeCenterScreen(),
      ),
      GoRoute(
        path: '/driver/radar',
        builder: (context, state) => const DriverRadarScreen(),
      ),
      GoRoute(
        path: '/driver/job/:orderId',
        builder: (context, state) =>
            DriverActiveJobScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/driver/wallet',
        builder: (context, state) => const DriverWalletScreen(),
      ),
      GoRoute(
        path: '/merchant',
        builder: (context, state) => const MerchantDashboardScreen(),
      ),
      GoRoute(
        path: '/merchant/orders',
        builder: (context, state) => const MerchantOrdersScreen(),
      ),
      GoRoute(
        path: '/merchant/menu',
        builder: (context, state) => const MenuManagementScreen(),
      ),
      GoRoute(
        path: '/merchant/settings',
        builder: (context, state) => const StoreSettingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminPanelScreen(),
      ),
    ],
  );
});
