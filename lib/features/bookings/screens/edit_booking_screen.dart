import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/booking.dart';
import '../../../models/room.dart';
import '../../../repositories/booking_repository.dart';
import '../../../repositories/room_repository.dart';
import '../../../widgets/common_widgets.dart';

class EditBookingScreen extends StatefulWidget {
  final String bookingId;
  const EditBookingScreen({super.key, required this.bookingId});

  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  Booking? _booking;
  List<Room> _rooms = [];

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _requestsController;
  late TextEditingController _totalAmountController;
  late TextEditingController _paidAmountController;

  late DateTime _checkIn;
  late DateTime _checkOut;
  Room? _selectedRoom;
  int _adults = 1;
  int _children = 0;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _requestsController = TextEditingController();
    _totalAmountController = TextEditingController();
    _paidAmountController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _requestsController.dispose();
    _totalAmountController.dispose();
    _paidAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final bookingRepo = context.read<BookingRepository>();
    final roomRepo = context.read<RoomRepository>();

    final booking = await bookingRepo.getBookingById(widget.bookingId);
    final rooms = await roomRepo.getRooms();

    if (!mounted) return;
    if (booking == null) {
      setState(() => _isLoading = false);
      return;
    }

    _booking = booking;
    _rooms = rooms;
    _nameController.text = booking.guestName;
    _phoneController.text = booking.guestPhone;
    _requestsController.text = booking.specialRequest ?? '';
    _totalAmountController.text = booking.totalAmount.toStringAsFixed(0);
    _paidAmountController.text = booking.paidAmount.toStringAsFixed(0);
    _checkIn = booking.checkIn;
    _checkOut = booking.checkOut;
    _adults = booking.adults;
    _children = booking.children;

    try {
      _selectedRoom = rooms.firstWhere((r) => r.id == booking.roomId || r.number == booking.roomNumber);
    } catch (_) {
      _selectedRoom = rooms.isNotEmpty ? rooms.first : null;
    }

    setState(() => _isLoading = false);
  }

  int get _nights {
    final diff = _checkOut.difference(_checkIn).inDays;
    return diff <= 0 ? 1 : diff;
  }

  void _recalculateTotal() {
    if (_selectedRoom != null) {
      final total = _selectedRoom!.pricePerNight * _nights;
      _totalAmountController.text = total.toStringAsFixed(0);
    }
  }

  Future<void> _selectDate(bool isCheckIn) async {
    final initial = isCheckIn ? _checkIn : _checkOut;
    final first = isCheckIn ? DateTime.now().subtract(const Duration(days: 30)) : _checkIn.add(const Duration(days: 1));
    final last = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : initial,
      firstDate: first,
      lastDate: last,
    );

    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (!_checkOut.isAfter(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          _checkOut = picked;
        }
        _recalculateTotal();
      });
    }
  }

  Future<void> _saveBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final bookingRepo = context.read<BookingRepository>();

    final total = double.tryParse(_totalAmountController.text) ?? _booking!.totalAmount;
    final paid = double.tryParse(_paidAmountController.text) ?? _booking!.paidAmount;

    final updates = <String, dynamic>{
      'guestName': _nameController.text.trim(),
      'guestPhone': _phoneController.text.trim(),
      'roomId': _selectedRoom!.id,
      'roomNumber': _selectedRoom!.number,
      'roomType': _selectedRoom!.type.label,
      'checkIn': _checkIn,
      'checkOut': _checkOut,
      'adults': _adults,
      'children': _children,
      'totalAmount': total,
      'paidAmount': paid,
      'specialRequest': _requestsController.text.trim(),
    };

    try {
      await bookingRepo.updateBooking(widget.bookingId, updates);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking updated successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating booking: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());
    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Booking')),
        body: const EmptyState(icon: Icons.error_outline, title: 'Booking not found'),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Edit Booking #${widget.bookingId.substring(0, 8).toUpperCase()}'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _saveBooking,
            icon: _isSaving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Guest Information ────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Guest Information', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Guest Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter guest name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number *',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Enter phone number' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Stay & Room Details ───────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Stay & Room Selection', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 14),

                    // Room Dropdown
                    DropdownButtonFormField<Room>(
                      isExpanded: true,
                      value: _selectedRoom,
                      decoration: const InputDecoration(
                        labelText: 'Select Room *',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      items: _rooms.map((r) {
                        return DropdownMenuItem<Room>(
                          value: r,
                          child: Text(
                            'Room ${r.number} - ${r.type.label} (${AppFormatters.formatCurrency(r.pricePerNight)}/nt)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedRoom = val;
                          _recalculateTotal();
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Dates Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-In',
                                prefixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(AppFormatters.formatDate(_checkIn), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Check-Out',
                                prefixIcon: Icon(Icons.calendar_month, size: 18),
                              ),
                              child: Text(AppFormatters.formatDate(_checkOut), style: const TextStyle(fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duration: $_nights Night(s)',
                      style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    // Guests Count
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Adults:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: _adults > 1 ? () => setState(() => _adults--) : null,
                                  ),
                                  Text('$_adults', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _adults < 10 ? () => setState(() => _adults++) : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Children:', style: TextStyle(fontWeight: FontWeight.w600)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: _children > 0 ? () => setState(() => _children--) : null,
                                  ),
                                  Text('$_children', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: _children < 8 ? () => setState(() => _children++) : null,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Payment Details ──────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _totalAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Total Tariff (₹)',
                              prefixIcon: Icon(Icons.currency_rupee),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _paidAmountController,
                            decoration: const InputDecoration(
                              labelText: 'Paid Amount (₹)',
                              prefixIcon: Icon(Icons.check_circle_outline),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid amount' : null,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Special Request ──────────────────────────────
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Special Requests / Notes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _requestsController,
                      decoration: const InputDecoration(
                        hintText: 'Any special requests from guest...',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Submit Button ────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveBooking,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save),
                  label: Text(_isSaving ? 'Updating...' : 'Update Booking'),
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
      ),
    );
  }
}
