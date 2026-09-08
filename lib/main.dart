import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_router.dart';
import 'core/utils/web_printer.dart';
import 'services/auth_service.dart';
import 'repositories/room_repository.dart';
import 'repositories/booking_repository.dart';
import 'repositories/guest_repository.dart';
import 'repositories/restaurant_repository.dart';
import 'repositories/housekeeping_repository.dart';
import 'repositories/inventory_repository.dart';
import 'repositories/expense_repository.dart';
import 'repositories/staff_repository.dart';
import 'repositories/maintenance_repository.dart';
import 'repositories/notification_repository.dart';
import 'repositories/cafe_repository.dart';

import 'services/api_client.dart';
import 'repositories/http_repositories.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API client and WebPrinter branding
  await ApiClient.instance.init();
  await WebPrinter.init();

  // Lock orientation to portrait (mobile only)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  final authService = HttpAuthService();
  final router = AppRouter(authService);

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => authService),
        Provider<RoomRepository>(create: (_) => HttpRoomRepository()),
        Provider<BookingRepository>(create: (_) => HttpBookingRepository()),
        Provider<GuestRepository>(create: (_) => HttpGuestRepository()),
        Provider<RestaurantRepository>(create: (_) => HttpRestaurantRepository()),
        Provider<CafeRepository>(create: (_) => HttpCafeRepository()),
        Provider<HousekeepingRepository>(create: (_) => HttpHousekeepingRepository()),
        Provider<InventoryRepository>(create: (_) => HttpInventoryRepository()),
        Provider<ExpenseRepository>(create: (_) => HttpExpenseRepository()),
        Provider<StaffRepository>(create: (_) => HttpStaffRepository()),
        Provider<MaintenanceRepository>(create: (_) => HttpMaintenanceRepository()),
        Provider<NotificationRepository>(create: (_) => HttpNotificationRepository()),
      ],
      child: HotelErpApp(router: router),
    ),
  );
}

class HotelErpApp extends StatelessWidget {
  final AppRouter router;

  const HotelErpApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hotel ERP',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router.router,
      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;

        // 100% edge-to-edge native mobile layout for phones & mobile viewports
        if (screenWidth <= 520) {
          return ColoredBox(
            color: AppColors.background,
            child: child ?? const SizedBox.shrink(),
          );
        }

        // Sleek mobile mockup preview frame when viewed on desktop / laptop screens
        return ColoredBox(
          color: const Color(0xFF0F172A), // Dark slate backdrop
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 440,
                maxHeight: 920,
              ),
              margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(36),
                border: Border.all(color: const Color(0xFF334155), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 36,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(33),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
      },
    );
  }
}
