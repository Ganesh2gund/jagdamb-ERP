import '../models/guest.dart';

abstract class GuestRepository {
  Future<List<Guest>> getGuests();
  Future<Guest?> getGuestById(String id);
  Future<List<Guest>> searchGuests(String query);
  Future<void> createGuest(Guest guest);
  Future<void> updateGuest(Guest guest);
}

class MockGuestRepository implements GuestRepository {
  final List<Guest> _guests = [];

  @override
  Future<List<Guest>> getGuests() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_guests);
  }

  @override
  Future<Guest?> getGuestById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _guests.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Guest>> searchGuests(String query) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final q = query.toLowerCase();
    return _guests.where((g) =>
      g.name.toLowerCase().contains(q) ||
      g.phone.contains(q) ||
      g.email.toLowerCase().contains(q)
    ).toList();
  }

  @override
  Future<void> createGuest(Guest guest) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _guests.add(guest);
  }

  @override
  Future<void> updateGuest(Guest guest) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _guests.indexWhere((g) => g.id == guest.id);
    if (idx != -1) _guests[idx] = guest;
  }
}
