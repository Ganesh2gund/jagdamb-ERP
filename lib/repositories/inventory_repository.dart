import '../models/inventory.dart';

abstract class InventoryRepository {
  Future<List<InventoryItem>> getItems();
  Future<List<InventoryItem>> getLowStockItems();
  Future<void> addStock(String id, double quantity, String reason);
  Future<void> removeStock(String id, double quantity, String reason);
  Future<void> createItem(InventoryItem item);
}

class MockInventoryRepository implements InventoryRepository {
  final List<InventoryItem> _items = [];

  @override
  Future<List<InventoryItem>> getItems() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_items);
  }

  @override
  Future<List<InventoryItem>> getLowStockItems() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _items.where((i) => i.status != InventoryStatus.inStock).toList();
  }

  @override
  Future<void> addStock(String id, double quantity, String reason) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      final history = List<StockHistory>.from(item.history)
        ..add(StockHistory(
          id: 'sh${DateTime.now().millisecondsSinceEpoch}',
          quantity: quantity, isAddition: true,
          date: DateTime.now(), reason: reason,
        ));
      _items[idx] = item.copyWith(
        currentStock: item.currentStock + quantity,
        lastUpdated: DateTime.now(),
        history: history,
      );
    }
  }

  @override
  Future<void> removeStock(String id, double quantity, String reason) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      final item = _items[idx];
      final history = List<StockHistory>.from(item.history)
        ..add(StockHistory(
          id: 'sh${DateTime.now().millisecondsSinceEpoch}',
          quantity: quantity, isAddition: false,
          date: DateTime.now(), reason: reason,
        ));
      _items[idx] = item.copyWith(
        currentStock: (item.currentStock - quantity).clamp(0, double.infinity),
        lastUpdated: DateTime.now(),
        history: history,
      );
    }
  }

  @override
  Future<void> createItem(InventoryItem item) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _items.add(item);
  }
}
