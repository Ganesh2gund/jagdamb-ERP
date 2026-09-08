import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/room.dart';
import '../../../repositories/room_repository.dart';
import '../../../widgets/common_widgets.dart';
import 'add_edit_room_screen.dart';
import 'room_availability_screen.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _isLoading = true;
  List<Room> _allRooms = [];
  List<Room> _filteredRooms = [];
  RoomStatus? _selectedStatus;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRooms() async {
    final repo = context.read<RoomRepository>();
    final rooms = await repo.getRooms();
    if (!mounted) return;
    setState(() {
      _allRooms = rooms;
      _filteredRooms = rooms;
      _isLoading = false;
    });
  }

  void _applyFilter() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredRooms = _allRooms.where((r) {
        final matchesStatus = _selectedStatus == null || r.status == _selectedStatus;
        final matchesSearch = q.isEmpty ||
            r.number.contains(q) ||
            r.type.label.toLowerCase().contains(q) ||
            (r.currentGuestName?.toLowerCase().contains(q) ?? false);
        return matchesStatus && matchesSearch;
      }).toList();
    });
  }

  Color _statusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available: return AppColors.available;
      case RoomStatus.occupied: return AppColors.occupied;
      case RoomStatus.reserved: return AppColors.reserved;
      case RoomStatus.cleaning: return AppColors.cleaning;
      case RoomStatus.maintenance: return AppColors.maintenance;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    final statusCounts = <RoomStatus?, int>{null: _allRooms.length};
    for (final s in RoomStatus.values) {
      statusCounts[s] = _allRooms.where((r) => r.status == s).length;
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Rooms'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            tooltip: 'Availability Calendar',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RoomAvailabilityScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRooms,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddEditRoomScreen()),
          );
          if (result == true) _loadRooms();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Room', style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppSearchBar(
              controller: _searchController,
              hintText: 'Search rooms, guests...',
              onChanged: (_) => _applyFilter(),
            ),
          ),
          // Filter chips
          Container(
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${statusCounts[null]})',
                    isSelected: _selectedStatus == null,
                    onTap: () { setState(() => _selectedStatus = null); _applyFilter(); },
                  ),
                  const SizedBox(width: 8),
                  ...RoomStatus.values.map((s) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: '${s.label} (${statusCounts[s]})',
                      isSelected: _selectedStatus == s,
                      color: _statusColor(s),
                      onTap: () { setState(() => _selectedStatus = s); _applyFilter(); },
                    ),
                  )),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          // Rooms list
          Expanded(
            child: _filteredRooms.isEmpty
                ? const EmptyState(icon: Icons.hotel, title: 'No rooms found', subtitle: 'Try adjusting your filters')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredRooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final room = _filteredRooms[index];
                      return _RoomCard(
                        room: room,
                        statusColor: _statusColor(room.status),
                        onTap: () => context.go('/rooms/${room.id}'),
                        onMarkCleaned: room.status == RoomStatus.cleaning
                            ? () async {
                                final repo = context.read<RoomRepository>();
                                await repo.updateRoomStatus(room.id, RoomStatus.available);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('✨ Room ${room.number} cleaning completed - now Available!'),
                                    backgroundColor: AppColors.available,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                _loadRooms();
                              }
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({required this.label, required this.isSelected, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? c.withOpacity(0.12) : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? c : Colors.transparent, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? c : AppColors.textSecondary,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final Color statusColor;
  final VoidCallback onTap;
  final VoidCallback? onMarkCleaned;

  const _RoomCard({
    required this.room,
    required this.statusColor,
    required this.onTap,
    this.onMarkCleaned,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Room number block
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  room.number,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: statusColor, fontFamily: 'Inter'),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Room info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Room ${room.number}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter'),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• Floor ${room.floor}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    room.type.label,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter'),
                  ),
                  if (room.currentGuestName != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 13, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            room.currentGuestName!,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Right side
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(label: room.status.label, color: statusColor),
                const SizedBox(height: 6),
                if (onMarkCleaned != null)
                  ElevatedButton.icon(
                    onPressed: onMarkCleaned,
                    icon: const Icon(Icons.check_circle, size: 13),
                    label: const Text('Mark Clean', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.available,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  )
                else
                  Text(
                    '₹${room.pricePerNight.toStringAsFixed(0)}/day',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
