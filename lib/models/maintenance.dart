enum MaintenancePriority { low, medium, high, urgent }
enum MaintenanceStatus { open, inProgress, completed, cancelled }

extension MaintenancePriorityExt on MaintenancePriority {
  String get label {
    switch (this) {
      case MaintenancePriority.low: return 'Low';
      case MaintenancePriority.medium: return 'Medium';
      case MaintenancePriority.high: return 'High';
      case MaintenancePriority.urgent: return 'Urgent';
    }
  }
}

extension MaintenanceStatusExt on MaintenanceStatus {
  String get label {
    switch (this) {
      case MaintenanceStatus.open: return 'Open';
      case MaintenanceStatus.inProgress: return 'In Progress';
      case MaintenanceStatus.completed: return 'Completed';
      case MaintenanceStatus.cancelled: return 'Cancelled';
    }
  }
}

class MaintenanceTicket {
  final String id;
  final String roomId;
  final String roomNumber;
  final String issue;
  final MaintenancePriority priority;
  final MaintenanceStatus status;
  final DateTime reportedDate;
  final String description;
  final String? assignedPersonId;
  final String? assignedPersonName;
  final DateTime? resolvedDate;
  final String? notes;
  final double? cost;

  const MaintenanceTicket({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.issue,
    required this.priority,
    required this.status,
    required this.reportedDate,
    required this.description,
    this.assignedPersonId,
    this.assignedPersonName,
    this.resolvedDate,
    this.notes,
    this.cost,
  });

  int get daysOpen => DateTime.now().difference(reportedDate).inDays;

  MaintenanceTicket copyWith({
    MaintenanceStatus? status,
    String? assignedPersonId,
    String? assignedPersonName,
    DateTime? resolvedDate,
    String? notes,
    double? cost,
  }) {
    return MaintenanceTicket(
      id: id,
      roomId: roomId,
      roomNumber: roomNumber,
      issue: issue,
      priority: priority,
      status: status ?? this.status,
      reportedDate: reportedDate,
      description: description,
      assignedPersonId: assignedPersonId ?? this.assignedPersonId,
      assignedPersonName: assignedPersonName ?? this.assignedPersonName,
      resolvedDate: resolvedDate ?? this.resolvedDate,
      notes: notes ?? this.notes,
      cost: cost ?? this.cost,
    );
  }
}
