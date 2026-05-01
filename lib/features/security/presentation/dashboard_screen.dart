import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/utils/responsive_utils.dart';
import 'package:mobile_app/core/widgets/dashboard_avatar.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/security/domain/security_model.dart';
import 'package:mobile_app/features/security/providers/security_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(securityDashboardProvider);
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFF0F766E); // teal for security
    const accentDark = Color(0xFF0D5F57);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(securityDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: ResponsiveUtils.getHeaderHeight(context),
              pinned: true,
              backgroundColor: accent,
              elevation: 0,
              actions: [
                IconButton(
                  tooltip: 'Profile',
                  icon: const Icon(Icons.account_circle_outlined,
                      color: Colors.white),
                  onPressed: () => context.go('/security/profile'),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout_outlined, color: Colors.white),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accent, accentDark],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          DashboardAvatar(
                            imageUrl: user?.image,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            onTap: () => context.go('/security/profile'),
                            fallback: const Icon(Icons.security_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello, ${user?.name.split(' ').first ?? 'Guard'}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                                  style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: dashAsync.when(
                  loading: () => const Center(
                      heightFactor: 5, child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorCard(
                    message: e.toString(),
                    onRetry: () => ref.refresh(securityDashboardProvider.future),
                  ),
                  data: (dash) => _DashContent(dash: dash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashContent extends StatelessWidget {
  const _DashContent({required this.dash});
  final SecurityDashboard dash;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat grid
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              label: "Today's Entries",
              value: '${dash.todayEntries}',
              icon: Icons.login_rounded,
              color: const Color(0xFF10B981),
            ),
            _StatCard(
              label: "Today's Exits",
              value: '${dash.todayExits}',
              icon: Icons.logout_rounded,
              color: const Color(0xFF3B82F6),
            ),
            _StatCard(
              label: 'Active Visitors',
              value: '${dash.activeVisitors}',
              icon: Icons.people_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _StatCard(
              label: 'Pending Passes',
              value: '${dash.pendingPasses}',
              icon: Icons.badge_rounded,
              color: const Color(0xFF8B5CF6),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Quick actions
        Row(
          children: [
            _QuickAction(
              icon: Icons.swap_horiz_rounded,
              label: 'Log Entry/Exit',
              color: const Color(0xFF0F766E),
              onTap: () => context.go('/security/entry-exit'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.person_add_rounded,
              label: 'Visitors',
              color: const Color(0xFF3B82F6),
              onTap: () => context.go('/security/visitors'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.badge_rounded,
              label: 'Gate Passes',
              color: const Color(0xFF8B5CF6),
              onTap: () => context.go('/security/passes'),
            ),
          ],
        ),

        if (dash.recentLog.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Recent Activity',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...dash.recentLog.take(5).map((r) => _LogTile(record: r)),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface)),
              Text(label,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 5),
              Text(label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.record});
  final EntryExitRecord record;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEntry = record.type == 'entry';
    final color = isEntry ? const Color(0xFF10B981) : const Color(0xFF3B82F6);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isEntry ? Icons.login_rounded : Icons.logout_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(record.personName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                Text(record.personType,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ),
          Text(record.time,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
                maxLines: 3),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
