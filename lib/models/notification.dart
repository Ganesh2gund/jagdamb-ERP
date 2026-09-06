enum NotificationCategory { bookings, payments, rooms, inventory, general }
enum NotificationPriority { low, medium, high }

extension NotificationCategoryExt on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.bookings: return 'Bookings';
      case NotificationCategory.payments: return 'Payments';
      case NotificationCategory.rooms: return 'Rooms';
      case NotificationCategory.inventory: return 'Inventory';
      case NotificationCategory.general: return 'General';
    }
  }
}

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final DateTime createdAt;
  final bool isRead;
  final String? actionRoute;
  final String? actionId;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.createdAt,
    required this.isRead,
    this.actionRoute,
    this.actionId,
  });

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      category: category,
      priority: priority,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      actionRoute: actionRoute,
      actionId: actionId,
    );
  }
}
