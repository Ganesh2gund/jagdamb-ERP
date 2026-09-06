import '../models/maintenance.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceTicket>> getTickets();
  Future<List<MaintenanceTicket>> getTicketsByStatus(MaintenanceStatus status);
  Future<void> createTicket(MaintenanceTicket ticket);
  Future<void> updateTicketStatus(String id, MaintenanceStatus status);
  Future<void> assignTicket(String id, String personId, String personName);
}

class MockMaintenanceRepository implements MaintenanceRepository {
  final List<MaintenanceTicket> _tickets = [];

  @override
  Future<List<MaintenanceTicket>> getTickets() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_tickets);
  }

  @override
  Future<List<MaintenanceTicket>> getTicketsByStatus(MaintenanceStatus status) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _tickets.where((t) => t.status == status).toList();
  }

  @override
  Future<void> createTicket(MaintenanceTicket ticket) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _tickets.add(ticket);
  }

  @override
  Future<void> updateTicketStatus(String id, MaintenanceStatus status) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _tickets.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(
        status: status,
        resolvedDate: status == MaintenanceStatus.completed ? DateTime.now() : null,
      );
    }
  }

  @override
  Future<void> assignTicket(String id, String personId, String personName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final idx = _tickets.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tickets[idx] = _tickets[idx].copyWith(
        assignedPersonId: personId,
        assignedPersonName: personName,
        status: MaintenanceStatus.inProgress,
      );
    }
  }
}
