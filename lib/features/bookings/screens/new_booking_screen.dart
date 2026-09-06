import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/booking.dart';
import '../../../models/room.dart';
import '../../../models/guest.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/room_repository.dart';
import '../../../repositories/guest_repository.dart';

class NewBookingScreen extends StatefulWidget {
  const NewBookingScreen({super.key});

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _dataLoading = true;

  List<Room> _availableRooms = [];
  List<Guest> _guests = [];

  Guest? _selectedGuest;
  Room? _selectedRoom;
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _adults = 2;
  int _children = 0;
  BookingSource _source = BookingSource.direct;
  PaymentStatus _paymentStatus = PaymentStatus.pending;
  bool _checkInNow = false; // Auto check-in toggle
  final _specialRequestController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _advanceAmountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _specialRequestController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final roomRepo = context.read<RoomRepository>();
    final guestRepo = context.read<GuestRepository>();
    final results = await Future.wait([roomRepo.getRooms(), guestRepo.getGuests()]);
    if (!mounted) return;
    setState(() {
      _availableRooms = (results[0] as List<Room>).where((r) => r.status == RoomStatus.available).toList();
      _guests = results[1] as List<Guest>;
      _dataLoading = false;
    });
  }

  double get _totalAmount {
    if (_selectedRoom == null) return 0;
    final nights = _checkOut.difference(_checkIn).inDays;
    return _selectedRoom!.pricePerNight * (nights <= 0 ? 1 : nights);
  }

  double get _advanceAmount => double.tryParse(_advanceAmountController.text.trim()) ?? 0.0;
  double get _pendingBalance => (_totalAmount - _advanceAmount).clamp(0.0, double.infinity);

  Future<void> _selectDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn.add(const Duration(days: 1)))) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);
    const uuid = Uuid();
    final bookingRepo = context.read<BookingRepository>();
    final roomRepo = context.read<RoomRepository>();

    // If checkInNow, check-in date = today
    final effectiveCheckIn = _checkInNow ? DateTime.now() : _checkIn;
    final adv = _advanceAmount;
    final effectivePaymentStatus = adv >= _totalAmount && _totalAmount > 0
        ? PaymentStatus.paid
        : (adv > 0 ? PaymentStatus.partial : PaymentStatus.pending);

    final booking = Booking(
      id: uuid.v4(),
      guestId: _selectedGuest?.id ?? uuid.v4(),
      guestName: _selectedGuest?.name ?? _guestNameController.text.trim(),
      guestPhone: _selectedGuest?.phone ?? _guestPhoneController.text.trim(),
      roomId: _selectedRoom!.id,
      roomNumber: _selectedRoom!.number,
      roomType: _selectedRoom!.type.label,
      checkIn: effectiveCheckIn,
      checkOut: _checkOut,
      adults: _adults,
      children: _children,
      source: _source,
      status: _checkInNow ? BookingStatus.checkedIn : BookingStatus.upcoming,
      paymentStatus: effectivePaymentStatus,
      totalAmount: _totalAmount,
      paidAmount: adv,
      createdAt: DateTime.now(),
      specialRequest: _specialRequestController.text.trim().isEmpty ? null : _specialRequestController.text.trim(),
    );

    await bookingRepo.createBooking(booking, checkInNow: _checkInNow);

    // If auto check-in, also update room in the repository
    if (_checkInNow) {
      await roomRepo.checkIn(
        _selectedRoom!.id,
        booking.guestId,
        booking.guestName,
        booking.id,
        effectiveCheckIn,
        _checkOut,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _checkInNow
              ? '✅ Booking created & Guest Checked-In — Room ${_selectedRoom!.number}'
              : 'Booking created successfully!',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _checkInNow ? AppColors.available : null,
      ),
    );
    context.go('/bookings');
  }

  @override
  Widget build(BuildContext context) {
    if (_dataLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/bookings');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('New Booking'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back)',
            onPressed: () => context.go('/bookings'),
          ),
        ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Guest section
            _SectionCard(
              title: 'Guest Information',
              child: Column(
                children: [
                  // Select existing guest
                  DropdownButtonFormField<Guest>(
                    decoration: const InputDecoration(labelText: 'Select Existing Guest (optional)'),
                    value: _selectedGuest,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('New Guest')),
                      ..._guests.map((g) => DropdownMenuItem(value: g, child: Text(g.name))),
                    ],
                    onChanged: (g) => setState(() => _selectedGuest = g),
                  ),
                  if (_selectedGuest == null) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guestNameController,
                      decoration: const InputDecoration(labelText: 'Guest Name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _guestPhoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number *'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Room section
            _SectionCard(
              title: 'Room Selection',
              child: DropdownButtonFormField<Room>(
                decoration: const InputDecoration(labelText: 'Select Room *'),
                value: _selectedRoom,
                items: _availableRooms.map((r) => DropdownMenuItem(
                  value: r,
                  child: Text('Room ${r.number} - ${r.type.label} (₹${r.pricePerNight.toStringAsFixed(0)}/night)'),
                )).toList(),
                onChanged: (r) => setState(() => _selectedRoom = r),
                validator: (v) => v == null ? 'Please select a room' : null,
              ),
            ),
            const SizedBox(height: 16),

            // Dates
            _SectionCard(
              title: 'Stay Duration',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Check-in',
                          date: _checkIn,
                          onTap: () => _selectDate(true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'Check-out',
                          date: _checkOut,
                          onTap: () => _selectDate(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _NumberField(label: 'Adults', value: _adults, onChanged: (v) => setState(() => _adults = v), min: 1)),
                      const SizedBox(width: 12),
                      Expanded(child: _NumberField(label: 'Children', value: _children, onChanged: (v) => setState(() => _children = v), min: 0)),
                    ],
                  ),
                  if (_selectedRoom != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_checkOut.difference(_checkIn).inDays} Night(s)', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
                          Text(AppFormatters.formatCurrency(_totalAmount), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Booking details
            _SectionCard(
              title: 'Booking Details',
              child: Column(
                children: [
                  DropdownButtonFormField<BookingSource>(
                    decoration: const InputDecoration(labelText: 'Booking Source'),
                    value: _source,
                    items: BookingSource.values.map((s) => DropdownMenuItem(value: s, child: Text(s.label))).toList(),
                    onChanged: (v) => setState(() => _source = v!),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _specialRequestController,
                    decoration: const InputDecoration(labelText: 'Special Request (optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Advance Payment Section ─────────────────────
            _SectionCard(
              title: '💰 अग्रिम भुगतान (Advance Payment)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _advanceAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'अग्रिम राशि (Advance Amount Received)',
                      prefixText: '₹ ',
                      hintText: '0',
                    ),
                    onChanged: (v) {
                      final adv = double.tryParse(v) ?? 0;
                      setState(() {
                        if (adv >= _totalAmount && _totalAmount > 0) {
                          _paymentStatus = PaymentStatus.paid;
                        } else if (adv > 0) {
                          _paymentStatus = PaymentStatus.partial;
                        } else {
                          _paymentStatus = PaymentStatus.pending;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  // Quick shortcut buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.money_off, size: 16),
                        label: const Text('₹0 (बिना एडवांस)'),
                        onPressed: () {
                          _advanceAmountController.text = '0';
                          setState(() => _paymentStatus = PaymentStatus.pending);
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.pie_chart_outline, size: 16),
                        label: const Text('50% एडवांस'),
                        onPressed: () {
                          final half = (_totalAmount * 0.5).round();
                          _advanceAmountController.text = '$half';
                          setState(() => _paymentStatus = PaymentStatus.partial);
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.check_circle_outline, size: 16, color: AppColors.success),
                        label: const Text('पूरा पेमेंट (100% Full)'),
                        onPressed: () {
                          _advanceAmountController.text = '${_totalAmount.round()}';
                          setState(() => _paymentStatus = PaymentStatus.paid);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Live breakdown
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('कुल कमरा किराया (Total Tariff):', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                            Text(AppFormatters.formatCurrency(_totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('अग्रिम जमा (Advance Paid):', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                            Text(AppFormatters.formatCurrency(_advanceAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'Inter')),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('चेकआउट पर बाकी (Due at Check-out):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                            Text(
                              AppFormatters.formatCurrency(_pendingBalance),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Inter',
                                color: _pendingBalance > 0 ? AppColors.error : AppColors.success,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Check-in Now Toggle ─────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: _checkInNow
                    ? LinearGradient(
                        colors: [AppColors.available.withAlpha(25), AppColors.available.withAlpha(10)],
                      )
                    : null,
                color: _checkInNow ? null : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _checkInNow ? AppColors.available : AppColors.border,
                  width: _checkInNow ? 1.5 : 1,
                ),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: const Text(
                  'Check-in Now',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Inter'),
                ),
                subtitle: Text(
                  _checkInNow
                      ? 'Guest will be checked in immediately. Room → Occupied.'
                      : 'Toggle to check-in the guest right now (walk-in)',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Inter',
                    color: _checkInNow ? AppColors.available : AppColors.textSecondary,
                  ),
                ),
                secondary: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _checkInNow ? AppColors.available.withAlpha(30) : AppColors.grey100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _checkInNow ? Icons.login_rounded : Icons.login_outlined,
                    color: _checkInNow ? AppColors.available : AppColors.textSecondary,
                    size: 22,
                  ),
                ),
                value: _checkInNow,
                activeColor: AppColors.available,
                onChanged: (v) => setState(() => _checkInNow = v),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: _checkInNow
                    ? ElevatedButton.styleFrom(
                        backgroundColor: AppColors.available,
                        foregroundColor: Colors.white,
                      )
                    : null,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _checkInNow ? Icons.login_rounded : Icons.check_circle_outline,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _checkInNow ? 'Create Booking & Check-In' : 'Create Booking',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ));
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter')),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grey50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
            const SizedBox(height: 4),
            Text(AppFormatters.formatDate(date), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  const _NumberField({required this.label, required this.value, required this.onChanged, required this.min});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: () { if (value > min) onChanged(value - 1); },
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.grey100, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, size: 16)),
            ),
            const SizedBox(width: 12),
            Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => onChanged(value + 1),
              child: Container(width: 32, height: 32, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, size: 16, color: Colors.white)),
            ),
          ],
        ),
      ],
    );
  }
}
