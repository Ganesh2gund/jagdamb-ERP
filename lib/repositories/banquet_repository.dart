import 'dart:developer' as dev;
import '../models/banquet.dart';
import '../services/api_client.dart';

abstract class BanquetRepository {
  // Halls
  Future<List<BanquetHall>> getHalls();
  Future<BanquetHall?> addHall(Map<String, dynamic> data);
  Future<BanquetHall?> updateHall(String id, Map<String, dynamic> data);
  Future<bool> deleteHall(String id);

  // Packages
  Future<List<BanquetPackage>> getPackages();
  Future<BanquetPackage?> addPackage(Map<String, dynamic> data);
  Future<bool> deletePackage(String id);

  // Bookings
  Future<List<BanquetBooking>> getBookings();
  Future<BanquetBooking?> createBooking(Map<String, dynamic> data);
  Future<BanquetBooking?> updateBooking(String id, Map<String, dynamic> data);
  Future<bool> cancelBooking(String id, {String reason = ''});
}

class MockBanquetRepository implements BanquetRepository {
  static final List<BanquetHall> _halls = [
    const BanquetHall(
      id: 'hall_1',
      name: 'Grand Kohinoor Ballroom',
      capacity: 350,
      baseRentMorning: 20000,
      baseRentEvening: 35000,
      baseRentFullDay: 50000,
      amenities: ['Central AC', 'Bridal Room', 'DJ & Sound System', 'Stage Lighting', 'Valet Parking'],
      status: 'available',
    ),
    const BanquetHall(
      id: 'hall_2',
      name: 'Royal Heritage Banquet',
      capacity: 150,
      baseRentMorning: 12000,
      baseRentEvening: 20000,
      baseRentFullDay: 30000,
      amenities: ['AC', 'Stage & Mic', 'Projector & Screen', 'Buffet Area'],
      status: 'available',
    ),
  ];

  static final List<BanquetPackage> _packages = [
    const BanquetPackage(
      id: 'pkg_silver',
      name: 'Silver Wedding / Party Package',
      pricePerPlate: 450,
      isVeg: true,
      description: 'Standard 3-course banquet meal with welcome drink',
      inclusions: ['Welcome Drink', '2 Veg Starters', 'Paneer Sabji', 'Seasonal Veg', 'Dal Fry & Jeera Rice', 'Roti / Naan', 'Gulab Jamun & Ice Cream'],
    ),
    const BanquetPackage(
      id: 'pkg_gold',
      name: 'Gold Grand Maharaja Package',
      pricePerPlate: 750,
      isVeg: true,
      description: 'Luxury lavish banquet spread with live counter & desserts',
      inclusions: ['2 Welcome Drinks', '4 Starters', 'Shahi Paneer', 'Veg Kofta', 'Dal Makhani', 'Dum Biryani with Raita', 'Assorted Breads', '2 Desserts', 'Salad Counter'],
    ),
    const BanquetPackage(
      id: 'pkg_corporate',
      name: 'Corporate High-Tea & Lunch Package',
      pricePerPlate: 350,
      isVeg: true,
      description: 'Business seminar package with tea/coffee & executive lunch',
      inclusions: ['Morning Tea/Coffee & Cookies', 'Executive Lunch Buffet', 'Evening High Tea & Snacks'],
    ),
  ];

  static final List<BanquetBooking> _bookings = [
    const BanquetBooking(
      id: 'bnq_demo_1',
      bookingNumber: 'BNQ-2026-001',
      hallId: 'hall_1',
      hallName: 'Grand Kohinoor Ballroom',
      customerName: 'Rajesh Sharma',
      customerPhone: '9876543210',
      eventType: 'Wedding Reception',
      eventDate: '2026-09-15',
      slot: 'Evening',
      expectedGuests: 250,
      packageId: 'pkg_silver',
      packageName: 'Silver Wedding / Party Package',
      pricePerPlate: 450,
      foodTotal: 112500,
      hallRent: 35000,
      extraCharges: 10000,
      tax: 0,
      grandTotal: 157500,
      advancePaid: 50000,
      balanceDue: 107500,
      status: 'confirmed',
      notes: 'Floral stage decoration included.',
    ),
  ];

  @override
  Future<List<BanquetHall>> getHalls() async => List.unmodifiable(_halls);

  @override
  Future<BanquetHall?> addHall(Map<String, dynamic> data) async {
    final hall = BanquetHall.fromJson({
      ...data,
      'id': 'hall_${DateTime.now().millisecondsSinceEpoch}',
    });
    _halls.add(hall);
    return hall;
  }

