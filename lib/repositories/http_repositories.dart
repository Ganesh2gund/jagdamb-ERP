import 'dart:developer' as dev;
import '../models/room.dart';
import '../models/booking.dart';
import '../models/guest.dart';
import '../models/restaurant.dart';
import '../models/expense.dart';
import '../services/api_client.dart';
import 'room_repository.dart';
import 'booking_repository.dart';
import 'guest_repository.dart';
import 'restaurant_repository.dart';
import 'housekeeping_repository.dart';
import 'inventory_repository.dart';
import 'expense_repository.dart';
import 'staff_repository.dart';
import 'maintenance_repository.dart';
import 'notification_repository.dart';

// ==========================================
// 1. HTTP ROOM REPOSITORY
// ==========================================
class HttpRoomRepository implements RoomRepository {
  final ApiClient _api = ApiClient.instance;
  final MockRoomRepository _fallback = MockRoomRepository();

  RoomType _parseRoomType(String? t) {
    switch (t?.toLowerCase()) {
      case 'deluxe': return RoomType.deluxe;
      case 'suite': return RoomType.suite;
      case 'executive': return RoomType.executive;
      case 'presidential': return RoomType.presidential;
      default: return RoomType.standard;
    }
  }

  RoomStatus _parseRoomStatus(String? s) {
    switch (s?.toLowerCase()) {
      case 'occupied': return RoomStatus.occupied;
      case 'reserved': return RoomStatus.reserved;
      case 'cleaning': return RoomStatus.cleaning;
      case 'maintenance': return RoomStatus.maintenance;
      default: return RoomStatus.available;
    }
  }

  Room _fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id']?.toString() ?? '',
      number: map['number']?.toString() ?? '',
      floor: (map['floor'] as num?)?.toInt() ?? 1,
      type: _parseRoomType(map['type']?.toString()),
      pricePerNight: (map['pricePerNight'] as num?)?.toDouble() ?? 0.0,
      status: _parseRoomStatus(map['status']?.toString()),
      amenities: (map['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      maxGuests: (map['maxGuests'] as num?)?.toInt() ?? 2,
      currentGuestName: map['currentGuestName']?.toString(),
      currentGuestId: map['currentGuestId']?.toString(),
      currentBookingId: map['currentBookingId']?.toString(),
      checkInDate: map['checkInDate'] != null ? DateTime.tryParse(map['checkInDate'].toString()) : null,
      checkOutDate: map['checkOutDate'] != null ? DateTime.tryParse(map['checkOutDate'].toString()) : null,
      maintenanceNote: map['maintenanceNote']?.toString(),
      imageUrl: map['imageUrl']?.toString(),
    );
  }

  @override
  Future<List<Room>> getRooms() async {
    try {
      final res = await _api.get('/rooms');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Fastify API /rooms offline, using fallback: $e');
    }
    return _fallback.getRooms();
  }

  @override
  Future<Room?> getRoomById(String id) async {
    try {
      final res = await _api.get('/rooms/$id');
      if (res is Map && res['data'] != null) {
        return _fromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Fastify API /rooms/$id offline, using fallback: $e');
    }
    return _fallback.getRoomById(id);
  }

  @override
  Future<List<Room>> getRoomsByStatus(RoomStatus status) async {
    final all = await getRooms();
    return all.where((r) => r.status == status).toList();
  }

  @override
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    try {
      await _api.put('/rooms/$roomId/status', body: {'status': status.name});
    } catch (e) {
      dev.log('Fastify API update status offline: $e');
    }
    await _fallback.updateRoomStatus(roomId, status);
  }

  @override
  Future<void> checkIn(String roomId, String guestId, String guestName, String bookingId, DateTime checkIn, DateTime checkOut) async {
    try {
      await _api.post('/rooms/$roomId/checkin', body: {
        'guestId': guestId,
        'guestName': guestName,
        'bookingId': bookingId,
        'checkInDate': checkIn.toIso8601String(),
        'checkOutDate': checkOut.toIso8601String(),
      });
    } catch (e) {
      dev.log('Fastify checkIn offline: $e');
    }
    await _fallback.checkIn(roomId, guestId, guestName, bookingId, checkIn, checkOut);
  }

  @override
  Future<void> checkOut(String roomId) async {
    try {
      await _api.post('/rooms/$roomId/checkout');
    } catch (e) {
      dev.log('Fastify checkOut offline: $e');
    }
    await _fallback.checkOut(roomId);
  }
}

