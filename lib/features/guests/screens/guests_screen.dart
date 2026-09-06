import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/guest.dart';
import '../../../repositories/guest_repository.dart';
import '../../../widgets/common_widgets.dart';

class GuestsScreen extends StatefulWidget {
  const GuestsScreen({super.key});

  @override
  State<GuestsScreen> createState() => _GuestsScreenState();
}

class _GuestsScreenState extends State<GuestsScreen> {
  bool _isLoading = true;
  List<Guest> _allGuests = [];
  List<Guest> _filteredGuests = [];
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGuests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGuests() async {
    final repo = context.read<GuestRepository>();
    final guests = await repo.getGuests();
    if (!mounted) return;
    setState(() { _allGuests = guests; _filteredGuests = guests; _isLoading = false; });
  }

  void _search(String query) async {
    if (query.isEmpty) {
      setState(() => _filteredGuests = _allGuests);
      return;
    }
    final repo = context.read<GuestRepository>();
    final results = await repo.searchGuests(query);
    if (!mounted) return;
    setState(() => _filteredGuests = results);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingState());
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Guests')),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: AppSearchBar(controller: _searchController, hintText: 'Search guests...', onChanged: _search),
          ),
          const Divider(height: 1),
          Expanded(
            child: _filteredGuests.isEmpty
                ? const EmptyState(icon: Icons.people, title: 'No guests found')
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredGuests.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, i) => _GuestCard(guest: _filteredGuests[i], onTap: () => context.go('/guests/${_filteredGuests[i].id}')),
                  ),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Guest guest;
  final VoidCallback onTap;

  const _GuestCard({required this.guest, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.primarySurface, shape: BoxShape.circle),
            child: Center(child: Text(guest.name.substring(0, 1), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.primary, fontFamily: 'Inter'))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(guest.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFamily: 'Inter')),
              if (guest.isVip) ...[const SizedBox(width: 6), const Text('⭐', style: TextStyle(fontSize: 14))],
              if (guest.isReturning) ...[const SizedBox(width: 6), StatusBadge(label: 'Returning', color: AppColors.primary, fontSize: 10)],
            ]),
            const SizedBox(height: 3),
            Text(guest.phone, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontFamily: 'Inter')),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${guest.totalVisits} stays', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontFamily: 'Inter')),
            const SizedBox(height: 3),
            Text(AppFormatters.formatCurrency(guest.totalSpent), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontFamily: 'Inter')),
          ]),
        ]),
      ),
    );
  }
}
