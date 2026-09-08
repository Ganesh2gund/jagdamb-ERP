import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../widgets/common_widgets.dart';
import '../../rooms/screens/room_availability_screen.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Booking> _allBookings = [];

  final _tabs = [
    (label: 'Upcoming', status: BookingStatus.upcoming),
    (label: 'Today', status: BookingStatus.checkedIn),
    (label: 'Completed', status: BookingStatus.checkedOut),
    (label: 'Cancelled', status: BookingStatus.cancelled),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final repo = context.read<BookingRepository>();
    final bookings = await repo.getBookings();
    if (!mounted) return;
    setState(() { _allBookings = bookings; _isLoading = false; });
  }

  List<Booking> _getBookingsForTab(int index) {
    return _allBookings.where((b) => b.status == _tabs[index].status).toList();
  }

  Color _paymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid: return AppColors.success;
      case PaymentStatus.pending: return AppColors.error;
      case PaymentStatus.partial: return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Bookings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Room Availability Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoomAvailabilityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadBookings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) {
            final count = _getBookingsForTab(_tabs.indexOf(t)).length;
            return Tab(text: '${t.label} ($count)');
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/bookings/new'),
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (index) {
          final bookings = _getBookingsForTab(index);
          if (bookings.isEmpty) {
            return EmptyState(
              icon: Icons.book,
              title: 'No ${_tabs[index].label} bookings',
              subtitle: 'Bookings will appear here',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: bookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _BookingCard(
              booking: bookings[i],
              paymentColor: _paymentColor(bookings[i].paymentStatus),
              onTap: () => context.go('/bookings/${bookings[i].id}'),
            ),
          );
        }),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final Color paymentColor;
  final VoidCallback onTap;

  const _BookingCard({required this.booking, required this.paymentColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(booking.guestName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter')),
                      const SizedBox(height: 2),
                      Text('Room ${booking.roomNumber} • ${booking.roomType}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    ],
                  ),
                ),
                StatusBadge(label: booking.paymentStatus.label, color: paymentColor),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${AppFormatters.formatDateRange(booking.checkIn, booking.checkOut)} (${booking.nights}D)',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.people_outline, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${booking.adults + booking.children} guests',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(6)),
                  child: Text(booking.source.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                ),
                const Spacer(),
                Text(
                  AppFormatters.formatCurrency(booking.totalAmount),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
