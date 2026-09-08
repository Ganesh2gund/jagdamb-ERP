import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/web_printer.dart';
import '../../../repositories/room_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/notification_repository.dart';
import '../../../repositories/restaurant_repository.dart';
import '../../../repositories/cafe_repository.dart';
import '../../../services/api_client.dart';
import '../../../models/room.dart';
import '../../../models/booking.dart';
import '../../../models/restaurant.dart';
import '../../../models/cafe.dart';
import '../../../models/banquet.dart';
import '../../../repositories/banquet_repository.dart';
import '../../../widgets/common_widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<Room> _rooms = [];
  List<Booking> _bookings = [];
  List<RestaurantOrder> _restaurantOrders = [];
  List<CafeOrder> _cafeOrders = [];
  List<BanquetBooking> _banquetBookings = [];
  int _unreadNotifications = 0;
  String _hotelName = AppConstants.hotelName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Load dynamic hotel name
    try {
      final prefs = await SharedPreferences.getInstance();
      final localName = prefs.getString('hotel_name');
      if (localName != null && localName.trim().isNotEmpty && mounted) {
        setState(() => _hotelName = localName.trim());
      }
    } catch (_) {}

    try {
      ApiClient.instance.get('/settings').then((data) {
        final s = data['settings'] as Map<String, dynamic>? ?? {};
        if (s['hotelName'] != null && (s['hotelName'] as String).trim().isNotEmpty && mounted) {
          setState(() => _hotelName = (s['hotelName'] as String).trim());
        }
      }).catchError((_) {});
    } catch (_) {}

    if (!mounted) return;
    final roomRepo = context.read<RoomRepository>();
    final bookingRepo = context.read<BookingRepository>();
    final notifRepo = context.read<NotificationRepository>();
    final restaurantRepo = context.read<RestaurantRepository>();
    final cafeRepo = context.read<CafeRepository>();
    final banquetRepo = context.read<BanquetRepository>();

    final results = await Future.wait([
      roomRepo.getRooms().catchError((_) => <Room>[]),
      bookingRepo.getBookings().catchError((_) => <Booking>[]),
      notifRepo.getUnreadCount().catchError((_) => 0),
      restaurantRepo.getOrders().catchError((_) => <RestaurantOrder>[]),
      cafeRepo.getOrders().catchError((_) => <CafeOrder>[]),
      banquetRepo.getBookings().catchError((_) => <BanquetBooking>[]),
    ]);

    if (!mounted) return;
    setState(() {
      _rooms = results[0] as List<Room>;
      _bookings = results[1] as List<Booking>;
      _unreadNotifications = results[2] as int;
      _restaurantOrders = results[3] as List<RestaurantOrder>;
      _cafeOrders = results[4] as List<CafeOrder>;
      _banquetBookings = results[5] as List<BanquetBooking>;
      _isLoading = false;
    });
  }

  void _showEditHotelNameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: _hotelName);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
        ),
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
                  child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Edit Hotel Name', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                      SizedBox(height: 2),
                      Text('This name will appear on all invoices and reports', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(dialogCtx)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text('Hotel Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Hotel Jagdamb Palace',
                prefixIcon: const Icon(Icons.hotel_rounded, color: AppColors.primary),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final newName = ctrl.text.trim();
                  if (newName.isEmpty) return;
                  Navigator.pop(dialogCtx);
                  setState(() => _hotelName = newName);

                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('hotel_name', newName);
                    WebPrinter.updateConfig(name: newName);
                  } catch (_) {}

                  try {
                    await ApiClient.instance.put('/settings', body: {'hotelName': newName});
                  } catch (_) {}

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hotel name updated to "$newName"!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 20),
                label: const Text('Save Name', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
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
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState(message: 'Loading dashboard...'));

    final totalRooms = _rooms.length;
    final occupied = _rooms.where((r) => r.status == RoomStatus.occupied).length;
    final available = _rooms.where((r) => r.status == RoomStatus.available).length;
    final cleaning = _rooms.where((r) => r.status == RoomStatus.cleaning).length;
    final maintenance = _rooms.where((r) => r.status == RoomStatus.maintenance).length;

    final today = DateTime.now();
    final checkIns = _bookings.where((b) =>
      b.checkIn.year == today.year && b.checkIn.month == today.month &&
      b.checkIn.day == today.day && b.status == BookingStatus.checkedIn).length;
    final checkOuts = _bookings.where((b) =>
      b.checkOut.year == today.year && b.checkOut.month == today.month &&
      b.checkOut.day == today.day).length;
    final upcoming = _bookings.where((b) => b.status == BookingStatus.upcoming).length;
    final pendingPayments = _bookings.where((b) =>
      b.paymentStatus == PaymentStatus.pending || b.paymentStatus == PaymentStatus.partial).length;

    // Real live revenue calculated from today's bookings
    final todayPaidBookings = _bookings.where((b) =>
      b.createdAt.year == today.year && b.createdAt.month == today.month && b.createdAt.day == today.day
    );
    final roomRevenue = todayPaidBookings.fold(0.0, (s, b) => s + b.paidAmount);

    // Real live revenue calculated from today's paid restaurant orders
    final todayPaidOrders = _restaurantOrders.where((o) =>
      o.isPaid &&
      o.createdAt.year == today.year && o.createdAt.month == today.month && o.createdAt.day == today.day
    );
    final restaurantRevenue = todayPaidOrders.fold(0.0, (s, o) => s + o.total);

    // Real live revenue calculated from today's cafe orders
    final todayPaidCafeOrders = _cafeOrders.where((o) =>
      o.isPaid &&
      o.createdAt.year == today.year && o.createdAt.month == today.month && o.createdAt.day == today.day
    );
    final cafeRevenue = todayPaidCafeOrders.fold(0.0, (s, o) => s + o.totalAmount);

    // Real live revenue calculated from today's banquet bookings
    final todayBanquetBookings = _banquetBookings.where((b) {
      if (b.status == 'cancelled') return false;
      if (b.createdAt != null && b.createdAt!.isNotEmpty) {
        try {
          final dt = DateTime.parse(b.createdAt!).toLocal();
          if (dt.year == today.year && dt.month == today.month && dt.day == today.day) {
            return true;
          }
        } catch (_) {}
      }
      try {
        final ev = DateTime.parse(b.eventDate);
        if (ev.year == today.year && ev.month == today.month && ev.day == today.day) {
          return true;
        }
      } catch (_) {}
      return false;
    });
    final banquetRevenue = todayBanquetBookings.fold(0.0, (s, b) => s + b.advancePaid);

    final totalRevenue = roomRevenue + restaurantRevenue + cafeRevenue + banquetRevenue;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: _buildHeader(context),
              ),
              // Content
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Room stats
                    _buildRoomStats(totalRooms, occupied, available, cleaning, maintenance),
                    const SizedBox(height: 20),

                    // Revenue card (Dynamic: Rooms + Restaurant + Cafe + Banquet)
                    _buildRevenueCard(context, totalRevenue, roomRevenue, restaurantRevenue, cafeRevenue, banquetRevenue),
                    const SizedBox(height: 20),

                    // Today's activity (Dynamic)
                    _buildTodayActivity(context, checkIns, checkOuts, upcoming, cleaning),
                    const SizedBox(height: 20),

                    // Alerts (Dynamic)
                    _buildAlerts(context, pendingPayments, cleaning, maintenance),
                    const SizedBox(height: 20),

                    // Quick actions
                    _buildQuickActions(context),
                    const SizedBox(height: 20),

                    // Business insights (Dynamic)
                    _buildBusinessInsights(context, occupied, totalRooms, totalRevenue, pendingPayments),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()} 👋',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: () => _showEditHotelNameDialog(context),
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _hotelName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            fontFamily: 'Inter',
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Notification bell
          GestureDetector(
            onTap: () => context.go('/notifications'),
            child: Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 22),
                ),
                if (_unreadNotifications > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Profile Icon
          GestureDetector(
            onTap: () async {
              await context.push('/settings');
              _loadData();
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStats(int total, int occupied, int available, int cleaning, int maintenance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const SectionHeader(title: "Today's Overview"),
        const SizedBox(height: 14),
        Row(
          children: [
            _StatCard(label: 'Total', value: '$total', color: AppColors.primary),
            const SizedBox(width: 10),
            _StatCard(label: 'Occupied', value: '$occupied', color: AppColors.occupied),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _StatCard(label: 'Available', value: '$available', color: AppColors.available),
            const SizedBox(width: 10),
            _StatCard(label: 'Cleaning', value: '$cleaning', color: AppColors.cleaning),
            const SizedBox(width: 10),
            _StatCard(label: 'Maint.', value: '$maintenance', color: AppColors.maintenance),
          ],
        ),
      ],
    );
  }

  Widget _buildRevenueCard(
    BuildContext context,
    double totalRevenue,
    double roomRevenue,
    double restaurantRevenue,
    double cafeRevenue,
    double banquetRevenue,
  ) {
    final hasRev = totalRevenue > 0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Revenue",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasRev ? AppColors.successLight : AppColors.grey100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      hasRev ? Icons.trending_up : Icons.remove,
                      color: hasRev ? AppColors.success : AppColors.textSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hasRev ? 'Active' : 'Live: ₹0',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasRev ? AppColors.success : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppFormatters.formatCurrency(totalRevenue),
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontFamily: 'Inter',
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasRev ? 'Total revenue collected today across all streams' : 'No revenue collected today',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          // Revenue breakdown: Rooms, Restaurant, Cafe, Banquet
          Row(
            children: [
              Expanded(child: _RevenueBreakdown(label: 'Rooms', amount: AppFormatters.formatCurrency(roomRevenue), icon: Icons.hotel)),
              Expanded(child: _RevenueBreakdown(label: 'Restaurant', amount: AppFormatters.formatCurrency(restaurantRevenue), icon: Icons.restaurant)),
              Expanded(child: _RevenueBreakdown(label: 'Cafe', amount: AppFormatters.formatCurrency(cafeRevenue), icon: Icons.local_cafe)),
              Expanded(child: _RevenueBreakdown(label: 'Banquet', amount: AppFormatters.formatCurrency(banquetRevenue), icon: Icons.celebration)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTodayActivity(BuildContext context, int checkIns, int checkOuts, int upcoming, int cleaning) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: "Today's Activity"),
        const SizedBox(height: 14),
        _ActivityItem(
          icon: Icons.login,
          color: AppColors.success,
          label: '$checkIns Check-ins',
          onTap: () => context.go('/bookings'),
        ),
        const SizedBox(height: 8),
        _ActivityItem(
          icon: Icons.logout,
          color: AppColors.warning,
          label: '$checkOuts Check-outs',
          onTap: () => context.go('/bookings'),
        ),
        const SizedBox(height: 8),
        _ActivityItem(
          icon: Icons.calendar_today,
          color: AppColors.primary,
          label: '$upcoming Upcoming Bookings',
          onTap: () => context.go('/bookings'),
        ),
        const SizedBox(height: 8),
        _ActivityItem(
          icon: Icons.cleaning_services_outlined,
          color: AppColors.cleaning,
          label: '$cleaning Rooms to Clean',
          onTap: () => context.go('/rooms'),
        ),
      ],
    );
  }

  Widget _buildAlerts(BuildContext context, int pendingPayments, int cleaningRooms, int maintenanceRooms) {
    final hasAlerts = pendingPayments > 0 || cleaningRooms > 0 || maintenanceRooms > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Attention Required'),
        const SizedBox(height: 14),
        AppCard(
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              if (!hasAlerts)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.success, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'All systems running smoothly — No pending alerts',
                          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (pendingPayments > 0)
                  _AlertItem(
                    message: '$pendingPayments pending payment(s) require follow-up',
                    onTap: () => context.go('/bookings'),
                  ),
                if (cleaningRooms > 0) ...[
                  const Divider(height: 1),
                  _AlertItem(
                    message: '$cleaningRooms room(s) waiting for cleaning',
                    onTap: () => context.go('/rooms'),
                  ),
                ],
                if (maintenanceRooms > 0) ...[
                  const Divider(height: 1),
                  _AlertItem(
                    message: '$maintenanceRooms room(s) under maintenance',
                    onTap: () => context.go('/rooms'),
                    isLast: true,
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick Actions'),
        const SizedBox(height: 14),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _QuickActionButton(
              icon: Icons.login_rounded,
              label: 'New Check-In',
              color: AppColors.available,
              onTap: () => context.go('/bookings/new?checkInNow=true'),
            ),
            _QuickActionButton(
              icon: Icons.logout_rounded,
              label: 'Check-Out & Bill',
              color: AppColors.warning,
              onTap: () => context.go('/check-out'),
            ),
            _QuickActionButton(
              icon: Icons.calendar_month_outlined,
              label: 'Bookings',
              color: AppColors.primary,
              onTap: () => context.go('/bookings'),
            ),
            _QuickActionButton(
              icon: Icons.restaurant_outlined,
              label: 'Restaurant',
              color: AppColors.cleaning,
              onTap: () => context.go('/restaurant'),
            ),
            _QuickActionButton(
              icon: Icons.local_cafe_outlined,
              label: 'Cafe',
              color: const Color(0xFFD97706),
              onTap: () => context.go('/cafe'),
            ),
            _QuickActionButton(
              icon: Icons.receipt_long_outlined,
              label: 'Expenses',
              color: AppColors.warning,
              onTap: () => context.go('/expenses'),
            ),
            _QuickActionButton(
              icon: Icons.assessment_outlined,
              label: '10-Day Report',
              color: AppColors.primary,
              onTap: () => context.go('/report-cycle'),
            ),
            _QuickActionButton(
              icon: Icons.celebration_outlined,
              label: 'Banquet Hall',
              color: AppColors.primary,
              onTap: () => context.push('/banquet'),
            ),
          ],
        ),
      ],
    );
  }

   Widget _buildBusinessInsights(BuildContext context, int occupied, int total, double totalRevenue, int pendingPayments) {
    final occupancyPct = total > 0 ? ((occupied / total) * 100).round() : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: '💡 Business Insights'),
        const SizedBox(height: 14),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InsightItem('Occupancy is currently at $occupancyPct% ($occupied of $total rooms occupied)'),
              const Divider(),
              _InsightItem('Today\'s collected revenue: ${AppFormatters.formatCurrency(totalRevenue)}'),
              if (pendingPayments > 0) ...[
                const Divider(),
                _InsightItem('$pendingPayments pending booking payment(s) to collect ⚠️'),
              ],
              if (total == 0) ...[
                const Divider(),
                const _InsightItem('Start by adding your hotel rooms from the Rooms tab below 🏨'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, fontFamily: 'Inter'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueBreakdown extends StatelessWidget {
  final String label;
  final String amount;
  final IconData icon;

  const _RevenueBreakdown({required this.label, required this.amount, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter')),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
      ],
    );
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ActivityItem({required this.icon, required this.color, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter'))),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _AlertItem extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  final bool isLast;

  const _AlertItem({required this.message, required this.onTap, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary, size: 18),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightItem extends StatelessWidget {
  final String text;

  const _InsightItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
    );
  }
}
