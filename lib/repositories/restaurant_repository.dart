import '../models/restaurant.dart';

abstract class RestaurantRepository {
  // Menu
  Future<List<MenuItem>> getMenuItems();
  Future<List<MenuItem>> getMenuByCategory(String category);
  Future<MenuItem> addMenuItem(Map<String, dynamic> data);
  Future<MenuItem?> updateMenuItem(String id, Map<String, dynamic> data);
  Future<bool> deleteMenuItem(String id);

  // Categories
  Future<List<String>> getCategories();
  Future<String?> addCategory(String name);
  Future<bool> deleteCategory(String name);

  // Tables
  Future<List<RestaurantTable>> getTables();
  Future<RestaurantTable?> addTable(String number, int capacity);
  Future<RestaurantTable?> updateTable(String id, String number, int capacity);
  Future<bool> deleteTable(String id);

  // Orders & Payment
  Future<List<RestaurantOrder>> getOrders();
  Future<RestaurantOrder?> createOrder(RestaurantOrder order);
}

class MockRestaurantRepository implements RestaurantRepository {
  static final List<MenuItem> _menuItems = [];
  static final List<String> _categories = [];
  static final List<RestaurantOrder> _orders = [];
  static final List<RestaurantTable> _tables = [];

  @override
  Future<List<MenuItem>> getMenuItems() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_menuItems);
  }

  @override
  Future<List<MenuItem>> getMenuByCategory(String category) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _menuItems.where((m) => m.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Future<MenuItem> addMenuItem(Map<String, dynamic> data) async {
    final item = MenuItem(
      id: 'm${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '',
      category: data['category']?.toString() ?? 'Main Course',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      isVeg: data['isVeg'] == true,
      description: data['description']?.toString(),
    );
    _menuItems.add(item);
    return item;
  }

  @override
  Future<MenuItem?> updateMenuItem(String id, Map<String, dynamic> data) async {
    final idx = _menuItems.indexWhere((m) => m.id == id);
    if (idx == -1) return null;
    final old = _menuItems[idx];
    final updated = MenuItem(
      id: old.id,
      name: data['name'] ?? old.name,
      category: data['category']?.toString() ?? old.category,
      price: (data['price'] as num?)?.toDouble() ?? old.price,
      isVeg: data['isVeg'] ?? old.isVeg,
      description: data['description'] ?? old.description,
    );
    _menuItems[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteMenuItem(String id) async {
    final idx = _menuItems.indexWhere((m) => m.id == id);
    if (idx == -1) return false;
    _menuItems.removeAt(idx);
    return true;
  }

  @override
  Future<List<String>> getCategories() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_categories);
  }

  @override
  Future<String?> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return null;
    if (!_categories.contains(clean)) _categories.add(clean);
    return clean;
  }

  @override
  Future<bool> deleteCategory(String name) async {
    return _categories.remove(name.trim());
  }

  @override
  Future<List<RestaurantTable>> getTables() async {
    await Future.delayed(const Duration(milliseconds: 50));
    return List.from(_tables);
  }

  @override
  Future<RestaurantTable?> addTable(String number, int capacity) async {
    final t = RestaurantTable(
      id: 'tbl_${DateTime.now().millisecondsSinceEpoch}',
      number: number,
      capacity: capacity,
    );
    _tables.add(t);
    return t;
  }

  @override
  Future<RestaurantTable?> updateTable(String id, String number, int capacity) async {
    final idx = _tables.indexWhere((t) => t.id == id || t.number == id);
    if (idx == -1) return null;
    final updated = RestaurantTable(id: _tables[idx].id, number: number, capacity: capacity);
    _tables[idx] = updated;
    return updated;
  }

  @override
  Future<bool> deleteTable(String id) async {
    final idx = _tables.indexWhere((t) => t.id == id || t.number == id);
    if (idx == -1) return false;
    _tables.removeAt(idx);
    return true;
  }

  @override
  Future<List<RestaurantOrder>> getOrders() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_orders);
  }

  @override
  Future<RestaurantOrder?> createOrder(RestaurantOrder order) async {
    _orders.insert(0, order);
    return order;
  }
}
