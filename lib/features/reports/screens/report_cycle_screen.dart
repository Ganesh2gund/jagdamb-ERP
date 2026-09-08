import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../repositories/report_repository.dart';
import '../../../services/report_pdf_service.dart';

class ReportCycleScreen extends StatefulWidget {
  const ReportCycleScreen({super.key});

  @override
  State<ReportCycleScreen> createState() => _ReportCycleScreenState();
}

class _ReportCycleScreenState extends State<ReportCycleScreen> {
  final ReportRepository _repo = ReportRepository();
  bool _isLoading = true;
  bool _isDownloading = false;
  Map<String, dynamic> _status = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    // Auto-refresh every 30 seconds for live countdown
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadStatus());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final status = await _repo.getCycleStatus();
    if (mounted) {
      setState(() {
        _status = status;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloading = true);
    try {
      final reportData = await _repo.getReportData();
      if (reportData.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to load report data from server.')),
          );
        }
        return;
      }

      await ReportPdfService.downloadOrPrintReport(reportData);

      // Trigger 6-hour delayed cleanup schedule on backend
      await _repo.scheduleCleanup();
      await _loadStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('✅ PDF downloaded! Data will be refreshed automatically in 6 hours.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleCancelCleanup() async {
    final ok = await _repo.cancelCleanup();
    if (ok) {
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cleanup timer cancelled! Data will remain safe.')),
        );
      }
    }
  }

  Future<void> _handleInstantDelete() async {
    final confirm = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + MediaQuery.of(ctx).padding.bottom + 16,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.grey300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: AppColors.errorLight, shape: BoxShape.circle),
                  child: const Icon(Icons.delete_sweep_rounded, color: AppColors.error, size: 26),
                ),
                const SizedBox(height: 10),
                const Text(
                  'बिलिंग डेटा रीसेट करें (Confirm Data Clean)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Inter'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.grey50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• Archive / Reset hoga: Purane Checked-Out Rooms, Past Events & Settled Bills', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.error)),
                      SizedBox(height: 4),
                      Text('• 100% Safe rahega: Future / Advance Bookings, Currently In-House Guests, Upcoming Hall Events, Rooms & Menu', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('रद्द करें (Cancel)', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary, fontSize: 13)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: const Text('अभी डिलीट करें', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final ok = await _repo.instantDelete();
      await _loadStatus();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ok ? AppColors.success : AppColors.error,
            content: Text(ok
                ? '✨ Database refreshed! All billing records cleared for the new cycle.'
                : 'Failed to delete data. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('10-Day Report & Cleanup')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final cycleNum = _status['cycleNumber']?.toString() ?? '1';
    final startDate = _status['startDate']?.toString() ?? '';
    final endDate = _status['endDate']?.toString() ?? '';
    final daysElapsed = (_status['daysElapsed'] as num?)?.toInt() ?? 1;
    final daysRemaining = (_status['daysRemaining'] as num?)?.toInt() ?? 9;
    final isReady = _status['isReady'] == true;
    final isCleanupActive = _status['isCleanupActive'] == true;
    final remainingMins = (_status['cleanupRemainingMinutes'] as num?)?.toInt() ?? 0;

    final summary = (_status['summary'] as Map<String, dynamic>?) ?? {};
    final roomRev = (summary['roomRevenue'] as num?)?.toDouble() ?? 0.0;
    final restRev = (summary['restaurantRevenue'] as num?)?.toDouble() ?? 0.0;
    final cafeRev = (summary['cafeRevenue'] as num?)?.toDouble() ?? 0.0;
    final banquetRev = (summary['banquetRevenue'] as num?)?.toDouble() ?? 0.0;
    final totalExp = (summary['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (summary['netProfit'] as num?)?.toDouble() ?? 0.0;

    final bookingsCount = summary['totalBookingsCount'] ?? 0;
    final ordersCount = summary['totalOrdersCount'] ?? 0;
    final cafeOrdersCount = summary['totalCafeOrdersCount'] ?? 0;
    final banquetBookingsCount = summary['totalBanquetBookingsCount'] ?? 0;
    final expensesCount = summary['totalExpensesCount'] ?? 0;

    final progress = (daysElapsed / 10).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('10-Day Report & Cleanup'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Status',
            onPressed: () => _loadStatus(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Active Cleanup Countdown Banner ───────────────────
              if (isCleanupActive) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.amber.shade700, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, color: Colors.amber.shade900, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '⏰ 6-Hour Auto-Cleanup Scheduled',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Cleanup in: ${remainingMins ~/ 60}h ${remainingMins % 60}m remaining',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red.shade700,
                            ),
                            onPressed: _handleCancelCleanup,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PDF download ho chuki hai. Timer khatam hone par billing data refresh hoga.',
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── 10-Day Cycle Card ─────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Cycle #$cycleNum',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$startDate – $endDate',
                            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isReady ? AppColors.success : AppColors.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isReady ? 'Ready' : '$daysRemaining d left',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isReady ? AppColors.success : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Day $daysElapsed of 10',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          '${(progress * 100).toInt()}% Completed',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isReady ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isReady
                          ? '🎉 10 din pure ho gaye hain! Niche button se PDF report download karein.'
                          : 'ℹ️ 10 din hone par PDF report download kar sakte hain. Data tab tak safe rahega.',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── Financial Overview Grid ───────────────────────────
              const Text(
                'Financial Overview (Current Cycle)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard('Room Revenue', '₹${roomRev.toStringAsFixed(0)}', '$bookingsCount Bookings', AppColors.success),
                  const SizedBox(width: 10),
                  _statCard('Restaurant Sales', '₹${restRev.toStringAsFixed(0)}', '$ordersCount Orders', AppColors.cleaning),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard('Cafe Sales', '₹${cafeRev.toStringAsFixed(0)}', '$cafeOrdersCount Orders', Colors.amber.shade700),
                  const SizedBox(width: 10),
                  _statCard('Banquet (हॉल)', '₹${banquetRev.toStringAsFixed(0)}', '$banquetBookingsCount Events', AppColors.primary),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _statCard('Expenses', '₹${totalExp.toStringAsFixed(0)}', '$expensesCount Expenses', AppColors.warning),
                  const SizedBox(width: 10),
                  _statCard(
                    'Net Profit',
                    '₹${netProfit.toStringAsFixed(0)}',
                    netProfit >= 0 ? 'Profitable' : 'Loss',
                    netProfit >= 0 ? AppColors.primary : AppColors.error,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Primary Action: Download PDF Report ────────────────
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  onPressed: _isDownloading ? null : _handleDownloadPdf,
                  icon: _isDownloading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    _isDownloading ? 'Generating PDF...' : 'Download 10-Day PDF Report',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  '💡 Note: PDF download karne ke 6 ghante baad billing data refresh hoga.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(height: 24),

              // ── Secondary Action: Instant Clean Button ─────────────
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _handleInstantDelete,
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const Text(
                  'Delete Data Now (Instant Clean)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),

              // ── Info Card (What stays safe) ───────────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Master Data Hamesha Safe Rahega',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '• Rooms, Room Types, Rates\n'
                      '• Restaurant Dishes, Menu, Categories\n'
                      '• Restaurant Tables\n'
                      '• Hotel Name, Phone & Settings\n\n'
                      'Ye sab kabhi delete nahi honge! Sirf billing aur transactions delete honge.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(String title, String value, String subtitle, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
