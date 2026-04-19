import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/features/auth/domain/user_model.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  // ── Admin / Clerk tabs ────────────────────────────────────────────────────
  static const _adminTabs = [
    _TabItem(label: 'Dashboard', icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard, path: '/admin/dashboard'),
    _TabItem(label: 'Students', icon: Icons.people_outlined,
        activeIcon: Icons.people, path: '/admin/students'),
    _TabItem(label: 'Fees', icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long, path: '/admin/fee-collection'),
    _TabItem(label: 'More', icon: Icons.more_horiz_outlined,
        activeIcon: Icons.more_horiz, path: '/admin/more'),
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
