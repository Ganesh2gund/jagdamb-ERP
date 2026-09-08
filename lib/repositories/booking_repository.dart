import '../models/booking.dart';

abstract class BookingRepository {
  Future<List<Booking>> getBookings();
  Future<Booking?> getBookingById(String id);
  Future<List<Booking>> getBookingsByStatus(BookingStatus status);
  Future<List<Booking>> getTodayBookings();
  Future<void> createBooking(Booking booking, {bool checkInNow = false});
  Future<void> updateBooking(String id, Map<String, dynamic> updates);
  Future<void> cancelBooking(String id, String reason);
  Future<void> updateBookingStatus(String id, BookingStatus status);
  Future<void> updatePaymentStatus(String id, PaymentStatus status, double paidAmount);
  Future<Map<String, dynamic>> extendStay(String id, int additionalNights);
}

class MockBookingRepository implements BookingRepository {
  final List<Booking> _bookings = [];

  @override
  Future<List<Booking>> getBookings() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_bookings);
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _bookings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Booking>> getBookingsByStatus(BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _bookings.where((b) => b.status == status).toList();
  }

  @override
  Future<List<Booking>> getTodayBookings() async {
    await Future.delayed(const Duration(milliseconds: 200));
    final today = DateTime.now();
    return _bookings.where((b) {
      return b.checkIn.year == today.year &&
          b.checkIn.month == today.month &&
          b.checkIn.day == today.day;
    }).toList();
  }

  @override
  Future<void> createBooking(Booking booking, {bool checkInNow = false}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _bookings.add(booking);
  }

  @override
  Future<void> updateBooking(String id, Map<String, dynamic> updates) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final old = _bookings[idx];
      _bookings[idx] = old.copyWith(
        guestName: updates['guestName'] ?? old.guestName,
        guestPhone: updates['guestPhone'] ?? old.guestPhone,
        checkIn: updates['checkIn'] ?? old.checkIn,
        checkOut: updates['checkOut'] ?? old.checkOut,
        adults: updates['adults'] ?? old.adults,
        children: updates['children'] ?? old.children,
        totalAmount: (updates['totalAmount'] as num?)?.toDouble() ?? old.totalAmount,
        paidAmount: (updates['paidAmount'] as num?)?.toDouble() ?? old.paidAmount,
      );
    }
  }

  @override
  Future<void> cancelBooking(String id, String reason) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        status: BookingStatus.cancelled,
        cancellationReason: reason,
      );
    }
  }

  @override
  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(status: status);
    }
  }

  @override
  Future<void> updatePaymentStatus(
      String id, PaymentStatus status, double paidAmount) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      _bookings[idx] = _bookings[idx].copyWith(
        paymentStatus: status,
        paidAmount: paidAmount,
      );
    }
  }

  @override
  Future<Map<String, dynamic>> extendStay(String id, int additionalNights) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx != -1) {
      final old = _bookings[idx];
      final currentNights = old.checkOut.difference(old.checkIn).inDays.clamp(1, 999);
      final pricePerNight = old.totalAmount / currentNights;
      final newOut = old.checkOut.add(Duration(days: additionalNights));
      final newNights = currentNights + additionalNights;
      final newTotal = pricePerNight * newNights;
      _bookings[idx] = old.copyWith(
        checkOut: newOut,
        totalAmount: newTotal,
      );
      return {'success': true, 'message': 'Stay extended'};
    }
    return {'success': false, 'message': 'Booking not found'};
  }
}
