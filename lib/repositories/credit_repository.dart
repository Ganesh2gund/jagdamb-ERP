import 'dart:developer' as dev;
import '../models/credit_khata.dart';
import '../services/api_client.dart';

class CreditRepository {
  final ApiClient _api = ApiClient.instance;

  /// In-memory cache for fast offline / fallback display
  static final List<CreditKhata> _cachedList = [];

  Future<Map<String, dynamic>> getCreditSummaryAndList() async {
    try {
      final res = await _api.get('/credit');
      if (res is Map && res['success'] == true) {
        final rawCredits = (res['credits'] as List?) ?? [];
        final list = rawCredits
            .map((c) => CreditKhata.fromJson(Map<String, dynamic>.from(c)))
            .toList();

        _cachedList
          ..clear()
          ..addAll(list);

        final summary = (res['summary'] as Map?) != null
            ? Map<String, dynamic>.from(res['summary'])
            : <String, dynamic>{};

        return {
          'credits': list,
          'summary': summary,
        };
      }
    } catch (e) {
      dev.log('Error loading credit data: $e');
    }

    // Fallback using cached list
    final totalUdhaar = _cachedList.fold<double>(0, (sum, c) => sum + c.totalAmount);
    final totalRecovered = _cachedList.fold<double>(0, (sum, c) => sum + c.paidAmount);
    final totalOutstanding = _cachedList.fold<double>(0, (sum, c) => sum + c.balanceAmount);

    return {
      'credits': List<CreditKhata>.from(_cachedList),
      'summary': {
        'totalUdhaar': totalUdhaar,
        'totalRecovered': totalRecovered,
        'totalOutstanding': totalOutstanding,
        'totalCount': _cachedList.length,
        'pendingCount': _cachedList.where((c) => !c.isSettled).length,
        'paidCount': _cachedList.where((c) => c.isSettled).length,
      },
    };
  }

  Future<CreditKhata?> createCreditBill(Map<String, dynamic> data) async {
    try {
      final res = await _api.post('/credit', body: data);
      if (res is Map && res['credit'] != null) {
        final created = CreditKhata.fromJson(Map<String, dynamic>.from(res['credit']));
        _cachedList.insert(0, created);
        return created;
      }
    } catch (e) {
      dev.log('Error creating credit bill: $e');
      if (e is ApiException) rethrow;
    }

    // Fallback: create locally
    final total = (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final created = CreditKhata(
      id: 'udh_${DateTime.now().millisecondsSinceEpoch}',
      billNumber: 'UDH-${1001 + _cachedList.length}',
      customerName: (data['customerName'] ?? 'Customer').toString(),
      customerPhone: (data['customerPhone'] ?? '').toString(),
      description: (data['description'] ?? 'Food & Dining Credit').toString(),
      totalAmount: total,
      paidAmount: 0,
      balanceAmount: total,
      status: 'pending',
      payments: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _cachedList.insert(0, created);
    return created;
  }

  Future<CreditKhata?> recordPayment(
    String id, {
    required double amount,
    String paymentMethod = 'Cash',
    String notes = '',
  }) async {
    try {
      final res = await _api.post(
        '/credit/$id/pay',
        body: {
          'amount': amount,
          'paymentMethod': paymentMethod,
          'notes': notes,
        },
      );
      if (res is Map && res['credit'] != null) {
        final updated = CreditKhata.fromJson(Map<String, dynamic>.from(res['credit']));
        final idx = _cachedList.indexWhere((c) => c.id == updated.id || c.billNumber == updated.billNumber);
        if (idx != -1) {
          _cachedList[idx] = updated;
        }
        return updated;
      }
    } catch (e) {
      dev.log('Error recording payment: $e');
      if (e is ApiException) rethrow;
    }

    // Fallback locally
    final idx = _cachedList.indexWhere((c) => c.id == id || c.billNumber == id);
    if (idx != -1) {
      final old = _cachedList[idx];
      final newPaid = old.paidAmount + amount;
      final newBal = (old.totalAmount - newPaid).clamp(0.0, double.infinity);
      final newStatus = newBal <= 0 ? 'paid' : 'partially_paid';

      final newPayments = List<CreditPayment>.from(old.payments)
        ..add(CreditPayment(
          amount: amount,
          paymentMethod: paymentMethod,
          paidAt: DateTime.now(),
          notes: notes,
        ));

      final updated = CreditKhata(
        id: old.id,
        billNumber: old.billNumber,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        description: old.description,
        totalAmount: old.totalAmount,
        paidAmount: newPaid,
        balanceAmount: newBal,
        status: newStatus,
        payments: newPayments,
        createdAt: old.createdAt,
        updatedAt: DateTime.now(),
      );
      _cachedList[idx] = updated;
      return updated;
    }

    return null;
  }

  Future<bool> deleteCreditBill(String id) async {
    try {
      final res = await _api.delete('/credit/$id');
      if (res is Map && res['success'] == true) {
        _cachedList.removeWhere((c) => c.id == id || c.billNumber == id);
        return true;
      }
    } catch (e) {
      dev.log('Error deleting credit bill: $e');
    }
    final lenBefore = _cachedList.length;
    _cachedList.removeWhere((c) => c.id == id || c.billNumber == id);
    return _cachedList.length < lenBefore;
  }
}
