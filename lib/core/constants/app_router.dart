
import 'package:go_router/go_router.dart';
import 'package:hotel_erp/features/splash/splash_screen.dart';
import 'package:hotel_erp/features/auth/screens/login_screen.dart';
import 'package:hotel_erp/features/dashboard/screens/dashboard_screen.dart';
import 'package:hotel_erp/features/rooms/screens/rooms_screen.dart';
import 'package:hotel_erp/features/rooms/screens/room_detail_screen.dart';
import 'package:hotel_erp/features/rooms/screens/room_availability_screen.dart';
import 'package:hotel_erp/features/bookings/screens/bookings_screen.dart';
import 'package:hotel_erp/features/bookings/screens/new_booking_screen.dart';
import 'package:hotel_erp/features/bookings/screens/booking_detail_screen.dart';
import 'package:hotel_erp/features/bookings/screens/edit_booking_screen.dart';
import 'package:hotel_erp/features/bookings/screens/checkin_screen.dart';
import 'package:hotel_erp/features/bookings/screens/checkout_screen.dart';
import 'package:hotel_erp/features/guests/screens/guests_screen.dart';
import 'package:hotel_erp/features/guests/screens/guest_detail_screen.dart';
import 'package:hotel_erp/features/billing/screens/billing_screen.dart';
import 'package:hotel_erp/features/payments/screens/payments_screen.dart';
import 'package:hotel_erp/features/restaurant/screens/restaurant_screen.dart';
import 'package:hotel_erp/features/housekeeping/screens/housekeeping_screen.dart';
import 'package:hotel_erp/features/inventory/screens/inventory_screen.dart';
import 'package:hotel_erp/features/expenses/screens/expenses_screen.dart';
import 'package:hotel_erp/features/staff/screens/staff_screen.dart';
import 'package:hotel_erp/features/maintenance/screens/maintenance_screen.dart';
import 'package:hotel_erp/features/reports/screens/reports_screen.dart';
import 'package:hotel_erp/features/notifications/screens/notifications_screen.dart';
import 'package:hotel_erp/features/settings/screens/settings_screen.dart';
import 'package:hotel_erp/features/dashboard/screens/more_screen.dart';
import 'package:hotel_erp/services/auth_service.dart';
import 'package:hotel_erp/shell_screen.dart';

class AppRouter {
  final AuthService authService;

  AppRouter(this.authService);

  late final GoRouter router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) async {
      final isLoggedIn = await authService.isLoggedIn();
      final isOnLogin = state.matchedLocation == '/login';
      final isOnSplash = state.matchedLocation == '/';

      if (isOnSplash) return null;
      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/rooms',
            builder: (context, state) => const RoomsScreen(),
            routes: [
              GoRoute(
                path: 'availability',
                builder: (context, state) => const RoomAvailabilityScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    RoomDetailScreen(roomId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/bookings',
            builder: (context, state) => const BookingsScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const NewBookingScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    BookingDetailScreen(bookingId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) =>
                        EditBookingScreen(bookingId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/check-in',
            builder: (context, state) => const CheckInScreen(),
          ),
          GoRoute(
            path: '/check-out',
            builder: (context, state) => CheckOutScreen(
              bookingId: state.uri.queryParameters['bookingId'],
            ),
          ),
          GoRoute(
            path: '/guests',
            builder: (context, state) => const GuestsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) =>
                    GuestDetailScreen(guestId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/billing/:bookingId',
            builder: (context, state) =>
                BillingScreen(bookingId: state.pathParameters['bookingId']!),
          ),
          GoRoute(
            path: '/payments',
            builder: (context, state) => const PaymentsScreen(),
          ),
          GoRoute(
            path: '/restaurant',
            builder: (context, state) => const RestaurantScreen(),
          ),
          GoRoute(
            path: '/housekeeping',
            builder: (context, state) => const HousekeepingScreen(),
          ),
          GoRoute(
            path: '/inventory',
            builder: (context, state) => const InventoryScreen(),
          ),
          GoRoute(
            path: '/expenses',
            builder: (context, state) => const ExpensesScreen(),
          ),
          GoRoute(
            path: '/staff',
            builder: (context, state) => const StaffScreen(),
          ),
          GoRoute(
            path: '/maintenance',
            builder: (context, state) => const MaintenanceScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/more',
            builder: (context, state) => const MoreScreen(),
          ),
        ],
      ),
    ],
  );
}
