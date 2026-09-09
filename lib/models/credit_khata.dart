class CreditPayment {
  final double amount;
  final String paymentMethod;
  final DateTime paidAt;
  final String notes;

  CreditPayment({
    required this.amount,
    required this.paymentMethod,
    required this.paidAt,
    this.notes = '',
  });

  factory CreditPayment.fromJson(Map<String, dynamic> json) {
    return CreditPayment(
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'] ?? 'Cash',
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'amount': amount,
        'paymentMethod': paymentMethod,
        'paidAt': paidAt.toIso8601String(),
        'notes': notes,
      };
}

class CreditKhata {
  final String id;
  final String billNumber;
  final String customerName;
  final String customerPhone;
  final String description;
  final double totalAmount;
  final double paidAmount;
  final double balanceAmount;
  final String status;
  final List<CreditPayment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  CreditKhata({
    required this.id,
    required this.billNumber,
    required this.customerName,
    required this.customerPhone,
    this.description = 'Food & Dining Credit',
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.balanceAmount,
    this.status = 'pending',
    this.payments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSettled => status == 'paid' || balanceAmount <= 0;
  bool get isPartial => status == 'partially_paid' && balanceAmount > 0;
  bool get isPending => status == 'pending';

  factory CreditKhata.fromJson(Map<String, dynamic> json) {
    final paymentsList = (json['payments'] as List?)
            ?.map((p) => CreditPayment.fromJson(Map<String, dynamic>.from(p)))
            .toList() ??
        [];

    final total = (json['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final paid = (json['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final balance = (json['balanceAmount'] as num?)?.toDouble() ?? (total - paid).clamp(0.0, double.infinity);

    return CreditKhata(
      id: json['id']?.toString() ?? '',
      billNumber: json['billNumber']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? 'Customer',
      customerPhone: json['customerPhone']?.toString() ?? '',
      description: json['description']?.toString() ?? 'Food & Dining Credit',
      totalAmount: total,
      paidAmount: paid,
      balanceAmount: balance,
      status: json['status']?.toString() ?? 'pending',
      payments: paymentsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'billNumber': billNumber,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'description': description,
        'totalAmount': totalAmount,
        'paidAmount': paidAmount,
        'balanceAmount': balanceAmount,
        'status': status,
        'payments': payments.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
