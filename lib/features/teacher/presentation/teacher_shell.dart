import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      path: '/teacher/dashboard',
    ),
    _TabItem(
      label: 'Class',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
      path: '/teacher/class',
    ),
    _TabItem(
      label: 'Attendance',
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check_rounded,
      path: '/teacher/attendance',
    ),
    _TabItem(
      label: 'Exams',
      icon: Icons.assignment_outlined,
      activeIcon: Icons.assignment_rounded,
      path: '/teacher/exams',
    ),
    _TabItem(
      label: 'More',
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps_rounded,
      path: '/teacher/more',
    ),
  ];

  int _selectedIndex(String location) {
    // Find the longest matching tab path so nested routes activate
    // their parent tab correctly.
    var bestIndex = 0;
    var bestLen = 0;
    for (var i = 0; i < _tabs.length; i++) {
      final p = _tabs[i].path;
      if (location.startsWith(p) && p.length > bestLen) {
        bestIndex = i;
        bestLen = p.length;
      }
    }
    return bestIndex;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);
    final brand = AppConfigScope.of(context).primaryColor;

    return Scaffold(
      restorationId: 'teacher_shell',
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: brand,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => context.go(_tabs[index].path),
          height: 64,
          backgroundColor: brand,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.white.withValues(alpha: 0.20),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _tabs
              .map(
                (t) => NavigationDestination(
                  icon: Icon(t.icon, color: Colors.white.withValues(alpha: 0.7)),
                  selectedIcon: Icon(t.activeIcon, color: Colors.white),
                  label: t.label,
                ),
              )
              .toList(),
        ),
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