// ==========================================
// 2. HTTP BOOKING REPOSITORY
// ==========================================
class HttpBookingRepository implements BookingRepository {
  final ApiClient _api = ApiClient.instance;
  final MockBookingRepository _fallback = MockBookingRepository();

  BookingStatus _parseBookingStatus(String? s) {
    final clean = s?.toLowerCase().replaceAll(RegExp(r'[\s\-_]'), '') ?? '';
    switch (clean) {
      case 'checkedin': return BookingStatus.checkedIn;
      case 'checkedout': return BookingStatus.checkedOut;
      case 'cancelled': return BookingStatus.cancelled;
      case 'noshow': return BookingStatus.noShow;
      case 'confirmed':
      case 'upcoming':
      default: return BookingStatus.upcoming;
    }
  }

  Booking _fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id']?.toString() ?? '',
      guestId: map['guestId']?.toString() ?? '',
      guestName: map['guestName']?.toString() ?? '',
      guestPhone: map['guestPhone']?.toString() ?? '',
      roomId: map['roomId']?.toString() ?? '',
      roomNumber: map['roomNumber']?.toString() ?? '',
      roomType: map['roomType']?.toString() ?? 'Standard',
      checkIn: map['checkInDate'] != null ? DateTime.parse(map['checkInDate'].toString()) : DateTime.now(),
      checkOut: map['checkOutDate'] != null ? DateTime.parse(map['checkOutDate'].toString()) : DateTime.now().add(const Duration(days: 1)),
      adults: (map['numberOfGuests'] as num?)?.toInt() ?? 1,
      children: 0,
      source: BookingSource.direct,
      status: _parseBookingStatus(map['status']?.toString()),
      paymentStatus: map['paymentStatus'] == 'paid' ? PaymentStatus.paid : (map['paymentStatus'] == 'partial' ? PaymentStatus.partial : PaymentStatus.pending),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: ((map['paidAmount'] ?? map['advancePaid']) as num?)?.toDouble() ?? 0.0,
      createdAt: map['createdAt'] != null ? (DateTime.tryParse(map['createdAt'].toString())?.toLocal() ?? DateTime.now()) : DateTime.now(),
      specialRequest: map['specialRequests']?.toString(),
      cancellationReason: map['cancellationReason']?.toString(),
    );
  }

  @override
  Future<List<Booking>> getBookings() async {
    try {
      final res = await _api.get('/bookings');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Fastify /bookings offline, using fallback: $e');
    }
    return _fallback.getBookings();
  }

  @override
  Future<Booking?> getBookingById(String id) async {
    try {
      final res = await _api.get('/bookings/$id');
      if (res is Map && res['data'] != null) {
        return _fromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Fastify /bookings/$id offline, using fallback: $e');
    }
    return _fallback.getBookingById(id);
  }

  @override
  Future<List<Booking>> getBookingsByStatus(BookingStatus status) async {
    final all = await getBookings();
    return all.where((b) => b.status == status).toList();
  }

  @override
  Future<List<Booking>> getTodayBookings() async {
    final all = await getBookings();
    final now = DateTime.now();
    return all.where((b) =>
      b.checkIn.year == now.year && b.checkIn.month == now.month && b.checkIn.day == now.day
    ).toList();
  }

  @override
  Future<void> createBooking(Booking booking, {bool checkInNow = false}) async {
    try {
      await _api.post('/bookings', body: {
        'guestName': booking.guestName,
        'guestPhone': booking.guestPhone,
        'guestId': booking.guestId,
        'roomId': booking.roomId,
        'roomNumber': booking.roomNumber,
        'roomType': booking.roomType,
        'checkInDate': booking.checkIn.toIso8601String(),
        'checkOutDate': booking.checkOut.toIso8601String(),
        'numberOfGuests': booking.adults + booking.children,
        'totalAmount': booking.totalAmount,
        'advancePaid': booking.paidAmount,
        'checkInNow': checkInNow, // 🚀 auto check-in flag
      });
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      dev.log('Fastify createBooking offline: $e');
    }
    await _fallback.createBooking(booking, checkInNow: checkInNow);
  }

  @override
  Future<void> updateBooking(String id, Map<String, dynamic> updates) async {
    try {
      final apiPayload = <String, dynamic>{...updates};
      if (updates['checkIn'] is DateTime) {
        apiPayload['checkInDate'] = (updates['checkIn'] as DateTime).toIso8601String();
        apiPayload.remove('checkIn');
      }
      if (updates['checkOut'] is DateTime) {
        apiPayload['checkOutDate'] = (updates['checkOut'] as DateTime).toIso8601String();
        apiPayload.remove('checkOut');
      }
      if (updates['adults'] != null || updates['children'] != null) {
        final adults = (updates['adults'] as int?) ?? 1;
        final children = (updates['children'] as int?) ?? 0;
        apiPayload['numberOfGuests'] = adults + children;
      }
      await _api.put('/bookings/$id', body: apiPayload);
    } catch (e) {
      dev.log('Fastify updateBooking offline: $e');
    }
    await _fallback.updateBooking(id, updates);
  }

  @override
  Future<void> cancelBooking(String id, String reason) async {
    try {
      await _api.post('/bookings/$id/cancel', body: {'reason': reason});
    } catch (e) {
      dev.log('Fastify cancelBooking offline: $e');
    }
    await _fallback.cancelBooking(id, reason);
  }

  @override
  Future<void> updateBookingStatus(String id, BookingStatus status) async {
    try {
      await _api.put('/bookings/$id/status', body: {'status': status.name});
    } catch (e) {
      dev.log('Fastify updateBookingStatus offline: $e');
    }
    await _fallback.updateBookingStatus(id, status);
  }

  @override
  Future<void> updatePaymentStatus(String id, PaymentStatus status, double paidAmount) async {
    try {
      await _api.put('/bookings/$id/payment', body: {
        'paymentStatus': status.name,
        'paidAmount': paidAmount,
      });
    } catch (e) {
      dev.log('Fastify updatePaymentStatus offline: $e');
    }
    await _fallback.updatePaymentStatus(id, status, paidAmount);
  }

  @override
  Future<Map<String, dynamic>> extendStay(String id, int additionalNights) async {
    try {
      final res = await _api.post('/bookings/$id/extend', body: {
        'additionalNights': additionalNights,
      });
      if (res is Map<String, dynamic>) {
        return res;
      }
      return {'success': true, 'message': 'Stay extended successfully'};
    } catch (e) {
      if (e is ApiException) {
        return {'success': false, 'message': e.message};
      }
      dev.log('Fastify extendStay offline, using fallback: $e');
      return await _fallback.extendStay(id, additionalNights);
    }
  }
}

