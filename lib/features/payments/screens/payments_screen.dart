import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

import '../../../models/booking.dart';
import '../../../repositories/booking_repository.dart';
import '../../../widgets/common_widgets.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final repo = context.read<BookingRepository>();
    final bookings = await repo.getBookings();
    if (!mounted) return;
    setState(() { _bookings = bookings; _isLoading = false; });
  }

  List<Booking> get _paid => _bookings.where((b) => b.paymentStatus == PaymentStatus.paid).toList();
  List<Booking> get _pending => _bookings.where((b) => b.paymentStatus == PaymentStatus.pending).toList();
  List<Booking> get _partial => _bookings.where((b) => b.paymentStatus == PaymentStatus.partial).toList();

  double get _totalOutstanding =>
    _pending.fold(0.0, (s, b) => s + b.totalAmount) + _partial.fold(0.0, (s, b) => s + b.pendingAmount);

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payments'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Paid (${_paid.length})'),
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Partial (${_partial.length})'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Outstanding banner
          if (_totalOutstanding > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: AppColors.errorLight,
              child: Row(children: [
                const Icon(Icons.warning_outlined, color: AppColors.error, size: 18),
                const SizedBox(width: 10),
                Text(
                  'Total Outstanding: ${AppFormatters.formatCurrency(_totalOutstanding)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.error, fontFamily: 'Inter'),
                ),
              ]),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPaymentList(_paid, AppColors.success),
                _buildPaymentList(_pending, AppColors.error),
                _buildPaymentList(_partial, AppColors.warning),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentList(List<Booking> bookings, Color color) {
    if (bookings.isEmpty) return const EmptyState(icon: Icons.payments, title: 'No payments in this category');
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final b = bookings[i];
        final amount = b.paymentStatus == PaymentStatus.partial ? b.pendingAmount : b.totalAmount;
        return AppCard(
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
              child: Center(child: Text(b.guestName.substring(0, 1), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter'))),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(b.guestName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              const SizedBox(height: 3),
              Text('Room ${b.roomNumber} • ${b.source.label}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(
                b.paymentStatus == PaymentStatus.paid ? AppFormatters.formatCurrency(b.paidAmount) : '${AppFormatters.formatCurrency(amount)} pending',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 3),
              Text(AppFormatters.formatDate(b.checkIn), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
            ]),
          ]),
        );
      },
    );
  }
}
