import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ReceptionShell extends StatelessWidget {
  const ReceptionShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/reception/dashboard'),
    _TabItem(label: 'Visitors', icon: Icons.person_add_outlined,
        activeIcon: Icons.person_add, path: '/reception/visitors'),
    _TabItem(label: 'Calls', icon: Icons.call_outlined,
        activeIcon: Icons.call, path: '/reception/calls'),
    _TabItem(label: 'More', icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz, path: '/reception/more'),
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
      restorationId: 'reception_shell',
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
