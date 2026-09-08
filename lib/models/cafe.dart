class CafeMenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isVeg;
  final String? description;
  final bool isAvailable;

  const CafeMenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.isVeg = true,
    this.description,
    this.isAvailable = true,
  });

  CafeMenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isVeg,
    String? description,
    bool? isAvailable,
  }) {
    return CafeMenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'price': price,
    'isVeg': isVeg,
    'description': description,
    'isAvailable': isAvailable,
  };

  factory CafeMenuItem.fromJson(Map<String, dynamic> json) => CafeMenuItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    category: json['category']?.toString() ?? 'Hot Beverages',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    isVeg: json['isVeg'] != false,
    description: json['description']?.toString(),
    isAvailable: json['isAvailable'] != false,
  );
}

class CafeOrderItem {
  final String id;
  final String name;
  final double price;
  int quantity;
  final bool isVeg;

  CafeOrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.isVeg = true,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'price': price,
    'quantity': quantity,
    'isVeg': isVeg,
  };

  factory CafeOrderItem.fromJson(Map<String, dynamic> json) => CafeOrderItem(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    price: (json['price'] as num?)?.toDouble() ?? 0.0,
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    isVeg: json['isVeg'] != false,
  );
}

class CafeOrder {
  final String id;
  final String orderNumber;
  final String? guestName;
  final List<CafeOrderItem> items;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final bool isPaid;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  const CafeOrder({
    required this.id,
    required this.orderNumber,
    this.guestName,
    required this.items,
    required this.subtotal,
    this.tax = 0.0,
    required this.totalAmount,
    this.isPaid = true,
    this.paymentMethod = 'Cash',
    this.status = 'completed',
    required this.createdAt,
  });

  factory CafeOrder.fromJson(Map<String, dynamic> json) {
    final itemsList = (json['items'] as List?) ?? [];
    return CafeOrder(
      id: json['id']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString() ?? 'CF-000',
      guestName: json['guestName']?.toString() ?? 'Walk-in Guest',
      items: itemsList.map((it) => CafeOrderItem.fromJson(it as Map<String, dynamic>)).toList(),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? (json['total'] as num?)?.toDouble() ?? 0.0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total'] as num?)?.toDouble() ?? 0.0,
      isPaid: json['isPaid'] != false,
      paymentMethod: json['paymentMethod']?.toString() ?? 'Cash',
      status: json['status']?.toString() ?? 'completed',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString())?.toLocal() ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'orderNumber': orderNumber,
    'guestName': guestName,
    'items': items.map((i) => i.toJson()).toList(),
    'subtotal': subtotal,
    'tax': tax,
    'total': totalAmount,
    'isPaid': isPaid,
    'paymentMethod': paymentMethod,
    'status': status,
    'createdAt': createdAt.toIso8601String(),
  };
}
