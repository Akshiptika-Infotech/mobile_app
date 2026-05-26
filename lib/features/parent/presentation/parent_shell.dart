import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/parent/providers/parent_providers.dart';

/// Bottom-nav shell for the parent portal. Also force-loads the children
/// list at session start so [selectedChildIdProvider] can default to the
/// first child on first render.
class ParentShell extends ConsumerWidget {
  const ParentShell({super.key, required this.child});

  final Widget child;

  static const _tabs = [
    _TabItem(
      label: 'Home',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
      path: '/parent/dashboard',
    ),
    _TabItem(
      label: 'Fees',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
      path: '/parent/fees',
    ),
    _TabItem(
      label: 'Attendance',
      icon: Icons.fact_check_outlined,
      activeIcon: Icons.fact_check_rounded,
      path: '/parent/attendance',
    ),
    _TabItem(
      label: 'Bus',
      icon: Icons.directions_bus_outlined,
      activeIcon: Icons.directions_bus_rounded,
      path: '/parent/transport',
    ),
    _TabItem(
      label: 'More',
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps_rounded,
      path: '/parent/more',
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
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch children so the selected-child default is populated by the time
    // any tab needs it. We don't render based on the result here.
    ref.watch(childrenProvider);

    final location = GoRouterState.of(context).matchedLocation;
    final selectedIndex = _selectedIndex(location);
    final brand = AppConfigScope.of(context).primaryColor;

    return Scaffold(
      restorationId: 'parent_shell',
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
