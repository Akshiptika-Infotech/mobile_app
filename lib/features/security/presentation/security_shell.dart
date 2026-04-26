import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecurityShell extends StatelessWidget {
  const SecurityShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/security/dashboard'),
    _TabItem(label: 'Entry/Exit', icon: Icons.swap_horiz_outlined,
        activeIcon: Icons.swap_horiz, path: '/security/entry-exit'),
    _TabItem(label: 'Visitors', icon: Icons.person_add_outlined,
        activeIcon: Icons.person_add, path: '/security/visitors'),
    _TabItem(label: 'Passes', icon: Icons.badge_outlined,
        activeIcon: Icons.badge, path: '/security/passes'),
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
      restorationId: 'security_shell',
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
