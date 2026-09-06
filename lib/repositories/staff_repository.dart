import '../models/staff.dart';

abstract class StaffRepository {
  Future<List<Staff>> getStaff();
  Future<Staff?> getStaffById(String id);
  Future<List<ActivityLog>> getActivityLogs();
  Future<void> createStaff(Staff staff);
  Future<void> updateStaff(Staff staff);
}

class MockStaffRepository implements StaffRepository {
  final List<Staff> _staff = [];
  final List<ActivityLog> _logs = [];

  @override
  Future<List<Staff>> getStaff() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_staff);
  }

  @override
  Future<Staff?> getStaffById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _staff.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ActivityLog>> getActivityLogs() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_logs)..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> createStaff(Staff staff) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _staff.add(staff);
  }

  @override
  Future<void> updateStaff(Staff staff) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _staff.indexWhere((s) => s.id == staff.id);
    if (idx != -1) _staff[idx] = staff;
  }
}
