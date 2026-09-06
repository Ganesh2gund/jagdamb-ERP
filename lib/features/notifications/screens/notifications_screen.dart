import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/notification.dart';
import '../../../repositories/notification_repository.dart';
import '../../../widgets/common_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<NotificationRepository>();
    final notifs = await repo.getNotifications();
    if (!mounted) return;
    setState(() { _notifications = notifs; _isLoading = false; });
  }

  List<AppNotification> _getFiltered(NotificationCategory? category) {
    if (category == null) return _notifications;
    return _notifications.where((n) => n.category == category).toList();
  }

  Future<void> _markAllRead() async {
    final repo = context.read<NotificationRepository>();
    await repo.markAllAsRead();
    await _load();
  }

  Color _priorityColor(NotificationPriority p) {
    switch (p) {
      case NotificationPriority.low: return AppColors.textSecondary;
      case NotificationPriority.medium: return AppColors.primary;
      case NotificationPriority.high: return AppColors.error;
    }
  }

  IconData _categoryIcon(NotificationCategory c) {
    switch (c) {
      case NotificationCategory.bookings: return Icons.book_outlined;
      case NotificationCategory.payments: return Icons.payments_outlined;
      case NotificationCategory.rooms: return Icons.hotel_outlined;
      case NotificationCategory.inventory: return Icons.inventory_2_outlined;
      case NotificationCategory.general: return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text('Mark all read', style: TextStyle(fontSize: 13, fontFamily: 'Inter')),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            const Tab(text: 'All'),
            ...NotificationCategory.values.map((c) => Tab(text: c.label)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [null, ...NotificationCategory.values].map((cat) {
          final items = _getFiltered(cat);
          if (items.isEmpty) return const EmptyState(icon: Icons.notifications_none, title: 'No notifications');
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, i) {
              final n = items[i];
              final pColor = _priorityColor(n.priority);
              return Container(
                decoration: BoxDecoration(
                  color: n.isRead ? AppColors.surface : AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: n.isRead ? AppColors.border : AppColors.primaryLight.withOpacity(0.4)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: pColor.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(_categoryIcon(n.category), color: pColor, size: 22),
                  ),
                  title: Text(n.title, style: TextStyle(fontSize: 13, fontWeight: n.isRead ? FontWeight.w500 : FontWeight.w700, fontFamily: 'Inter')),
                  subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 3),
                    Text(n.body, style: const TextStyle(fontSize: 12, fontFamily: 'Inter', color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(AppFormatters.timeAgo(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'Inter')),
                  ]),
                  trailing: !n.isRead ? Container(width: 8, height: 8, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)) : null,
                  onTap: () async {
                    final repo = context.read<NotificationRepository>();
                    await repo.markAsRead(n.id);
                    await _load();
                  },
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
