import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/booking.dart';
import '../../../models/payment.dart';
import '../../../repositories/booking_repository.dart';
import '../../../widgets/common_widgets.dart';

class BillingScreen extends StatefulWidget {
  final String bookingId;
  const BillingScreen({super.key, required this.bookingId});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  Booking? _booking;
  bool _isLoading = true;
  late final TextEditingController _phoneController;
  String _hotelName = AppConstants.hotelName;
  String _hotelAddress = AppConstants.hotelAddress;
  String _hotelPhone = AppConstants.hotelPhone;
  String _hotelEmail = AppConstants.hotelEmail;

  // Bill items - purely Room charge as set by Admin (pricePerNight * nights)
  List<BillItem> get _items {
    if (_booking == null) return [];
    return [
      BillItem(
        description: 'Room ${_booking!.roomNumber} (${_booking!.roomType}) - ${_booking!.nights} night(s)',
        type: PaymentType.roomCharge,
        amount: _booking!.totalAmount,
        quantity: 1,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getString('hotel_name');
      final a = prefs.getString('hotel_address');
      final p = prefs.getString('hotel_phone');
      final e = prefs.getString('hotel_email');
      if (n != null && n.trim().isNotEmpty) _hotelName = n.trim();
      if (a != null && a.trim().isNotEmpty) _hotelAddress = a.trim();
      if (p != null) _hotelPhone = p.trim();
      if (e != null) _hotelEmail = e.trim();
    } catch (_) {}

    final repo = context.read<BookingRepository>();
    final booking = await repo.getBookingById(widget.bookingId);
    if (!mounted) return;
    setState(() {
      _booking = booking;
      if (booking != null && _phoneController.text.isEmpty) {
        _phoneController.text = booking.guestPhone;
      }
      _isLoading = false;
    });
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.total);
  double get _grandTotal => _subtotal;

  bool get _isSettled =>
      _booking?.status == BookingStatus.checkedOut ||
      _booking?.paymentStatus == PaymentStatus.paid;

  double get _paid => _isSettled ? _grandTotal : (_booking?.paidAmount ?? 0.0);
  double get _pending => _isSettled ? 0.0 : (_grandTotal - _paid).clamp(0.0, double.infinity);

  Future<void> _markPaid() async {
    if (_booking == null) return;
    final repo = context.read<BookingRepository>();
    await repo.updatePaymentStatus(_booking!.id, PaymentStatus.paid, _grandTotal);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment marked as fully PAID!'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
    _load();
  }



  void _sendWhatsApp() {
    if (_booking == null) return;
    final b = _booking!;
    WhatsAppHelper.openWhatsApp(
      context: context,
      rawPhone: _phoneController.text.trim(),
      customerName: b.guestName,
      invoiceNo: 'INV-${b.id.substring(0, b.id.length > 6 ? 6 : b.id.length).toUpperCase()}',
      totalAmount: _grandTotal,
      hotelName: _hotelName,
      roomOrTable: 'Room ${b.roomNumber} (${b.roomType})',
      items: _items.map((i) => '${i.description} : ₹${i.total.toStringAsFixed(0)}').toList(),
      paymentMethod: 'Direct',
      paymentStatus: _isSettled ? 'PAID (पूर्ण भुगतान)' : 'PENDING / PARTIAL',
      date: b.checkOut,
    );
  }

  void _showInvoiceDialog() {
    if (_booking == null) return;
    final b = _booking!;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 650),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_hotelName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          if (_hotelAddress.isNotEmpty)
                            Text(_hotelAddress, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          if (_hotelPhone.isNotEmpty || _hotelEmail.isNotEmpty)
                            Text(
                              [_hotelPhone, _hotelEmail].where((s) => s.isNotEmpty).join(' • '),
                              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'HOTEL RECEIPT',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text('#INV-${b.id.substring(0, b.id.length > 6 ? 6 : b.id.length).toUpperCase()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(AppFormatters.formatDate(DateTime.now()), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Guest Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Billed To:', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text(b.guestName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                        Text(b.guestPhone, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Room: ${b.roomNumber} (${b.roomType})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Stay: ${AppFormatters.formatDate(b.checkIn)} - ${AppFormatters.formatDate(b.checkOut)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        Text('${b.nights} Night(s)', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Items Table
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Item / Service', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                          Expanded(flex: 2, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700))),
                        ],
                      ),
                      const Divider(),
                      ..._items.map((i) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text(i.description, style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 1, child: Text('${i.quantity}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                            Expanded(flex: 2, child: Text(AppFormatters.formatCurrency(i.total), textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Calculation Breakdown
                Column(
                  children: [
                    _dialogTotalRow('Subtotal (कमरा किराया)', AppFormatters.formatCurrency(_subtotal)),
                    if (b.paidAmount > 0 && !_isSettled)
                      _dialogTotalRow('Advance Paid (अग्रिम जमा)', AppFormatters.formatCurrency(b.paidAmount), color: AppColors.success),
                    const Divider(),
                    _dialogTotalRow('Grand Total (कुल बिल)', AppFormatters.formatCurrency(_grandTotal), isBold: true),
                    _dialogTotalRow('Amount Paid (प्राप्त राशि)', AppFormatters.formatCurrency(_paid), color: AppColors.success),
                    if (_pending > 0)
                      _dialogTotalRow('Balance Due (बकाया)', AppFormatters.formatCurrency(_pending), isBold: true, color: AppColors.error),
                  ],
                ),
                const SizedBox(height: 20),

                // Footer Actions
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _sendWhatsApp();
                        },
                        icon: const Icon(Icons.chat, size: 18),
                        label: const Text(
                          'Send WhatsApp (व्हाट्सएप)',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('बंद करें (Close)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogTotalRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.w700 : FontWeight.w600, color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(icon: Icons.receipt, title: 'Bill not found'),
      );
    }

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
          title: const Text('Hotel Bill & Receipt (होटल बिल)'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back to Bookings)',
            onPressed: () => context.go('/bookings'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'Preview Printable Bill',
              onPressed: _showInvoiceDialog,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined),
              tooltip: 'Share Bill',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invoice link copied to clipboard!'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // ── Top Summary Header Card ─────────────────────
              AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isSettled ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSettled ? Icons.check_circle : Icons.pending_actions,
                        color: _isSettled ? AppColors.success : AppColors.warning,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _isSettled ? 'BILL SETTLED' : 'PAYMENT DUE',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: _isSettled ? AppColors.success : AppColors.warning,
                                    fontFamily: 'Inter',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _isSettled ? AppColors.successLight : AppColors.warningLight,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _isSettled ? 'Paid' : 'Pending',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _isSettled ? AppColors.success : AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSettled
                                ? 'Full payment received. Room check-out completed.'
                                : 'Pending balance remaining to be collected from guest.',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Guest & Stay Info Card ────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Guest & Stay Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.chat, size: 12, color: Color(0xFF25D366)),
                              SizedBox(width: 4),
                              Text(
                                'WhatsApp Ready',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InfoRow(label: 'Guest Name', value: b.guestName),
                    InfoRow(label: 'Room Number', value: 'Room ${b.roomNumber} (${b.roomType})'),
                    InfoRow(label: 'Stay Duration', value: '${b.nights} Night(s) (${AppFormatters.formatDate(b.checkIn)} - ${AppFormatters.formatDate(b.checkOut)})'),
                    InfoRow(label: 'Booking ID', value: '#${b.id.substring(0, b.id.length > 8 ? 8 : b.id.length).toUpperCase()}'),
                    const Divider(height: 20),
                    const Text(
                      'Customer WhatsApp Number:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'e.g. 9876543210',
                        prefixIcon: const Icon(Icons.chat, color: Color(0xFF25D366), size: 20),
                        suffixIcon: _phoneController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 16),
                                onPressed: () => setState(() => _phoneController.clear()),
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF25D366), width: 2),
                        ),
                        helperText: '10 digits Indian number automatically gets +91',
                        helperStyle: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Items Breakdown ──────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Billing Items', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                        Text('${_items.length} item', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                    const Divider(height: 20),
                    ..._items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.description, style: const TextStyle(fontSize: 13, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                                Text(item.type.label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
                              ],
                            ),
                          ),
                          Text(
                            AppFormatters.formatCurrency(item.total),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // ── Totals Card ──────────────────────────────────
              AppCard(
                child: Column(
                  children: [
                    _TotalLine(label: 'कमरे का किराया (Room Tariff)', value: AppFormatters.formatCurrency(_subtotal)),
                    if (b.paidAmount > 0 && !_isSettled)
                      _TotalLine(
                        label: 'अग्रिम जमा राशि (Advance Paid)',
                        value: '- ${AppFormatters.formatCurrency(b.paidAmount)}',
                        valueColor: AppColors.success,
                        isBold: true,
                      ),
                    const Divider(),
                    _TotalLine(
                      label: 'कुल बिल (Total Bill)',
                      value: AppFormatters.formatCurrency(_grandTotal),
                      isBold: true,
                      isLarge: true,
                    ),
                    const Divider(),
                    _TotalLine(
                      label: 'कुल प्राप्त (Total Paid)',
                      value: AppFormatters.formatCurrency(_paid),
                      valueColor: AppColors.success,
                    ),
                    if (_pending > 0)
                      _TotalLine(
                        label: 'बाकी रकम (Balance Due)',
                        value: AppFormatters.formatCurrency(_pending),
                        valueColor: AppColors.error,
                        isBold: true,
                      )
                    else
                      const _TotalLine(
                        label: 'Payment Status',
                        value: 'पूर्ण भुगतान (FULL PAID)',
                        valueColor: AppColors.success,
                        isBold: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Action Button: [ Send WhatsApp ] ──
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _sendWhatsApp,
                  icon: const Icon(Icons.chat, size: 22, color: Colors.white),
                  label: const Text(
                    'Send WhatsApp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shadowColor: const Color(0xFF25D366).withOpacity(0.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              if (!_isSettled && _pending > 0)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _markPaid,
                    icon: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                    label: Text(
                      'बाकी ₹${_pending.toStringAsFixed(0)} प्राप्त करें (Mark as Paid)',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.success),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.success),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TotalLine extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isLarge;
  final Color? valueColor;

  const _TotalLine({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isLarge = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isLarge ? 15 : 13,
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                fontFamily: 'Inter',
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 17 : 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              fontFamily: 'Inter',
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
