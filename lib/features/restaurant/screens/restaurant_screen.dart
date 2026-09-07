import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/web_printer.dart';
import '../../../models/restaurant.dart';
import '../../../repositories/restaurant_repository.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/whatsapp_button.dart';

class RestaurantScreen extends StatefulWidget {
  const RestaurantScreen({super.key});

  @override
  State<RestaurantScreen> createState() => _RestaurantScreenState();
}

class _RestaurantScreenState extends State<RestaurantScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<RestaurantTable> _tables = [];
  List<String> _categories = [];
  List<MenuItem> _menuItems = [];
  List<RestaurantOrder> _orders = [];

  String _selectedCategory = '';
  final List<OrderItem> _cart = [];
  String? _selectedTableForOrder; // e.g. "Table 1" or "Counter / Walk-in"

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final repo = context.read<RestaurantRepository>();
    final results = await Future.wait([
      repo.getTables(),
      repo.getCategories(),
      repo.getMenuItems(),
      repo.getOrders(),
    ]);

    if (!mounted) return;
    setState(() {
      _tables = results[0] as List<RestaurantTable>;
      _categories = results[1] as List<String>;
      _menuItems = results[2] as List<MenuItem>;
      _orders = results[3] as List<RestaurantOrder>;

      if (_categories.isNotEmpty) {
        if (!_categories.contains(_selectedCategory)) {
          _selectedCategory = _categories.first;
        }
      } else {
        _selectedCategory = '';
      }
      _isLoading = false;
    });
  }

  double get _cartTotal => _cart.fold(0, (s, i) => s + i.total);

  void _addToCart(MenuItem item) {
    final idx = _cart.indexWhere((o) => o.menuItem.id == item.id);
    setState(() {
      if (idx >= 0) {
        _cart[idx].quantity++;
      } else {
        _cart.add(OrderItem(menuItem: item, quantity: 1));
      }
    });
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "${item.name}" to cart'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeFromCart(MenuItem item) {
    final idx = _cart.indexWhere((o) => o.menuItem.id == item.id);
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

  int _getItemCartQty(String itemId) {
    final it = _cart.where((o) => o.menuItem.id == itemId).firstOrNull;
    return it?.quantity ?? 0;
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 1. TABLE CRUD DIALOGS
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _showAddEditTableDialog([RestaurantTable? existing]) async {
    final isEdit = existing != null;
    final numCtrl = TextEditingController(text: existing?.number ?? '');
    final capCtrl = TextEditingController(text: existing != null ? existing.capacity.toString() : '4');
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) {
          final currentCap = int.tryParse(capCtrl.text) ?? 4;
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 12, 20,
              MediaQuery.of(ctx2).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top drag pill
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grey300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.table_restaurant, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isEdit ? 'टेबल एडिट करें (Edit Table)' : 'नई टेबल जोड़ें (Add Table)',
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isEdit ? 'टेबल नंबर और बैठने की क्षमता बदलें' : 'रेस्टोरेंट में नई डाइनिंग टेबल दर्ज करें',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Table Number Input
                    const Text('टेबल नंबर (Table Number)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: numCtrl,
                      autofocus: !isEdit,
                      decoration: InputDecoration(
                        hintText: 'उदा. 1, 2, 10, T-5',
                        prefixIcon: const Icon(Icons.pin, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'टेबल नंबर दर्ज करें' : null,
                    ),
                    const SizedBox(height: 16),

                    // Seating Capacity Input
                    const Text('बैठने की क्षमता (Seating Capacity)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: capCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModal(() {}),
                      decoration: InputDecoration(
                        hintText: 'उदा. 2, 4, 6, 8',
                        prefixIcon: const Icon(Icons.event_seat, color: AppColors.primary),
                        suffixText: 'सीटें (Seats)',
                        filled: true,
                        fillColor: AppColors.grey50,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'क्षमता दर्ज करें';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'वैध संख्या दर्ज करें';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick capacity selector chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [2, 4, 6, 8, 10].map((capVal) {
                          final isSel = currentCap == capVal;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text('$capVal सीटें'),
                              selected: isSel,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSel ? Colors.white : AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                              backgroundColor: AppColors.grey100,
                              onSelected: (_) {
                                capCtrl.text = capVal.toString();
                                setModal(() {});
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final number = numCtrl.text.trim();
                          final cap = int.parse(capCtrl.text.trim());
                          Navigator.pop(ctx);

                          final repo = context.read<RestaurantRepository>();
                          if (isEdit) {
                            await repo.updateTable(existing.id, number, cap);
                          } else {
                            await repo.addTable(number, cap);
                          }
                          await _loadData();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isEdit ? '✅ Table $number अपडेट हो गई!' : '✅ Table $number सफलतापूर्वक जुड़ गई!'),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.success,
                            ),
                          );
                        },
                        icon: Icon(isEdit ? Icons.check_circle_outline : Icons.add, size: 20),
                        label: Text(
                          isEdit ? 'अपडेट करें (Save Changes)' : 'टेबल सुरक्षित करें (Save Table)',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteTable(RestaurantTable t) async {
    final ok = await _showConfirmDeleteSheet(
      title: 'Table ${t.number} हटाएं?',
      message: 'क्या आप सचमुच Table ${t.number} को हटाना चाहते हैं?',
      confirmText: 'हाँ, हटाएं (Delete)',
    );

    if (ok == true) {
      final repo = context.read<RestaurantRepository>();
      await repo.deleteTable(t.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ Table ${t.number} हटा दी गई'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 2. CATEGORY CRUD DIALOGS
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _showAddCategoryDialog() async {
    final catCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 12, 20,
            MediaQuery.of(ctx2).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.category_rounded, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('नई कैटेगरी जोड़ें (Add Category)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                            SizedBox(height: 2),
                            Text('व्यंजनों का वर्गीकरण (जैसे Thali, Snacks)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Text('कैटेगरी का नाम (Category Name)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: catCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'उदा. Chinese, Thali, Snacks, Drinks',
                      prefixIcon: const Icon(Icons.bookmark_outline, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'कैटेगरी नाम दर्ज करें' : null,
                  ),
                  const SizedBox(height: 12),

                  // Suggestion chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: ['Thali', 'Snacks', 'Chinese', 'Main Course', 'Beverages', 'Desserts'].map((sug) {
                      return ActionChip(
                        label: Text(sug, style: const TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.grey100,
                        onPressed: () {
                          catCtrl.text = sug;
                          setModal(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final name = catCtrl.text.trim();
                        Navigator.pop(ctx);
                        final repo = context.read<RestaurantRepository>();
                        await repo.addCategory(name);
                        setState(() {
                          _selectedCategory = name;
                        });
                        await _loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('✅ Category "$name" जोड़ दी गई'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 20),
                      label: const Text('कैटेगरी जोड़ें (Save Category)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(String name) async {
    final ok = await _showConfirmDeleteSheet(
      title: 'Category "$name" हटाएं?',
      message: 'क्या आप सचमुच category "$name" को हटाना चाहते हैं?',
      confirmText: 'हाँ, हटाएं (Delete)',
    );

    if (ok == true) {
      final repo = context.read<RestaurantRepository>();
      await repo.deleteCategory(name);
      setState(() {
        _categories.remove(name);
        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
      await _loadData();
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. MENU ITEM CRUD DIALOGS
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _showAddEditMenuItemDialog([MenuItem? existing]) async {
    if (_categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('कृपया पहले कम से कम एक कैटेगरी जोड़ें (Please add a category first)'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _showAddCategoryDialog();
      return;
    }

    final isEdit = existing != null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final priceCtrl = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    bool isVeg = existing?.isVeg ?? true;
    String category = existing?.category ?? _selectedCategory;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 12, 20,
            MediaQuery.of(ctx2).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEdit ? 'डिश एडिट करें (Edit Dish)' : 'नई डिश जोड़ें (Add Dish)',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isEdit ? 'डिश का नाम, कीमत या कैटेगरी बदलें' : 'मेन्यू में नया खाद्य पदार्थ जोड़ें',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Veg / Non-veg selector cards
                  const Text('व्यंजन का प्रकार (Food Type)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModal(() => isVeg = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: isVeg ? const Color(0xFFDCFCE7) : AppColors.grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isVeg ? const Color(0xFF22C55E) : AppColors.border,
                                width: isVeg ? 1.5 : 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, color: Color(0xFF22C55E), size: 14),
                                SizedBox(width: 8),
                                Text('शाकाहारी (Veg)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF15803D))),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setModal(() => isVeg = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                            decoration: BoxDecoration(
                              color: !isVeg ? const Color(0xFFFEE2E2) : AppColors.grey50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: !isVeg ? const Color(0xFFEF4444) : AppColors.border,
                                width: !isVeg ? 1.5 : 1,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.circle, color: Color(0xFFEF4444), size: 14),
                                SizedBox(width: 8),
                                Text('मांसाहारी (Non-Veg)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFFB91C1C))),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dish Name
                  const Text('डिश का नाम (Dish Name)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      hintText: 'उदा. Paneer Butter Masala, Roti, Dal Tadka',
                      prefixIcon: const Icon(Icons.fastfood_outlined, color: AppColors.primary),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'डिश का नाम दर्ज करें' : null,
                  ),
                  const SizedBox(height: 16),

                  // Price & Category in row
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('कीमत (Price ₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'उदा. 180',
                                prefixText: '₹ ',
                                prefixStyle: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                                filled: true,
                                fillColor: AppColors.grey50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'कीमत दर्ज करें';
                                final p = double.tryParse(v);
                                if (p == null || p < 0) return 'अवैध कीमत';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Category
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('कैटेगरी (Category)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              value: _categories.contains(category) ? category : (_categories.isNotEmpty ? _categories.first : null),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.grey50,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)))).toList(),
                              onChanged: (v) {
                                if (v != null) setModal(() => category = v);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  const Text('विवरण (Description - Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'उदा. Rich gravy with butter and fresh paneer',
                      prefixIcon: const Icon(Icons.notes_outlined, color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.grey50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final name = nameCtrl.text.trim();
                        final price = double.parse(priceCtrl.text.trim());
                        final desc = descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim();
                        Navigator.pop(ctx);

                        final repo = context.read<RestaurantRepository>();
                        final payload = {
                          'name': name,
                          'price': price,
                          'category': category,
                          'isVeg': isVeg,
                          'description': desc,
                        };

                        if (isEdit) {
                          await repo.updateMenuItem(existing.id, payload);
                        } else {
                          await repo.addMenuItem(payload);
                        }
                        await _loadData();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit ? '✅ "$name" अपडेट हो गया' : '✅ "$name" मेन्यू में जोड़ दिया गया'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(isEdit ? Icons.check_circle_outline : Icons.add, size: 20),
                      label: Text(
                        isEdit ? 'डिश अपडेट करें (Save Changes)' : 'डिश सुरक्षित करें (Save Dish)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteMenuItem(MenuItem item) async {
    final ok = await _showConfirmDeleteSheet(
      title: '"${item.name}" हटाएं?',
      message: 'क्या आप सचमुच "${item.name}" को मेन्यू से हटाना चाहते हैं?',
      confirmText: 'हाँ, हटाएं (Delete)',
    );

    if (ok == true) {
      final repo = context.read<RestaurantRepository>();
      await repo.deleteMenuItem(item.id);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('🗑️ "${item.name}" हटा दी गई'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<bool?> _showConfirmDeleteSheet({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: AppColors.errorLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('रद्द करें (Cancel)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(confirmText, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. CART & DIRECT PAYMENT SHEET
  // ───────────────────────────────────────────────────────────────────────────
  void _showCartSheet() {
    String selectedTarget = _selectedTableForOrder ?? (_tables.isNotEmpty ? 'Table ${_tables.first.number}' : 'Counter / Walk-in');
    String paymentMethod = 'Cash';
    final guestNameCtrl = TextEditingController();
    final guestPhoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setModal) {
          final subtotal = _cartTotal;
          final targetOptions = [
            'Counter / Walk-in (काउंटर)',
            ..._tables.map((t) => 'Table ${t.number}'),
          ];

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 16, 20,
              MediaQuery.of(ctx2).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44, height: 5,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ऑर्डर और बिलिंग (Restaurant POS)',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _cart.clear());
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('खाली करें (Clear)', style: TextStyle(color: AppColors.error, fontSize: 12)),
                      ),
                    ],
                  ),
                  const Divider(),

                  // ── Target (Table or Counter) ──
                  const Text('ऑर्डर किसके लिए है? (Order For):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: targetOptions.contains(selectedTarget) ? selectedTarget : targetOptions.first,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      prefixIcon: Icon(Icons.place),
                    ),
                    items: targetOptions.map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                    onChanged: (v) {
                      if (v != null) setModal(() => selectedTarget = v);
                    },
                  ),
                  const SizedBox(height: 14),

                  // ── Cart Items List ──
                  const Text('चयनित व्यंजन (Selected Items):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: _cart.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 12, color: item.menuItem.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.menuItem.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _removeFromCart(item.menuItem);
                                      setModal(() {});
                                      if (_cart.isEmpty) Navigator.pop(ctx);
                                    },
                                    icon: const Icon(Icons.remove_circle_outline, size: 20, color: AppColors.textSecondary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      _addToCart(item.menuItem);
                                      setModal(() {});
                                    },
                                    icon: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                AppFormatters.formatCurrency(item.total),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Optional guest details
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: guestNameCtrl,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'ग्राहक का नाम (Optional)',
                            hintText: 'Guest Name',
                            prefixIcon: Icon(Icons.person, size: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: guestPhoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'मोबाइल नंबर (Optional)',
                            hintText: 'Phone for WhatsApp',
                            prefixIcon: Icon(Icons.phone, size: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Direct Payment Method Choice ──
                  const Text('सीधा भुगतान माध्यम (Payment Method):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['Cash', 'UPI / QR', 'Card'].map((m) {
                      final isSel = paymentMethod == m;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setModal(() => paymentMethod = m),
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSel ? AppColors.primary : AppColors.grey100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                            ),
                            child: Center(
                              child: Text(
                                m,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSel ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Total Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('कुल राशि (Grand Total):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                      Text(
                        AppFormatters.formatCurrency(subtotal),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Confirm & Settle Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_cart.isEmpty) return;
                        Navigator.pop(ctx);
                        final guestName = guestNameCtrl.text.trim().isEmpty ? 'Walk-in Guest' : guestNameCtrl.text.trim();
                        final guestPhone = guestPhoneCtrl.text.trim();
                        final orderItemsCopy = List<OrderItem>.from(_cart);
                        final finalTotal = subtotal;

                        final newOrder = RestaurantOrder(
                          id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
                          tableOrRoom: selectedTarget,
                          guestName: guestName,
                          items: orderItemsCopy,
                          createdAt: DateTime.now(),
                          isPaid: true,
                          paymentMethod: paymentMethod,
                          totalAmount: finalTotal,
                        );

                        final repo = context.read<RestaurantRepository>();
                        await repo.createOrder(newOrder);

                        setState(() {
                          _cart.clear();
                          _selectedTableForOrder = null;
                        });
                        _loadData();

                        if (!mounted) return;
                        _showOrderSuccessDialog(newOrder, guestPhone);
                      },
                      icon: const Icon(Icons.check_circle_rounded, size: 22),
                      label: Text(
                        '✅ Collect ${AppFormatters.formatCurrency(subtotal)} ($paymentMethod Paid)',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showOrderSuccessDialog(RestaurantOrder order, String guestPhone) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'भुगतान सफल! (Payment Successful)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 6),
            Text(
              '${order.tableOrRoom} • ${order.paymentMethod} से भुगतान प्राप्त हुआ',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            Text(
              AppFormatters.formatCurrency(order.total),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
            const SizedBox(height: 20),

            // Print Receipt
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  WebPrinter.printRestaurantReceipt(
                    orderId: order.id.substring(order.id.length > 8 ? order.id.length - 8 : 0).toUpperCase(),
                    tableOrCounter: order.tableOrRoom ?? 'Counter',
                    items: order.items.map((i) => {
                      'name': i.menuItem.name,
                      'price': i.menuItem.price,
                      'quantity': i.quantity,
                    }).toList(),
                    totalAmount: order.total,
                    paymentMethod: order.paymentMethod,
                    guestName: order.guestName,
                  );
                },
                icon: const Icon(Icons.print, size: 18),
                label: const Text('🖨️ रसीद प्रिंट करें (Print Bill)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // WhatsApp button if phone provided or prompt
            if (guestPhone.isNotEmpty)
              WhatsAppSendChip(
                phone: guestPhone,
                guestName: order.guestName ?? 'Guest',
                invoiceNumber: order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0).toUpperCase(),
                totalAmount: order.total,
              ),

            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('ओके (Done)'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // MAIN SCAFFOLD & TABS
  // ───────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Restaurant & POS (रेस्टोरेंट)'),
        actions: [
          IconButton(
            tooltip: 'रिफ्रेश (Refresh)',
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          tabs: const [
            Tab(icon: Icon(Icons.table_restaurant, size: 20), text: 'टेबल्स (Tables)'),
            Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'मेन्यू (Menu)'),
            Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'बिल (Bills)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTablesTab(),
          _buildMenuTab(),
          _buildOrdersTab(),
        ],
      ),
      floatingActionButton: _cart.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCartSheet,
              icon: const Icon(Icons.shopping_cart_rounded),
              label: Text(
                'Cart (${_cart.fold<int>(0, (s, i) => s + i.quantity)}) • ${AppFormatters.formatCurrency(_cartTotal)}',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 1: TABLES
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTablesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'डाइनिंग टेबल प्रबंधन',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'कुल टेबल: ${_tables.length}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddEditTableDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('टेबल जोड़ें', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_tables.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    const Icon(Icons.table_restaurant_outlined, size: 60, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text('कोई टेबल नहीं जोड़ी गई है (No Tables Added)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 6),
                    const Text('ऊपर दिए बटन से नई टेबल जोड़ें', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditTableDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('पहली टेबल जोड़ें (Add First Table)'),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tables.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (ctx, i) {
                final t = _tables[i];
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      // Table Icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.table_restaurant, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: 12),

                      // Table Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Table ${t.number}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${t.capacity} सीटें (${t.capacity} Seater)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Order Button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedTableForOrder = 'Table ${t.number}';
                          });
                          _tabController.animateTo(1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Selected Table ${t.number} for ordering'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.add_shopping_cart, size: 14),
                        label: const Text('ऑर्डर', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                      const SizedBox(width: 4),

                      // More Actions (Edit / Delete)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, color: AppColors.textSecondary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onSelected: (val) {
                          if (val == 'edit') _showAddEditTableDialog(t);
                          if (val == 'delete') _deleteTable(t);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                SizedBox(width: 8),
                                Text('एडिट करें (Edit)'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                SizedBox(width: 8),
                                Text('हटाएं (Delete)', style: TextStyle(color: AppColors.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 2: MENU & ORDER (POS)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMenuTab() {
    if (_categories.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 14),
              const Text(
                'कोई कैटेगरी नहीं है (No Categories Yet)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'मेन्यू में डिश जोड़ने से पहले एक कैटेगरी बनाएं (जैसे: Thali, Snacks, Chinese, Drinks)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: _showAddCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('+ पहली कैटेगरी जोड़ें (Add Category)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final filtered = _menuItems.where((m) => m.category.toLowerCase() == _selectedCategory.toLowerCase()).toList();

    return Column(
      children: [
        // ── Categories Scroll Bar ──
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ..._categories.map((cat) {
                  final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isSelected ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.grey100,
                      onPressed: () => setState(() => _selectedCategory = cat),
                      onDeleted: () => _deleteCategory(cat),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 14,
                        color: isSelected ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                  );
                }),
                ActionChip(
                  avatar: const Icon(Icons.add, size: 16, color: AppColors.primary),
                  label: const Text('+ Category (कैटेगरी जोड़ें)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  onPressed: _showAddCategoryDialog,
                  backgroundColor: AppColors.primarySurface,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Category Header with Add Dish Button ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$_selectedCategory (${filtered.length})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddEditMenuItemDialog(),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('डिश जोड़ें', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),

        // ── Menu Items List ──
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.fastfood_outlined, size: 50, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text(
                          '"$_selectedCategory" में कोई डिश नहीं है',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text('ऊपर दिए बटन से इस कैटेगरी में डिश जोड़ें', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () => _showAddEditMenuItemDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('डिश जोड़ें (Add Food Item)'),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    final inCartQty = _getItemCartQty(item.id);

                    return AppCard(
                      child: Row(
                        children: [
                          // Veg / Non-veg indicator
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: item.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444), width: 1.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: item.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (item.description != null && item.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.formatCurrency(item.price),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                          ),

                          // Edit / Delete PopupMenu
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onSelected: (val) {
                              if (val == 'edit') _showAddEditMenuItemDialog(item);
                              if (val == 'delete') _deleteMenuItem(item);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                    SizedBox(width: 8),
                                    Text('एडिट करें (Edit)'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                    SizedBox(width: 8),
                                    Text('हटाएं (Delete)', style: TextStyle(color: AppColors.error)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),

                          // Cart Add / Quantity control
                          if (inCartQty == 0)
                            ElevatedButton(
                              onPressed: () => _addToCart(item),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('+ Add', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF16A34A)),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () => _removeFromCart(item),
                                    icon: const Icon(Icons.remove, size: 16, color: Color(0xFF16A34A)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                  Text(
                                    '$inCartQty',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF16A34A), fontSize: 13),
                                  ),
                                  IconButton(
                                    onPressed: () => _addToCart(item),
                                    icon: const Icon(Icons.add, size: 16, color: Color(0xFF16A34A)),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3: ORDERS & BILLS (PAID BILLS HISTORY)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.textSecondary),
              SizedBox(height: 12),
              Text('कोई बिल इतिहास नहीं है (No Orders Yet)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              SizedBox(height: 6),
              Text('मेन्यू से ऑर्डर लेकर पेमेंट सेटल करने पर बिल यहाँ दिखाई देंगे', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final o = _orders[i];
        final itemCount = o.items.fold<int>(0, (s, it) => s + it.quantity);

        return AppCard(
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
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          o.tableOrRoom ?? 'Counter',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '#${o.id.substring(o.id.length > 6 ? o.id.length - 6 : 0).toUpperCase()}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Paid (${o.paymentMethod})',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF16A34A)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (o.guestName != null && o.guestName!.isNotEmpty) ...[
                Text('Guest: ${o.guestName}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
              ],
              Text(
                o.items.map((it) => '${it.menuItem.name} × ${it.quantity}').join(', '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemCount Items • ${AppFormatters.formatTime(o.createdAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppFormatters.formatCurrency(o.total),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          WebPrinter.printRestaurantReceipt(
                            orderId: o.id.substring(o.id.length > 8 ? o.id.length - 8 : 0).toUpperCase(),
                            tableOrCounter: o.tableOrRoom ?? 'Counter',
                            items: o.items.map((it) => {
                              'name': it.menuItem.name,
                              'price': it.menuItem.price,
                              'quantity': it.quantity,
                            }).toList(),
                            totalAmount: o.total,
                            paymentMethod: o.paymentMethod,
                            guestName: o.guestName,
                          );
                        },
                        icon: const Icon(Icons.print, size: 14),
                        label: const Text('प्रिंट', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
