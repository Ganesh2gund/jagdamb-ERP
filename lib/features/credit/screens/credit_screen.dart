import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/whatsapp_helper.dart';
import '../../../models/credit_khata.dart';
import '../../../repositories/credit_repository.dart';
import '../../../widgets/common_widgets.dart';

class CreditScreen extends StatefulWidget {
  const CreditScreen({super.key});

  @override
  State<CreditScreen> createState() => _CreditScreenState();
}

class _CreditScreenState extends State<CreditScreen> {
  final CreditRepository _repo = CreditRepository();
  final TextEditingController _searchCtrl = TextEditingController();

  List<CreditKhata> _allCredits = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Paid'

  String _hotelName = AppConstants.hotelName;

  @override
  void initState() {
    super.initState();
    _loadHotelName();
    _loadData();
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadHotelName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final n = prefs.getString('hotel_name');
      if (n != null && n.trim().isNotEmpty) {
        setState(() => _hotelName = n.trim());
      }
    } catch (_) {}
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final res = await _repo.getCreditSummaryAndList();
    if (mounted) {
      setState(() {
        _allCredits = (res['credits'] as List<CreditKhata>?) ?? [];
        _summary = (res['summary'] as Map<String, dynamic>?) ?? {};
        _isLoading = false;
      });
    }
  }

  List<CreditKhata> get _filteredCredits {
    final query = _searchCtrl.text.trim().toLowerCase();
    return _allCredits.filter((c) {
      // Status filter
      if (_selectedFilter == 'Pending' && c.isSettled) return false;
      if (_selectedFilter == 'Paid' && !c.isSettled) return false;

      // Search query filter
      if (query.isNotEmpty) {
        final matchesName = c.customerName.toLowerCase().contains(query);
        final matchesPhone = c.customerPhone.toLowerCase().contains(query);
        final matchesBill = c.billNumber.toLowerCase().contains(query);
        return matchesName || matchesPhone || matchesBill;
      }
      return true;
    }).toList();
  }

  double get _totalOutstanding =>
      (_summary['totalOutstanding'] as num?)?.toDouble() ??
      _allCredits.fold(0.0, (sum, c) => sum + c.balanceAmount);

  double get _totalRecovered =>
      (_summary['totalRecovered'] as num?)?.toDouble() ??
      _allCredits.fold(0.0, (sum, c) => sum + c.paidAmount);

  int get _totalBillsCount =>
      (_summary['totalCount'] as num?)?.toInt() ?? _allCredits.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Customer Credit / Khata'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Data',
            onPressed: _loadData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCreditDialog,
        backgroundColor: const Color(0xFFE11D48),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'New Credit Bill',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Gradient Summary Card (Matching Cafe & Restaurant Bills)
                _buildTopSummaryCard(),

                // Search Bar and Status Filters
                _buildSearchAndFilterBar(),

                // Bills List or Empty State
                Expanded(
                  child: _filteredCredits.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 6, 16, 85),
                          itemCount: _filteredCredits.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) => _buildCreditCard(_filteredCredits[i]),
                        ),
                ),
              ],
            ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP SUMMARY CARD (Gradient Header like Restaurant / Cafe)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopSummaryCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF881337), Color(0xFFE11D48)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE11D48).withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Outstanding (Balance Due)',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppFormatters.formatCurrency(_totalOutstanding),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Inter',
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Total Bills',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$_totalBillsCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 15, color: Color(0xFF86EFAC)),
                  const SizedBox(width: 6),
                  Text(
                    'Total Recovered: ${AppFormatters.formatCurrency(_totalRecovered)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${_allCredits.where((c) => !c.isSettled).length} Unsettled',
                style: const TextStyle(
                  color: Color(0xFFFED7AA),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SEARCH & FILTER BAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          // Search Input
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by Customer Name, Phone, or Bill #',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Filter Chips (All, Pending, Paid)
          Row(
            children: [
              _buildFilterChip('All', _allCredits.length),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Pending',
                _allCredits.where((c) => !c.isSettled).length,
                color: const Color(0xFFE11D48),
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                'Paid',
                _allCredits.where((c) => c.isSettled).length,
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, {Color? color}) {
    final isSelected = _selectedFilter == label;
    final activeColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withValues(alpha: 0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CREDIT BILL CARD (Matching Restaurant / Cafe Style)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCreditCard(CreditKhata credit) {
    final isSettled = credit.isSettled;
    final hasPartial = credit.isPartial;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Bill Number & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '#${credit.billNumber}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFFE11D48),
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppFormatters.formatTime(credit.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              // Status Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSettled
                      ? const Color(0xFFDCFCE7)
                      : (hasPartial ? const Color(0xFFFEF3C7) : const Color(0xFFFFE4E6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isSettled
                      ? 'PAID'
                      : (hasPartial ? 'PARTIAL DUE' : 'PENDING'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    color: isSettled
                        ? const Color(0xFF16A34A)
                        : (hasPartial ? const Color(0xFFD97706) : const Color(0xFFE11D48)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Row 2: Customer Name & Phone
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFE11D48).withValues(alpha: 0.12),
                child: const Icon(Icons.person, size: 18, color: Color(0xFFE11D48)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.customerName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📞 ${credit.customerPhone}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (credit.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Note: ${credit.description}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          const Divider(height: 18),

          // Row 3: Financial Figures
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildAmountMetric('Total Bill', credit.totalAmount, AppColors.textPrimary),
              _buildAmountMetric('Paid', credit.paidAmount, const Color(0xFF16A34A)),
              _buildAmountMetric(
                'Balance Due',
                credit.balanceAmount,
                isSettled ? AppColors.textSecondary : const Color(0xFFE11D48),
                isBold: true,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons: Receive Payment, WhatsApp Bill, More Options
          Row(
            children: [
              // Receive Payment Button (Enabled only if balance > 0)
              if (!isSettled) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showReceivePaymentDialog(credit),
                    icon: const Icon(Icons.payment, size: 16, color: Colors.white),
                    label: const Text(
                      'Receive Payment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              // WhatsApp Bill Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleSendWhatsApp(credit),
                  icon: const Icon(Icons.chat, size: 16, color: Color(0xFF25D366)),
                  label: const Text(
                    'WhatsApp Bill',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF25D366)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              // Overflow Menu (History, Delete)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textSecondary),
                onSelected: (val) {
                  if (val == 'history') {
                    _showPaymentHistoryDialog(credit);
                  } else if (val == 'delete') {
                    _confirmDelete(credit);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.history, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Payment History'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Delete Bill', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAmountMetric(String title, double amount, Color color, {bool isBold = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          AppFormatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: color,
            fontFamily: 'Inter',
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 14),
            const Text(
              'No Credit Bills Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Customer credit bills and payment balances will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _showAddCreditDialog,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add First Credit Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // WHATSAPP BILL SENDING
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _handleSendWhatsApp(CreditKhata credit) async {
    final lastPayment = credit.payments.isNotEmpty ? credit.payments.last.paymentMethod : null;

    await WhatsAppHelper.sendCreditBillWhatsApp(
      context: context,
      rawPhone: credit.customerPhone,
      customerName: credit.customerName,
      billNumber: credit.billNumber,
      totalAmount: credit.totalAmount,
      paidAmount: credit.paidAmount,
      balanceAmount: credit.balanceAmount,
      status: credit.status,
      description: credit.description,
      hotelName: _hotelName,
      date: credit.createdAt,
      lastPaymentMethod: lastPayment,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DIALOG: ADD NEW CREDIT BILL
  // ───────────────────────────────────────────────────────────────────────────
  void _showAddCreditDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController(text: 'Food & Dining Credit');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.add_card, color: Color(0xFFE11D48)),
                SizedBox(width: 8),
                Text('New Credit Bill', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Name *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Ramesh Kumar',
                      prefixIcon: Icon(Icons.person, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Phone Number (WhatsApp) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 9876543210',
                      prefixIcon: Icon(Icons.phone, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Total Credit Amount (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 1500',
                      prefixIcon: Icon(Icons.currency_rupee, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Particulars / Notes (Optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Family dinner, lunch delivery',
                      prefixIcon: Icon(Icons.note, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final name = nameCtrl.text.trim();
                        final phone = phoneCtrl.text.trim();
                        final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                        final desc = descCtrl.text.trim();

                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter customer name')),
                          );
                          return;
                        }
                        if (phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter phone number')),
                          );
                          return;
                        }
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid credit amount')),
                          );
                          return;
                        }

                        setDlgState(() => isSaving = true);
                        final created = await _repo.createCreditBill({
                          'customerName': name,
                          'customerPhone': phone,
                          'totalAmount': amount,
                          'description': desc.isNotEmpty ? desc : 'Food & Dining Credit',
                        });

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted && created != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✅ Credit Bill #${created.billNumber} created!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadData();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE11D48),
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Bill', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DIALOG: RECEIVE PAYMENT (Full or Partial)
  // ───────────────────────────────────────────────────────────────────────────
  void _showReceivePaymentDialog(CreditKhata credit) {
    final payAmountCtrl = TextEditingController(
      text: credit.balanceAmount.truncateToDouble() == credit.balanceAmount
          ? credit.balanceAmount.toInt().toString()
          : credit.balanceAmount.toStringAsFixed(2),
    );
    final notesCtrl = TextEditingController();
    String selectedMethod = 'Cash';
    bool sendWhatsAppAuto = true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Receive Payment (#${credit.billNumber})',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Customer:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(credit.customerName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Bill:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(AppFormatters.formatCurrency(credit.totalAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Remaining Balance Due:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            Text(
                              AppFormatters.formatCurrency(credit.balanceAmount),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFE11D48)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Payment Amount (₹) *', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: payAmountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.currency_rupee, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text('Payment Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: ['Cash', 'UPI', 'Card'].map((method) {
                      final isSel = selectedMethod == method;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(method),
                          selected: isSel,
                          onSelected: (_) => setDlgState(() => selectedMethod = method),
                          selectedColor: const Color(0xFF16A34A).withValues(alpha: 0.18),
                          labelStyle: TextStyle(
                            color: isSel ? const Color(0xFF16A34A) : AppColors.textSecondary,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),

                  const Text('Remarks / Transaction Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: notesCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. GPay reference or cash received',
                      prefixIcon: Icon(Icons.edit_note, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: const Text('Send WhatsApp Receipt after payment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    value: sendWhatsAppAuto,
                    activeColor: const Color(0xFF25D366),
                    onChanged: (val) => setDlgState(() => sendWhatsAppAuto = val ?? true),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amt = double.tryParse(payAmountCtrl.text.trim()) ?? 0.0;
                        if (amt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid payment amount')),
                          );
                          return;
                        }

                        setDlgState(() => isSaving = true);
                        final updated = await _repo.recordPayment(
                          credit.id,
                          amount: amt,
                          paymentMethod: selectedMethod,
                          notes: notesCtrl.text.trim(),
                        );

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        if (mounted && updated != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                updated.isSettled
                                    ? '✅ Payment complete! Bill #${updated.billNumber} is FULLY PAID.'
                                    : '✅ Payment of ₹$amt recorded! Remaining: ₹${updated.balanceAmount.toStringAsFixed(0)}',
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _loadData();

                          // Automatically trigger WhatsApp receipt if option is checked
                          if (sendWhatsAppAuto) {
                            _handleSendWhatsApp(updated);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                ),
                child: isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Payment', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DIALOG: PAYMENT HISTORY
  // ───────────────────────────────────────────────────────────────────────────
  void _showPaymentHistoryDialog(CreditKhata credit) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Payment History (#${credit.billNumber})',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        content: credit.payments.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No payments recorded yet for this bill.', textAlign: TextAlign.center),
              )
            : SizedBox(
                width: double.maxFinite,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: credit.payments.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (ctx, i) {
                    final p = credit.payments[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(0xFFDCFCE7),
                        child: Icon(Icons.check, size: 14, color: Color(0xFF16A34A)),
                      ),
                      title: Text(
                        AppFormatters.formatCurrency(p.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF16A34A)),
                      ),
                      subtitle: Text(
                        '${p.paymentMethod} • ${AppFormatters.formatTime(p.paidAt)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      trailing: p.notes.isNotEmpty
                          ? Text(p.notes, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic))
                          : null,
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // DELETE CONFIRMATION
  // ───────────────────────────────────────────────────────────────────────────
  Future<void> _confirmDelete(CreditKhata credit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Credit Bill?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Are you sure you want to delete Bill #${credit.billNumber} for ${credit.customerName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await _repo.deleteCreditBill(credit.id);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credit bill deleted successfully')),
        );
        _loadData();
      }
    }
  }
}

extension<T> on List<T> {
  List<T> filter(bool Function(T) test) {
    return where(test).toList();
  }
}
