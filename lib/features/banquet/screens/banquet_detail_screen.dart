import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/banquet.dart';
import '../../../repositories/banquet_repository.dart';
import '../../../widgets/common_widgets.dart';

class BanquetDetailScreen extends StatefulWidget {
  final String bookingId;
  const BanquetDetailScreen({super.key, required this.bookingId});

  @override
  State<BanquetDetailScreen> createState() => _BanquetDetailScreenState();
}

class _BanquetDetailScreenState extends State<BanquetDetailScreen> {
  final BanquetRepository _repository = HttpBanquetRepository();
  BanquetBooking? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final bookings = await _repository.getBookings();
    if (!mounted) return;
    final found = bookings.where((b) => b.id == widget.bookingId || b.bookingNumber == widget.bookingId);
    setState(() {
      _booking = found.isNotEmpty ? found.first : null;
      _isLoading = false;
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _sendWhatsApp() {
    if (_booking == null) return;
    final b = _booking!;
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
  }

  Future<void> _collectPaymentSheet() async {
    if (_booking == null) return;
    final b = _booking!;
    final amountCtrl = TextEditingController(text: b.balanceDue.toStringAsFixed(0));
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
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Collect Due Payment', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx, false)),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.grey50, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Customer: ${b.customerName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text('Hall: ${b.hallName}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text('Amount to Collect', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  filled: true,
                  fillColor: AppColors.grey50,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Payment Mode', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: ['Cash', 'UPI', 'Card'].map((m) {
                  final isSel = paymentMode == m;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => setSheetState(() => paymentMode = m),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : AppColors.grey50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            m,
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
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                    if (amount <= 0) return;
                    Navigator.pop(ctx, true);
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('Confirm Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
      final newAdvance = b.advancePaid + amount;
      await _repository.updateBooking(b.id, {
        'advancePaid': newAdvance,
        'grandTotal': b.grandTotal,
        'paymentMode': paymentMode,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('₹${amount.toStringAsFixed(0)} payment received successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadBooking();
    }
  }

  Future<void> _markCompleted() async {
    if (_booking == null) return;
    await _repository.updateBooking(_booking!.id, {'status': 'completed'});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Banquet Event marked as COMPLETED!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
    );
    _loadBooking();
  }

  Future<void> _cancelBooking() async {
    if (_booking == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this banquet booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _repository.cancelBooking(_booking!.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking Cancelled'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
      _loadBooking();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Banquet Booking')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    final b = _booking!;
    final isSettled = b.balanceDue <= 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Booking #${b.bookingNumber}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Status bar ──
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Booking Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
                        const SizedBox(height: 4),
                        StatusBadge(label: b.status.toUpperCase(), color: _statusColor(b.status), fontSize: 13),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Payment Status', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
                        const SizedBox(height: 4),
                        StatusBadge(
                          label: isSettled ? 'PAID IN FULL' : 'PARTIAL / PENDING',
                          color: isSettled ? AppColors.success : const Color(0xFFD97706),
                          fontSize: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Client Info ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Client Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Host / Client Name', value: b.customerName),
                  InfoRow(label: 'Contact Phone', value: b.customerPhone),
                  if (b.customerEmail.isNotEmpty) InfoRow(label: 'Email', value: b.customerEmail),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Event & Venue Info ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Event & Venue Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Banquet Hall', value: b.hallName),
                  InfoRow(label: 'Event Function', value: b.eventType),
                  InfoRow(label: 'Date & Slot', value: '${b.eventDate} (${b.slot} Slot)'),
                  InfoRow(label: 'Expected Guests', value: '${b.expectedGuests} Persons'),
                  if (b.packageName.isNotEmpty)
                    InfoRow(label: 'Catering Package', value: '${b.packageName} (₹${b.pricePerPlate.toStringAsFixed(0)}/plate)'),
                  if (b.notes.isNotEmpty)
                    InfoRow(label: 'Notes / Requests', value: b.notes, valueColor: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Bill Breakdown Card ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Bill Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isSettled ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isSettled ? 'Paid' : 'Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSettled ? AppColors.success : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Hall Base Tariff (${b.slot})', value: AppFormatters.formatCurrency(b.hallRent)),
                  if (b.foodTotal > 0)
                    InfoRow(
                      label: 'Catering Food (${b.expectedGuests} × ₹${b.pricePerPlate.toStringAsFixed(0)})',
                      value: AppFormatters.formatCurrency(b.foodTotal),
                    ),
                  if (b.extraCharges > 0)
                    InfoRow(label: 'Decoration & Extras', value: AppFormatters.formatCurrency(b.extraCharges)),
                  const Divider(height: 16),
                  InfoRow(label: 'Grand Total', value: AppFormatters.formatCurrency(b.grandTotal), valueColor: AppColors.primary),
                  InfoRow(label: 'Advance Paid', value: AppFormatters.formatCurrency(b.advancePaid), valueColor: AppColors.success),
                  if (b.balanceDue > 0)
                    InfoRow(label: 'Balance Due', value: AppFormatters.formatCurrency(b.balanceDue), valueColor: const Color(0xFFDC2626)),

                  if (b.balanceDue > 0 && b.status != 'cancelled') ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.success,
                          side: const BorderSide(color: AppColors.success),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _collectPaymentSheet,
                        icon: const Icon(Icons.payments_outlined, size: 18),
                        label: Text(
                          '💰 Collect Due ₹${b.balanceDue.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Primary Action Buttons ──
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _sendWhatsApp,
                icon: const Icon(Icons.chat, size: 20),
                label: const Text('Send WhatsApp Bill', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (b.status == 'confirmed') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _markCompleted,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text('Complete Event'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.success,
                        side: const BorderSide(color: AppColors.success),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _cancelBooking,
                      icon: const Icon(Icons.cancel_outlined, size: 18, color: AppColors.error),
                      label: const Text('Cancel Booking', style: TextStyle(color: AppColors.error)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
