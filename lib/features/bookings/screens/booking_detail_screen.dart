import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';

import '../../../widgets/common_widgets.dart';
import 'edit_booking_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Booking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final repo = context.read<BookingRepository>();
    final booking = await repo.getBookingById(widget.bookingId);
    if (!mounted) return;
    setState(() { _booking = booking; _isLoading = false; });
  }

  Color _paymentColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid: return AppColors.success;
      case PaymentStatus.pending: return AppColors.error;
      case PaymentStatus.partial: return AppColors.warning;
    }
  }

  Color _statusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.upcoming: return AppColors.primary;
      case BookingStatus.checkedIn: return AppColors.success;
      case BookingStatus.checkedOut: return AppColors.textSecondary;
      case BookingStatus.cancelled: return AppColors.error;
      case BookingStatus.noShow: return AppColors.warning;
    }
  }

  Future<void> _confirmCancelBooking() async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to cancel this booking? The room will be released immediately back to Available.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                hintText: 'e.g., Guest requested cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final repo = context.read<BookingRepository>();
      final reason = reasonController.text.trim().isNotEmpty
          ? reasonController.text.trim()
          : 'Cancelled by admin';
      await repo.cancelBooking(widget.bookingId, reason);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking cancelled successfully and room released!'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadBooking();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());
    if (_booking == null) return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.book, title: 'Booking not found'));

    final b = _booking!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/bookings');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Booking #${b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase()}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back to Bookings)',
            onPressed: () => context.go('/bookings'),
          ),
        actions: [
          if (b.status != BookingStatus.cancelled && b.status != BookingStatus.checkedOut)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit Booking',
              onPressed: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => EditBookingScreen(bookingId: b.id)),
                );
                if (result == true) _loadBooking();
              },
            ),
          IconButton(
            icon: const Icon(Icons.receipt_long_outlined),
            tooltip: 'View Invoice',
            onPressed: () => context.go('/billing/${b.id}'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Status bar
            AppCard(
              child: Row(
                children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Booking Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    StatusBadge(label: b.status.label, color: _statusColor(b.status), fontSize: 13),
                  ])),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Payment', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    const SizedBox(height: 4),
                    StatusBadge(label: b.paymentStatus.label, color: _paymentColor(b.paymentStatus), fontSize: 13),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Cancellation notice if cancelled
            if (b.status == BookingStatus.cancelled) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cancel_outlined, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'This booking is CANCELLED',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error),
                          ),
                          if (b.cancellationReason != null && b.cancellationReason!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Reason: ${b.cancellationReason}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Guest info
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Guest', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                const SizedBox(height: 12),
                InfoRow(label: 'Name', value: b.guestName),
                InfoRow(label: 'Phone', value: b.guestPhone),
                InfoRow(label: 'Guests', value: '${b.adults} Adult(s), ${b.children} Child(ren)'),
              ]),
            ),
            const SizedBox(height: 12),

            // Room & Stay info
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Stay Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                const SizedBox(height: 12),
                InfoRow(label: 'Room', value: 'Room ${b.roomNumber} (${b.roomType})'),
                InfoRow(label: 'Check-in', value: AppFormatters.formatDate(b.checkIn)),
                InfoRow(label: 'Check-out', value: AppFormatters.formatDate(b.checkOut)),
                InfoRow(label: 'Duration', value: '${b.nights} Night(s)'),
                InfoRow(label: 'Source', value: b.source.label),
                if (b.specialRequest != null && b.specialRequest!.isNotEmpty)
                  InfoRow(label: 'Request', value: b.specialRequest!, valueColor: AppColors.warning),
              ]),
            ),
            const SizedBox(height: 12),

            // Payment info
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('भुगतान व अग्रिम (Payment Details)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: b.paymentStatus == PaymentStatus.paid
                            ? AppColors.successLight
                            : (b.paidAmount > 0 ? AppColors.warningLight : AppColors.errorLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        b.paymentStatus == PaymentStatus.paid
                            ? 'पूर्ण भुगतान (Paid)'
                            : (b.paidAmount > 0 ? 'अग्रिम जमा (Advance)' : 'बाकी (Pending)'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: b.paymentStatus == PaymentStatus.paid
                              ? AppColors.success
                              : (b.paidAmount > 0 ? AppColors.warning : AppColors.error),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InfoRow(label: 'कुल कमरा किराया (Total)', value: AppFormatters.formatCurrency(b.totalAmount)),
                InfoRow(label: 'अग्रिम जमा (Advance Paid)', value: AppFormatters.formatCurrency(b.paidAmount), valueColor: AppColors.success),
                if (b.pendingAmount > 0)
                  InfoRow(label: 'चेकआउट पर बाकी (Pending)', value: AppFormatters.formatCurrency(b.pendingAmount), valueColor: AppColors.error),
              ]),
            ),
            const SizedBox(height: 20),

            // Actions
            if (b.status == BookingStatus.upcoming) ...[
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
                onPressed: () => context.go('/check-in'),
                icon: const Icon(Icons.login, size: 18),
                label: const Text('Process Check-in'),
              )),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => EditBookingScreen(bookingId: b.id)),
                        );
                        if (res == true) _loadBooking();
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Booking'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancelBooking,
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                      label: const Text('Cancel Booking', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: TextButton.icon(
                onPressed: () => context.go('/billing/${b.id}'),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('View / Print Pro-Forma Invoice'),
              )),
            ],

            if (b.status == BookingStatus.checkedIn) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/check-out?bookingId=${b.id}'),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    '🚪 Check-out & Settle Bill (चेकआउट और बिल)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/billing/${b.id}'),
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('📄 View / Print Invoice (बिल देखें)'),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final res = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => EditBookingScreen(bookingId: b.id)),
                        );
                        if (res == true) _loadBooking();
                      },
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Edit Details'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _confirmCancelBooking,
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                      label: const Text('Cancel Stay', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                    ),
                  ),
                ],
              ),
            ],

            if (b.status == BookingStatus.checkedOut) ...[
              SizedBox(width: double.infinity, height: 48, child: ElevatedButton.icon(
                onPressed: () => context.go('/billing/${b.id}'),
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('View Final Tax Invoice'),
              )),
            ],
          ],
        ),
      ),
    ));
  }
}
