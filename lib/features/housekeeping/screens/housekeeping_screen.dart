import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/housekeeping.dart';
import '../../../repositories/housekeeping_repository.dart';
import '../../../widgets/common_widgets.dart';

class HousekeepingScreen extends StatefulWidget {
  const HousekeepingScreen({super.key});

  @override
  State<HousekeepingScreen> createState() => _HousekeepingScreenState();
}

class _HousekeepingScreenState extends State<HousekeepingScreen> {
  bool _isLoading = true;
  List<HousekeepingTask> _tasks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<HousekeepingRepository>();
    final tasks = await repo.getTasks();
    if (!mounted) return;
    setState(() { _tasks = tasks; _isLoading = false; });
  }

  Color _statusColor(HousekeepingStatus s) {
    switch (s) {
      case HousekeepingStatus.needsCleaning: return AppColors.error;
      case HousekeepingStatus.cleaning: return AppColors.warning;
      case HousekeepingStatus.ready: return AppColors.success;
      case HousekeepingStatus.inspected: return AppColors.primary;
    }
  }

  Color _priorityColor(HousekeepingPriority p) {
    switch (p) {
      case HousekeepingPriority.low: return AppColors.textSecondary;
      case HousekeepingPriority.medium: return AppColors.info;
      case HousekeepingPriority.high: return AppColors.warning;
      case HousekeepingPriority.urgent: return AppColors.error;
    }
  }

  List<HousekeepingTask> _getByStatus(HousekeepingStatus status) =>
    _tasks.where((t) => t.status == status).toList();

  Future<void> _updateStatus(HousekeepingTask task, HousekeepingStatus newStatus) async {
    final repo = context.read<HousekeepingRepository>();
    await repo.updateTaskStatus(task.id, newStatus);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Room ${task.roomNumber} marked as ${newStatus.label}'), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Housekeeping'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _tasks.isEmpty
            ? const EmptyState(icon: Icons.cleaning_services, title: 'No housekeeping tasks')
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...HousekeepingStatus.values.map((status) {
                    final grouped = _getByStatus(status);
                    if (grouped.isEmpty) return const SizedBox.shrink();
                    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(width: 10, height: 10, decoration: BoxDecoration(color: _statusColor(status), shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Text(status.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                        const SizedBox(width: 8),
                        Text('(${grouped.length})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
                      ]),
                      const SizedBox(height: 10),
                      ...grouped.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(color: _statusColor(task.status).withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                                child: Center(child: Text(task.roomNumber, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _statusColor(task.status), fontFamily: 'Inter'))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Room ${task.roomNumber} — ${task.task}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                                if (task.assignedStaffName != null)
                                  Text('👤 ${task.assignedStaffName}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
                              ])),
                              StatusBadge(label: task.priority.label, color: _priorityColor(task.priority)),
                            ]),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            Row(children: [
                              Text(AppFormatters.formatTime(task.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
                              const Spacer(),
                              if (task.status == HousekeepingStatus.needsCleaning)
                                _ActionBtn(label: 'Start Cleaning', color: AppColors.warning, onTap: () => _updateStatus(task, HousekeepingStatus.cleaning)),
                              if (task.status == HousekeepingStatus.cleaning)
                                _ActionBtn(label: 'Mark Clean', color: AppColors.success, onTap: () => _updateStatus(task, HousekeepingStatus.ready)),
                              if (task.status == HousekeepingStatus.ready)
                                _ActionBtn(label: 'Inspect', color: AppColors.primary, onTap: () => _updateStatus(task, HousekeepingStatus.inspected)),
                            ]),
                          ]),
                        ),
                      )),
                    ]);
                  }),
                ],
              ),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
      ),
    );
  }
}
