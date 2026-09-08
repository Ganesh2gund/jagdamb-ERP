import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/room.dart';
import '../../../repositories/room_repository.dart';
import '../../../widgets/common_widgets.dart';
import '../../../services/api_client.dart';
import 'add_edit_room_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final String roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  Room? _room;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    final repo = context.read<RoomRepository>();
    final room = await repo.getRoomById(widget.roomId);
    if (!mounted) return;
    setState(() { _room = room; _isLoading = false; });
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

  Future<void> _editRoom() async {
    if (_room == null) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => AddEditRoomScreen(existingRoom: _room)),
    );
    if (result == true && mounted) {
      await _loadRoom();
    }
  }

  Future<void> _deleteRoom() async {
    if (_room == null) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              'Room ${_room!.number} हटाएं?',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'क्या आप सचमुच Room ${_room!.number} को हटाना चाहते हैं? यह एक्शन वापस नहीं हो सकता।',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
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
                      child: const Text('रद्द करें (Cancel)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
                      child: const Text('कमरा हटाएं (Delete)', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ApiClient.instance.delete('/rooms/${_room!.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room ${_room!.number} deleted successfully'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('ApiException: ', '')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changeStatus() async {
    if (_room == null) return;
    final statuses = RoomStatus.values.where((s) => s != _room!.status).toList();
    final selected = await showModalBottomSheet<RoomStatus>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            ...statuses.map((s) => ListTile(
              leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: _statusColor(s), shape: BoxShape.circle)),
              title: Text(s.label, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w500)),
              onTap: () => Navigator.pop(ctx, s),
            )),
          ],
        ),
      ),
    );
    if (selected != null && mounted) {
      final repo = context.read<RoomRepository>();
      await repo.updateRoomStatus(widget.roomId, selected);
      if (!mounted) return;
      await _loadRoom();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room ${_room!.number} status updated to ${selected.label}'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());
    if (_room == null) return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.hotel, title: 'Room not found'));

    final room = _room!;
    final statusColor = _statusColor(room.status);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/rooms');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('Room ${room.number}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back to Rooms)',
            onPressed: () => context.go('/rooms'),
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Room',
            onPressed: _editRoom,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            tooltip: 'Delete Room',
            onPressed: _deleteRoom,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Room header card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
                        child: Center(child: Text(room.number, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: statusColor, fontFamily: 'Inter'))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Room ${room.number}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                            const SizedBox(height: 4),
                            Text('${room.type.label} • Floor ${room.floor}', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, fontFamily: 'Inter')),
                          ],
                        ),
                      ),
                      StatusBadge(label: room.status.label, color: statusColor),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  InfoRow(label: 'Price', value: '₹${room.pricePerNight.toStringAsFixed(0)}/day'),
                  InfoRow(label: 'Max Guests', value: '${room.maxGuests} guests'),
                  if (room.currentGuestName != null)
                    InfoRow(label: 'Current Guest', value: room.currentGuestName!, valueColor: AppColors.primary),
                  if (room.checkInDate != null)
                    InfoRow(label: 'Check-in', value: AppFormatters.formatDate(room.checkInDate!)),
                  if (room.checkOutDate != null)
                    InfoRow(label: 'Check-out', value: AppFormatters.formatDate(room.checkOutDate!)),
                  if (room.maintenanceNote != null)
                    InfoRow(label: 'Maintenance', value: room.maintenanceNote!, valueColor: AppColors.error),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Amenities
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Amenities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: room.amenities.map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primarySurface, borderRadius: BorderRadius.circular(20)),
                      child: Text(a, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500, fontFamily: 'Inter')),
                    )).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            const Text('Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            // Context-Aware Actions based on Room Status
            if (room.status == RoomStatus.available) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: () => context.go('/bookings/new?roomId=${room.id}&checkInNow=true'),
                  icon: const Icon(Icons.login_rounded, size: 22),
                  label: const Text(
                    '🟢 Check-in Guest (इस कमरे में चेक-इन करें)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changeStatus,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('कमरे की स्थिति बदलें (Change Status)'),
                ),
              ),
            ] else if (room.status == RoomStatus.occupied) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/check-out?bookingId=${room.currentBookingId ?? ''}'),
                  icon: const Icon(Icons.logout, size: 22),
                  label: const Text(
                    '🚪 Check-out & Settle Bill (कमरा खाली करें और बिल)',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                ),
              ),
              if (room.currentBookingId != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go('/bookings/${room.currentBookingId}'),
                    icon: const Icon(Icons.receipt_long, size: 18),
                    label: const Text('📄 View Booking & Bill (बुकिंग व बिल देखें)'),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _changeStatus,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Change Room Status Manually'),
                ),
              ),
            ] else if (room.status == RoomStatus.cleaning) ...[
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final repo = context.read<RoomRepository>();
                    await repo.updateRoomStatus(widget.roomId, RoomStatus.available);
                    if (!mounted) return;
                    await _loadRoom();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Room is clean and now Available!'),
                        backgroundColor: AppColors.available,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  label: const Text('✨ Mark Clean & Ready (कमरा तैयार है)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changeStatus,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Change Status'),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _changeStatus,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Change Room Status'),
                ),
              ),
            ],
          ],
        ),
      ),
    ));
  }
}
