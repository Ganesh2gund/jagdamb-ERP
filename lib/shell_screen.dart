import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';

class ShellScreen extends StatelessWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  int _getSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/rooms')) return 1;
    if (location.startsWith('/bookings') ||
        location.startsWith('/check-in') ||
        location.startsWith('/check-out')) return 2;
    return 3; // More
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _getSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: const Border(top: BorderSide(color: AppColors.border, width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: selectedIndex,
            elevation: 0,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primarySurface,
            height: 64,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            onDestinationSelected: (index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/rooms');
                  break;
                case 2:
                  context.go('/bookings');
                  break;
                case 3:
                  context.go('/more');
                  break;
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.hotel_outlined),
                selectedIcon: Icon(Icons.hotel_rounded, color: AppColors.primary),
                label: 'Rooms',
              ),
              NavigationDestination(
                icon: Icon(Icons.book_outlined),
                selectedIcon: Icon(Icons.book_rounded, color: AppColors.primary),
                label: 'Bookings',
              ),
              NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded, color: AppColors.primary),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
