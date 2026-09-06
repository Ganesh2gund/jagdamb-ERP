class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final String? description;
  final bool isVeg;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isVeg,
    this.description,
  });

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    double? price,
    bool? isVeg,
    String? description,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      isVeg: isVeg ?? this.isVeg,
      description: description ?? this.description,
    );
  }
}

class OrderItem {
  final MenuItem menuItem;
  int quantity;
  final String? notes;

  OrderItem({
    required this.menuItem,
    required this.quantity,
    this.notes,
  });

  double get total => menuItem.price * quantity;
}

class RestaurantOrder {
  final String id;
  final String? tableOrRoom; // "Table 1" or "Counter / Walk-in"
  final String? guestName;
  final List<OrderItem> items;
  final DateTime createdAt;
  final bool isPaid;
  final String paymentMethod; // Cash, UPI, Card
  final double totalAmount;

  const RestaurantOrder({
    required this.id,
    required this.items,
    required this.createdAt,
    this.tableOrRoom,
    this.guestName,
    this.isPaid = true,
    this.paymentMethod = 'Cash',
    this.totalAmount = 0.0,
  });

  double get total => totalAmount > 0 ? totalAmount : items.fold(0, (sum, item) => sum + item.total);
}

class RestaurantTable {
  final String id;
  final String number; // "1", "2", "T1"
  final int capacity;

  const RestaurantTable({
    required this.id,
    required this.number,
    required this.capacity,
  });

  RestaurantTable copyWith({
    String? id,
    String? number,
    int? capacity,
  }) {
    return RestaurantTable(
      id: id ?? this.id,
      number: number ?? this.number,
      capacity: capacity ?? this.capacity,
    );
  }
}
