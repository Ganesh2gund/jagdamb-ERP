enum BookingStatus { upcoming, checkedIn, checkedOut, cancelled, noShow }
enum BookingSource { direct, phone, website, walkIn, ota, travelAgent }
enum PaymentStatus { paid, pending, partial }

extension BookingStatusExt on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.upcoming: return 'Upcoming';
      case BookingStatus.checkedIn: return 'Checked In';
      case BookingStatus.checkedOut: return 'Checked Out';
      case BookingStatus.cancelled: return 'Cancelled';
      case BookingStatus.noShow: return 'No Show';
    }
  }
}

extension BookingSourceExt on BookingSource {
  String get label {
    switch (this) {
      case BookingSource.direct: return 'Direct';
      case BookingSource.phone: return 'Phone';
      case BookingSource.website: return 'Website';
      case BookingSource.walkIn: return 'Walk-in';
      case BookingSource.ota: return 'OTA';
      case BookingSource.travelAgent: return 'Travel Agent';
    }
  }
}

extension PaymentStatusExt on PaymentStatus {
  String get label {
    switch (this) {
      case PaymentStatus.paid: return 'Paid';
      case PaymentStatus.pending: return 'Pending';
      case PaymentStatus.partial: return 'Partial';
    }
  }
}

class Booking {
  final String id;
  final String guestId;
  final String guestName;
  final String guestPhone;
  final String roomId;
  final String roomNumber;
  final String roomType;
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final BookingSource source;
  final BookingStatus status;
  final PaymentStatus paymentStatus;
  final double totalAmount;
  final double paidAmount;
  final String? specialRequest;
  final DateTime createdAt;
  final String? notes;
  final String? cancellationReason;

  const Booking({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.guestPhone,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.source,
    required this.status,
    required this.paymentStatus,
    required this.totalAmount,
    required this.paidAmount,
    required this.createdAt,
    this.specialRequest,
    this.notes,
    this.cancellationReason,
  });

  double get pendingAmount => totalAmount - paidAmount;
  int get nights {
    final diff = checkOut.difference(checkIn).inDays;
    return diff <= 0 ? 1 : diff;
  }

  Booking copyWith({
    String? guestName,
    String? guestPhone,
    String? roomId,
    String? roomNumber,
    String? roomType,
    DateTime? checkIn,
    DateTime? checkOut,
    int? adults,
    int? children,
    BookingStatus? status,
    PaymentStatus? paymentStatus,
    double? totalAmount,
    double? paidAmount,
    String? specialRequest,
    String? notes,
    String? cancellationReason,
  }) {
    return Booking(
      id: id,
      guestId: guestId,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      roomId: roomId ?? this.roomId,
      roomNumber: roomNumber ?? this.roomNumber,
      roomType: roomType ?? this.roomType,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      adults: adults ?? this.adults,
      children: children ?? this.children,
      source: source,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      createdAt: createdAt,
      specialRequest: specialRequest ?? this.specialRequest,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
