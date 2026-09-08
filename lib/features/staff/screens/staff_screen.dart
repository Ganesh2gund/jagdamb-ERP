import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/staff.dart';
import '../../../repositories/staff_repository.dart';
import '../../../widgets/common_widgets.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Staff> _staff = [];
  List<ActivityLog> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<StaffRepository>();
    final results = await Future.wait([repo.getStaff(), repo.getActivityLogs()]);
    if (!mounted) return;
    setState(() {
      _staff = results[0] as List<Staff>;
      _logs = results[1] as List<ActivityLog>;
      _isLoading = false;
    });
  }

  Color _statusColor(StaffStatus s) {
    switch (s) {
      case StaffStatus.active: return AppColors.success;
      case StaffStatus.inactive: return AppColors.error;
      case StaffStatus.onLeave: return AppColors.warning;
    }
  }

  Color _deptColor(StaffDepartment d) {
    switch (d) {
      case StaffDepartment.reception: return AppColors.primary;
      case StaffDepartment.housekeeping: return AppColors.info;
      case StaffDepartment.restaurant: return AppColors.cleaning;
      case StaffDepartment.kitchen: return AppColors.warning;
      case StaffDepartment.maintenance: return AppColors.error;
      case StaffDepartment.management: return AppColors.reserved;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Staff'),
        bottom: TabBar(controller: _tabController, tabs: const [Tab(text: 'Team'), Tab(text: 'Activity Log')]),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildTeam(), _buildActivityLog()],
      ),
    );
  }

  Widget _buildTeam() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _staff.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final s = _staff[i];
        final deptColor = _deptColor(s.department);
        return AppCard(
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: deptColor.withOpacity(0.12), shape: BoxShape.circle),
              child: Center(child: Text(s.name.isNotEmpty ? s.name.substring(0, 1) : 'S', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: deptColor, fontFamily: 'Inter'))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(s.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              const SizedBox(height: 2),
              Text('${s.role ?? s.department.label} • ${s.department.label}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
              const SizedBox(height: 3),
              Text('Since ${AppFormatters.formatDate(s.joiningDate)}', style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'Inter')),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              StatusBadge(label: s.status.label, color: _statusColor(s.status), fontSize: 10),
              if (s.salary != null) ...[
                const SizedBox(height: 4),
                Text(AppFormatters.formatCurrency(s.salary!), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
              ],
            ]),
          ]),
        );
      },
    );
  }

  Widget _buildActivityLog() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final log = _logs[i];
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            if (i < _logs.length - 1) Container(width: 1, height: 48, color: AppColors.border),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(AppFormatters.formatTime(log.timestamp), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
            const SizedBox(height: 2),
            Text(log.action, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
            if (log.details != null) Text(log.details!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
            const SizedBox(height: 2),
            Text('by ${log.staffName}', style: const TextStyle(fontSize: 11, color: AppColors.primary, fontFamily: 'Inter', fontWeight: FontWeight.w500)),
          ])),
        ]);
      },
    );
  }
}
