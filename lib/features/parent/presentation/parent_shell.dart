import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ParentShell extends StatelessWidget {
  const ParentShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/parent/dashboard'),
    _TabItem(label: 'Receipts', icon: Icons.article_outlined,
        activeIcon: Icons.article, path: '/parent/receipts'),
    _TabItem(label: 'Timetable', icon: Icons.calendar_view_week_outlined,
        activeIcon: Icons.calendar_view_week, path: '/parent/timetable'),
    _TabItem(label: 'Calendar', icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month, path: '/parent/calendar'),
    _TabItem(label: 'Profile', icon: Icons.person_outlined,
        activeIcon: Icons.person, path: '/parent/profile'),
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
      restorationId: 'parent_shell',
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
