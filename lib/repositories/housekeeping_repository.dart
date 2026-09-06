import '../models/housekeeping.dart';

abstract class HousekeepingRepository {
  Future<List<HousekeepingTask>> getTasks();
  Future<List<HousekeepingTask>> getTasksByStatus(HousekeepingStatus status);
  Future<void> createTask(HousekeepingTask task);
  Future<void> updateTaskStatus(String id, HousekeepingStatus status);
  Future<void> assignTask(String id, String staffId, String staffName);
}

class MockHousekeepingRepository implements HousekeepingRepository {
  final List<HousekeepingTask> _tasks = [];

  @override
  Future<List<HousekeepingTask>> getTasks() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_tasks);
  }

  @override
  Future<List<HousekeepingTask>> getTasksByStatus(HousekeepingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tasks.where((t) => t.status == status).toList();
  }

  @override
  Future<void> createTask(HousekeepingTask task) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _tasks.add(task);
  }

  @override
  Future<void> updateTaskStatus(String id, HousekeepingStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        status: status,
        completedAt: status == HousekeepingStatus.ready || status == HousekeepingStatus.inspected
            ? DateTime.now() : null,
      );
    }
  }

  @override
  Future<void> assignTask(String id, String staffId, String staffName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx] = _tasks[idx].copyWith(
        assignedStaffId: staffId,
        assignedStaffName: staffName,
        status: HousekeepingStatus.cleaning,
      );
    }
  }
}
