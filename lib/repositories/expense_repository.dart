import '../models/expense.dart';

abstract class ExpenseRepository {
  Future<List<Expense>> getExpenses();
  Future<List<Expense>> getTodayExpenses();
  Future<List<Expense>> getMonthExpenses();
  Future<void> createExpense(Expense expense);
  Future<void> updateExpense(Expense expense);
  Future<bool> deleteExpense(String id);
}

class MockExpenseRepository implements ExpenseRepository {
  static final List<Expense> _expenses = [];

  @override
  Future<List<Expense>> getExpenses() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return List.from(_expenses);
  }

  @override
  Future<List<Expense>> getTodayExpenses() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final today = DateTime.now();
    return _expenses.where((e) =>
      e.date.year == today.year && e.date.month == today.month && e.date.day == today.day
    ).toList();
  }

  @override
  Future<List<Expense>> getMonthExpenses() async {
    await Future.delayed(const Duration(milliseconds: 50));
    final today = DateTime.now();
    return _expenses.where((e) =>
      e.date.year == today.year && e.date.month == today.month
    ).toList();
  }

  @override
  Future<void> createExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _expenses.insert(0, expense);
  }

  @override
  Future<void> updateExpense(Expense expense) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) {
      _expenses[idx] = expense;
    }
  }

  @override
  Future<bool> deleteExpense(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final idx = _expenses.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _expenses.removeAt(idx);
      return true;
    }
    return false;
  }
}
