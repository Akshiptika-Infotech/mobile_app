import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/utils/responsive_utils.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/reception/domain/reception_model.dart';
import 'package:mobile_app/features/reception/providers/reception_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final dashAsync = ref.watch(receptionDashboardProvider);
    final cs = Theme.of(context).colorScheme;
    const accent = Color(0xFF9333EA);
    const accentDark = Color(0xFF7E22CE);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(receptionDashboardProvider.future),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: ResponsiveUtils.getHeaderHeight(context),
              pinned: true,
              backgroundColor: accent,
              elevation: 0,
              actions: [
                IconButton(
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
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                Colors.white.withValues(alpha: 0.2),
                            child: const Icon(Icons.desk_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Hello, ${user?.name.split(' ').first ?? 'Receptionist'}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  DateFormat('EEEE, d MMMM yyyy')
                                      .format(DateTime.now()),
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.8),
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
                    onRetry: () =>
                        ref.refresh(receptionDashboardProvider.future),
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
  final ReceptionDashboard dash;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              label: "Today's Appointments",
              value: '${dash.todayAppointments}',
              icon: Icons.event_rounded,
              color: const Color(0xFF9333EA),
            ),
            _StatCard(
              label: 'Pending Passes',
              value: '${dash.pendingPasses}',
              icon: Icons.badge_rounded,
              color: const Color(0xFFF59E0B),
            ),
            _StatCard(
              label: 'Calls Logged',
              value: '${dash.callsLogged}',
              icon: Icons.call_rounded,
              color: const Color(0xFF10B981),
            ),
            _StatCard(
              label: 'Late Arrivals',
              value: '${dash.lateArrivals}',
              icon: Icons.access_time_rounded,
              color: const Color(0xFFEF4444),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.person_add_rounded,
              label: 'Visitor',
              color: const Color(0xFF9333EA),
              onTap: () => context.go('/reception/visitors'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.call_rounded,
              label: 'Log Call',
              color: const Color(0xFF10B981),
              onTap: () => context.go('/reception/calls'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.event_rounded,
              label: 'Appointments',
              color: const Color(0xFF3B82F6),
              onTap: () => context.go('/reception/more'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.access_time_rounded,
              label: 'Late',
              color: const Color(0xFFEF4444),
              onTap: () => context.go('/reception/more'),
            ),
          ],
        ),
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
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
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
                  style: TextStyle(
                      fontSize: 10,
                      color: color,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
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
