import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';

class SecurityShell extends StatelessWidget {
  const SecurityShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      path: '/security/dashboard',
    ),
    _TabItem(
      label: 'Visitors',
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_alt_rounded,
      path: '/security/visitors',
    ),
    _TabItem(
      label: 'Entry/Exit',
      icon: Icons.swap_horiz_outlined,
      activeIcon: Icons.swap_horiz_rounded,
      path: '/security/entry-exit',
    ),
    _TabItem(
      label: 'More',
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps_rounded,
      path: '/security/more',
    ),
  ];

  int _selectedIndex(String location) {
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
      restorationId: 'security_shell',
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
          onDestinationSelected: (i) => context.go(_tabs[i].path),
          height: 64,
          backgroundColor: brand,
          surfaceTintColor: Colors.transparent,
          indicatorColor: Colors.white.withValues(alpha: 0.20),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: _tabs
              .map((t) => NavigationDestination(
                    icon: Icon(t.icon,
                        color: Colors.white.withValues(alpha: 0.7)),
                    selectedIcon: Icon(t.activeIcon, color: Colors.white),
                    label: t.label,
                  ))
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
