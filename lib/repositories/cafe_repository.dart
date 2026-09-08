import 'dart:developer' as dev;
import '../models/cafe.dart';
import '../services/api_client.dart';

abstract class CafeRepository {
  // Menu
  Future<List<CafeMenuItem>> getMenuItems();
  Future<List<CafeMenuItem>> getMenuByCategory(String category);
  Future<CafeMenuItem?> addMenuItem(Map<String, dynamic> data);
  Future<CafeMenuItem?> updateMenuItem(String id, Map<String, dynamic> data);
  Future<bool> deleteMenuItem(String id);

  // Categories
  Future<List<String>> getCategories();
  Future<String?> addCategory(String name);
  Future<bool> deleteCategory(String name);

  // Orders & Billing
  Future<List<CafeOrder>> getOrders();
  Future<CafeOrder?> createOrder(Map<String, dynamic> data);
}

class MockCafeRepository implements CafeRepository {
  static final List<String> _categories = [
    'Hot Beverages',
    'Cold Beverages',
    'Snacks & Fast Food',
    'Bakery & Desserts',
  ];

  static final List<CafeMenuItem> _menuItems = [
    const CafeMenuItem(id: 'cf_1', name: 'Espresso Coffee', category: 'Hot Beverages', price: 60, isVeg: true),
    const CafeMenuItem(id: 'cf_2', name: 'Cappuccino', category: 'Hot Beverages', price: 90, isVeg: true),
    const CafeMenuItem(id: 'cf_3', name: 'Masala Chai', category: 'Hot Beverages', price: 30, isVeg: true),
    const CafeMenuItem(id: 'cf_4', name: 'Cold Coffee with Ice Cream', category: 'Cold Beverages', price: 120, isVeg: true),
    const CafeMenuItem(id: 'cf_5', name: 'Iced Lemon Tea', category: 'Cold Beverages', price: 80, isVeg: true),
    const CafeMenuItem(id: 'cf_6', name: 'Fresh Lime Soda', category: 'Cold Beverages', price: 60, isVeg: true),
    const CafeMenuItem(id: 'cf_7', name: 'Grilled Cheese Sandwich', category: 'Snacks & Fast Food', price: 110, isVeg: true),
    const CafeMenuItem(id: 'cf_8', name: 'French Fries (Peri Peri)', category: 'Snacks & Fast Food', price: 90, isVeg: true),
    const CafeMenuItem(id: 'cf_9', name: 'Veg Club Sandwich', category: 'Snacks & Fast Food', price: 130, isVeg: true),
    const CafeMenuItem(id: 'cf_10', name: 'Chocolate Brownie with Ice Cream', category: 'Bakery & Desserts', price: 140, isVeg: true),
    const CafeMenuItem(id: 'cf_11', name: 'Butter Croissant', category: 'Bakery & Desserts', price: 80, isVeg: true),
  ];

  static final List<CafeOrder> _orders = [];

  @override
  Future<List<CafeMenuItem>> getMenuItems() async {
    return List.from(_menuItems);
  }

