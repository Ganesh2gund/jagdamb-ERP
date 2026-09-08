import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/banquet.dart';
import '../../../repositories/banquet_repository.dart';
import '../../../widgets/common_widgets.dart';
import 'new_banquet_booking_screen.dart';
import 'banquet_detail_screen.dart';

class BanquetScreen extends StatefulWidget {
  const BanquetScreen({super.key});

  @override
  State<BanquetScreen> createState() => _BanquetScreenState();
}

class _BanquetScreenState extends State<BanquetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BanquetRepository _repository = HttpBanquetRepository();

  bool _isLoading = true;
  List<BanquetHall> _halls = [];
  List<BanquetPackage> _packages = [];
  List<BanquetBooking> _bookings = [];
  String _bookingFilter = 'all';

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
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _repository.getHalls(),
        _repository.getPackages(),
        _repository.getBookings(),
      ]);
      if (mounted) {
        setState(() {
          _halls = results[0] as List<BanquetHall>;
          _packages = results[1] as List<BanquetPackage>;
          _bookings = results[2] as List<BanquetBooking>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Banquet & Events'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.event_note), text: 'Bookings'),
            Tab(icon: Icon(Icons.meeting_room_outlined), text: 'Halls'),
            Tab(icon: Icon(Icons.restaurant_menu_outlined), text: 'Packages'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBookingsTab(),
                _buildHallsTab(),
                _buildPackagesTab(),
              ],
            ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget? _buildFab() {
    return FloatingActionButton.extended(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: Text(
        _tabController.index == 0
            ? 'New Booking'
            : _tabController.index == 1
                ? 'Add Hall'
                : 'Add Package',
      ),
      onPressed: () async {
        if (_tabController.index == 0) {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const NewBanquetBookingScreen()),
          );
          if (res == true) _loadData();
        } else if (_tabController.index == 1) {
          _openAddHallDialog();
        } else {
          _openAddPackageDialog();
        }
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 1: BOOKINGS
  // ══════════════════════════════════════════════════════════════════
  Widget _buildBookingsTab() {
    final filtered = _bookings.where((b) {
      if (_bookingFilter == 'all') return b.status.toLowerCase() != 'cancelled';
      return b.status.toLowerCase() == _bookingFilter.toLowerCase();
    }).toList();

    final totalRevenue = _bookings.fold<double>(0, (sum, b) => b.status != 'cancelled' ? sum + b.grandTotal : sum);
    final totalAdvance = _bookings.fold<double>(0, (sum, b) => b.status != 'cancelled' ? sum + b.advancePaid : sum);
    final totalPending = _bookings.fold<double>(0, (sum, b) => b.status != 'cancelled' ? sum + b.balanceDue : sum);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Metrics Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF334155)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Banquet Revenue & Events',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetricCol('Total Booking', AppFormatters.currency(totalRevenue)),
                    _buildMetricCol('Advance Recd.', AppFormatters.currency(totalAdvance)),
                    _buildMetricCol('Pending Due', AppFormatters.currency(totalPending)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('All (${_bookings.where((b) => b.status.toLowerCase() != 'cancelled').length})', 'all'),
                const SizedBox(width: 8),
                _filterChip('Confirmed', 'confirmed'),
                const SizedBox(width: 8),
                _filterChip('Completed', 'completed'),
                const SizedBox(width: 8),
                _filterChip('Cancelled', 'cancelled'),
              ],
            ),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  const Text('No bookings found', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            )
          else
            ...filtered.map((b) => _buildBookingCard(b)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String filterKey) {
    final isSelected = _bookingFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _bookingFilter = filterKey),
      selectedColor: AppColors.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }

  Widget _buildBookingCard(BanquetBooking b) {
    Color statusColor;
    switch (b.status.toLowerCase()) {
      case 'completed':
        statusColor = AppColors.success;
        break;
      case 'cancelled':
        statusColor = AppColors.error;
        break;
      default:
        statusColor = AppColors.primary;
    }

    final isSettled = b.balanceDue <= 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BanquetDetailScreen(bookingId: b.id)),
        ).then((_) => _loadData());
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Client Name, Hall Name & Status Badge
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.customerName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${b.hallName} • ${b.eventType}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                StatusBadge(
                  label: b.status.toUpperCase(),
                  color: statusColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Date & Guests Row
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${b.eventDate} (${b.slot})',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${b.expectedGuests} guests',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Financial Summary & Actions
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSettled ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isSettled ? 'Paid in Full' : 'Adv: ${AppFormatters.currency(b.advancePaid)} (Bal: ${AppFormatters.currency(b.balanceDue)})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSettled ? const Color(0xFF065F46) : const Color(0xFFB45309),
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                  tooltip: 'WhatsApp Bill',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    WhatsAppHelper.sendBanquetWhatsApp(
                      context: context,
                      rawPhone: b.customerPhone,
                      customerName: b.customerName,
                      bookingNumber: b.bookingNumber,
                      hallName: b.hallName,
                      eventType: b.eventType,
                      eventDate: b.eventDate,
                      slot: b.slot,
                      expectedGuests: b.expectedGuests,
                      packageName: b.packageName,
                      pricePerPlate: b.pricePerPlate,
                      foodTotal: b.foodTotal,
                      hallRent: b.hallRent,
                      extraCharges: b.extraCharges,
                      grandTotal: b.grandTotal,
                      advancePaid: b.advancePaid,
                      balanceDue: b.balanceDue,
                    );
                  },
                ),
                const SizedBox(width: 6),
                Text(
                  AppFormatters.currency(b.grandTotal),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // ══════════════════════════════════════════════════════════════════
  // TAB 2: HALLS SETUP
  // ══════════════════════════════════════════════════════════════════
  Widget _buildHallsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Banquet Halls Setup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Manage banquet halls, capacities, and base slot rental rates.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._halls.map((h) => _buildHallCard(h)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHallCard(BanquetHall h) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    h.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people_outline, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Up to ${h.capacity} Guests',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _rateCol('Morning Slot', AppFormatters.currency(h.baseRentMorning)),
                  _rateCol('Evening Slot', AppFormatters.currency(h.baseRentEvening)),
                  _rateCol('Full Day', AppFormatters.currency(h.baseRentFullDay)),
                ],
              ),
            ),
            if (h.amenities.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: h.amenities.map((a) {
                  return Chip(
                    label: Text(a, style: const TextStyle(fontSize: 10)),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: () => _confirmDeleteHall(h),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _rateCol(String slot, String amount) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(slot, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          const SizedBox(height: 2),
          Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // TAB 3: PACKAGES SETUP
  // ══════════════════════════════════════════════════════════════════
  Widget _buildPackagesTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Catering & Menu Packages',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'Define per-plate catering plans and buffet menu inclusions.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          ..._packages.map((p) => _buildPackageCard(p)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildPackageCard(BanquetPackage p) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    p.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  '${AppFormatters.currency(p.pricePerPlate)} / plate',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            if (p.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(p.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(height: 10),
            if (p.inclusions.isNotEmpty) ...[
              const Text('Includes:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: p.inclusions.map((inc) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(inc, style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  onPressed: () => _confirmDeletePackage(p),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════
  // HALL & PACKAGE DIALOGS
  // ══════════════════════════════════════════════════════════════════


  Future<void> _openAddHallDialog() async {
    final nameCtrl = TextEditingController();
    final capCtrl = TextEditingController(text: '200');
    final morningCtrl = TextEditingController(text: '15000');
    final eveningCtrl = TextEditingController(text: '25000');
    final fullDayCtrl = TextEditingController(text: '35000');
    final amenitiesCtrl = TextEditingController(text: 'AC, Stage, DJ Sound, Parking');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Banquet Hall'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Hall Name *')),
              const SizedBox(height: 8),
              TextField(controller: capCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capacity (Guests)')),
              const SizedBox(height: 8),
              TextField(controller: morningCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Morning Rent (₹)')),
              const SizedBox(height: 8),
              TextField(controller: eveningCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Evening Rent (₹)')),
              const SizedBox(height: 8),
              TextField(controller: fullDayCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Full Day Rent (₹)')),
              const SizedBox(height: 8),
              TextField(controller: amenitiesCtrl, decoration: const InputDecoration(labelText: 'Amenities (comma separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final amenities = amenitiesCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final data = {
                'name': nameCtrl.text.trim(),
                'capacity': int.tryParse(capCtrl.text) ?? 100,
                'baseRentMorning': double.tryParse(morningCtrl.text) ?? 15000,
                'baseRentEvening': double.tryParse(eveningCtrl.text) ?? 25000,
                'baseRentFullDay': double.tryParse(fullDayCtrl.text) ?? 35000,
                'amenities': amenities,
              };
              Navigator.pop(ctx);
              await _repository.addHall(data);
              _loadData();
            },
            child: const Text('Add Hall', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteHall(BanquetHall h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Hall?'),
        content: Text('Are you sure you want to delete ${h.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repository.deleteHall(h.id);
      _loadData();
    }
  }

  Future<void> _openAddPackageDialog() async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '500');
    final descCtrl = TextEditingController();
    final inclusionsCtrl = TextEditingController(text: 'Welcome Drink, 2 Starters, Main Course, Dessert');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Catering Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Package Name *')),
              const SizedBox(height: 8),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rate Per Plate (₹) *')),
              const SizedBox(height: 8),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 8),
              TextField(controller: inclusionsCtrl, decoration: const InputDecoration(labelText: 'Inclusions (comma separated)')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final inclusions = inclusionsCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
              final data = {
                'name': nameCtrl.text.trim(),
                'pricePerPlate': double.tryParse(priceCtrl.text) ?? 450,
                'description': descCtrl.text.trim(),
                'inclusions': inclusions,
                'isVeg': true,
              };
              Navigator.pop(ctx);
              await _repository.addPackage(data);
              _loadData();
            },
            child: const Text('Add Package', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePackage(BanquetPackage p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Package?'),
        content: Text('Delete package "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repository.deletePackage(p.id);
      _loadData();
    }
  }
}
