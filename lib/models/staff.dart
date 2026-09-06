enum StaffDepartment {
  reception, housekeeping, restaurant, kitchen, maintenance, management
}

enum StaffStatus { active, inactive, onLeave }

extension StaffDepartmentExt on StaffDepartment {
  String get label {
    switch (this) {
      case StaffDepartment.reception: return 'Reception';
      case StaffDepartment.housekeeping: return 'Housekeeping';
      case StaffDepartment.restaurant: return 'Restaurant';
      case StaffDepartment.kitchen: return 'Kitchen';
      case StaffDepartment.maintenance: return 'Maintenance';
      case StaffDepartment.management: return 'Management';
    }
  }
}

extension StaffStatusExt on StaffStatus {
  String get label {
    switch (this) {
      case StaffStatus.active: return 'Active';
      case StaffStatus.inactive: return 'Inactive';
      case StaffStatus.onLeave: return 'On Leave';
    }
  }
}

class Staff {
  final String id;
  final String name;
  final StaffDepartment department;
  final String phone;
  final String email;
  final DateTime joiningDate;
  final StaffStatus status;
  final String? role;
  final double? salary;
  final String? avatarUrl;

  const Staff({
    required this.id,
    required this.name,
    required this.department,
    required this.phone,
    required this.email,
    required this.joiningDate,
    required this.status,
    this.role,
    this.salary,
    this.avatarUrl,
  });
}

class ActivityLog {
  final String id;
  final String staffId;
  final String staffName;
  final String action;
  final String? details;
  final DateTime timestamp;
  final String? module;

  const ActivityLog({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.action,
    required this.timestamp,
    this.details,
    this.module,
  });
}
