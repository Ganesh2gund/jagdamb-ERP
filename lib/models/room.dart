enum RoomType { standard, deluxe, suite, executive, presidential }
enum RoomStatus { available, occupied, reserved, cleaning, maintenance }

extension RoomTypeExt on RoomType {
  String get label {
    switch (this) {
      case RoomType.standard: return 'Standard';
      case RoomType.deluxe: return 'Deluxe';
      case RoomType.suite: return 'Suite';
      case RoomType.executive: return 'Executive';
      case RoomType.presidential: return 'Presidential';
    }
  }
}

extension RoomStatusExt on RoomStatus {
  String get label {
    switch (this) {
      case RoomStatus.available: return 'Available';
      case RoomStatus.occupied: return 'Occupied';
      case RoomStatus.reserved: return 'Reserved';
      case RoomStatus.cleaning: return 'Cleaning';
      case RoomStatus.maintenance: return 'Maintenance';
    }
  }
}

class Room {
  final String id;
  final String number;
  final int floor;
  final RoomType type;
  final double pricePerNight;
  final RoomStatus status;
  final List<String> amenities;
  final String? currentGuestName;
  final String? currentGuestId;
  final String? currentBookingId;
  final DateTime? checkInDate;
  final DateTime? checkOutDate;
  final String? maintenanceNote;
  final String? imageUrl;
  final int maxGuests;

  const Room({
    required this.id,
    required this.number,
    required this.floor,
    required this.type,
    required this.pricePerNight,
    required this.status,
    required this.amenities,
    required this.maxGuests,
    this.currentGuestName,
    this.currentGuestId,
    this.currentBookingId,
    this.checkInDate,
    this.checkOutDate,
    this.maintenanceNote,
    this.imageUrl,
  });

  Room copyWith({
    RoomStatus? status,
    String? currentGuestName,
    String? currentGuestId,
    String? currentBookingId,
    DateTime? checkInDate,
    DateTime? checkOutDate,
    String? maintenanceNote,
  }) {
    return Room(
      id: id,
      number: number,
      floor: floor,
      type: type,
      pricePerNight: pricePerNight,
      status: status ?? this.status,
      amenities: amenities,
      maxGuests: maxGuests,
      currentGuestName: currentGuestName ?? this.currentGuestName,
      currentGuestId: currentGuestId ?? this.currentGuestId,
      currentBookingId: currentBookingId ?? this.currentBookingId,
      checkInDate: checkInDate ?? this.checkInDate,
      checkOutDate: checkOutDate ?? this.checkOutDate,
      maintenanceNote: maintenanceNote ?? this.maintenanceNote,
      imageUrl: imageUrl,
    );
  }
}
