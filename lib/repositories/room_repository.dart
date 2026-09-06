import '../models/room.dart';

abstract class RoomRepository {
  Future<List<Room>> getRooms();
  Future<Room?> getRoomById(String id);
  Future<List<Room>> getRoomsByStatus(RoomStatus status);
  Future<void> updateRoomStatus(String roomId, RoomStatus status);
  Future<void> checkIn(String roomId, String guestId, String guestName, String bookingId, DateTime checkIn, DateTime checkOut);
  Future<void> checkOut(String roomId);
}

class MockRoomRepository implements RoomRepository {
  static final List<Room> _rooms = [];

  List<Room> _mutableRooms = List.from(_rooms);

  MockRoomRepository() {
    _mutableRooms = _rooms.map((r) => r).toList();
  }

  @override
  Future<List<Room>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_mutableRooms);
  }

  @override
  Future<Room?> getRoomById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mutableRooms.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Room>> getRoomsByStatus(RoomStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _mutableRooms.where((r) => r.status == status).toList();
  }

  @override
  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _mutableRooms.indexWhere((r) => r.id == roomId || r.number == roomId);
    if (idx != -1) {
      final isFree = status == RoomStatus.available || status == RoomStatus.cleaning;
      _mutableRooms[idx] = Room(
        id: _mutableRooms[idx].id,
        number: _mutableRooms[idx].number,
        floor: _mutableRooms[idx].floor,
        type: _mutableRooms[idx].type,
        pricePerNight: _mutableRooms[idx].pricePerNight,
        status: status,
        amenities: _mutableRooms[idx].amenities,
        maxGuests: _mutableRooms[idx].maxGuests,
        currentGuestId: isFree ? null : _mutableRooms[idx].currentGuestId,
        currentGuestName: isFree ? null : _mutableRooms[idx].currentGuestName,
        currentBookingId: isFree ? null : _mutableRooms[idx].currentBookingId,
        checkInDate: isFree ? null : _mutableRooms[idx].checkInDate,
        checkOutDate: isFree ? null : _mutableRooms[idx].checkOutDate,
        maintenanceNote: _mutableRooms[idx].maintenanceNote,
      );
    }
  }

  @override
  Future<void> checkIn(String roomId, String guestId, String guestName,
      String bookingId, DateTime checkIn, DateTime checkOut) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _mutableRooms.indexWhere((r) => r.id == roomId || r.number == roomId);
    if (idx != -1) {
      _mutableRooms[idx] = _mutableRooms[idx].copyWith(
        status: RoomStatus.occupied,
        currentGuestId: guestId,
        currentGuestName: guestName,
        currentBookingId: bookingId,
        checkInDate: checkIn,
        checkOutDate: checkOut,
      );
    }
  }

  @override
  Future<void> checkOut(String roomId) async {
    await updateRoomStatus(roomId, RoomStatus.available);
  }
}
