import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotel_erp/main.dart';
import 'package:hotel_erp/core/constants/app_constants.dart';
import 'package:hotel_erp/core/constants/app_router.dart';
import 'package:hotel_erp/models/room.dart';
import 'package:hotel_erp/models/booking.dart';
import 'package:hotel_erp/models/inventory.dart';
import 'package:hotel_erp/services/auth_service.dart';
import 'package:hotel_erp/repositories/room_repository.dart';
import 'package:hotel_erp/repositories/booking_repository.dart';
import 'package:hotel_erp/repositories/guest_repository.dart';
import 'package:hotel_erp/repositories/restaurant_repository.dart';
import 'package:hotel_erp/repositories/housekeeping_repository.dart';
import 'package:hotel_erp/repositories/inventory_repository.dart';
import 'package:hotel_erp/repositories/expense_repository.dart';
import 'package:hotel_erp/repositories/staff_repository.dart';
import 'package:hotel_erp/repositories/maintenance_repository.dart';
import 'package:hotel_erp/repositories/notification_repository.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Repository Unit Tests', () {
    test('MockAuthService correctly authenticates admin', () async {
      final authService = MockAuthService();
      expect(await authService.isLoggedIn(), isFalse);

      final result = await authService.login(AppConstants.adminEmail, AppConstants.adminPassword);
      expect(result.success, isTrue);
      expect(await authService.isLoggedIn(), isTrue);

      final email = await authService.getCurrentUserEmail();
      expect(email, AppConstants.adminEmail);

      await authService.logout();
      expect(await authService.isLoggedIn(), isFalse);
    });

    test('MockRoomRepository loads rooms and filters correctly', () async {
      final repo = MockRoomRepository();
      final rooms = await repo.getRooms();
      expect(rooms.isNotEmpty, isTrue);

      final availableRooms = await repo.getRoomsByStatus(RoomStatus.available);
      expect(availableRooms.every((r) => r.status == RoomStatus.available), isTrue);
    });

    test('MockBookingRepository loads bookings and filters', () async {
      final repo = MockBookingRepository();
      final bookings = await repo.getBookings();
      expect(bookings.isNotEmpty, isTrue);

      final activeBookings = await repo.getBookingsByStatus(BookingStatus.checkedIn);
      expect(activeBookings.isNotEmpty, isTrue);
    });

    test('MockInventoryRepository loads items and flags low stock', () async {
      final repo = MockInventoryRepository();
      final items = await repo.getItems();
      expect(items.isNotEmpty, isTrue);

      final lowStock = await repo.getLowStockItems();
      expect(lowStock.every((i) => i.status != InventoryStatus.inStock), isTrue);
    });
  });

  group('Widget Smoke Test', () {
    testWidgets('HotelErpApp builds and renders correctly', (WidgetTester tester) async {
      final authService = MockAuthService();
      final router = AppRouter(authService);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthService>(create: (_) => authService),
            Provider<RoomRepository>(create: (_) => MockRoomRepository()),
            Provider<BookingRepository>(create: (_) => MockBookingRepository()),
            Provider<GuestRepository>(create: (_) => MockGuestRepository()),
            Provider<RestaurantRepository>(create: (_) => MockRestaurantRepository()),
            Provider<HousekeepingRepository>(create: (_) => MockHousekeepingRepository()),
            Provider<InventoryRepository>(create: (_) => MockInventoryRepository()),
            Provider<ExpenseRepository>(create: (_) => MockExpenseRepository()),
            Provider<StaffRepository>(create: (_) => MockStaffRepository()),
            Provider<MaintenanceRepository>(create: (_) => MockMaintenanceRepository()),
            Provider<NotificationRepository>(create: (_) => MockNotificationRepository()),
          ],
          child: HotelErpApp(router: router),
        ),
      );

      // Settle splash timers and navigation
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
