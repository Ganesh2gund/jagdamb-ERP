import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      _MoreItem(icon: Icons.assessment_outlined, label: '10-Day Report', route: '/report-cycle', color: AppColors.primary),
      _MoreItem(icon: Icons.restaurant_outlined, label: 'Restaurant', route: '/restaurant', color: AppColors.cleaning),
      _MoreItem(icon: Icons.local_cafe_outlined, label: 'Cafe (कैफे)', route: '/cafe', color: Color(0xFFD97706)),
      _MoreItem(icon: Icons.receipt_long_outlined, label: 'Expenses', route: '/expenses', color: AppColors.warning),
      _MoreItem(icon: Icons.settings_outlined, label: 'Settings', route: '/settings', color: AppColors.textSecondary),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('More'),
        backgroundColor: AppColors.surface,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.25,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => context.go(item.route),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.color, size: 24),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          fontFamily: 'Inter',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MoreItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _MoreItem({required this.icon, required this.label, required this.route, required this.color});
}
