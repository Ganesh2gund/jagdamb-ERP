enum ExpenseCategory {
  electricity, water, salary, foodPurchase, maintenance, supplies, other
}

extension ExpenseCategoryExt on ExpenseCategory {
  String get label {
    switch (this) {
      case ExpenseCategory.electricity: return 'Electricity';
      case ExpenseCategory.water: return 'Water';
      case ExpenseCategory.salary: return 'Salary';
      case ExpenseCategory.foodPurchase: return 'Food Purchase';
      case ExpenseCategory.maintenance: return 'Maintenance';
      case ExpenseCategory.supplies: return 'Supplies';
      case ExpenseCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.electricity: return '⚡';
      case ExpenseCategory.water: return '💧';
      case ExpenseCategory.salary: return '👥';
      case ExpenseCategory.foodPurchase: return '🛒';
      case ExpenseCategory.maintenance: return '🔧';
      case ExpenseCategory.supplies: return '📦';
      case ExpenseCategory.other: return '💰';
    }
  }
}

class Expense {
  final String id;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String description;
  final String paymentMethod;
  final String? notes;
  final String? receipt;

  const Expense({
    required this.id,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    required this.paymentMethod,
    this.notes,
    this.receipt,
  });
}
