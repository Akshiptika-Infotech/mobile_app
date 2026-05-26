import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  // ── Admin / Clerk tabs ────────────────────────────────────────────────────
  // Mobile admin scope: oversight only — Approvals, Reports, Users.
  // Day-to-day data entry (students, fees, classes, etc.) lives on the web app.
  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/admin/dashboard'),
    _TabItem(label: 'Approvals', icon: Icons.task_alt_outlined,
        activeIcon: Icons.task_alt, path: '/admin/approvals'),
    _TabItem(label: 'Reports', icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart, path: '/admin/reports/collection'),
    _TabItem(label: 'Users', icon: Icons.group_outlined,
        activeIcon: Icons.group, path: '/admin/users'),
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
      restorationId: 'admin_shell',
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(_tabs[index].path),
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
