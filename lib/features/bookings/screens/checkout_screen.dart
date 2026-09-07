import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/booking.dart';
import '../../../models/room.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/room_repository.dart';
import '../../../widgets/common_widgets.dart';
import '../../../widgets/whatsapp_button.dart';

class CheckOutScreen extends StatefulWidget {
  final String? bookingId;
  const CheckOutScreen({super.key, this.bookingId});

  @override
  State<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends State<CheckOutScreen> {
  bool _isLoading = true;
  List<Booking> _checkedInBookings = [];
  List<Booking> _recentCheckOuts = [];
  List<Booking> _upcomingBookings = [];
  Booking? _selectedBooking;
  int _step = 0;
  double _discount = 0;
  bool _settleRemainingBalance = true;
  String _paymentMethod = 'Cash';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<BookingRepository>();
    if (widget.bookingId != null) {
      final b = await repo.getBookingById(widget.bookingId!);
      if (b != null) {
        if (!mounted) return;
        setState(() {
          _selectedBooking = b;
          _step = 1;
          _isLoading = false;
        });
        return;
      }
    }

    final checkedIn = await repo.getBookingsByStatus(BookingStatus.checkedIn);
    final checkedOut = await repo.getBookingsByStatus(BookingStatus.checkedOut);
    final upcoming = await repo.getBookingsByStatus(BookingStatus.upcoming);

    if (!mounted) return;
    setState(() {
      _checkedInBookings = checkedIn;
      _recentCheckOuts = checkedOut;
      _upcomingBookings = upcoming;
      _isLoading = false;
    });
  }

  double get _roomCharge => _selectedBooking?.totalAmount ?? 0;
  double get _subtotal => _roomCharge;
  double get _discountAmt => _subtotal * (_discount / 100);
  double get _grandTotal => (_subtotal - _discountAmt).clamp(0.0, double.infinity);
  double get _paid => _selectedBooking?.paidAmount ?? 0;
  double get _pending => (_grandTotal - _paid).clamp(0.0, double.infinity);

  Future<void> _confirmCheckOut() async {
    if (_selectedBooking == null) return;
    setState(() => _isLoading = true);

    final bookingRepo = context.read<BookingRepository>();
    final roomRepo = context.read<RoomRepository>();
    final b = _selectedBooking!;

    // 1. Mark payment as paid if full amount settled or toggle checked
    if (_settleRemainingBalance || _pending <= 0) {
      await bookingRepo.updatePaymentStatus(b.id, PaymentStatus.paid, _grandTotal);
    }

    // 2. Mark booking as checked-out
    await bookingRepo.updateBookingStatus(b.id, BookingStatus.checkedOut);

    // 3. Free up room (set status to available)
    final roomIdToUse = b.roomId.isNotEmpty ? b.roomId : b.roomNumber;
    await roomRepo.checkOut(roomIdToUse);
    await roomRepo.updateRoomStatus(roomIdToUse, RoomStatus.available);

    if (!mounted) return;
    setState(() => _isLoading = false);

    // 4. Show friendly, clear Success Dialog
    _showSuccessDialog(b);
  }

