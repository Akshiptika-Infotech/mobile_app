import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WebAdminShell extends StatelessWidget {
  const WebAdminShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
      path: '/web-admin/dashboard',
    ),
    _TabItem(
      label: 'Content',
      icon: Icons.article_outlined,
      activeIcon: Icons.article,
      path: '/web-admin/content',
    ),
    _TabItem(
      label: 'Gallery',
      icon: Icons.photo_library_outlined,
      activeIcon: Icons.photo_library,
      path: '/web-admin/gallery',
    ),
    _TabItem(
      label: 'More',
      icon: Icons.more_horiz_outlined,
      activeIcon: Icons.more_horiz,
      path: '/web-admin/more',
    ),
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
        onDestinationSelected: (index) => context.go(_tabs[index].path),
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: Icon(t.icon),
                selectedIcon: Icon(t.activeIcon),
                label: t.label,
              ),
            )
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
