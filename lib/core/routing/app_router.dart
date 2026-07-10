import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

// Splash and Onboarding Screens
import '../../features/auth/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';

// Real Sub-screens
import '../../features/home/category_services_screen.dart';
import '../../features/home/service_details_screen.dart';
import '../../features/home/search_screen.dart';

// Phase 5 Screens
import '../../features/address/address_management_screen.dart';
import '../../features/address/add_address_screen.dart';
import '../../features/address/location_picker_screen.dart';
import '../../features/cart/payment_selection_screen.dart';
import '../../features/cart/booking_success_screen.dart';

// Placeholder / Sub-screens (To be implemented in subsequent phases)
// We will define standard placeholder widgets for pages that aren't built yet
// to prevent compilation errors and allow navigation to work.
import '../../features/home/home_screen.dart';
import '../../features/bookings/bookings_screen.dart';
import '../../features/bookings/booking_details_screen.dart';
import '../../features/cart/cart_view.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/profile/edit_profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

class AppRouter {
  static GoRouter router(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoggingIn = state.matchedLocation == '/login';
        final isOnboarding = state.matchedLocation == '/onboarding';
        final isSplash = state.matchedLocation == '/';

        // Don't redirect during splash check
        if (isSplash && authProvider.isLoading) return null;

        if (!isAuthenticated) {
          // If not authenticated and not currently logging in or on onboarding, send to onboarding
          if (!isLoggingIn && !isOnboarding && !isSplash) {
            return '/onboarding';
          }
        } else {
          // If authenticated and trying to access onboarding, splash, or login, send to home
          if (isLoggingIn || isOnboarding || isSplash) {
            return '/home';
          }
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Stateful Shell Route for Tabbed Navigation (persists state & prevents unmounting tabs)
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return TabShell(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: HomeScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/bookings',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: BookingsScreen(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/cart',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: CartView(),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/profile',
                  pageBuilder: (context, state) => const NoTransitionPage(
                    child: ProfileScreen(),
                  ),
                ),
              ],
            ),
          ],
        ),
        // Sub-routes implementation:
        GoRoute(
          path: '/category-services',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            final id = extra['id']?.toString() ?? '';
            final category = extra['category']?.toString() ?? 'Services';
            return CategoryServicesScreen(categoryId: id, categoryName: category);
          },
        ),
        GoRoute(
          path: '/service-details',
          builder: (context, state) {
            final Map<String, dynamic> extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : {};
            final id = extra['id']?.toString() ?? '';
            return ServiceDetailsScreen(serviceId: id);
          },
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) {
            final Map<String, dynamic> extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : {};
            final query = extra['query']?.toString();
            return SearchScreen(initialQuery: query);
          },
        ),
        GoRoute(
          path: '/address-management',
          builder: (context, state) => const AddressManagementScreen(),
        ),
        GoRoute(
          path: '/add-address',
          builder: (context, state) {
            final Map<String, dynamic> extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : {};
            return AddAddressScreen(initialData: extra);
          },
        ),
        GoRoute(
          path: '/location-picker',
          builder: (context, state) => const LocationPickerScreen(),
        ),
        GoRoute(
          path: '/payment-selection',
          builder: (context, state) {
            final query = state.uri.queryParameters;
            return PaymentSelectionScreen(
              bookingDate: query['booking_date'],
              timeSlot: query['time_slot'],
              couponCode: query['coupon_code'],
              totalAmount: double.tryParse(query['total_amount'] ?? ''),
            );
          },
        ),
        GoRoute(
          path: '/booking-success',
          builder: (context, state) {
            final Map<String, dynamic> extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : {};
            return BookingSuccessScreen(
              bookingId: extra['booking_id']?.toString(),
              totalAmount: extra['total_amount']?.toString(),
              paymentMethod: extra['payment_method']?.toString(),
              bookingDate: extra['booking_date']?.toString(),
              timeSlot: extra['time_slot']?.toString(),
              serviceName: extra['service_name']?.toString(),
            );
          },
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/booking-details',
          builder: (context, state) {
            final Map<String, dynamic> extra = state.extra is Map
                ? Map<String, dynamic>.from(state.extra as Map)
                : {};
            final id = extra['id']?.toString() ?? state.uri.queryParameters['id']?.toString() ?? '';
            return BookingDetailsScreen(bookingId: id);
          },
        ),
      ],
    );
  }
}

// Scaffold Navigation Tab Shell
class TabShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const TabShell({super.key, required this.navigationShell});

  void _onItemTapped(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF004680).withValues(alpha: 0.08),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.home, color: Color(0xFF004680)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF004680)),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.shopping_cart, color: Color(0xFF004680)),
              label: 'Cart',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Color(0xFF64748B)),
              selectedIcon: Icon(Icons.person, color: Color(0xFF004680)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Temporary Placeholder Screen to prevent route failures
class PlaceholderScreen extends StatelessWidget {
  final String title;

  const PlaceholderScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title Screen\n(Under Migration)',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Color(0xFF64748B)),
        ),
      ),
    );
  }
}
