import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/room.dart';
import '../../../models/booking.dart';
import '../../../repositories/room_repository.dart';
import '../../../repositories/booking_repository.dart';
import '../../../widgets/common_widgets.dart';

class RoomAvailabilityScreen extends StatefulWidget {
  const RoomAvailabilityScreen({super.key});

  @override
  State<RoomAvailabilityScreen> createState() => _RoomAvailabilityScreenState();
}

class _RoomAvailabilityScreenState extends State<RoomAvailabilityScreen> {
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  List<Room> _allRooms = [];
  List<Booking> _allBookings = [];
  RoomStatus? _filterStatus;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final roomRepo = context.read<RoomRepository>();
    final bookingRepo = context.read<BookingRepository>();

    final rooms = await roomRepo.getRooms();
    final bookings = await bookingRepo.getBookings();

    if (!mounted) return;
    setState(() {
      _allRooms = rooms;
      _allBookings = bookings;
      _isLoading = false;
    });
  }

  // Determine room status for selected date
  (RoomStatus status, String? guestName, String? bookingId) _getRoomStatusForDate(Room room, DateTime date) {
    // Check if any active booking covers this date
    final dateOnly = DateTime(date.year, date.month, date.day);

    final matchingBooking = _allBookings.firstWhere(
      (b) {
        if (b.roomId != room.id && b.roomNumber != room.number) return false;
        if (b.status == BookingStatus.cancelled || b.status == BookingStatus.noShow) return false;

        final checkInDate = DateTime(b.checkIn.year, b.checkIn.month, b.checkIn.day);
        final checkOutDate = DateTime(b.checkOut.year, b.checkOut.month, b.checkOut.day);

        return !dateOnly.isBefore(checkInDate) && dateOnly.isBefore(checkOutDate);
      },
      orElse: () => Booking(
        id: '',
        guestId: '',
        guestName: '',
        guestPhone: '',
        roomId: '',
        roomNumber: '',
        roomType: '',
        checkIn: DateTime.now(),
        checkOut: DateTime.now(),
        adults: 0,
        children: 0,
        source: BookingSource.direct,
        status: BookingStatus.upcoming,
        paymentStatus: PaymentStatus.pending,
        totalAmount: 0,
        paidAmount: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (matchingBooking.id.isNotEmpty) {
      if (matchingBooking.status == BookingStatus.checkedIn) {
        return (RoomStatus.occupied, matchingBooking.guestName, matchingBooking.id);
      } else {
        return (RoomStatus.reserved, matchingBooking.guestName, matchingBooking.id);
      }
    }

    // Default to current room status if viewing today
    final isToday = dateOnly == DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    if (isToday) {
      return (room.status, room.currentGuestName, room.currentBookingId);
    }

    return (RoomStatus.available, null, null);
  }

  Color _statusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return AppColors.available;
      case RoomStatus.occupied:
        return AppColors.occupied;
      case RoomStatus.reserved:
        return AppColors.reserved;
      case RoomStatus.cleaning:
        return AppColors.cleaning;
      case RoomStatus.maintenance:
        return AppColors.maintenance;
    }
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: offsetDays));
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: LoadingState());
    }

    // Calculate room statuses for selected date
    final roomStatusMap = <String, (RoomStatus status, String? guestName, String? bookingId)>{};
    int availableCount = 0;
    int occupiedCount = 0;
    int reservedCount = 0;
    int cleaningCount = 0;

    for (final room in _allRooms) {
      final info = _getRoomStatusForDate(room, _selectedDate);
      roomStatusMap[room.id] = info;
      switch (info.$1) {
        case RoomStatus.available:
          availableCount++;
          break;
        case RoomStatus.occupied:
          occupiedCount++;
          break;
        case RoomStatus.reserved:
          reservedCount++;
          break;
        case RoomStatus.cleaning:
        case RoomStatus.maintenance:
          cleaningCount++;
          break;
      }
    }

    // Filter rooms
    final filteredRooms = _allRooms.where((r) {
      final info = roomStatusMap[r.id]!;
      if (_filterStatus != null && info.$1 != _filterStatus) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesNum = r.number.toLowerCase().contains(q);
        final matchesType = r.type.label.toLowerCase().contains(q);
        final matchesGuest = info.$2?.toLowerCase().contains(q) ?? false;
        if (!matchesNum && !matchesType && !matchesGuest) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Room Availability Calendar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Date Navigation Bar ──────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeDate(-1),
                  tooltip: 'Previous Day',
                ),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          AppFormatters.formatDate(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 20),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeDate(1),
                  tooltip: 'Next Day',
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedDate = DateTime.now()),
                  child: const Text('Today', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),

          // ── Occupancy Metrics Summary Bar ─────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                _SummaryBadge(
                  label: 'Available',
                  count: availableCount,
                  color: AppColors.available,
                  isSelected: _filterStatus == RoomStatus.available,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == RoomStatus.available ? null : RoomStatus.available;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _SummaryBadge(
                  label: 'Occupied',
                  count: occupiedCount,
                  color: AppColors.occupied,
                  isSelected: _filterStatus == RoomStatus.occupied,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == RoomStatus.occupied ? null : RoomStatus.occupied;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _SummaryBadge(
                  label: 'Reserved',
                  count: reservedCount,
                  color: AppColors.reserved,
                  isSelected: _filterStatus == RoomStatus.reserved,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == RoomStatus.reserved ? null : RoomStatus.reserved;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _SummaryBadge(
                  label: 'Cleaning',
                  count: cleaningCount,
                  color: AppColors.cleaning,
                  isSelected: _filterStatus == RoomStatus.cleaning,
                  onTap: () {
                    setState(() {
                      _filterStatus = _filterStatus == RoomStatus.cleaning ? null : RoomStatus.cleaning;
                    });
                  },
                ),
                const SizedBox(width: 6),
                _SummaryBadge(
                  label: 'Total',
                  count: _allRooms.length,
                  color: AppColors.primary,
                  isSelected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Search & Filter ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search room number or guest name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.surface,
              ),
            ),
          ),

          // ── Room Grid / List ─────────────────────────────────
          Expanded(
            child: filteredRooms.isEmpty
                ? const EmptyState(
                    icon: Icons.meeting_room_outlined,
                    title: 'No rooms found',
                    subtitle: 'Try changing the date or filter',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      final room = filteredRooms[index];
                      final info = roomStatusMap[room.id]!;
                      final status = info.$1;
                      final guestName = info.$2;
                      final bookingId = info.$3;
                      final statusCol = _statusColor(status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(color: statusCol.withOpacity(0.3), width: 1.2),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusCol.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Room ${room.number}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: statusCol,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    room.type.label,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const Spacer(),
                                  StatusBadge(
                                    label: status.label,
                                    color: statusCol,
                                    fontSize: 12,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${AppFormatters.formatCurrency(room.pricePerNight)} / day',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Floor ${room.floor} • Max ${room.maxGuests} Guests',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              if (guestName != null && guestName.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Guest: $guestName',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (bookingId != null && bookingId.isNotEmpty)
                                    OutlinedButton.icon(
                                      onPressed: () => context.go('/bookings/$bookingId'),
                                      icon: const Icon(Icons.receipt_long, size: 16),
                                      label: const Text('View Booking'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  if (status == RoomStatus.available)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        context.go('/bookings/new');
                                      },
                                      icon: const Icon(Icons.add, size: 16),
                                      label: const Text('Book This Room'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.available,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.18) : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
