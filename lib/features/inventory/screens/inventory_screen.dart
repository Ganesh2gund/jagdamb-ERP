import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/inventory.dart';
import '../../../repositories/inventory_repository.dart';
import '../../../widgets/common_widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  bool _isLoading = true;
  List<InventoryItem> _items = [];
  InventoryCategory? _selectedCategory;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<InventoryRepository>();
    final items = await repo.getItems();
    if (!mounted) return;
    setState(() { _items = items; _isLoading = false; });
  }

  List<InventoryItem> get _filtered {
    return _items.where((i) {
      final matchesCat = _selectedCategory == null || i.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || i.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCat && matchesSearch;
    }).toList();
  }

  int get _lowStockCount => _items.where((i) => i.status != InventoryStatus.inStock).length;

  Color _statusColor(InventoryStatus s) {
    switch (s) {
      case InventoryStatus.inStock: return AppColors.success;
      case InventoryStatus.lowStock: return AppColors.warning;
      case InventoryStatus.outOfStock: return AppColors.error;
    }
  }

  void _showStockAction(InventoryItem item, bool isAdd) {
    final controller = TextEditingController();
    final reasonController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${isAdd ? 'Add' : 'Remove'} Stock — ${item.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
          const SizedBox(height: 8),
          Text('Current: ${item.currentStock} ${item.unit}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
          const SizedBox(height: 16),
          TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Quantity (${item.unit})')),
          const SizedBox(height: 12),
          TextField(controller: reasonController, decoration: const InputDecoration(labelText: 'Reason')),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 48, child: ElevatedButton(
            onPressed: () async {
              final qty = double.tryParse(controller.text) ?? 0;
              if (qty <= 0) return;
              Navigator.pop(ctx);
              final repo = context.read<InventoryRepository>();
              if (isAdd) await repo.addStock(item.id, qty, reasonController.text.isEmpty ? 'Stock added' : reasonController.text);
              else await repo.removeStock(item.id, qty, reasonController.text.isEmpty ? 'Stock removed' : reasonController.text);
              await _load();
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stock updated for ${item.name}'), behavior: SnackBarBehavior.floating));
            },
            style: ElevatedButton.styleFrom(backgroundColor: isAdd ? AppColors.success : AppColors.error),
            child: Text(isAdd ? 'Add Stock' : 'Remove Stock'),
          )),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          if (_lowStockCount > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.warningLight,
              child: Text('⚠️ $_lowStockCount item(s) need restocking', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.warning, fontFamily: 'Inter')),
            ),
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: AppSearchBar(controller: _searchController, hintText: 'Search items...', onChanged: (v) => setState(() => _searchQuery = v)),
          ),
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(children: [
              _FilterChip(label: 'All', isSelected: _selectedCategory == null, onTap: () => setState(() => _selectedCategory = null)),
              ...InventoryCategory.values.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _FilterChip(label: c.label, isSelected: _selectedCategory == c, onTap: () => setState(() => _selectedCategory = c)),
              )),
            ]),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(icon: Icons.inventory_2, title: 'No items found')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      final statusColor = _statusColor(item.status);
                      return AppCard(
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Text(item.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                              const SizedBox(width: 8),
                              StatusBadge(label: item.status.label, color: statusColor, fontSize: 10),
                            ]),
                            const SizedBox(height: 3),
                            Text('${item.currentStock} ${item.unit} (Min: ${item.minimumStock} ${item.unit})', style: TextStyle(fontSize: 12, color: item.status != InventoryStatus.inStock ? statusColor : AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                            Text(item.category.label, style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'Inter')),
                          ])),
                          Column(children: [
                            GestureDetector(onTap: () => _showStockAction(item, true), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, color: AppColors.success, size: 18))),
                            const SizedBox(height: 6),
                            GestureDetector(onTap: () => _showStockAction(item, false), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, color: AppColors.error, size: 18))),
                          ]),
                        ]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : Colors.transparent, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? AppColors.primary : AppColors.textSecondary, fontFamily: 'Inter')),
      ),
    );
  }
}
