import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/guest.dart';
import '../../../repositories/guest_repository.dart';
import '../../../widgets/common_widgets.dart';

class GuestDetailScreen extends StatefulWidget {
  final String guestId;
  const GuestDetailScreen({super.key, required this.guestId});

  @override
  State<GuestDetailScreen> createState() => _GuestDetailScreenState();
}

class _GuestDetailScreenState extends State<GuestDetailScreen> {
  Guest? _guest;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGuest();
  }

  Future<void> _loadGuest() async {
    final repo = context.read<GuestRepository>();
    final guest = await repo.getGuestById(widget.guestId);
    if (!mounted) return;
    setState(() { _guest = guest; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());
    if (_guest == null) return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.person, title: 'Guest not found'));

    final g = _guest!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        context.go('/guests');
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(g.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'वापस जाएं (Back)',
            onPressed: () => context.go('/guests'),
          ),
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Header
          AppCard(
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
                  child: Center(child: Text(g.name.substring(0, 1), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'Inter'))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(g.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                    if (g.isVip) const Padding(padding: EdgeInsets.only(left: 6), child: Text('⭐', style: TextStyle(fontSize: 16))),
                  ]),
                  const SizedBox(height: 4),
                  if (g.isReturning) StatusBadge(label: '${g.totalVisits}x Returning Guest', color: AppColors.primary),
                ])),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _StatBox(label: 'Total Stays', value: '${g.totalVisits}'),
                _StatBox(label: 'Total Spent', value: AppFormatters.formatCurrency(g.totalSpent)),
                if (g.lastStay != null) _StatBox(label: 'Last Stay', value: AppFormatters.formatDateShort(g.lastStay!)),
              ]),
            ]),
          ),
          const SizedBox(height: 12),

          // Contact info
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Contact Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              const SizedBox(height: 12),
              InfoRow(label: 'Phone', value: g.phone),
              InfoRow(label: 'Email', value: g.email),
              if (g.address != null) InfoRow(label: 'Address', value: g.address!),
              if (g.idType != null) InfoRow(label: g.idType!, value: g.idNumber ?? '-'),
            ]),
          ),
          const SizedBox(height: 12),

          if (g.preferences != null)
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Preferences & Notes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
                const SizedBox(height: 10),
                Text(g.preferences!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
              ]),
            ),
        ]),
      ),
    ));
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Inter')),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'Inter')),
    ]);
  }
}
