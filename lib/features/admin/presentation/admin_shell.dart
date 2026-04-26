import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  // ── Admin / Clerk tabs ────────────────────────────────────────────────────
  // Mobile admin scope: oversight only — Approvals, Reports, Users.
  // Day-to-day data entry (students, fees, classes, etc.) lives on the web app.
  static const _adminTabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/admin/dashboard'),
    _TabItem(label: 'Approvals', icon: Icons.task_alt_outlined,
        activeIcon: Icons.task_alt, path: '/admin/approvals'),
    _TabItem(label: 'Reports', icon: Icons.bar_chart_outlined,
        activeIcon: Icons.bar_chart, path: '/admin/reports/collection'),
    _TabItem(label: 'Users', icon: Icons.group_outlined,
        activeIcon: Icons.group, path: '/admin/users'),
  ];

  // ── Teacher tabs ──────────────────────────────────────────────────────────
  static const _teacherTabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/admin/dashboard'),
    _TabItem(label: 'Timetable', icon: Icons.calendar_view_week_outlined,
        activeIcon: Icons.calendar_view_week, path: '/admin/timetable/my'),
    _TabItem(label: 'Attendance', icon: Icons.fact_check_outlined,
        activeIcon: Icons.fact_check, path: '/admin/attendance/my-class'),
    _TabItem(label: 'Exams', icon: Icons.assignment_outlined,
        activeIcon: Icons.assignment, path: '/admin/exams/marks'),
    _TabItem(label: 'Calendar', icon: Icons.event_outlined,
        activeIcon: Icons.event, path: '/admin/calendar'),
  ];

  List<_TabItem> _tabsForRole(String? role) =>
      role == AppRole.teacher ? _teacherTabs : _adminTabs;

  int _selectedIndex(List<_TabItem> tabs, String location) {
    for (var i = 0; i < tabs.length; i++) {
      if (location.startsWith(tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentUserProvider)?.role;
    final tabs = _tabsForRole(role);
    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(tabs, location);

    return Scaffold(
      restorationId: 'admin_shell',
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => context.go(tabs[index].path),
        destinations: tabs
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
