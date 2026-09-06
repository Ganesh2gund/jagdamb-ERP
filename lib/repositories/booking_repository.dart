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
      final current = _bookings[idx];
      _bookings[idx] = current.copyWith(
        guestName: updates['guestName'] as String?,
        guestPhone: updates['guestPhone'] as String?,
        roomId: updates['roomId'] as String?,
        roomNumber: updates['roomNumber'] as String?,
        roomType: updates['roomType'] as String?,
        checkIn: updates['checkIn'] as DateTime?,
        checkOut: updates['checkOut'] as DateTime?,
        adults: updates['adults'] as int?,
        children: updates['children'] as int?,
        totalAmount: (updates['totalAmount'] as num?)?.toDouble(),
        paidAmount: (updates['paidAmount'] as num?)?.toDouble(),
        paymentStatus: updates['paidAmount'] != null
            ? (((updates['paidAmount'] as num).toDouble() >=
                    ((updates['totalAmount'] as num?)?.toDouble() ??
                        current.totalAmount))
                ? PaymentStatus.paid
                : (((updates['paidAmount'] as num).toDouble() > 0)
                    ? PaymentStatus.partial
                    : PaymentStatus.pending))
            : current.paymentStatus,
        specialRequest: updates['specialRequest'] as String?,
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
}
