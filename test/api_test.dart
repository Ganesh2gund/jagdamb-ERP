import 'package:flutter_test/flutter_test.dart';
import 'package:hotel_erp/services/api_client.dart';
import 'package:hotel_erp/services/auth_service.dart';
import 'package:hotel_erp/repositories/http_repositories.dart';
import 'package:hotel_erp/models/room.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('Fastify Backend & HTTP Repositories Tests', () {
    test('ApiClient instance has correct default base URL', () {
      final client = ApiClient.instance;
      expect(client.baseUrl, contains(':5000/api'));
    });

    test('HttpAuthService handles login with fallback smoothly', () async {
      final auth = HttpAuthService();
      final result = await auth.login('tejas@gmail.com', 'tejas4010');
      expect(result.success, isTrue);
      expect(result.userEmail, equals('tejas@gmail.com'));
    });

    test('HttpRoomRepository retrieves rooms and parses successfully', () async {
      final roomRepo = HttpRoomRepository();
      final rooms = await roomRepo.getRooms();
      expect(rooms, isNotEmpty);
      expect(rooms.first.number, isNotEmpty);
      expect(rooms.first.status, isA<RoomStatus>());
    });

    test('HttpBookingRepository retrieves bookings', () async {
      final bookingRepo = HttpBookingRepository();
      final bookings = await bookingRepo.getBookings();
      expect(bookings, isNotEmpty);
      expect(bookings.first.guestName, isNotEmpty);
    });

    test('HttpGuestRepository retrieves guests', () async {
      final guestRepo = HttpGuestRepository();
      final guests = await guestRepo.getGuests();
      expect(guests, isNotEmpty);
    });
  });
}
