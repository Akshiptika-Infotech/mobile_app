import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/student/dashboard'),
    _TabItem(label: 'Fees', icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long, path: '/student/fees'),
    _TabItem(label: 'Receipts', icon: Icons.article_outlined,
        activeIcon: Icons.article, path: '/student/receipts'),
    _TabItem(label: 'Transport', icon: Icons.directions_bus_outlined,
        activeIcon: Icons.directions_bus, path: '/student/transport'),
    _TabItem(label: 'Profile', icon: Icons.person_outlined,
        activeIcon: Icons.person, path: '/student/profile'),
  ];

  int _selectedIndex(String location) {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) =>
            context.go(_tabs[index].path),
        destinations: _tabs
            .map((t) => NavigationDestination(
                  icon: Icon(t.icon),
                  selectedIcon: Icon(t.activeIcon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.path,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String path;
}
