import '../services/api_client.dart';

class ReportRepository {
  final ApiClient _api = ApiClient.instance;

  Future<Map<String, dynamic>> getCycleStatus() async {
    try {
      final res = await _api.get('/report/status');
      if (res['success'] == true && res['data'] != null) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (e) {
      // ignore
    }
    return {};
  }

  Future<Map<String, dynamic>> getReportData() async {
    try {
      final res = await _api.get('/report/data');
      if (res['success'] == true && res['data'] != null) {
        return Map<String, dynamic>.from(res['data'] as Map);
      }
    } catch (e) {
      // ignore
    }
    return {};
  }

  Future<bool> scheduleCleanup() async {
    try {
      final res = await _api.post('/report/schedule-cleanup');
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> cancelCleanup() async {
    try {
      final res = await _api.post('/report/cancel-cleanup');
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> instantDelete() async {
    try {
      final res = await _api.post('/report/instant-delete');
      return res['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
