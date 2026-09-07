import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/expense.dart';
import '../../../repositories/expense_repository.dart';
import '../../../widgets/common_widgets.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  bool _isLoading = true;
  List<Expense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = context.read<ExpenseRepository>();
    final expenses = await repo.getExpenses();
    if (!mounted) return;
    setState(() {
      _expenses = expenses;
      _isLoading = false;
    });
  }

  double get _todayTotal {
    final today = DateTime.now();
    return _expenses
        .where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get _monthTotal {
    final today = DateTime.now();
    return _expenses
        .where((e) => e.date.year == today.year && e.date.month == today.month)
        .fold(0.0, (s, e) => s + e.amount);
  }

  double get _totalExpenses => _expenses.fold(0, (s, e) => s + e.amount);

  void _showAddEditExpense([Expense? existing]) {
    final isEdit = existing != null;
    final amountController = TextEditingController(
      text: isEdit ? (existing.amount % 1 == 0 ? existing.amount.toInt().toString() : existing.amount.toString()) : '',
    );
    final descController = TextEditingController(text: existing?.description ?? '');
    final notesController = TextEditingController(text: existing?.notes ?? '');
    ExpenseCategory selectedCategory = existing?.category ?? ExpenseCategory.other;
    String selectedPayment = existing?.paymentMethod ?? 'Cash';
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(ctx2).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'खर्च एडिट करें (Edit Expense)' : 'नया खर्च जोड़ें (Add Expense)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<ExpenseCategory>(
                    decoration: const InputDecoration(
                      labelText: 'कैटेगरी (Category)',
                      prefixIcon: Icon(Icons.category),
                    ),
                    value: selectedCategory,
                    items: ExpenseCategory.values
                        .map((c) => DropdownMenuItem(value: c, child: Text('${c.emoji} ${c.label}')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedCategory = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Amount
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'राशि (Amount ₹)',
                      prefixText: '₹ ',
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'राशि दर्ज करें (Enter amount)';
                      final num = double.tryParse(v.trim());
                      if (num == null || num <= 0) return 'वैध राशि दर्ज करें (Enter valid amount)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Description
                  TextFormField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'विवरण (Description)',
                      hintText: 'e.g. Electricity bill, vegetables, plumbing',
                      prefixIcon: Icon(Icons.description),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'विवरण दर्ज करें (Enter description)' : null,
                  ),
                  const SizedBox(height: 12),

                  // Payment Method
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'भुगतान माध्यम (Payment Method)',
                      prefixIcon: Icon(Icons.payment),
                    ),
                    value: ['Cash', 'UPI', 'Bank Transfer', 'Card'].contains(selectedPayment)
                        ? selectedPayment
                        : 'Cash',
                    items: ['Cash', 'UPI', 'Bank Transfer', 'Card']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedPayment = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Notes
                  TextFormField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'नोट्स (Notes - Optional)',
                      prefixIcon: Icon(Icons.notes),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final amount = double.parse(amountController.text.trim());
                        final desc = descController.text.trim();
                        final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                        Navigator.pop(ctx);

                        final repo = context.read<ExpenseRepository>();
                        if (isEdit) {
                          final updated = Expense(
                            id: existing.id,
                            category: selectedCategory,
                            amount: amount,
                            date: existing.date,
                            description: desc,
                            paymentMethod: selectedPayment,
                            notes: notes,
                            receipt: existing.receipt,
                          );
                          await repo.updateExpense(updated);
                        } else {
                          const uuid = Uuid();
                          final newExp = Expense(
                            id: uuid.v4(),
                            category: selectedCategory,
                            amount: amount,
                            date: DateTime.now(),
                            description: desc,
                            paymentMethod: selectedPayment,
                            notes: notes,
                          );
                          await repo.createExpense(newExp);
                        }

                        await _load();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isEdit
                                ? '✅ खर्च अपडेट हो गया (Expense updated)'
                                : '✅ नया खर्च जुड़ गया (Expense added)'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: Icon(isEdit ? Icons.save : Icons.add),
                      label: Text(
                        isEdit ? 'अपडेट करें (Save Changes)' : 'खर्च जोड़ें (Add Expense)',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteExpense(Expense expense) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
              child: const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 14),
            const Text(
              'खर्च हटाएं? (Delete Expense)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'क्या आप "${expense.description}" (${AppFormatters.formatCurrency(expense.amount)}) को हटाना चाहते हैं?',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('रद्द करें (Cancel)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('खर्च हटाएं (Delete)', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (ok == true) {
      final repo = context.read<ExpenseRepository>();
      await repo.deleteExpense(expense.id);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗑️ खर्च "${expense.description}" हटा दिया गया'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Expenses (खर्च प्रबंधन)'),
        actions: [
          IconButton(
            tooltip: 'रिफ्रेश (Refresh)',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditExpense(),
        icon: const Icon(Icons.add),
        label: const Text('खर्च जोड़ें (Add Expense)', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          // Summary Cards
          Row(
            children: [
              Expanded(child: _SummaryCard(label: "Today's (आज)", amount: _todayTotal, color: AppColors.warning)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: 'This Month (महीना)', amount: _monthTotal, color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(child: _SummaryCard(label: 'Total (कुल)', amount: _totalExpenses, color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'खर्चों का इतिहास (Expense History)'),
              Text(
                'कुल रिकॉर्ड: ${_expenses.length}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_expenses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 60, color: AppColors.textSecondary),
                    const SizedBox(height: 12),
                    const Text(
                      'कोई खर्च रिकॉर्ड नहीं है (No Expenses Recorded)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'नीचे दिए बटन से पहला खर्च जोड़ें',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditExpense(),
                      icon: const Icon(Icons.add),
                      label: const Text('पहला खर्च जोड़ें (Add Expense)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._expenses.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    child: Row(
                      children: [
                        // Category Icon
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.warningLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(e.category.emoji, style: const TextStyle(fontSize: 22))),
                        ),
                        const SizedBox(width: 14),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.description,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${e.category.label} • ${e.paymentMethod}',
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter'),
                              ),
                              if (e.notes != null && e.notes!.isNotEmpty)
                                Text(
                                  'नोट: ${e.notes}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              Text(
                                AppFormatters.formatDate(e.date),
                                style: const TextStyle(fontSize: 11, color: AppColors.textTertiary, fontFamily: 'Inter'),
                              ),
                            ],
                          ),
                        ),

                        // Amount and Action Buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              AppFormatters.formatCurrency(e.amount),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                                fontFamily: 'Inter',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Edit Button
                                InkWell(
                                  onTap: () => _showAddEditExpense(e),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                                  ),
                                ),
                                const SizedBox(width: 8),

                                // Delete Button
                                InkWell(
                                  onTap: () => _deleteExpense(e),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const _SummaryCard({required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
          const SizedBox(height: 4),
          Text(
            AppFormatters.formatCurrency(amount),
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter'),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
