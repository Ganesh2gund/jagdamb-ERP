enum HousekeepingStatus { needsCleaning, cleaning, ready, inspected }
enum HousekeepingPriority { low, medium, high, urgent }

extension HousekeepingStatusExt on HousekeepingStatus {
  String get label {
    switch (this) {
      case HousekeepingStatus.needsCleaning: return 'Needs Cleaning';
      case HousekeepingStatus.cleaning: return 'Cleaning';
      case HousekeepingStatus.ready: return 'Ready';
      case HousekeepingStatus.inspected: return 'Inspected';
    }
  }
}

extension HousekeepingPriorityExt on HousekeepingPriority {
  String get label {
    switch (this) {
      case HousekeepingPriority.low: return 'Low';
      case HousekeepingPriority.medium: return 'Medium';
      case HousekeepingPriority.high: return 'High';
      case HousekeepingPriority.urgent: return 'Urgent';
    }
  }
}

class HousekeepingTask {
  final String id;
  final String roomId;
  final String roomNumber;
  final String task;
  final HousekeepingPriority priority;
  final HousekeepingStatus status;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? notes;

  const HousekeepingTask({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.task,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.assignedStaffId,
    this.assignedStaffName,
    this.completedAt,
    this.notes,
  });

  HousekeepingTask copyWith({
    HousekeepingStatus? status,
    String? assignedStaffId,
    String? assignedStaffName,
    DateTime? completedAt,
    String? notes,
  }) {
    return HousekeepingTask(
      id: id,
      roomId: roomId,
      roomNumber: roomNumber,
      task: task,
      priority: priority,
      status: status ?? this.status,
      createdAt: createdAt,
      assignedStaffId: assignedStaffId ?? this.assignedStaffId,
      assignedStaffName: assignedStaffName ?? this.assignedStaffName,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
    );
  }
}
