class BanquetHall {
  final String id;
  final String name;
  final int capacity;
  final double baseRentMorning;
  final double baseRentEvening;
  final double baseRentFullDay;
  final List<String> amenities;
  final String? imageUrl;
  final String status;

  const BanquetHall({
    required this.id,
    required this.name,
    this.capacity = 100,
    this.baseRentMorning = 15000,
    this.baseRentEvening = 25000,
    this.baseRentFullDay = 35000,
    this.amenities = const [],
    this.imageUrl,
    this.status = 'available',
  });

  factory BanquetHall.fromJson(Map<String, dynamic> json) {
    return BanquetHall(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 100,
      baseRentMorning: (json['baseRentMorning'] as num?)?.toDouble() ?? 15000.0,
      baseRentEvening: (json['baseRentEvening'] as num?)?.toDouble() ?? 25000.0,
      baseRentFullDay: (json['baseRentFullDay'] as num?)?.toDouble() ?? 35000.0,
      amenities: (json['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      imageUrl: json['imageUrl']?.toString(),
      status: json['status']?.toString() ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'capacity': capacity,
      'baseRentMorning': baseRentMorning,
      'baseRentEvening': baseRentEvening,
      'baseRentFullDay': baseRentFullDay,
      'amenities': amenities,
      'imageUrl': imageUrl,
      'status': status,
    };
  }
}

class BanquetPackage {
  final String id;
  final String name;
  final double pricePerPlate;
  final bool isVeg;
  final String description;
  final List<String> inclusions;

  const BanquetPackage({
    required this.id,
    required this.name,
    this.pricePerPlate = 450,
    this.isVeg = true,
    this.description = '',
    this.inclusions = const [],
  });

  factory BanquetPackage.fromJson(Map<String, dynamic> json) {
    return BanquetPackage(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      pricePerPlate: (json['pricePerPlate'] as num?)?.toDouble() ?? 450.0,
      isVeg: json['isVeg'] != false,
      description: json['description']?.toString() ?? '',
      inclusions: (json['inclusions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'pricePerPlate': pricePerPlate,
      'isVeg': isVeg,
      'description': description,
      'inclusions': inclusions,
    };
  }
}

class BanquetBooking {
  final String id;
  final String bookingNumber;
  final String hallId;
  final String hallName;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String eventType;
  final String eventDate;
  final String slot; // Morning, Evening, Full Day
  final int expectedGuests;
  final String packageId;
  final String packageName;
  final double pricePerPlate;
  final double foodTotal;
  final double hallRent;
  final double extraCharges;
  final double tax;
  final double grandTotal;
  final double advancePaid;
  final double balanceDue;
  final String status; // confirmed, completed, cancelled
  final String notes;
  final String? createdAt;

  const BanquetBooking({
    required this.id,
    required this.bookingNumber,
    required this.hallId,
    required this.hallName,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    this.eventType = 'Wedding',
    required this.eventDate,
    this.slot = 'Evening',
    this.expectedGuests = 100,
    this.packageId = '',
    this.packageName = '',
    this.pricePerPlate = 0,
    this.foodTotal = 0,
    this.hallRent = 0,
    this.extraCharges = 0,
    this.tax = 0,
    this.grandTotal = 0,
    this.advancePaid = 0,
    this.balanceDue = 0,
    this.status = 'confirmed',
    this.notes = '',
    this.createdAt,
  });

  factory BanquetBooking.fromJson(Map<String, dynamic> json) {
    return BanquetBooking(
      id: json['id']?.toString() ?? '',
      bookingNumber: json['bookingNumber']?.toString() ?? '',
      hallId: json['hallId']?.toString() ?? '',
      hallName: json['hallName']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      customerPhone: json['customerPhone']?.toString() ?? '',
      customerEmail: json['customerEmail']?.toString() ?? '',
      eventType: json['eventType']?.toString() ?? 'Wedding',
      eventDate: json['eventDate']?.toString() ?? '',
      slot: json['slot']?.toString() ?? 'Evening',
      expectedGuests: (json['expectedGuests'] as num?)?.toInt() ?? 100,
      packageId: json['packageId']?.toString() ?? '',
      packageName: json['packageName']?.toString() ?? '',
      pricePerPlate: (json['pricePerPlate'] as num?)?.toDouble() ?? 0.0,
      foodTotal: (json['foodTotal'] as num?)?.toDouble() ?? 0.0,
      hallRent: (json['hallRent'] as num?)?.toDouble() ?? 0.0,
      extraCharges: (json['extraCharges'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grandTotal'] as num?)?.toDouble() ?? 0.0,
      advancePaid: (json['advancePaid'] as num?)?.toDouble() ?? 0.0,
      balanceDue: (json['balanceDue'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'confirmed',
      notes: json['notes']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingNumber': bookingNumber,
      'hallId': hallId,
      'hallName': hallName,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'eventType': eventType,
      'eventDate': eventDate,
      'slot': slot,
      'expectedGuests': expectedGuests,
      'packageId': packageId,
      'packageName': packageName,
      'pricePerPlate': pricePerPlate,
      'foodTotal': foodTotal,
      'hallRent': hallRent,
      'extraCharges': extraCharges,
      'tax': tax,
      'grandTotal': grandTotal,
      'advancePaid': advancePaid,
      'balanceDue': balanceDue,
      'status': status,
      'notes': notes,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
