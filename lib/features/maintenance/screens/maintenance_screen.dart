import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/maintenance.dart';
import '../../../repositories/maintenance_repository.dart';
import '../../../widgets/common_widgets.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<MaintenanceTicket> _tickets = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<MaintenanceRepository>();
    final tickets = await repo.getTickets();
    if (!mounted) return;
    setState(() { _tickets = tickets; _isLoading = false; });
  }

  List<MaintenanceTicket> _getByStatus(MaintenanceStatus status) =>
    _tickets.where((t) => t.status == status).toList();

  Color _priorityColor(MaintenancePriority p) {
    switch (p) {
      case MaintenancePriority.low: return AppColors.textSecondary;
      case MaintenancePriority.medium: return AppColors.info;
      case MaintenancePriority.high: return AppColors.warning;
      case MaintenancePriority.urgent: return AppColors.error;
    }
  }

  Future<void> _updateStatus(MaintenanceTicket t, MaintenanceStatus s) async {
    final repo = context.read<MaintenanceRepository>();
    await repo.updateTicketStatus(t.id, s);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket updated to ${s.label}'), behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Maintenance'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Open (${_getByStatus(MaintenanceStatus.open).length})'),
            Tab(text: 'In Progress (${_getByStatus(MaintenanceStatus.inProgress).length})'),
            Tab(text: 'Done (${_getByStatus(MaintenanceStatus.completed).length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_getByStatus(MaintenanceStatus.open)),
          _buildList(_getByStatus(MaintenanceStatus.inProgress)),
          _buildList(_getByStatus(MaintenanceStatus.completed)),
        ],
      ),
    );
  }

  Widget _buildList(List<MaintenanceTicket> tickets) {
    if (tickets.isEmpty) return const EmptyState(icon: Icons.build, title: 'No tickets in this category');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tickets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final t = tickets[i];
        final pColor = _priorityColor(t.priority);
        return AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: pColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Center(child: Text(t.roomNumber, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: pColor, fontFamily: 'Inter'))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Room ${t.roomNumber} — ${t.issue}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                if (t.assignedPersonName != null) Text('👤 ${t.assignedPersonName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
              ])),
              StatusBadge(label: '${t.priority.label} Priority', color: pColor, fontSize: 10),
            ]),
            const SizedBox(height: 8),
            Text(t.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                t.status == MaintenanceStatus.completed
                    ? 'Resolved ${AppFormatters.formatDate(t.resolvedDate!)}'
                    : '${t.daysOpen} day(s) open',
                style: TextStyle(fontSize: 11, color: t.daysOpen > 3 ? AppColors.error : AppColors.textSecondary, fontFamily: 'Inter', fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (t.status == MaintenanceStatus.open)
                _ActionBtn(label: 'Start', color: AppColors.warning, onTap: () => _updateStatus(t, MaintenanceStatus.inProgress)),
              if (t.status == MaintenanceStatus.inProgress)
                _ActionBtn(label: 'Complete', color: AppColors.success, onTap: () => _updateStatus(t, MaintenanceStatus.completed)),
            ]),
          ]),
        );
      },
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ),
    );
  }
}
