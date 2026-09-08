import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/room_repository.dart';
import '../../../widgets/common_widgets.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});
  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isLoading = true;
  List<Booking> _upcomingBookings = [];
  Booking? _selectedBooking;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<BookingRepository>();
    final bookings = await repo.getBookingsByStatus(BookingStatus.upcoming);
    if (!mounted) return;
    setState(() { _upcomingBookings = bookings; _isLoading = false; });
  }

  Future<void> _confirmCheckIn() async {
    if (_selectedBooking == null) return;
    setState(() => _isLoading = true);
    final bookingRepo = context.read<BookingRepository>();
    final roomRepo = context.read<RoomRepository>();
    await bookingRepo.updateBookingStatus(_selectedBooking!.id, BookingStatus.checkedIn);
    await roomRepo.checkIn(
      _selectedBooking!.roomId, _selectedBooking!.guestId,
      _selectedBooking!.guestName, _selectedBooking!.id,
      _selectedBooking!.checkIn, _selectedBooking!.checkOut,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedBooking!.guestName} checked in to Room ${_selectedBooking!.roomNumber}!'), behavior: SnackBarBehavior.floating),
    );
    context.go('/bookings');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState(message: 'Processing...'));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step == 1) {
          setState(() => _step = 0);
        } else {
          context.go('/bookings');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Check-in'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () {
              if (_step == 1) {
                setState(() => _step = 0);
              } else {
                context.go('/bookings');
              }
            },
          ),
        ),
        body: _step == 0 ? _buildSelectBooking() : _buildConfirm(),
      ),
    );
  }

  Widget _buildSelectBooking() {
    if (_upcomingBookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.available.withOpacity(0.12), shape: BoxShape.circle),
                child: const Icon(Icons.login, color: AppColors.available, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('No pending advance check-ins', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
              const SizedBox(height: 8),
              const Text(
                'If a guest is checking in right now, tap below to assign a room:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: () => context.go('/bookings/new?checkInNow=true'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('New Walk-in Check-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Advance Bookings:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.available,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => context.go('/bookings/new?checkInNow=true'),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('New Walk-in', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: _upcomingBookings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final b = _upcomingBookings[i];
              return GestureDetector(
                onTap: () { setState(() { _selectedBooking = b; _step = 1; }); },
                child: AppCard(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(b.guestName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    Text('Room ${b.roomNumber} • ${AppFormatters.formatDateRange(b.checkIn, b.checkOut)}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    const SizedBox(height: 8),
                    Row(children: [
                      StatusBadge(label: b.paymentStatus.label, color: b.paymentStatus == PaymentStatus.paid ? AppColors.success : AppColors.error),
                      const Spacer(),
                      Text(AppFormatters.formatCurrency(b.totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    ]),
                  ]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirm() {
    final b = _selectedBooking!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
          child: const Icon(Icons.how_to_reg, color: AppColors.success, size: 40),
        ),
        const SizedBox(height: 20),
        Text('Check-in Confirmation', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
        const SizedBox(height: 24),
        AppCard(
          child: Column(children: [
            InfoRow(label: 'Guest', value: b.guestName),
            InfoRow(label: 'Phone', value: b.guestPhone),
            InfoRow(label: 'Room', value: 'Room ${b.roomNumber} (${b.roomType})'),
            InfoRow(label: 'Check-in', value: AppFormatters.formatDate(b.checkIn)),
            InfoRow(label: 'Check-out', value: AppFormatters.formatDate(b.checkOut)),
            InfoRow(label: 'Days', value: '${b.nights}'),
            InfoRow(label: 'Total', value: AppFormatters.formatCurrency(b.totalAmount)),
            InfoRow(label: 'Payment', value: b.paymentStatus.label, valueColor: b.paymentStatus == PaymentStatus.paid ? AppColors.success : AppColors.error),
          ]),
        ),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          onPressed: _confirmCheckIn,
          icon: const Icon(Icons.login),
          label: const Text('Confirm Check-in'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
        )),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, child: OutlinedButton(
          onPressed: () => setState(() { _selectedBooking = null; _step = 0; }),
          child: const Text('Back'),
        )),
      ]),
    );
  }
}
