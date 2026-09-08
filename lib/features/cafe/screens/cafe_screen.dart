import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/cafe.dart';
import '../../../repositories/cafe_repository.dart';

class CafeScreen extends StatefulWidget {
  const CafeScreen({super.key});

  @override
  State<CafeScreen> createState() => _CafeScreenState();
}

class _CafeScreenState extends State<CafeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<String> _categories = [];
  List<CafeMenuItem> _menuItems = [];
  List<CafeOrder> _orders = [];

  String _selectedCategory = '';
  String _searchQuery = '';
  String _menuSelectedCategory = '';
  String _menuSearchQuery = '';
  final List<CafeOrderItem> _cart = [];
  String _paymentMethod = 'Cash';
  final TextEditingController _guestNameController = TextEditingController();

  // Color theme constants for Cafe
  static const Color _amberDark = Color(0xFF78350F);
  static const Color _amberPrimary = Color(0xFFD97706);
  static const Color _amberLight = Color(0xFFFEF3C7);
  static const Color _amberBorder = Color(0xFFFDE68A);

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('hot') || lower.contains('tea') || lower.contains('chai') || lower.contains('coffee')) return '☕';
    if (lower.contains('cold') || lower.contains('drink') || lower.contains('juice') || lower.contains('beverage') || lower.contains('shake')) return '🥤';
    if (lower.contains('snack') || lower.contains('fast') || lower.contains('burger') || lower.contains('sandwich') || lower.contains('pizza') || lower.contains('fries')) return '🍔';
    if (lower.contains('sweet') || lower.contains('dessert') || lower.contains('cake') || lower.contains('bakery') || lower.contains('pastry')) return '🍰';
    if (lower.contains('meal') || lower.contains('thali') || lower.contains('lunch') || lower.contains('dinner') || lower.contains('roti')) return '🍱';
    return '🍽️';
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _guestNameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = context.read<CafeRepository>();
    final results = await Future.wait([
      repo.getCategories(),
      repo.getMenuItems(),
      repo.getOrders(),
    ]);

    if (!mounted) return;
    setState(() {
      _categories = results[0] as List<String>;
      _menuItems = results[1] as List<CafeMenuItem>;
      _orders = results[2] as List<CafeOrder>;

      if (!_categories.contains(_selectedCategory)) {
        _selectedCategory = '';
      }
      if (!_categories.contains(_menuSelectedCategory)) {
        _menuSelectedCategory = '';
      }
      _isLoading = false;
    });
  }

  double get _cartTotal => _cart.fold(0.0, (s, i) => s + i.total);
  int get _cartItemCount => _cart.fold(0, (s, i) => s + i.quantity);

  void _addToCart(CafeMenuItem item) {
    final idx = _cart.indexWhere((o) => o.id == item.id);
    setState(() {
      if (idx >= 0) {
        _cart[idx].quantity++;
      } else {
        _cart.add(CafeOrderItem(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
          isVeg: item.isVeg,
        ));
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ "${item.name}" added to order'),
        duration: const Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _amberDark,
      ),
    );
  }

  void _removeFromCart(String itemId) {
    final idx = _cart.indexWhere((o) => o.id == itemId);
    if (idx >= 0) {
      setState(() {
        if (_cart[idx].quantity > 1) {
          _cart[idx].quantity--;
        } else {
          _cart.removeAt(idx);
        }
      });
    }
  }

  void _clearCart() {
    setState(() {
      _cart.clear();
      _guestNameController.clear();
      _paymentMethod = 'Cash';
    });
  }

  Future<void> _processCheckout() async {
    if (_cart.isEmpty) return;

    final repo = context.read<CafeRepository>();
    final total = _cartTotal;
    final guestName = _guestNameController.text.trim().isEmpty ? 'Walk-in Guest' : _guestNameController.text.trim();

    final orderPayload = {
      'guestName': guestName,
      'items': _cart.map((i) => i.toJson()).toList(),
      'subtotal': total,
      'total': total,
      'isPaid': true,
      'paymentMethod': _paymentMethod,
    };

    final createdOrder = await repo.createOrder(orderPayload);
    if (!mounted) return;

    if (createdOrder != null) {
      final savedCart = List<CafeOrderItem>.from(_cart);
      _clearCart();
      await _loadData();

      // Show success receipt dialog
      if (mounted) {
        _showOrderSuccessDialog(createdOrder, savedCart);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save order'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _showOrderSuccessDialog(CafeOrder order, List<CafeOrderItem> items) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(18),
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: _amberLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle_rounded, color: _amberPrimary, size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Order Completed!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bill #${order.orderNumber}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _amberDark),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            AppFormatters.formatCurrency(order.totalAmount),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Method:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text('${order.paymentMethod} (Paid)', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // WhatsApp Section Inside Success Dialog
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                          SizedBox(width: 6),
                          Text('Send Bill via WhatsApp:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          hintText: '10-digit WhatsApp number',
                          prefixIcon: const Icon(Icons.phone, size: 16, color: Color(0xFF25D366)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF25D366))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final ph = phoneCtrl.text.trim();
                            if (ph.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a 10-digit WhatsApp number'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            WhatsAppHelper.openWhatsApp(
                              context: context,
                              rawPhone: ph,
                              customerName: order.guestName ?? 'Guest',
                              invoiceNo: order.orderNumber,
                              totalAmount: order.totalAmount,
                              roomOrTable: 'Cafe Counter',
                              items: items.map((i) => '${i.name} × ${i.quantity} : ₹${i.total.toStringAsFixed(0)}').toList(),
                              paymentMethod: order.paymentMethod,
                              paymentStatus: 'PAID',
                              date: order.createdAt,
                            );
                          },
                          icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                          label: const Text('Send Bill via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _amberPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('New Order', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: _amberLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.local_cafe_rounded, color: _amberDark, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cafe Jagdamb',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                Text(
                  'Express Counter POS',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _amberPrimary,
          labelColor: _amberDark,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              icon: const Icon(Icons.point_of_sale_rounded, size: 20),
              text: _cart.isEmpty ? 'Fast POS' : 'POS (${_cartItemCount})',
            ),
            const Tab(
              icon: Icon(Icons.menu_book_rounded, size: 20),
              text: 'Menu',
            ),
            Tab(
              icon: const Icon(Icons.receipt_long_rounded, size: 20),
              text: 'Bills (${_orders.length})',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _amberPrimary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPosTab(),
                _buildMenuTab(),
                _buildBillsTab(),
              ],
            ),
      bottomSheet: (_tabController.index == 0 && _cart.isNotEmpty) ? _buildCartBottomBar() : null,
    );
  }

  // ==========================================
  // TAB 1: FAST BILLING (POS)
  // ==========================================
  Widget _buildPosTab() {
    final filtered = _menuItems.where((item) {
      final matchesCategory = _selectedCategory.isEmpty || item.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        // Search & Category selector
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // Search input
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search coffee, snacks, items...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.surfaceVariant.withOpacity(0.5),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Category chips
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategory.isEmpty,
                        selectedColor: _amberLight,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: _selectedCategory.isEmpty ? FontWeight.bold : FontWeight.normal,
                          color: _selectedCategory.isEmpty ? _amberDark : AppColors.textSecondary,
                        ),
                        side: BorderSide(color: _selectedCategory.isEmpty ? _amberPrimary : Colors.transparent),
                        onSelected: (val) => setState(() => _selectedCategory = ''),
                      ),
                    ),
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          avatar: Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 13)),
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: _amberLight,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? _amberDark : AppColors.textSecondary,
                          ),
                          side: BorderSide(color: isSelected ? _amberPrimary : Colors.transparent),
                          onSelected: (val) => setState(() => _selectedCategory = cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Items Display
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.coffee_maker_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text('No items found', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    ],
                  ),
                )
              : _buildPosItemsView(filtered),
        ),
      ],
    );
  }

  Widget _buildPosItemsView(List<CafeMenuItem> filtered) {
    final bottomPad = _cart.isNotEmpty ? 110.0 : 24.0;

    // If search is active or a single category is explicitly selected:
    if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
        children: [
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Search Results: ${filtered.length} items',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else if (_selectedCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(_selectedCategory), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '$_selectedCategory (${filtered.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _amberDark),
                  ),
                ],
              ),
            ),
          _buildPosGrid(filtered),
        ],
      );
    }

    // Default: Group items category-wise!
    final Map<String, List<CafeMenuItem>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomPad),
      children: [
        for (final cat in _categories)
          if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _amberLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amberBorder),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _amberPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${grouped[cat]!.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            _buildPosGrid(grouped[cat]!),
            const SizedBox(height: 8),
          ],
        for (final entry in grouped.entries)
          if (!_categories.contains(entry.key) && entry.value.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _amberLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amberBorder),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(entry.key), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.length} items',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _amberDark),
                  ),
                ],
              ),
            ),
            _buildPosGrid(entry.value),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildPosGrid(List<CafeMenuItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 800) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 550) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.22,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            final inCartIdx = _cart.indexWhere((c) => c.id == item.id);
            final inCartQty = inCartIdx >= 0 ? _cart[inCartIdx].quantity : 0;

            return InkWell(
              onTap: () => _addToCart(item),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: inCartQty > 0 ? _amberPrimary : AppColors.border,
                    width: inCartQty > 0 ? 1.8 : 1.0,
                  ),
                  boxShadow: inCartQty > 0
                      ? [
                          BoxShadow(
                            color: _amberPrimary.withOpacity(0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Veg dot & Price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            border: Border.all(color: item.isVeg ? Colors.green : Colors.red, width: 1.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 7,
                            color: item.isVeg ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          AppFormatters.formatCurrency(item.price),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Item Name
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                    ),
                    // Bottom Add or Stepper
                    if (inCartQty == 0)
                      Container(
                        height: 28,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _amberLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _amberBorder),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 15, color: _amberDark),
                            SizedBox(width: 4),
                            Text(
                              'Add',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _amberDark),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: _amberPrimary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _removeFromCart(item.id),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.remove_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                            Text(
                              '$inCartQty',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                            ),
                            InkWell(
                              onTap: () => _addToCart(item),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: Icon(Icons.add_rounded, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Sticky bottom cart preview bar
  Widget _buildCartBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_cartItemCount items | ${AppFormatters.formatCurrency(_cartTotal)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _amberDark),
                ),
                const Text('Express Counter Billing', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              icon: const Icon(Icons.shopping_bag_outlined, size: 18),
              label: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _amberPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _openCheckoutModal,
            ),
          ],
        ),
      ),
    );
  }

  // Full Checkout bottom sheet
  void _openCheckoutModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cart Summary',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton(
                    onPressed: () {
                      _clearCart();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Clear Cart', style: TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],
              ),
              const Divider(),
              // Items list
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _cart.length,
                  itemBuilder: (context, idx) {
                    final it = _cart[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(it.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                Text('₹${it.price.toStringAsFixed(0)} x ${it.quantity}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 20, color: _amberDark),
                                onPressed: () {
                                  _removeFromCart(it.id);
                                  setModalState(() {});
                                  setState(() {});
                                  if (_cart.isEmpty) Navigator.pop(ctx);
                                },
                              ),
                              Text('${it.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, size: 20, color: _amberDark),
                                onPressed: () {
                                  final item = _menuItems.firstWhere((m) => m.id == it.id);
                                  _addToCart(item);
                                  setModalState(() {});
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              AppFormatters.formatCurrency(it.total),
                              textAlign: TextAlign.end,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(),
              // Customer Name input (optional)
              TextField(
                controller: _guestNameController,
                decoration: InputDecoration(
                  labelText: 'Customer Name (Optional)',
                  hintText: 'e.g. Rahul Sharma / Walk-in Guest',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant.withOpacity(0.4),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
              ),
              const SizedBox(height: 14),
              // Payment method selector
              const Text('Payment Method:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: ['Cash', 'UPI', 'Card'].map((pm) {
                  final isSelected = _paymentMethod == pm;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setModalState(() => _paymentMethod = pm);
                          setState(() => _paymentMethod = pm);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? _amberLight : AppColors.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSelected ? _amberPrimary : AppColors.border, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              pm == 'Cash' ? '💵 Cash' : pm == 'UPI' ? '📱 UPI' : '💳 Card',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? _amberDark : AppColors.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              // Grand Total & Submit Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Payable:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  Text(
                    AppFormatters.formatCurrency(_cartTotal),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _amberDark),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_rounded, size: 20),
                  label: const Text('Settle & Print Bill', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amberPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _processCheckout();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: MENU MANAGEMENT
  // ==========================================
  Widget _buildMenuTab() {
    final menuFiltered = _menuItems.where((item) {
      final matchesCategory = _menuSelectedCategory.isEmpty || item.category == _menuSelectedCategory;
      final matchesSearch = _menuSearchQuery.isEmpty ||
          item.name.toLowerCase().contains(_menuSearchQuery.toLowerCase()) ||
          (item.description ?? '').toLowerCase().contains(_menuSearchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _amberPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openDishDialog(),
      ),
      body: Column(
        children: [
          // Search Bar in Menu Tab
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            child: TextField(
              onChanged: (val) => setState(() => _menuSearchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search menu items...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
                suffixIcon: _menuSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => setState(() => _menuSearchQuery = ''),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surfaceVariant.withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Category Management Bar
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(Icons.category_outlined, size: 18, color: _amberDark),
                const SizedBox(width: 8),
                const Text('Categories:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 16, color: _amberDark),
                  label: const Text('New Category', style: TextStyle(color: _amberDark, fontWeight: FontWeight.bold, fontSize: 12)),
                  onPressed: _openAddCategoryDialog,
                ),
              ],
            ),
          ),

          // Horizontal Category list with 'All' and category chips
          Container(
            height: 44,
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 6),
                  child: ChoiceChip(
                    label: const Text('All'),
                    selected: _menuSelectedCategory.isEmpty,
                    selectedColor: _amberLight,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: _menuSelectedCategory.isEmpty ? FontWeight.bold : FontWeight.normal,
                      color: _menuSelectedCategory.isEmpty ? _amberDark : AppColors.textSecondary,
                    ),
                    side: BorderSide(color: _menuSelectedCategory.isEmpty ? _amberPrimary : Colors.transparent),
                    onSelected: (val) => setState(() => _menuSelectedCategory = ''),
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = _menuSelectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 6),
                    child: InputChip(
                      avatar: Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 13)),
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: _amberLight,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? _amberDark : AppColors.textPrimary,
                      ),
                      side: BorderSide(color: isSelected ? _amberPrimary : AppColors.border),
                      onPressed: () => setState(() => _menuSelectedCategory = isSelected ? '' : cat),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => _confirmDeleteCategory(cat),
                    ),
                  );
                }),
              ],
            ),
          ),
          const Divider(height: 1),

          // Menu Items Display
          Expanded(
            child: menuFiltered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.4)),
                        const SizedBox(height: 10),
                        const Text('No items found', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      ],
                    ),
                  )
                : _buildMenuItemsList(menuFiltered),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemsList(List<CafeMenuItem> filtered) {
    if (_menuSelectedCategory.isNotEmpty || _menuSearchQuery.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          if (_menuSearchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Search Results: ${filtered.length} items found',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else if (_menuSelectedCategory.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(_menuSelectedCategory), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '$_menuSelectedCategory (${filtered.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _amberDark),
                  ),
                ],
              ),
            ),
          for (final item in filtered) _buildMenuItemCard(item),
        ],
      );
    }

    // Default: Grouped by Category!
    final Map<String, List<CafeMenuItem>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        for (final cat in _categories)
          if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _amberLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amberBorder),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _amberPrimary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${grouped[cat]!.length}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            for (final item in grouped[cat]!) _buildMenuItemCard(item),
          ],
        for (final entry in grouped.entries)
          if (!_categories.contains(entry.key) && entry.value.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _amberLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amberBorder),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(entry.key), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.length} items',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _amberDark),
                  ),
                ],
              ),
            ),
            for (final item in entry.value) _buildMenuItemCard(item),
          ],
      ],
    );
  }

  Widget _buildMenuItemCard(CafeMenuItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              border: Border.all(color: item.isVeg ? Colors.green : Colors.red, width: 1.5),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              Icons.circle,
              size: 8,
              color: item.isVeg ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category,
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                if (item.description != null && item.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  AppFormatters.formatCurrency(item.price),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () => _openDishDialog(item: item),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(),
                onPressed: () => _confirmDeleteDish(item),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. Cold Coffee, Shakes...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _amberPrimary),
            onPressed: () async {
              final val = controller.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx);
                final repo = context.read<CafeRepository>();
                await repo.addCategory(val);
                _loadData();
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$name" category?', style: const TextStyle(fontSize: 16)),
        content: const Text('All items in this category will also be removed from menu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = context.read<CafeRepository>();
              await repo.deleteCategory(name);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openDishDialog({CafeMenuItem? item}) {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final priceCtrl = TextEditingController(text: item != null ? item.price.toStringAsFixed(0) : '');
    final descCtrl = TextEditingController(text: item?.description ?? '');
    String category = item?.category ?? (_categories.isNotEmpty ? _categories.first : 'Hot Beverages');
    bool isVeg = item?.isVeg ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? 'Add Cafe Item' : 'Edit Item',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Item Name *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price (₹) *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categories.contains(category) ? category : (_categories.isNotEmpty ? _categories.first : null),
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => category = val);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Vegetarian (Veg)?', style: TextStyle(fontSize: 14)),
                  value: isVeg,
                  activeThumbColor: Colors.green,
                  onChanged: (val) => setDialogState(() => isVeg = val),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _amberPrimary),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty || price <= 0) return;

                Navigator.pop(ctx);
                final repo = context.read<CafeRepository>();
                final payload = {
                  'name': name,
                  'price': price,
                  'category': category,
                  'description': descCtrl.text.trim(),
                  'isVeg': isVeg,
                };

                if (item == null) {
                  await repo.addMenuItem(payload);
                } else {
                  await repo.updateMenuItem(item.id, payload);
                }
                _loadData();
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteDish(CafeMenuItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${item.name}"?', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              final repo = context.read<CafeRepository>();
              await repo.deleteMenuItem(item.id);
              _loadData();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: BILLS HISTORY
  // ==========================================
  Widget _buildBillsTab() {
    final totalCafeRevenue = _orders.fold(0.0, (s, o) => s + o.totalAmount);

    return Column(
      children: [
        // Summary Header Card
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_amberDark, _amberPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: _amberPrimary.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Cafe Revenue', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatCurrency(totalCafeRevenue),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text('Total Bills', style: TextStyle(color: Colors.white70, fontSize: 11)),
                    Text(
                      '${_orders.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Order list
        Expanded(
          child: _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.receipt_outlined, size: 56, color: AppColors.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text('No bills generated yet', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  itemCount: _orders.length,
                  itemBuilder: (context, index) {
                    final ord = _orders[index];
                    final dateStr = AppFormatters.formatDate(ord.createdAt);
                    final timeStr = AppFormatters.formatTime(ord.createdAt);
                    final itemsSummary = ord.items.map((i) => '${i.quantity}x ${i.name}').join(', ');

                    return InkWell(
                      onTap: () => _showBillDetailsDialog(ord),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _amberLight,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        ord.orderNumber,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _amberDark),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      ord.guestName ?? 'Walk-in Guest',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Text(
                                  AppFormatters.formatCurrency(ord.totalAmount),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _amberDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              itemsSummary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$dateStr $timeStr • ${ord.paymentMethod}',
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      icon: const Icon(Icons.receipt_long_outlined, size: 14, color: _amberDark),
                                      label: const Text('View Bill', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _amberDark)),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: _amberPrimary),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        minimumSize: const Size(0, 30),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      onPressed: () => _showBillDetailsDialog(ord),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showBillDetailsDialog(CafeOrder order) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _amberLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: _amberBorder),
                            ),
                            child: Text(
                              order.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _amberDark),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'Cafe Bill',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Guest & Date info card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Customer: ${order.guestName ?? "Walk-in Guest"}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppFormatters.formatDateTime(order.createdAt),
                            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Status:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          Text(
                            '${order.paymentMethod} (PAID)',
                            style: const TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Order Items list
                const Text('Order Items:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                ...order.items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${it.name} × ${it.quantity}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppFormatters.formatCurrency(it.total),
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                )),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    Text(
                      AppFormatters.formatCurrency(order.totalAmount),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: _amberDark),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // WhatsApp Section Inside Bill View Dialog
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF25D366).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF25D366).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                          SizedBox(width: 6),
                          Text('Send Bill via WhatsApp:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          hintText: '10-digit WhatsApp number',
                          prefixIcon: const Icon(Icons.phone, size: 16, color: Color(0xFF25D366)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF25D366))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 40,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final ph = phoneCtrl.text.trim();
                            if (ph.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a 10-digit WhatsApp number'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }
                            WhatsAppHelper.openWhatsApp(
                              context: context,
                              rawPhone: ph,
                              customerName: order.guestName ?? 'Guest',
                              invoiceNo: order.orderNumber,
                              totalAmount: order.totalAmount,
                              roomOrTable: 'Cafe Counter',
                              items: order.items.map((i) => '${i.name} × ${i.quantity} : ₹${i.total.toStringAsFixed(0)}').toList(),
                              paymentMethod: order.paymentMethod,
                              paymentStatus: 'PAID',
                              date: order.createdAt,
                            );
                          },
                          icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                          label: const Text('Send Bill via WhatsApp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