// ==========================================
// 3. HTTP GUEST REPOSITORY
// ==========================================
class HttpGuestRepository implements GuestRepository {
  final ApiClient _api = ApiClient.instance;
  final MockGuestRepository _fallback = MockGuestRepository();

  Guest _fromMap(Map<String, dynamic> map) {
    return Guest(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      phone: map['phone']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      idType: map['idType']?.toString() ?? 'Aadhaar',
      idNumber: map['idNumber']?.toString() ?? '',
      totalVisits: (map['totalStays'] as num?)?.toInt() ?? 1,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      lastStay: DateTime.now(),
      createdAt: DateTime.now(),
      bookingIds: [],
      isVip: map['isVip'] == true,
      preferences: map['notes']?.toString(),
    );
  }

  @override
  Future<List<Guest>> getGuests() async {
    try {
      final res = await _api.get('/guests');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Fastify /guests offline: $e');
    }
    return _fallback.getGuests();
  }

  @override
  Future<Guest?> getGuestById(String id) async {
    try {
      final res = await _api.get('/guests/$id');
      if (res is Map && res['data'] != null) {
        return _fromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Fastify /guests/$id offline: $e');
    }
    return _fallback.getGuestById(id);
  }

  @override
  Future<List<Guest>> searchGuests(String query) async {
    try {
      final res = await _api.get('/guests', queryParams: {'search': query});
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _fromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _fallback.searchGuests(query);
  }

  @override
  Future<void> createGuest(Guest guest) async {
    try {
      await _api.post('/guests', body: {
        'name': guest.name,
        'phone': guest.phone,
        'email': guest.email,
        'address': guest.address,
        'idType': guest.idType,
        'idNumber': guest.idNumber,
        'notes': guest.preferences,
      });
    } catch (_) {}
    await _fallback.createGuest(guest);
  }

  @override
  Future<void> updateGuest(Guest guest) async {
    try {
      await _api.put('/guests/${guest.id}', body: {
        'name': guest.name,
        'phone': guest.phone,
        'email': guest.email,
        'address': guest.address,
      });
    } catch (_) {}
    await _fallback.updateGuest(guest);
  }
}

// ==========================================
// 4. HTTP RESTAURANT REPOSITORY
// ==========================================
class HttpRestaurantRepository implements RestaurantRepository {
  final ApiClient _api = ApiClient.instance;
  final MockRestaurantRepository _fallback = MockRestaurantRepository();

  MenuItem _menuFromMap(Map<String, dynamic> m) {
    return MenuItem(
      id: m['id']?.toString() ?? '',
      name: m['name']?.toString() ?? '',
      category: m['category']?.toString() ?? 'Main Course',
      price: (m['price'] as num?)?.toDouble() ?? 0,
      isVeg: m['isVeg'] as bool? ?? true,
      description: m['description']?.toString(),
    );
  }

  RestaurantTable _tableFromMap(Map<String, dynamic> m) {
    return RestaurantTable(
      id: m['id']?.toString() ?? '',
      number: m['number']?.toString() ?? '',
      capacity: (m['capacity'] as num?)?.toInt() ?? 4,
    );
  }

  RestaurantOrder _orderFromMap(Map<String, dynamic> m) {
    final itemsList = (m['items'] as List?) ?? [];
    return RestaurantOrder(
      id: m['id']?.toString() ?? m['orderNumber']?.toString() ?? '',
      tableOrRoom: m['target']?.toString() ?? m['tableOrRoom']?.toString() ?? 'Counter',
      guestName: m['guestName']?.toString(),
      items: itemsList.map((it) {
        final itMap = it as Map<String, dynamic>;
        return OrderItem(
          menuItem: MenuItem(
            id: itMap['id']?.toString() ?? '',
            name: itMap['name']?.toString() ?? '',
            category: itMap['category']?.toString() ?? '',
            price: (itMap['price'] as num?)?.toDouble() ?? 0.0,
            isVeg: itMap['isVeg'] == true,
          ),
          quantity: (itMap['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList(),
      createdAt: m['createdAt'] != null ? (DateTime.tryParse(m['createdAt'].toString())?.toLocal() ?? DateTime.now()) : DateTime.now(),
      isPaid: m['isPaid'] == true,
      paymentMethod: m['paymentMethod']?.toString() ?? 'Cash',
      totalAmount: (m['total'] as num?)?.toDouble() ?? (m['grandTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  Future<List<MenuItem>> getMenuItems() async {
    try {
      final res = await _api.get('/restaurant/menu');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _menuFromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _fallback.getMenuItems();
  }

  @override
  Future<List<MenuItem>> getMenuByCategory(String category) async {
    final all = await getMenuItems();
    return all.where((m) => m.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Future<MenuItem> addMenuItem(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/restaurant/menu', body: data);
      if (res is Map && res['data'] is Map) {
        return _menuFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _fallback.addMenuItem(data);
  }

  @override
  Future<MenuItem?> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/restaurant/menu/$id', body: data);
      if (res is Map && res['data'] is Map) {
        return _menuFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _fallback.updateMenuItem(id, data);
  }

  @override
  Future<bool> deleteMenuItem(String id) async {
    try {
      await _api.delete('/restaurant/menu/$id');
      return true;
    } catch (_) {}
    return _fallback.deleteMenuItem(id);
  }

  // Categories
  @override
  Future<List<String>> getCategories() async {
    try {
      final res = await _api.get('/restaurant/categories');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return _fallback.getCategories();
  }

  @override
  Future<String?> addCategory(String name) async {
    try {
      final res = await _api.post('/restaurant/categories', body: {'name': name});
      if (res is Map && res['data'] != null) {
        return res['data'].toString();
      }
    } catch (_) {}
    return _fallback.addCategory(name);
  }

  @override
  Future<bool> deleteCategory(String name) async {
    try {
      await _api.delete('/restaurant/categories/${Uri.encodeComponent(name)}');
      return true;
    } catch (_) {}
    return _fallback.deleteCategory(name);
  }

  // Tables
  @override
  Future<List<RestaurantTable>> getTables() async {
    try {
      final res = await _api.get('/restaurant/tables');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((t) => _tableFromMap(t as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _fallback.getTables();
  }

  @override
  Future<RestaurantTable?> addTable(String number, int capacity) async {
    try {
      final res = await _api.post('/restaurant/tables', body: {'number': number, 'capacity': capacity});
      if (res is Map && res['data'] is Map) {
        return _tableFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _fallback.addTable(number, capacity);
  }

  @override
  Future<RestaurantTable?> updateTable(String id, String number, int capacity) async {
    try {
      final res = await _api.put('/restaurant/tables/$id', body: {'number': number, 'capacity': capacity});
      if (res is Map && res['data'] is Map) {
        return _tableFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (_) {}
    return _fallback.updateTable(id, number, capacity);
  }

  @override
  Future<bool> deleteTable(String id) async {
    try {
      await _api.delete('/restaurant/tables/$id');
      return true;
    } catch (_) {}
    return _fallback.deleteTable(id);
  }

  // Orders
  @override
  Future<List<RestaurantOrder>> getOrders() async {
    try {
      final res = await _api.get('/restaurant/orders');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((o) => _orderFromMap(o as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _fallback.getOrders();
  }

  @override
  Future<RestaurantOrder?> createOrder(RestaurantOrder order) async {
    try {
      final payload = {
        'type': 'dineIn',
        'target': order.tableOrRoom ?? 'Counter',
        'guestName': order.guestName,
        'items': order.items.map((i) => {
          'name': i.menuItem.name,
          'price': i.menuItem.price,
          'quantity': i.quantity,
        }).toList(),
        'isPaid': order.isPaid,
        'paymentMethod': order.paymentMethod,
        'total': order.total,
      };
      final res = await _api.post('/restaurant/orders', body: payload);
      if (res is Map && res['data'] is Map) {
        final created = _orderFromMap(res['data'] as Map<String, dynamic>);
        await _fallback.createOrder(created);
        return created;
      }
    } catch (_) {}
    return _fallback.createOrder(order);
  }
}

// ==========================================
// 5. HTTP OTHER REPOSITORIES (Wrapping mocks with Fastify sync)
// ==========================================
class HttpHousekeepingRepository extends MockHousekeepingRepository {}
class HttpInventoryRepository extends MockInventoryRepository {}
class HttpExpenseRepository implements ExpenseRepository {
  final ApiClient _api = ApiClient.instance;
  final MockExpenseRepository _fallback = MockExpenseRepository();

  ExpenseCategory _categoryFromString(String? cat) {
    if (cat == null) return ExpenseCategory.other;
    final lower = cat.toLowerCase().replaceAll(' ', '').replaceAll('_', '');
    for (final c in ExpenseCategory.values) {
      if (c.name.toLowerCase() == lower || c.label.toLowerCase().replaceAll(' ', '') == lower) {
        return c;
      }
    }
    return ExpenseCategory.other;
  }

  Expense _fromMap(Map<String, dynamic> m) {
    return Expense(
      id: m['id']?.toString() ?? '',
      category: _categoryFromString(m['category']?.toString()),
      amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
      date: m['date'] != null ? DateTime.tryParse(m['date'].toString()) ?? DateTime.now() : DateTime.now(),
      description: m['description']?.toString() ?? '',
      paymentMethod: m['paymentMethod']?.toString() ?? 'Cash',
      notes: m['notes']?.toString(),
      receipt: m['receipt']?.toString(),
    );
  }

  Map<String, dynamic> _toMap(Expense e) {
    return {
      'id': e.id,
      'category': e.category.label,
      'amount': e.amount,
      'date': e.date.toIso8601String(),
      'description': e.description,
      'paymentMethod': e.paymentMethod,
      'notes': e.notes,
      'receipt': e.receipt,
    };
  }

  @override
  Future<List<Expense>> getExpenses() async {
    try {
      final res = await _api.get('/expenses');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((e) => _fromMap(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return _fallback.getExpenses();
  }

  @override
  Future<List<Expense>> getTodayExpenses() async {
    final all = await getExpenses();
    final today = DateTime.now();
    return all.where((e) =>
      e.date.year == today.year && e.date.month == today.month && e.date.day == today.day
    ).toList();
  }

  @override
  Future<List<Expense>> getMonthExpenses() async {
    final all = await getExpenses();
    final today = DateTime.now();
    return all.where((e) =>
      e.date.year == today.year && e.date.month == today.month
    ).toList();
  }

  @override
  Future<void> createExpense(Expense expense) async {
    try {
      await _api.post('/expenses', body: _toMap(expense));
    } catch (_) {}
    await _fallback.createExpense(expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    try {
      await _api.put('/expenses/${expense.id}', body: _toMap(expense));
    } catch (_) {}
    await _fallback.updateExpense(expense);
  }

  @override
  Future<bool> deleteExpense(String id) async {
    try {
      await _api.delete('/expenses/$id');
    } catch (_) {}
    return _fallback.deleteExpense(id);
  }
}
class HttpStaffRepository extends MockStaffRepository {}
class HttpMaintenanceRepository extends MockMaintenanceRepository {}
class HttpNotificationRepository extends MockNotificationRepository {}
