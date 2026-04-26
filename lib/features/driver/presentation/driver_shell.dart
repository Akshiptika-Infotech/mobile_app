import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverShell extends StatelessWidget {
  const DriverShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/driver/dashboard'),
    _TabItem(label: 'Route', icon: Icons.map_outlined,
        activeIcon: Icons.map, path: '/driver/route'),
    _TabItem(label: 'Students', icon: Icons.people_outlined,
        activeIcon: Icons.people, path: '/driver/students'),
    _TabItem(label: 'Attendance', icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check, path: '/driver/attendance'),
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
      restorationId: 'driver_shell',
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
