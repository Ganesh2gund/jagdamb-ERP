import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/banquet.dart';
import '../../../repositories/banquet_repository.dart';
import '../../../services/api_client.dart';
import '../../../widgets/common_widgets.dart';

class NewBanquetBookingScreen extends StatefulWidget {
  const NewBanquetBookingScreen({super.key});

  @override
  State<NewBanquetBookingScreen> createState() => _NewBanquetBookingScreenState();
}

class _NewBanquetBookingScreenState extends State<NewBanquetBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final BanquetRepository _repository = HttpBanquetRepository();

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<BanquetHall> _halls = [];
  List<BanquetPackage> _packages = [];

  // Form Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController(text: '100');
  final _extraChargesCtrl = TextEditingController(text: '0');
  final _advanceCtrl = TextEditingController(text: '10000');
  final _notesCtrl = TextEditingController();

  // Selections
  BanquetHall? _selectedHall;
  BanquetPackage? _selectedPackage;
  String _eventType = 'Wedding (शादी)';
  DateTime _eventDate = DateTime.now().add(const Duration(days: 7));
  String _slot = 'Evening';
  String _paymentMode = 'Cash';

  final List<String> _eventTypes = [
    'Wedding (शादी)',
    'Reception (रिसेप्शन)',
    'Birthday (जन्मदिन)',
    'Corporate Event (कॉर्पोरेट)',
    'Anniversary (सालगिरह)',
    'Engagement (सगाई)',
    'Other Function (अन्य उत्सव)',
  ];

  @override
  void initState() {
    super.initState();
    _loadMasterData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _guestsCtrl.dispose();
    _extraChargesCtrl.dispose();
    _advanceCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Map<String, bool> _slotAvailability = {'Morning': true, 'Evening': true, 'Full Day': true};
  bool _isCheckingSlots = false;

  String _formatDateStr(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _checkSlotAvailability() async {
    if (_selectedHall == null) return;
    final dateStr = _formatDateStr(_eventDate);
    setState(() => _isCheckingSlots = true);
    try {
      final res = await _repository.getSlotAvailability(_selectedHall!.id, dateStr);
      final slots = res['slots'] as Map<String, dynamic>?;
      final morningAvail = res['morning'] is bool
          ? (res['morning'] as bool)
          : ((slots?['morning']?['available'] as bool?) ?? true);
      final eveningAvail = res['evening'] is bool
          ? (res['evening'] as bool)
          : ((slots?['evening']?['available'] as bool?) ?? true);
      final fullDayAvail = res['fullDay'] is bool
          ? (res['fullDay'] as bool)
          : ((slots?['fullDay']?['available'] as bool?) ?? true);

      if (mounted) {
        setState(() {
          _slotAvailability = {
            'Morning': morningAvail,
            'Evening': eveningAvail,
            'Full Day': fullDayAvail,
          };
          if (_slotAvailability[_slot] == false) {
            if (morningAvail) {
              _slot = 'Morning';
            } else if (eveningAvail) {
              _slot = 'Evening';
            } else if (fullDayAvail) {
              _slot = 'Full Day';
            }
          }
          _isCheckingSlots = false;
        });
      }
      return;
    } catch (_) {}
    if (mounted) setState(() => _isCheckingSlots = false);
  }

  Future<void> _loadMasterData() async {
    try {
      final results = await Future.wait([
        _repository.getHalls(),
        _repository.getPackages(),
      ]);
      if (!mounted) return;
      setState(() {
        _halls = results[0] as List<BanquetHall>;
        _packages = results[1] as List<BanquetPackage>;
        if (_halls.isNotEmpty) {
          _selectedHall = _halls.first;
        }
        if (_packages.isNotEmpty) {
          _selectedPackage = _packages.first;
        }
        _isLoading = false;
      });
      await _checkSlotAvailability();
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _hallRent {
    if (_selectedHall == null) return 0.0;
    if (_slot == 'Morning') return _selectedHall!.baseRentMorning;
    if (_slot == 'Evening') return _selectedHall!.baseRentEvening;
    return _selectedHall!.baseRentFullDay;
  }

  int get _expectedGuests => int.tryParse(_guestsCtrl.text.trim()) ?? 0;
  double get _pricePerPlate => _selectedPackage?.pricePerPlate ?? 0.0;
  double get _foodTotal => _expectedGuests * _pricePerPlate;
  double get _extraCharges => double.tryParse(_extraChargesCtrl.text.trim()) ?? 0.0;
  double get _grandTotal => _hallRent + _foodTotal + _extraCharges;
  double get _advanceAmount => double.tryParse(_advanceCtrl.text.trim()) ?? 0.0;
  double get _balanceDue => (_grandTotal - _advanceAmount).clamp(0.0, double.infinity);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedHall == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a banquet hall'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_slotAvailability[_slot] == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ यह स्लॉट ($_slot) इस तारीख के लिए पहले से बुक है! कृपया दूसरा स्लॉट चुनें।'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = {
      'hallId': _selectedHall!.id,
      'hallName': _selectedHall!.name,
      'customerName': _nameCtrl.text.trim(),
      'customerPhone': _phoneCtrl.text.trim(),
      'eventType': _eventType,
      'eventDate': _formatDateStr(_eventDate),
      'slot': _slot,
      'expectedGuests': _expectedGuests,
      'packageId': _selectedPackage?.id ?? '',
      'packageName': _selectedPackage?.name ?? '',
      'pricePerPlate': _pricePerPlate,
      'foodTotal': _foodTotal,
      'hallRent': _hallRent,
      'extraCharges': _extraCharges,
      'grandTotal': _grandTotal,
      'advancePaid': _advanceAmount,
      'balanceDue': _balanceDue,
      'status': 'confirmed',
      'paymentMode': _paymentMode,
      'notes': _notesCtrl.text.trim(),
    };

    try {
      final created = await _repository.createBooking(payload);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (created != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking ${created.bookingNumber} created successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create booking. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e is ApiException ? e.message : 'Failed to create booking: $e';
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
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('New Banquet Booking (नई बुकिंग)'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Section 1: Client Information ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Client Information (ग्राहक विवरण)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Customer / Host Name *',
                      hintText: 'उदा. Rajesh Patil',
                      prefixIcon: Icon(Icons.person, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter customer name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp / Contact Phone *',
                      hintText: '10-digit phone number',
                      prefixIcon: Icon(Icons.phone, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().length < 10) ? 'Enter valid 10-digit phone number' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 2: Event & Venue Details ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.celebration_outlined, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Event & Venue Details (इवेंट व हॉल)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<BanquetHall>(
                    initialValue: _halls.contains(_selectedHall) ? _selectedHall : (_halls.isNotEmpty ? _halls.first : null),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Banquet Hall *',
                      prefixIcon: Icon(Icons.meeting_room_outlined, size: 20),
                    ),
                    items: _halls.map((h) {
                      return DropdownMenuItem(
                        value: h,
                        child: Text(
                          '${h.name} (Cap: ${h.capacity})',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedHall = val);
                        _checkSlotAvailability();
                      }
                    },
                    validator: (v) => v == null ? 'Please select a hall' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _eventTypes.contains(_eventType) ? _eventType : _eventTypes.first,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Event Type (इवेंट का प्रकार)',
                      prefixIcon: Icon(Icons.event_outlined, size: 20),
                    ),
                    items: _eventTypes.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _eventType = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _eventDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _eventDate = picked);
                              _checkSlotAvailability();
                            }
                          },
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(
                            AppFormatters.formatDate(_eventDate),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      const Text('Slot Selection (समय स्लॉट):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      if (_isCheckingSlots) ...[
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _slotChip('Morning', 'सुबह (8 AM - 3 PM)'),
                      const SizedBox(width: 8),
                      _slotChip('Evening', 'शाम (4 PM - 11 PM)'),
                      const SizedBox(width: 8),
                      _slotChip('Full Day', 'पूरा दिन (Full Day)'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 3: Catering & Add-ons ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.restaurant_menu, size: 20, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Text('Catering & Guests (केटरिंग व अतिथि)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<BanquetPackage?>(
                    initialValue: (_selectedPackage != null && _packages.contains(_selectedPackage)) ? _selectedPackage : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Catering Food Package',
                      prefixIcon: Icon(Icons.food_bank_outlined, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('No Catering (हॉल रेंट केवल)', overflow: TextOverflow.ellipsis, maxLines: 1),
                      ),
                      ..._packages.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (₹${p.pricePerPlate.toStringAsFixed(0)}/plate)',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedPackage = val),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _guestsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Guests *',
                            prefixIcon: Icon(Icons.people_outline, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Enter valid count';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _extraChargesCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Decor & Extras (₹)',
                            prefixIcon: Icon(Icons.stars_outlined, size: 20),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Special Notes / Decoration Requests (वैकल्पिक)',
                      hintText: 'उदा. स्टेज डेकोरेशन, साउंड सिस्टम, वरमाला',
                      prefixIcon: Icon(Icons.note_alt_outlined, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Section 4: Live Billing & Advance Payment ──
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Billing & Payment (बिल व एडवांस भुगतान)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  InfoRow(label: 'हॉल बेस किराया ($_slot):', value: AppFormatters.formatCurrency(_hallRent)),
                  if (_selectedPackage != null)
                    InfoRow(
                      label: 'केटरिंग भोजन ($_expectedGuests × ₹${_pricePerPlate.toStringAsFixed(0)}):',
                      value: AppFormatters.formatCurrency(_foodTotal),
                    ),
                  if (_extraCharges > 0)
                    InfoRow(label: 'डेकोरेशन व अन्य:', value: AppFormatters.formatCurrency(_extraCharges)),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('कुल राशि (Grand Total):', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      Text(
                        AppFormatters.formatCurrency(_grandTotal),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _advanceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Advance Paid (जमा एडवांस राशि) *',
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      filled: true,
                      fillColor: AppColors.surfaceVariant.withValues(alpha: 0.4),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Cash', 'UPI', 'Card'].map((m) {
                      final isSel = _paymentMode == m;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            label: Text(m),
                            selected: isSel,
                            selectedColor: AppColors.primaryLight,
                            onSelected: (_) => setState(() => _paymentMode = m),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _balanceDue > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _balanceDue > 0 ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _balanceDue > 0 ? 'बकाया राशि (Balance Due):' : 'भुगतान स्थिति (Status):',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _balanceDue > 0 ? const Color(0xFFB45309) : const Color(0xFF065F46),
                          ),
                        ),
                        Text(
                          _balanceDue > 0 ? AppFormatters.formatCurrency(_balanceDue) : '✓ पूरा भुगतान (Paid)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: _balanceDue > 0 ? const Color(0xFFB45309) : const Color(0xFF065F46),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Submit Button ──
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, size: 22),
                label: Text(
                  _isSubmitting ? 'बुकिंग प्रोसेस हो रही है...' : 'बैंक्वेट बुकिंग कन्फर्म करें (Confirm Booking)',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _slotChip(String slotKey, String label) {
    final isSelected = _slot == slotKey;
    final isAvailable = _slotAvailability[slotKey] ?? true;

    return Expanded(
      child: GestureDetector(
        onTap: isAvailable ? () => setState(() => _slot = slotKey) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: !isAvailable
                ? AppColors.grey100
                : (isSelected ? AppColors.primary : AppColors.surfaceVariant.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: !isAvailable
                  ? AppColors.border
                  : (isSelected ? AppColors.primary : AppColors.border),
            ),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slotKey,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: !isAvailable
                      ? AppColors.textSecondary
                      : (isSelected ? Colors.white : AppColors.textPrimary),
                ),
              ),
              if (!isAvailable) ...[
                const SizedBox(height: 2),
                const Text(
                  'बुक है (Booked)',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
