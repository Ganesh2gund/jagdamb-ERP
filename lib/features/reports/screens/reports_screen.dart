import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/common_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Clean Initial State (No dummy data)
  static const Map<String, double> _weeklyRevenue = {
    'Mon': 0, 'Tue': 0, 'Wed': 0, 'Thu': 0,
    'Fri': 0, 'Sat': 0, 'Sun': 0,
  };

  static const double _occupancyRate = 0.0;
  static const double _adr = 0.0;
  static const double _revpar = 0.0;
  static const double _totalRevenue = 0.0;
  static const double _totalExpenses = 0.0;
  static const double _netProfit = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Reports'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Revenue'), Tab(text: 'Metrics')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildOverview(), _buildRevenue(), _buildMetrics()],
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Key metrics row
        Row(children: [
          Expanded(child: _MetricCard(label: 'Occupancy', value: '$_occupancyRate%', icon: Icons.hotel, color: AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(label: 'ADR', value: AppFormatters.formatCurrency(_adr), icon: Icons.trending_up, color: AppColors.success)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _MetricCard(label: 'RevPAR', value: AppFormatters.formatCurrency(_revpar), icon: Icons.bar_chart, color: AppColors.info)),
          const SizedBox(width: 10),
          Expanded(child: _MetricCard(label: 'Net Profit', value: AppFormatters.formatCurrency(_netProfit), icon: Icons.account_balance_wallet, color: AppColors.reserved)),
        ]),
        const SizedBox(height: 20),

        // Revenue vs Expense card
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Monthly Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            _SummaryRow(label: 'Total Revenue', value: AppFormatters.formatCurrency(_totalRevenue), color: AppColors.success),
            const SizedBox(height: 8),
            _SummaryRow(label: 'Total Expenses', value: AppFormatters.formatCurrency(_totalExpenses), color: AppColors.error),
            const Divider(),
            _SummaryRow(label: 'Net Profit', value: AppFormatters.formatCurrency(_netProfit), color: AppColors.primary, isBold: true),
          ]),
        ),
        const SizedBox(height: 20),

        // Report cards
        const SectionHeader(title: 'Report Categories'),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: const [
            _ReportCard(label: 'Daily Revenue', icon: Icons.today),
            _ReportCard(label: 'Monthly Revenue', icon: Icons.calendar_month),
            _ReportCard(label: 'Occupancy', icon: Icons.hotel),
            _ReportCard(label: 'Bookings', icon: Icons.book),
            _ReportCard(label: 'Payments', icon: Icons.payments),
            _ReportCard(label: 'Expenses', icon: Icons.receipt_long),
          ],
        ),
      ]),
    );
  }

  Widget _buildRevenue() {
    final entries = _weeklyRevenue.entries.toList();
    final maxVal = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Weekly Revenue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            const SizedBox(height: 4),
            const Text('This week\'s daily performance', style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
            const SizedBox(height: 20),
            SizedBox(
              height: 180,
              child: BarChart(
                BarChartData(
                  maxY: maxVal * 1.2,
                  gridData: FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) => Text(
                        entries[v.toInt()].key,
                        style: const TextStyle(fontSize: 10, fontFamily: 'Inter', color: AppColors.textSecondary),
                      ),
                    )),
                  ),
                  barGroups: List.generate(entries.length, (i) => BarChartGroupData(
                    x: i,
                    barRods: [BarChartRodData(
                      toY: entries[i].value,
                      color: AppColors.primary,
                      width: 20,
                      borderRadius: BorderRadius.circular(6),
                    )],
                  )),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Revenue Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(value: 74, title: 'Rooms\n74%', color: AppColors.primary, radius: 55, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                    PieChartSectionData(value: 21, title: 'Rest.\n21%', color: AppColors.info, radius: 55, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                    PieChartSectionData(value: 5, title: 'Other\n5%', color: AppColors.success, radius: 55, titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontFamily: 'Inter', fontWeight: FontWeight.w700)),
                  ],
                  centerSpaceRadius: 30,
                  sectionsSpace: 2,
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _buildMetrics() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        AppCard(
          child: Column(children: [
            _MetricRow(label: 'Occupancy Rate', value: '$_occupancyRate%', description: '10 of 14 rooms occupied'),
            const Divider(),
            _MetricRow(label: 'ADR (Avg Daily Rate)', value: AppFormatters.formatCurrency(_adr), description: 'Average room rate today'),
            const Divider(),
            _MetricRow(label: 'RevPAR', value: AppFormatters.formatCurrency(_revpar), description: 'Revenue per available room'),
            const Divider(),
            _MetricRow(label: 'Total Revenue (Month)', value: AppFormatters.formatCurrency(_totalRevenue), description: 'Rooms + Restaurant + Services'),
            const Divider(),
            _MetricRow(label: 'Total Expenses (Month)', value: AppFormatters.formatCurrency(_totalExpenses), description: 'Salaries, utilities, supplies'),
            const Divider(),
            _MetricRow(label: 'Net Profit (Month)', value: AppFormatters.formatCurrency(_netProfit), description: 'Revenue - Expenses', valueColor: AppColors.success),
          ]),
        ),
      ]),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis),
        ])),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, required this.color, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 14, fontFamily: 'Inter', fontWeight: isBold ? FontWeight.w700 : FontWeight.w400)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color, fontFamily: 'Inter')),
    ]);
  }
}

class _ReportCard extends StatelessWidget {
  final String label;
  final IconData icon;

  const _ReportCard({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'Inter'), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final String description;
  final Color? valueColor;

  const _MetricRow({required this.label, required this.value, required this.description, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, fontFamily: 'Inter')),
          Text(description, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
        ])),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.textPrimary, fontFamily: 'Inter')),
      ]),
    );
  }
}
