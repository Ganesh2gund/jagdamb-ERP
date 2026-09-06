enum InventoryCategory {
  food, beverages, housekeeping, bathroomSupplies, kitchen, stationery, other
}

enum InventoryStatus { inStock, lowStock, outOfStock }

extension InventoryCategoryExt on InventoryCategory {
  String get label {
    switch (this) {
      case InventoryCategory.food: return 'Food';
      case InventoryCategory.beverages: return 'Beverages';
      case InventoryCategory.housekeeping: return 'Housekeeping';
      case InventoryCategory.bathroomSupplies: return 'Bathroom Supplies';
      case InventoryCategory.kitchen: return 'Kitchen';
      case InventoryCategory.stationery: return 'Stationery';
      case InventoryCategory.other: return 'Other';
    }
  }
}

extension InventoryStatusExt on InventoryStatus {
  String get label {
    switch (this) {
      case InventoryStatus.inStock: return 'In Stock';
      case InventoryStatus.lowStock: return 'Low Stock';
      case InventoryStatus.outOfStock: return 'Out of Stock';
    }
  }
}

class InventoryItem {
  final String id;
  final String name;
  final InventoryCategory category;
  final double currentStock;
  final double minimumStock;
  final String unit;
  final double? unitPrice;
  final DateTime lastUpdated;
  final List<StockHistory> history;

  const InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentStock,
    required this.minimumStock,
    required this.unit,
    required this.lastUpdated,
    required this.history,
    this.unitPrice,
  });

  InventoryStatus get status {
    if (currentStock <= 0) return InventoryStatus.outOfStock;
    if (currentStock <= minimumStock) return InventoryStatus.lowStock;
    return InventoryStatus.inStock;
  }

  InventoryItem copyWith({
    double? currentStock,
    DateTime? lastUpdated,
    List<StockHistory>? history,
  }) {
    return InventoryItem(
      id: id,
      name: name,
      category: category,
      currentStock: currentStock ?? this.currentStock,
      minimumStock: minimumStock,
      unit: unit,
      unitPrice: unitPrice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      history: history ?? this.history,
    );
  }
}

class StockHistory {
  final String id;
  final double quantity;
  final bool isAddition; // true = added, false = removed
  final DateTime date;
  final String reason;

  const StockHistory({
    required this.id,
    required this.quantity,
    required this.isAddition,
    required this.date,
    required this.reason,
  });
}
