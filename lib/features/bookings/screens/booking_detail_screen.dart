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

  Future<void> _showExtendStaySheet(Booking b) async {
    int additionalNights = 1;
    bool isExtending = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final currentNights = b.checkOut.difference(b.checkIn).inDays.clamp(1, 999);
          final pricePerNight = b.totalAmount / currentNights;
          final newCheckOut = b.checkOut.add(Duration(days: additionalNights));
          final extraCost = pricePerNight * additionalNights;

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20, 14, 20,
              MediaQuery.of(context).viewInsets.bottom + 24,
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.more_time_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Extend Stay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                          SizedBox(height: 2),
                          Text('Extend guest checkout date and room tariff', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Room:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text('Room ${b.roomNumber} (${b.roomType})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Current Check-out:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text(AppFormatters.formatDate(b.checkOut), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('New Check-out:', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          Text(
                            AppFormatters.formatDate(newCheckOut),
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Additional Tariff (+Cost):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          Text('₹${extraCost.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text('Select Additional Days', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(
                  children: [1, 2, 3, 5].map((nights) {
                    final selected = additionalNights == nights;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: selected ? AppColors.primary : Colors.white,
                            foregroundColor: selected ? Colors.white : AppColors.textPrimary,
                            side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {
                            setSheetState(() => additionalNights = nights);
                          },
                          child: Text('+$nights Day', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: isExtending
                        ? null
                        : () async {
                            setSheetState(() => isExtending = true);
                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);
                            final repo = context.read<BookingRepository>();
                            final res = await repo.extendStay(b.id, additionalNights);
                            nav.pop();
                            if (res['success'] == true) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('✅ Stay extended successfully (+ $additionalNights day(s))! New check-out: ${AppFormatters.formatDate(newCheckOut)}'),
                                  backgroundColor: AppColors.success,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              if (mounted) _loadBooking();
                            } else {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(res['message']?.toString() ?? 'Failed to extend stay'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                    child: isExtending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(
                            'Extend Stay (+₹${extraCost.toStringAsFixed(0)})',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancelBooking() async {
    final reasonController = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20, 12, 20,
          MediaQuery.of(ctx).viewInsets.bottom + 20,
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
                  decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                  child: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cancel Booking', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                      SizedBox(height: 2),
                      Text('Room will be immediately released and marked Available', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, color: AppColors.textSecondary), onPressed: () => Navigator.pop(ctx, false)),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            const Text('Cancellation Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: reasonController,
              maxLines: 2,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Guest cancelled trip / Emergency',
                prefixIcon: const Icon(Icons.edit_note, color: AppColors.error),
                filled: true,
                fillColor: AppColors.grey50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.error, width: 2)),
              ),
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
                      child: const Text('Keep Booking', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                      child: const Text('Cancel Booking', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
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

  Future<void> _collectPaymentSheet(Booking b) async {
    final amountController = TextEditingController(text: b.pendingAmount.toStringAsFixed(0));
    String paymentMode = 'Cash';

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20, 20, 20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Collect Payment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(ctx, false),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.grey50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Guest: ${b.guestName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Room: ${b.roomNumber}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Amount to Collect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Cash', 'UPI', 'Card'].map((mode) {
                  final isSel = paymentMode == mode;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => paymentMode = mode),
                        child: Container(
                           padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            mode,
                            style: TextStyle(
                              color: isSel ? Colors.white : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final collected = double.tryParse(amountController.text.trim()) ?? 0.0;
      if (collected <= 0) return;
      final newPaid = b.paidAmount + collected;
      final newStatus = newPaid >= b.totalAmount ? PaymentStatus.paid : PaymentStatus.partial;
      final repo = context.read<BookingRepository>();
      await repo.updatePaymentStatus(b.id, newStatus, newPaid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₹${collected.toStringAsFixed(0)} ($paymentMode) payment collected successfully!'),
          backgroundColor: AppColors.success,
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
            tooltip: 'Back to Bookings',
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
                InfoRow(label: 'Duration', value: '${b.nights} Day(s)'),
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
                    const Expanded(
                      child: Text(
                        'Payment Details',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: b.paymentStatus == PaymentStatus.paid
                            ? AppColors.successLight
                            : (b.paidAmount > 0 ? AppColors.warningLight : AppColors.errorLight),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        b.paymentStatus == PaymentStatus.paid
                            ? 'Paid'
                            : (b.paidAmount > 0 ? 'Advance' : 'Pending'),
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
                InfoRow(label: 'Room Tariff (Total)', value: AppFormatters.formatCurrency(b.totalAmount)),
                InfoRow(label: 'Advance Paid', value: AppFormatters.formatCurrency(b.paidAmount), valueColor: AppColors.success),
                if (b.pendingAmount > 0)
                  InfoRow(label: 'Balance Due (Pending)', value: AppFormatters.formatCurrency(b.pendingAmount), valueColor: AppColors.error),
                if (b.pendingAmount > 0 && b.status != BookingStatus.cancelled) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _collectPaymentSheet(b),
                      icon: const Icon(Icons.payments_outlined, size: 18),
                      label: Text(
                        '💰 Collect Due ₹${b.pendingAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ),
                ],
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
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () => _showExtendStaySheet(b),
                  icon: const Icon(Icons.more_time_rounded, size: 20),
                  label: const Text(
                    '🛌 Extend Stay (+1 Day)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/check-out?bookingId=${b.id}'),
                  icon: const Icon(Icons.logout, size: 20),
                  label: const Text(
                    '🚪 Check-out & Settle Bill',
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
                  label: const Text('📄 View / Print Invoice'),
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