  @override
  Future<BanquetHall?> updateHall(String id, Map<String, dynamic> data) async {
    final idx = _halls.indexWhere((h) => h.id == id);
    if (idx == -1) return null;
    final updated = BanquetHall.fromJson({..._halls[idx].toJson(), ...data});
    _halls[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteHall(String id) async {
    final before = _halls.length;
    _halls.removeWhere((h) => h.id == id);
    return _halls.length < before;
  }

  @override
  Future<List<BanquetPackage>> getPackages() async => List.unmodifiable(_packages);

  @override
  Future<BanquetPackage?> addPackage(Map<String, dynamic> data) async {
    final pkg = BanquetPackage.fromJson({
      ...data,
      'id': 'pkg_${DateTime.now().millisecondsSinceEpoch}',
    });
    _packages.add(pkg);
    return pkg;
  }

  @override
  Future<bool> deletePackage(String id) async {
    final before = _packages.length;
    _packages.removeWhere((p) => p.id == id);
    return _packages.length < before;
  }

  @override
  Future<List<BanquetBooking>> getBookings() async => List.unmodifiable(_bookings);

  @override
  Future<BanquetBooking?> createBooking(Map<String, dynamic> data) async {
    final guests = (data['expectedGuests'] as num?)?.toInt() ?? 100;
    final rate = (data['pricePerPlate'] as num?)?.toDouble() ?? 0.0;
    final food = data['foodTotal'] != null ? (data['foodTotal'] as num).toDouble() : (guests * rate);
    final rent = (data['hallRent'] as num?)?.toDouble() ?? 0.0;
    final extra = (data['extraCharges'] as num?)?.toDouble() ?? 0.0;
    final tax = (data['tax'] as num?)?.toDouble() ?? 0.0;
    final grand = data['grandTotal'] != null ? (data['grandTotal'] as num).toDouble() : (food + rent + extra + tax);
    final advance = (data['advancePaid'] as num?)?.toDouble() ?? 0.0;
    final balance = (grand - advance).clamp(0.0, double.infinity);

    final booking = BanquetBooking.fromJson({
      ...data,
      'id': 'bnq_${DateTime.now().millisecondsSinceEpoch}',
      'bookingNumber': 'BNQ-2026-${String.fromCharCodes(Iterable.generate(3, (_) => 48 + DateTime.now().millisecond % 10))}',
      'foodTotal': food,
      'grandTotal': grand,
      'balanceDue': balance,
    });
    _bookings.insert(0, booking);
    return booking;
  }

  @override
  Future<BanquetBooking?> updateBooking(String id, Map<String, dynamic> data) async {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx == -1) return null;
    final updated = BanquetBooking.fromJson({..._bookings[idx].toJson(), ...data});
    _bookings[idx] = updated;
    return updated;
  }

  @override
  Future<bool> cancelBooking(String id, {String reason = ''}) async {
    final idx = _bookings.indexWhere((b) => b.id == id);
    if (idx == -1) return false;
    _bookings[idx] = BanquetBooking.fromJson({
      ..._bookings[idx].toJson(),
      'status': 'cancelled',
      'notes': '${_bookings[idx].notes}\nCancelled: $reason',
    });
    return true;
  }
}

class HttpBanquetRepository implements BanquetRepository {
  final ApiClient _api = ApiClient.instance;
  final MockBanquetRepository _fallback = MockBanquetRepository();

  @override
  Future<List<BanquetHall>> getHalls() async {
    try {
      final res = await _api.get('/banquet/halls');
      if (res is Map && res['halls'] is List) {
        return (res['halls'] as List).map((h) => BanquetHall.fromJson(h as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Error fetching banquet halls: $e');
    }
    return _fallback.getHalls();
  }

  @override
  Future<BanquetHall?> addHall(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/banquet/halls', body: data);
      if (res is Map && res['hall'] is Map) {
        return BanquetHall.fromJson(res['hall'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error adding banquet hall: $e');
    }
    return _fallback.addHall(data);
  }

  @override
  Future<BanquetHall?> updateHall(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/banquet/halls/$id', body: data);
      if (res is Map && res['hall'] is Map) {
        return BanquetHall.fromJson(res['hall'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error updating banquet hall: $e');
    }
    return _fallback.updateHall(id, data);
  }

  @override
  Future<bool> deleteHall(String id) async {
    try {
      final res = await _api.delete('/banquet/halls/$id');
      if (res is Map && res['success'] == true) return true;
    } catch (e) {
      dev.log('Error deleting banquet hall: $e');
    }
    return _fallback.deleteHall(id);
  }

  @override
  Future<List<BanquetPackage>> getPackages() async {
    try {
      final res = await _api.get('/banquet/packages');
      if (res is Map && res['packages'] is List) {
        return (res['packages'] as List).map((p) => BanquetPackage.fromJson(p as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Error fetching banquet packages: $e');
    }
    return _fallback.getPackages();
  }

  @override
  Future<BanquetPackage?> addPackage(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/banquet/packages', body: data);
      if (res is Map && res['package'] is Map) {
        return BanquetPackage.fromJson(res['package'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error adding banquet package: $e');
    }
    return _fallback.addPackage(data);
  }

  @override
  Future<bool> deletePackage(String id) async {
    try {
      final res = await _api.delete('/banquet/packages/$id');
      if (res is Map && res['success'] == true) return true;
    } catch (e) {
      dev.log('Error deleting banquet package: $e');
    }
    return _fallback.deletePackage(id);
  }

  @override
  Future<List<BanquetBooking>> getBookings() async {
    try {
      final res = await _api.get('/banquet/bookings');
      if (res is Map && res['bookings'] is List) {
        return (res['bookings'] as List).map((b) => BanquetBooking.fromJson(b as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Error fetching banquet bookings: $e');
    }
    return _fallback.getBookings();
  }

  @override
  Future<BanquetBooking?> createBooking(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/banquet/bookings', body: data);
      if (res is Map && res['booking'] is Map) {
        return BanquetBooking.fromJson(res['booking'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error creating banquet booking: $e');
    }
    return _fallback.createBooking(data);
  }

  @override
  Future<BanquetBooking?> updateBooking(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/banquet/bookings/$id', body: data);
      if (res is Map && res['booking'] is Map) {
        return BanquetBooking.fromJson(res['booking'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error updating banquet booking: $e');
    }
    return _fallback.updateBooking(id, data);
  }

  @override
  Future<bool> cancelBooking(String id, {String reason = ''}) async {
    try {
      final res = await _api.delete('/banquet/bookings/$id?reason=${Uri.encodeComponent(reason)}');
      if (res is Map && res['success'] == true) return true;
    } catch (e) {
      dev.log('Error cancelling banquet booking: $e');
    }
    return _fallback.cancelBooking(id, reason: reason);
  }
}
