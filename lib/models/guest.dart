class Guest {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? address;
  final String? idType;
  final String? idNumber;
  final int totalVisits;
  final double totalSpent;
  final DateTime? lastStay;
  final DateTime createdAt;
  final List<String> bookingIds;
  final String? preferences;
  final String? notes;
  final bool isVip;

  const Guest({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.totalVisits,
    required this.totalSpent,
    required this.createdAt,
    required this.bookingIds,
    this.address,
    this.idType,
    this.idNumber,
    this.lastStay,
    this.preferences,
    this.notes,
    this.isVip = false,
  });

  bool get isReturning => totalVisits > 1;

  Guest copyWith({
    int? totalVisits,
    double? totalSpent,
    DateTime? lastStay,
    List<String>? bookingIds,
    String? notes,
  }) {
    return Guest(
      id: id,
      name: name,
      phone: phone,
      email: email,
      address: address,
      idType: idType,
      idNumber: idNumber,
      totalVisits: totalVisits ?? this.totalVisits,
      totalSpent: totalSpent ?? this.totalSpent,
      lastStay: lastStay ?? this.lastStay,
      createdAt: createdAt,
      bookingIds: bookingIds ?? this.bookingIds,
      preferences: preferences,
      notes: notes ?? this.notes,
      isVip: isVip,
    );
  }
}
