enum PaymentMethod { cash, upi, card, bankTransfer, other }

extension PaymentMethodExt on PaymentMethod {
  String get label {
    switch (this) {
      case PaymentMethod.cash: return 'Cash';
      case PaymentMethod.upi: return 'UPI';
      case PaymentMethod.card: return 'Card';
      case PaymentMethod.bankTransfer: return 'Bank Transfer';
      case PaymentMethod.other: return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case PaymentMethod.cash: return '💵';
      case PaymentMethod.upi: return '📱';
      case PaymentMethod.card: return '💳';
      case PaymentMethod.bankTransfer: return '🏦';
      case PaymentMethod.other: return '💰';
    }
  }
}

enum PaymentType { roomCharge, restaurantCharge, roomService, laundry, extraBed, other }

extension PaymentTypeExt on PaymentType {
  String get label {
    switch (this) {
      case PaymentType.roomCharge: return 'Room Charge';
      case PaymentType.restaurantCharge: return 'Restaurant';
      case PaymentType.roomService: return 'Room Service';
      case PaymentType.laundry: return 'Laundry';
      case PaymentType.extraBed: return 'Extra Bed';
      case PaymentType.other: return 'Other Services';
    }
  }
}

class Payment {
  final String id;
  final String guestId;
  final String guestName;
  final String? bookingId;
  final String? invoiceId;
  final double amount;
  final PaymentMethod method;
  final PaymentType type;
  final DateTime date;
  final String status; // 'paid', 'pending', 'partial'
  final String? notes;
  final double? pendingAmount;

  const Payment({
    required this.id,
    required this.guestId,
    required this.guestName,
    required this.amount,
    required this.method,
    required this.type,
    required this.date,
    required this.status,
    this.bookingId,
    this.invoiceId,
    this.notes,
    this.pendingAmount,
  });
}

class BillItem {
  final String description;
  final PaymentType type;
  final double amount;
  final int quantity;

  const BillItem({
    required this.description,
    required this.type,
    required this.amount,
    this.quantity = 1,
  });

  double get total => amount * quantity;
}

class Bill {
  final String id;
  final String bookingId;
  final String guestId;
  final String guestName;
  final String roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final List<BillItem> items;
  final double discount;
  final double taxRate;
  final double paidAmount;
  final DateTime generatedAt;

  const Bill({
    required this.id,
    required this.bookingId,
    required this.guestId,
    required this.guestName,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.items,
    required this.discount,
    required this.taxRate,
    required this.paidAmount,
    required this.generatedAt,
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.total);
  double get discountAmount => subtotal * (discount / 100);
  double get taxableAmount => subtotal - discountAmount;
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get grandTotal => taxableAmount + taxAmount;
  double get pendingAmount => grandTotal - paidAmount;
}