  void _showSuccessDialog(Booking b) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: AppColors.success, size: 48),
            ),
            const SizedBox(height: 18),
            const Text(
              'चेकआउट सफल रहा!\nCheck-out Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                fontFamily: 'Inter',
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Guest / अतिथि:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                      Text(b.guestName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Room / कमरा:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                      Text('Room ${b.roomNumber}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bill / कुल बिल:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                      Text(AppFormatters.formatCurrency(_grandTotal), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'Inter')),
                    ],
                  ),
                  const Divider(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.cleaning_services_outlined, size: 16, color: AppColors.info),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'कमरा अब खाली है और सफाई के लिए तैयार है।',
                          style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions: WhatsApp, View Invoice, Go to Rooms
            WhatsAppSendChip(
              phone: b.guestPhone,
              guestName: b.guestName,
              invoiceNumber: 'INV-${b.id.substring(0, b.id.length > 6 ? 6 : b.id.length).toUpperCase()}',
              totalAmount: _grandTotal,
              roomOrTable: 'Room ${b.roomNumber} (${b.roomType})',
              items: [
                'Room Stay (${b.nights} night(s)) : ₹${_grandTotal.toStringAsFixed(0)}',
              ],
              paymentMethod: 'Direct',
              paymentStatus: 'PAID (पूर्ण भुगतान)',
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/billing/${b.id}');
                },
                icon: const Icon(Icons.receipt_long, size: 18),
                label: const Text('📄 बिल देखें (View Invoice)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/rooms');
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('कमरे देखें (Go to Rooms)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState(message: 'Loading details...'));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_step == 1 && widget.bookingId == null) {
          setState(() {
            _selectedBooking = null;
            _step = 0;
          });
        } else {
          context.go('/bookings');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Check-out & Bill (चेकआउट और बिल)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back)',
            onPressed: () {
              if (_step == 1 && widget.bookingId == null) {
                setState(() {
                  _selectedBooking = null;
                  _step = 0;
                });
              } else {
                context.go('/bookings');
              }
            },
          ),
        ),
        body: _step == 0 ? _buildSelectGuest() : _buildBill(),
      ),
    );
  }

  Widget _buildSelectGuest() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_checkedInBookings.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hotel_outlined, size: 36, color: AppColors.warning),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'कोई भी गेस्ट अभी चेक-इन नहीं है\n(No Checked-In Guests Currently)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter', height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'चेकआउट करने के लिए पहले गेस्ट का चेक-इन होना आवश्यक है।\nTo perform a check-out, guests must be checked in first.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter', height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (_upcomingBookings.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primarySurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${_upcomingBookings.length} बुकिंग्स चेक-इन के लिए तैयार हैं:',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: () => context.go('/check-in'),
                              icon: const Icon(Icons.login, size: 18),
                              label: const Text('🛬 गेस्ट चेक-इन करें (Go to Check-in)', style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/bookings/new'),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('New Booking'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.go('/bookings'),
                          icon: const Icon(Icons.list_alt, size: 16),
                          label: const Text('All Bookings'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_search, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'चेकआउट के लिए उपलब्ध गेस्ट (${_checkedInBookings.length}):',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_checkedInBookings.length, (i) {
              final b = _checkedInBookings[i];
              final pending = (b.totalAmount - b.paidAmount).clamp(0.0, double.infinity);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('ROOM', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.primary)),
                              Text(
                                b.roomNumber,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.primary, fontFamily: 'Inter'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.guestName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                            const SizedBox(height: 3),
                            Text(
                              '${b.roomType} • ${b.nights} Night(s) • फ़ोन: ${b.guestPhone}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'कुल: ₹${b.totalAmount.toStringAsFixed(0)} | बाकी: ₹${pending.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: pending > 0 ? AppColors.error : AppColors.success,
                                fontFamily: 'Inter',
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => setState(() { _selectedBooking = b; _step = 1; }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('चेकआउट करें', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],

          // ── Recent Check-outs Section ──
          if (_recentCheckOuts.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Row(
              children: [
                Icon(Icons.history, color: AppColors.textSecondary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'हाल ही में चेकआउट (Recent Check-outs):',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...List.generate(_recentCheckOuts.take(5).length, (i) {
              final b = _recentCheckOuts[i];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            b.roomNumber,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'Inter'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.guestName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                            const SizedBox(height: 2),
                            Text(
                              'Room ${b.roomNumber} • कुल बिल: ₹${b.totalAmount.toStringAsFixed(0)} (Paid)',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/billing/${b.id}'),
                        icon: const Icon(Icons.receipt_long, size: 14),
                        label: const Text('बिल देखें', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildBill() {
    final b = _selectedBooking!;
    final pricePerNight = b.nights > 0 ? (b.totalAmount / b.nights) : b.totalAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── 1. Top Guest & Room Details ──
          AppCard(
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('ROOM', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        Text(b.roomNumber, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(b.guestName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                      const SizedBox(height: 3),
                      Text('फ़ोन: ${b.guestPhone}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                      Text(
                        'रुकने का समय: ${b.nights} रातें (${AppFormatters.formatDate(b.checkIn)} से ${AppFormatters.formatDate(b.checkOut)})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 2. Final Bill Summary (Room Only) ──
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('फाइनल बिल (Room Bill)', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Room Only Bill', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),

                // Room Charge Row
                _BillLine(
                  label: 'कमरे का किराया (${b.nights} रातें × ₹${pricePerNight.toStringAsFixed(0)})',
                  amount: _roomCharge,
                  isBold: true,
                ),

                const Divider(height: 20),

                // Discount (Optional)
                Row(
                  children: [
                    const Expanded(
                      child: Text('छूट / Discount (%):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                    ),
                    SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue: '0',
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          isDense: true,
                          suffixText: '%',
                        ),
                        onChanged: (v) => setState(() => _discount = double.tryParse(v) ?? 0),
                      ),
                    ),
                  ],
                ),
                if (_discount > 0)
                  _BillLine(label: 'छूट की रकम (Discount)', amount: -_discountAmt, isRed: true),

                const Divider(thickness: 2, height: 24),

                // Grand Total
                _BillLine(
                  label: 'कुल बिल (Grand Total)',
                  amount: _grandTotal,
                  isBold: true,
                  isLarge: true,
                ),

                const Divider(height: 20),

                // Paid & Pending
                _BillLine(
                  label: 'पहले से जमा (Advance Paid)',
                  amount: _paid,
                  valueColor: AppColors.success,
                  isBold: true,
                ),

                if (_pending > 0)
                  _BillLine(
                    label: 'बाकी रकम (Balance Due to Collect)',
                    amount: _pending,
                    valueColor: AppColors.error,
                    isBold: true,
                    isLarge: true,
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.successLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: AppColors.success, size: 18),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'पूरा भुगतान पहले ही हो चुका है (No Due)',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 3. Settle Balance Box (When Pending > 0) ──
          if (_pending > 0)
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payment, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'रुपये प्राप्त करने की पुष्टि (Collect ₹${_pending.toStringAsFixed(0)})',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    value: _settleRemainingBalance,
                    onChanged: (v) => setState(() => _settleRemainingBalance = v ?? true),
                    title: Text(
                      'हाँ, बाकी ₹${_pending.toStringAsFixed(0)} प्राप्त हो गए (Mark as Paid)',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                    subtitle: const Text('चेकआउट के साथ ही पेमेंट अपने-आप पूरी हो जाएगी', style: TextStyle(fontSize: 11)),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.success,
                  ),
                  if (_settleRemainingBalance) ...[
                    const SizedBox(height: 8),
                    const Text('भुगतान का माध्यम (Payment Method):', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Cash', 'UPI / QR', 'Card'].map((m) {
                        final isSel = _paymentMethod == m;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(m, style: TextStyle(fontWeight: FontWeight.w600, color: isSel ? Colors.white : AppColors.textPrimary)),
                            selected: isSel,
                            selectedColor: AppColors.primary,
                            onSelected: (_) => setState(() => _paymentMethod = m),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ── 4. Large Action Button: Confirm Check-out ──
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _confirmCheckOut,
              icon: const Icon(Icons.logout, size: 22),
              label: const Text(
                '✅ Confirm Check-out (चेकआउट पूरा करें)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // View Bill / Print Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.go('/billing/${b.id}'),
              icon: const Icon(Icons.receipt_long, size: 18),
              label: const Text('बिल देखें / प्रिंट करें (View & Print Invoice)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          if (widget.bookingId == null)
            TextButton(
              onPressed: () => setState(() { _selectedBooking = null; _step = 0; }),
              child: const Text('← गेस्ट सूची पर वापस जाएं (Back to List)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
        ],
      ),
    );
  }
}

class _BillLine extends StatelessWidget {
  final String label;
  final double amount;
  final bool isBold;
  final bool isLarge;
  final bool isRed;
  final Color? valueColor;

  const _BillLine({
    required this.label,
    required this.amount,
    this.isBold = false,
    this.isLarge = false,
    this.isRed = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = valueColor ?? (isRed ? AppColors.error : AppColors.textPrimary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 16 : 14,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'Inter',
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${amount < 0 ? '-' : ''}${AppFormatters.formatCurrency(amount.abs())}',
            style: TextStyle(
              fontSize: isLarge ? 19 : 14,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              fontFamily: 'Inter',
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
