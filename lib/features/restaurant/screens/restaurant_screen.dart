import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/restaurant.dart';
import '../../../repositories/restaurant_repository.dart';
import '../../../widgets/common_widgets.dart';

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
  String _searchQuery = '';
  final List<OrderItem> _cart = [];
  String? _selectedTableForOrder; // e.g. "Table 1" or "Counter / Walk-in"

  String _getCategoryEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('thali') || lower.contains('meal') || lower.contains('lunch') || lower.contains('dinner')) return '🍱';
    if (lower.contains('snack') || lower.contains('fast') || lower.contains('starter') || lower.contains('chaat')) return '🥟';
    if (lower.contains('chinese') || lower.contains('noodle') || lower.contains('manchurian') || lower.contains('soup')) return '🍜';
    if (lower.contains('roti') || lower.contains('bread') || lower.contains('naan') || lower.contains('paratha')) return '🫓';
    if (lower.contains('rice') || lower.contains('biryani') || lower.contains('pulao')) return '🍚';
    if (lower.contains('paneer') || lower.contains('sabji') || lower.contains('curry') || lower.contains('main')) return '🥘';
    if (lower.contains('drink') || lower.contains('beverage') || lower.contains('cold') || lower.contains('juice') || lower.contains('shake') || lower.contains('lassi')) return '🥤';
    if (lower.contains('tea') || lower.contains('chai') || lower.contains('coffee') || lower.contains('hot')) return '☕';
    if (lower.contains('dessert') || lower.contains('sweet') || lower.contains('ice cream') || lower.contains('cake')) return '🍨';
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

      if (!_categories.contains(_selectedCategory)) {
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
    String category = existing?.category ?? (_selectedCategory.isNotEmpty ? _selectedCategory : (_categories.isNotEmpty ? _categories.first : ''));
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
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
                                Icon(Icons.circle, color: Color(0xFF22C55E), size: 12),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'शाकाहारी (Veg)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFF15803D)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
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
                                Icon(Icons.circle, color: Color(0xFFEF4444), size: 12),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    'मांसाहारी (Non-Veg)',
                                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Color(0xFFB91C1C)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                    children: [
                      const Expanded(
                        child: Text(
                          'ऑर्डर और बिलिंग (Restaurant POS)',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _cart.clear());
                          Navigator.pop(ctx);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                        label: const Text('खाली करें', style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600)),
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
    final phoneCtrl = TextEditingController(text: guestPhone);

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
            const SizedBox(height: 18),

            // WhatsApp Phone Input Field
            TextField(
              controller: phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                labelText: 'व्हाट्सएप नंबर (WhatsApp No.)',
                hintText: '10 अंकों का मोबाइल नंबर',
                prefixIcon: const Icon(Icons.phone, size: 18, color: Color(0xFF25D366)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),

            // WhatsApp Send Button (Replaces Print Bill)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  final ph = phoneCtrl.text.trim();
                  if (ph.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('कृपया ग्राहक का WhatsApp नंबर दर्ज करें'),
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
                    invoiceNo: order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0).toUpperCase(),
                    totalAmount: order.total,
                    roomOrTable: order.tableOrRoom ?? 'Counter',
                    items: order.items.map((i) => '${i.menuItem.name} × ${i.quantity} : ₹${i.total.toStringAsFixed(0)}').toList(),
                    paymentMethod: order.paymentMethod,
                    paymentStatus: 'PAID',
                    date: order.createdAt,
                  );
                },
                icon: const Icon(Icons.chat, size: 20, color: Colors.white),
                label: const Text(
                  'Send WhatsApp (व्हाट्सएप भेजें)',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
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
          tabs: [
            const Tab(icon: Icon(Icons.table_restaurant, size: 20), text: 'टेबल्स (Tables)'),
            const Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'मेन्यू (Menu)'),
            Tab(icon: const Icon(Icons.receipt_long, size: 20), text: 'बिल (${_orders.length})'),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'डाइनिंग टेबल प्रबंधन',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'कुल टेबल: ${_tables.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddEditTableDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'टेबल जोड़ें',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

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
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('पहली टेबल जोड़ें (Add First Table)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            LayoutBuilder(
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
                    childAspectRatio: 0.82,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemCount: _tables.length,
                  itemBuilder: (ctx, i) {
                    final t = _tables[i];
                    final isSelectedForOrder = _selectedTableForOrder == 'Table ${t.number}';

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedTableForOrder = 'Table ${t.number}';
                          });
                          _tabController.animateTo(1);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Table ${t.number} के लिए मेन्यू खुला'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelectedForOrder ? AppColors.primary : AppColors.border.withValues(alpha: 0.8),
                              width: isSelectedForOrder ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelectedForOrder
                                    ? AppColors.primary.withValues(alpha: 0.14)
                                    : Colors.black.withValues(alpha: 0.04),
                                blurRadius: isSelectedForOrder ? 10 : 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Top Row: Table Name & 3-dot Menu
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Table ${t.number}',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          fontFamily: 'Inter',
                                          color: AppColors.textPrimary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.textSecondary, size: 18),
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
                                    ),
                                  ],
                                ),

                                // Middle: Table Icon & Capacity Pill
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.16),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.table_restaurant_rounded,
                                        color: AppColors.primary,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.grey100,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: AppColors.border.withValues(alpha: 0.5),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        '${t.capacity} सीट (${t.capacity} Seater)',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Bottom: Order Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 34,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _selectedTableForOrder = 'Table ${t.number}';
                                      });
                                      _tabController.animateTo(1);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Table ${t.number} के लिए मेन्यू खुला'),
                                          duration: const Duration(seconds: 1),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                                    label: const Text(
                                      'ऑर्डर लें',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: EdgeInsets.zero,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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

    final filtered = _menuItems.where((m) {
      final matchesCategory = _selectedCategory.isEmpty || m.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch = _searchQuery.isEmpty ||
          m.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (m.description ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        // ── Search Input ──
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'व्यंजन या ड्रिंक्स खोजें (Search food, drinks)...',
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.grey50,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ),

        // ── Categories Scroll Bar ──
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.only(bottom: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // 'सभी (All)' chip
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: const Text('सभी (All)'),
                    selected: _selectedCategory.isEmpty,
                    selectedColor: AppColors.primarySurface,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _selectedCategory.isEmpty ? AppColors.primary : AppColors.textPrimary,
                    ),
                    side: BorderSide(color: _selectedCategory.isEmpty ? AppColors.primary : AppColors.border),
                    onSelected: (val) => setState(() => _selectedCategory = ''),
                  ),
                ),
                ..._categories.map((cat) {
                  final isSelected = _selectedCategory.toLowerCase() == cat.toLowerCase();
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InputChip(
                      avatar: Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 13)),
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
                      onPressed: () => setState(() => _selectedCategory = isSelected ? '' : cat),
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
                  label: const Text('+ Category', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  onPressed: _showAddCategoryDialog,
                  backgroundColor: AppColors.primarySurface,
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // ── Category Header & Add Dish Bar ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      _selectedCategory.isEmpty ? '🍽️' : _getCategoryEmoji(_selectedCategory),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _searchQuery.isNotEmpty
                            ? 'खोज परिणाम (${filtered.length})'
                            : _selectedCategory.isEmpty
                                ? 'सभी व्यंजन (${filtered.length})'
                                : '$_selectedCategory (${filtered.length})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _showAddEditMenuItemDialog(),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text(
                  'डिश जोड़ें',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),

        // ── Menu Items List / Grid ──
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
                          _searchQuery.isNotEmpty
                              ? 'कोई डिश नहीं मिली (No matches found)'
                              : _selectedCategory.isNotEmpty
                                  ? '"$_selectedCategory" में कोई डिश नहीं है'
                                  : 'मेन्यू में कोई डिश नहीं है',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        const Text('ऊपर दिए बटन से नई डिश जोड़ें', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
              : _buildRestaurantItemsView(filtered),
        ),
      ],
    );
  }

  Widget _buildRestaurantItemsView(List<MenuItem> filtered) {
    final bottomPad = _cart.isNotEmpty ? 100.0 : 30.0;

    // If search active or specific category chosen
    if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty) {
      return ListView(
        padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPad),
        children: [
          _buildRestaurantGrid(filtered),
        ],
      );
    }

    // Default: Group dishes category-wise!
    final Map<String, List<MenuItem>> grouped = {};
    for (final item in filtered) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPad),
      children: [
        for (final cat in _categories)
          if (grouped.containsKey(cat) && grouped[cat]!.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(cat), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    cat,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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
            _buildRestaurantGrid(grouped[cat]!),
            const SizedBox(height: 8),
          ],
        for (final entry in grouped.entries)
          if (!_categories.contains(entry.key) && entry.value.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Text(_getCategoryEmoji(entry.key), style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                  ),
                  const Spacer(),
                  Text(
                    '${entry.value.length} डिश',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            _buildRestaurantGrid(entry.value),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  Widget _buildRestaurantGrid(List<MenuItem> items) {
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
            childAspectRatio: 1.18,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, idx) {
            final item = items[idx];
            final inCartQty = _getItemCartQty(item.id);

            return InkWell(
              onTap: () => _addToCart(item),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: inCartQty > 0 ? const Color(0xFF16A34A) : AppColors.border,
                    width: inCartQty > 0 ? 1.8 : 1.0,
                  ),
                  boxShadow: inCartQty > 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top: Veg dot, Price & Popup Menu
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: item.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Icon(
                            Icons.circle,
                            size: 7,
                            color: item.isVeg ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          AppFormatters.formatCurrency(item.price),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A)),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
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
                      ],
                    ),
                    const SizedBox(height: 4),
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
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 15, color: Color(0xFF15803D)),
                            SizedBox(width: 4),
                            Text(
                              'जोड़ें',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _removeFromCart(item),
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

  // ───────────────────────────────────────────────────────────────────────────
  // TAB 3: ORDERS & BILLS (PAID BILLS HISTORY)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    final totalRevenue = _orders.fold<double>(0, (sum, o) => sum + o.total);

    return Column(
      children: [
        // Total Revenue & Bill Count Summary Card (Like Cafe)
        Container(
          margin: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDark, AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'कुल रेस्टोरेंट बिक्री (Total Revenue)',
                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    AppFormatters.formatCurrency(totalRevenue),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'कुल बिल',
                      style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_orders.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Orders List or Empty State
        Expanded(
          child: _orders.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
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
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
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
                                      color: AppColors.primary.withValues(alpha: 0.1),
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
                                    onPressed: () => _showBillDetailDialog(o),
                                    icon: const Icon(Icons.receipt_long, size: 14, color: AppColors.primary),
                                    label: const Text('बिल देखें', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.primary),
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
                ),
        ),
      ],
    );
  }

  void _showBillDetailDialog(RestaurantOrder order) {
    final phoneCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'बिल विवरण (Bill Details)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(Icons.close, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(order.tableOrRoom ?? 'Counter', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          'Paid (${order.paymentMethod})',
                          style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Guest: ${order.guestName ?? "Walk-in Guest"}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        Text(AppFormatters.formatTime(order.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text('ऑर्डर आइटम (Items):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              ...order.items.map((it) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${it.menuItem.name} × ${it.quantity}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(it.total),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              )),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('कुल राशि (Total):', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(
                    AppFormatters.formatCurrency(order.total),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // WhatsApp Section Inside Bill View
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
                        Text('WhatsApp पर बिल भेजें:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF15803D))),
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
                        hintText: '10 अंकों का WhatsApp नंबर',
                        prefixIcon: const Icon(Icons.phone, size: 16, color: Color(0xFF25D366)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF25D366))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final ph = phoneCtrl.text.trim();
                          if (ph.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('कृपया 10 अंकों का WhatsApp नंबर दर्ज करें'),
                                backgroundColor: Colors.orange,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          Navigator.pop(ctx);
                          WhatsAppHelper.openWhatsApp(
                            context: context,
                            rawPhone: ph,
                            customerName: order.guestName ?? 'Guest',
                            invoiceNo: order.id.substring(order.id.length > 6 ? order.id.length - 6 : 0).toUpperCase(),
                            totalAmount: order.total,
                            roomOrTable: order.tableOrRoom ?? 'Counter',
                            items: order.items.map((i) => '${i.menuItem.name} × ${i.quantity} : ₹${i.total.toStringAsFixed(0)}').toList(),
                            paymentMethod: order.paymentMethod,
                            paymentStatus: 'PAID',
                            date: order.createdAt,
                          );
                        },
                        icon: const Icon(Icons.chat, size: 18, color: Colors.white),
                        label: const Text('Send WhatsApp (व्हाट्सएप भेजें)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
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
            ],
          ),
        ),
      ),
    );
  }
}
