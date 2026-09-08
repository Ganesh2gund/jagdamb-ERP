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
import '../../../services/api_client.dart';

class NewBookingScreen extends StatefulWidget {
  final String? preselectedRoomId;
  final bool initialCheckInNow;

  const NewBookingScreen({
    super.key,
    this.preselectedRoomId,
    this.initialCheckInNow = true,
  });

  @override
  State<NewBookingScreen> createState() => _NewBookingScreenState();
}

class _NewBookingScreenState extends State<NewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _dataLoading = true;

  List<Room> _availableRooms = [];

  Guest? _selectedGuest;
  Room? _selectedRoom;
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _adults = 2;
  int _children = 0;
  BookingSource _source = BookingSource.direct;
  PaymentStatus _paymentStatus = PaymentStatus.paid;
  bool _checkInNow = true; // Auto check-in default for front desk walk-ins
  final _specialRequestController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _advanceAmountController = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _checkInNow = widget.initialCheckInNow;
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

  String _fmtDate(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  RoomType _parseRoomType(String? t) {
    switch (t?.toLowerCase()) {
      case 'deluxe': return RoomType.deluxe;
      case 'suite': return RoomType.suite;
      case 'executive': return RoomType.executive;
      case 'presidential': return RoomType.presidential;
      default: return RoomType.standard;
    }
  }

  Future<void> _fetchAvailableRoomsForDates() async {
    final effectiveCheckIn = _checkInNow ? DateTime.now() : _checkIn;
    final inStr = _fmtDate(effectiveCheckIn);
    final outStr = _fmtDate(_checkOut);
    try {
      final res = await ApiClient.instance.get('/rooms?checkIn=$inStr&checkOut=$outStr');
      if (res is Map && res['data'] is List) {
        final List<Room> loaded = (res['data'] as List).map((m) {
          return Room(
            id: m['id']?.toString() ?? '',
            number: m['number']?.toString() ?? '',
            floor: (m['floor'] as num?)?.toInt() ?? 1,
            type: _parseRoomType(m['type']?.toString()),
            pricePerNight: (m['pricePerNight'] as num?)?.toDouble() ?? 0.0,
            status: RoomStatus.available,
            amenities: (m['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
            maxGuests: (m['maxGuests'] as num?)?.toInt() ?? 2,
          );
        }).toList();

        if (mounted) {
          setState(() {
            _availableRooms = loaded;
            if (_selectedRoom != null && !_availableRooms.any((r) => r.id == _selectedRoom!.id)) {
              _selectedRoom = null;
            }
          });
        }
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    final roomRepo = context.read<RoomRepository>();
    final rooms = await roomRepo.getRooms();
    if (!mounted) return;
    setState(() {
      _availableRooms = rooms.where((r) => r.status == RoomStatus.available).toList();
      if (_selectedRoom != null && !_availableRooms.any((r) => r.id == _selectedRoom!.id)) {
        _selectedRoom = null;
      }
    });
  }

  Future<void> _loadData() async {
    await _fetchAvailableRoomsForDates();
    if (!mounted) return;

    Room? matchedRoom;
    if (widget.preselectedRoomId != null) {
      final matches = _availableRooms.where((r) => r.id == widget.preselectedRoomId || r.number == widget.preselectedRoomId);
      if (matches.isNotEmpty) {
        matchedRoom = matches.first;
      }
    }
    setState(() {
      _selectedRoom = matchedRoom;
      if (matchedRoom != null) {
        // Auto-fill advance = full total (nights × price)
        final nights = _checkOut.difference(_checkIn).inDays;
        final total = matchedRoom.pricePerNight * (nights <= 0 ? 1 : nights);
        _advanceAmountController.text = total.toStringAsFixed(0);
        _paymentStatus = PaymentStatus.paid;
      }
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
        // Auto-recalculate total & update advance if room is selected
        _recalculateAdvanceAfterDateChange();
      });
      await _fetchAvailableRoomsForDates();
    }
  }

  /// After dates change, recalculate advance amount to reflect new total
  void _recalculateAdvanceAfterDateChange() {
    if (_selectedRoom == null) return;
    final nights = _checkOut.difference(_checkIn).inDays;
    final newTotal = _selectedRoom!.pricePerNight * (nights <= 0 ? 1 : nights);
    final currentAdv = double.tryParse(_advanceAmountController.text.trim()) ?? 0;
    // Auto-update if user is in "full paid" mode or advance is 0
    // Don't override a partial amount user manually typed
    if (_paymentStatus == PaymentStatus.paid || currentAdv == 0) {
      _advanceAmountController.text = newTotal.toStringAsFixed(0);
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
      paymentStatus: _paymentStatus,
      totalAmount: _totalAmount,
      paidAmount: adv,
      createdAt: DateTime.now(),
      specialRequest: _specialRequestController.text.trim().isEmpty ? null : _specialRequestController.text.trim(),
    );

    try {
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
                ? '✅ Guest Checked-In to Room ${_selectedRoom!.number} — Room is now Occupied!'
                : 'Booking created successfully!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _checkInNow ? AppColors.available : null,
        ),
      );
      if (_checkInNow) {
        context.go('/rooms');
      } else {
        context.go('/bookings');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final msg = e is ApiException ? e.message : 'Booking creation failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dataLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/rooms');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(_checkInNow ? 'Check-in Guest' : 'Advance Booking'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Back',
            onPressed: () => context.go('/rooms'),
          ),
        ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Mode Switch: Walk-in Check-in vs Advance Reservation ──
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _checkInNow = true;
                          _checkIn = DateTime.now();
                        });
                        _fetchAvailableRoomsForDates();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _checkInNow ? AppColors.available : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.login, size: 16, color: _checkInNow ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Walk-in Check-in',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _checkInNow ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _checkInNow = false;
                        });
                        _fetchAvailableRoomsForDates();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_checkInNow ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_month, size: 16, color: !_checkInNow ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Advance Booking',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !_checkInNow ? Colors.white : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Guest section
            _SectionCard(
              title: 'Guest Information',
              child: Column(
                children: [
                  // Select existing guest
                  DropdownButtonFormField<Guest?>(
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Select Existing Guest (optional)'),
                    value: _selectedGuest,
                    items: const [
                      DropdownMenuItem<Guest?>(
                        value: null,
                        child: Text('New Guest', overflow: TextOverflow.ellipsis),
                      ),
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
              child: DropdownButtonFormField<String?>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Select Room *'),
                value: (_selectedRoom != null && _availableRooms.any((r) => r.id == _selectedRoom!.id))
                    ? _selectedRoom!.id
                    : null,
                items: _availableRooms.map((r) => DropdownMenuItem<String?>(
                  value: r.id,
                  child: Text(
                    'Room ${r.number} - ${r.type.label} (₹${r.pricePerNight.toStringAsFixed(0)}/day)',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                )).toList(),
                onChanged: (roomId) {
                  setState(() {
                    try {
                      _selectedRoom = _availableRooms.firstWhere((r) => r.id == roomId);
                    } catch (_) {
                      _selectedRoom = null;
                    }
                    if (_selectedRoom != null) {
                      // Auto-set advance = full total (nights × price per night)
                      final nights = _checkOut.difference(_checkIn).inDays;
                      final total = _selectedRoom!.pricePerNight * (nights <= 0 ? 1 : nights);
                      _advanceAmountController.text = total.toStringAsFixed(0);
                      _paymentStatus = PaymentStatus.paid;
                    }
                  });
                },
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
                          Text('${_checkOut.difference(_checkIn).inDays} Day(s)', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
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
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Booking Source'),
                    value: _source,
                    items: BookingSource.values.map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.label, overflow: TextOverflow.ellipsis),
                    )).toList(),
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

            // ── Payment Section ─────────────────────
            _SectionCard(
              title: 'Payment Option',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Timing / Advance:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Option 1: Full Payment
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _advanceAmountController.text = _totalAmount.toStringAsFixed(0);
                              _paymentStatus = PaymentStatus.paid;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: (_advanceAmount >= _totalAmount && _totalAmount > 0)
                                  ? AppColors.success.withAlpha(30)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_advanceAmount >= _totalAmount && _totalAmount > 0)
                                    ? AppColors.success
                                    : AppColors.border,
                                width: (_advanceAmount >= _totalAmount && _totalAmount > 0) ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: (_advanceAmount >= _totalAmount && _totalAmount > 0)
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Full Payment\n(Paid in Full)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Option 2: Partial
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              final half = (_totalAmount * 0.5).round();
                              _advanceAmountController.text = '$half';
                              _paymentStatus = PaymentStatus.partial;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: (_advanceAmount > 0 && _advanceAmount < _totalAmount)
                                  ? AppColors.warning.withAlpha(30)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_advanceAmount > 0 && _advanceAmount < _totalAmount)
                                    ? AppColors.warning
                                    : AppColors.border,
                                width: (_advanceAmount > 0 && _advanceAmount < _totalAmount) ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pie_chart_outline,
                                  color: (_advanceAmount > 0 && _advanceAmount < _totalAmount)
                                      ? AppColors.warning
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Partial Advance\n(Deposit)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Option 3: Pay at Check-out
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _advanceAmountController.text = '0';
                              _paymentStatus = PaymentStatus.pending;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                            decoration: BoxDecoration(
                              color: (_advanceAmount == 0)
                                  ? AppColors.error.withAlpha(30)
                                  : AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: (_advanceAmount == 0) ? AppColors.error : AppColors.border,
                                width: (_advanceAmount == 0) ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: (_advanceAmount == 0) ? AppColors.error : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Pay at Checkout\n(Zero Advance)',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _advanceAmountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Advance Amount Received Now',
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
                            const Text('Total Room Tariff:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
                            Text(AppFormatters.formatCurrency(_totalAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Advance Paid:', style: TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
                            Text(AppFormatters.formatCurrency(_advanceAmount), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.success, fontFamily: 'Inter')),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Balance Due at Check-out:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
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
            const SizedBox(height: 24),

            // ── Primary Action Button ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _checkInNow ? AppColors.available : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _checkInNow ? Icons.login_rounded : Icons.calendar_month,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _checkInNow
                                ? 'Check-In Guest'
                                : 'Save Booking',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