  @override
  Future<List<CafeMenuItem>> getMenuByCategory(String category) async {
    return _menuItems.where((m) => m.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Future<CafeMenuItem?> addMenuItem(Map<String, dynamic> data) async {
    final item = CafeMenuItem(
      id: 'cf_${DateTime.now().millisecondsSinceEpoch}',
      name: data['name'] ?? '',
      category: data['category']?.toString() ?? 'Hot Beverages',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      isVeg: data['isVeg'] != false,
      description: data['description']?.toString(),
      isAvailable: data['isAvailable'] != false,
    );
    _menuItems.add(item);
    return item;
  }

  @override
  Future<CafeMenuItem?> updateMenuItem(String id, Map<String, dynamic> data) async {
    final idx = _menuItems.indexWhere((m) => m.id == id);
    if (idx != -1) {
      final updated = _menuItems[idx].copyWith(
        name: data['name'],
        category: data['category'],
        price: (data['price'] as num?)?.toDouble(),
        isVeg: data['isVeg'],
        description: data['description'],
        isAvailable: data['isAvailable'],
      );
      _menuItems[idx] = updated;
      return updated;
    }
    return null;
  }

  @override
  Future<bool> deleteMenuItem(String id) async {
    final count = _menuItems.length;
    _menuItems.removeWhere((m) => m.id == id);
    return _menuItems.length < count;
  }

  @override
  Future<List<String>> getCategories() async {
    return List.from(_categories);
  }

  @override
  Future<String?> addCategory(String name) async {
    if (!_categories.contains(name)) {
      _categories.add(name);
    }
    return name;
  }

  @override
  Future<bool> deleteCategory(String name) async {
    _categories.remove(name);
    _menuItems.removeWhere((m) => m.category == name);
    return true;
  }

  @override
  Future<List<CafeOrder>> getOrders() async {
    return List.from(_orders);
  }

  @override
  Future<CafeOrder?> createOrder(Map<String, dynamic> data) async {
    final itemsData = (data['items'] as List?) ?? [];
    final items = itemsData.map((it) {
      final m = it as Map<String, dynamic>;
      return CafeOrderItem(
        id: m['id']?.toString() ?? '',
        name: m['name']?.toString() ?? '',
        price: (m['price'] as num?)?.toDouble() ?? 0.0,
        quantity: (m['quantity'] as num?)?.toInt() ?? 1,
        isVeg: m['isVeg'] != false,
      );
    }).toList();

    final double subtotal = (data['subtotal'] as num?)?.toDouble() ??
        items.fold<double>(0.0, (sum, it) => sum + it.total);
    final double total = (data['total'] as num?)?.toDouble() ?? subtotal;

    final order = CafeOrder(
      id: 'cf_ord_${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: 'CF-${(_orders.length + 1).toString().padLeft(3, '0')}',
      guestName: data['guestName']?.toString() ?? 'Walk-in Guest',
      items: items,
      subtotal: subtotal,
      totalAmount: total,
      isPaid: data['isPaid'] != false,
      paymentMethod: data['paymentMethod']?.toString() ?? 'Cash',
      status: 'completed',
      createdAt: DateTime.now(),
    );
    _orders.insert(0, order);
    return order;
  }
}

class HttpCafeRepository implements CafeRepository {
  final ApiClient _api = ApiClient.instance;
  final MockCafeRepository _fallback = MockCafeRepository();

  CafeMenuItem _menuFromMap(Map<String, dynamic> m) {
    return CafeMenuItem.fromJson(m);
  }

  CafeOrder _orderFromMap(Map<String, dynamic> m) {
    return CafeOrder.fromJson(m);
  }

  @override
  Future<List<CafeMenuItem>> getMenuItems() async {
    try {
      final res = await _api.get('/cafe/menu');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _menuFromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Error fetching cafe menu: $e');
    }
    return _fallback.getMenuItems();
  }

  @override
  Future<List<CafeMenuItem>> getMenuByCategory(String category) async {
    final all = await getMenuItems();
    return all.where((m) => m.category.toLowerCase() == category.toLowerCase()).toList();
  }

  @override
  Future<CafeMenuItem?> addMenuItem(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/cafe/menu', body: data);
      if (res is Map && res['data'] is Map) {
        return _menuFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error adding cafe menu item: $e');
    }
    return _fallback.addMenuItem(data);
  }

  @override
  Future<CafeMenuItem?> updateMenuItem(String id, Map<String, dynamic> data) async {
    try {
      final res = await _api.put('/cafe/menu/$id', body: data);
      if (res is Map && res['data'] is Map) {
        return _menuFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error updating cafe menu item: $e');
    }
    return _fallback.updateMenuItem(id, data);
  }

  @override
  Future<bool> deleteMenuItem(String id) async {
    try {
      final res = await _api.delete('/cafe/menu/$id');
      if (res is Map && res['success'] == true) return true;
    } catch (e) {
      dev.log('Error deleting cafe menu item: $e');
    }
    return _fallback.deleteMenuItem(id);
  }

  @override
  Future<List<String>> getCategories() async {
    try {
      final res = await _api.get('/cafe/categories');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((c) {
          if (c is Map) return c['name']?.toString() ?? '';
          return c.toString();
        }).where((s) => s.isNotEmpty).toList();
      }
    } catch (e) {
      dev.log('Error fetching cafe categories: $e');
    }
    return _fallback.getCategories();
  }

  @override
  Future<String?> addCategory(String name) async {
    try {
      final res = await _api.post('/cafe/categories', body: {'name': name});
      if (res is Map && res['data'] != null) {
        final d = res['data'];
        return d is Map ? (d['name']?.toString() ?? name) : d.toString();
      }
    } catch (e) {
      dev.log('Error adding cafe category: $e');
    }
    return _fallback.addCategory(name);
  }

  @override
  Future<bool> deleteCategory(String name) async {
    try {
      final res = await _api.delete('/cafe/categories/${Uri.encodeComponent(name)}');
      if (res is Map && res['success'] == true) return true;
    } catch (e) {
      dev.log('Error deleting cafe category: $e');
    }
    return _fallback.deleteCategory(name);
  }

  @override
  Future<List<CafeOrder>> getOrders() async {
    try {
      final res = await _api.get('/cafe/orders');
      if (res is Map && res['data'] is List) {
        return (res['data'] as List).map((m) => _orderFromMap(m as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      dev.log('Error fetching cafe orders: $e');
    }
    return _fallback.getOrders();
  }

  @override
  Future<CafeOrder?> createOrder(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/cafe/orders', body: data);
      if (res is Map && res['data'] is Map) {
        return _orderFromMap(res['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      dev.log('Error creating cafe order: $e');
    }
    return _fallback.createOrder(data);
  }
}
