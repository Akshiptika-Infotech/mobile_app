import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/core/utils/responsive_utils.dart';
import 'package:mobile_app/features/auth/providers/auth_provider.dart';
import 'package:mobile_app/features/driver/domain/driver_model.dart';
import 'package:mobile_app/features/driver/providers/driver_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tripAsync = ref.watch(driverTripProvider);
    final cs = Theme.of(context).colorScheme;
    final today = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(driverTripProvider.future),
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: ResponsiveUtils.getHeaderHeight(context),
              pinned: true,
              backgroundColor: const Color(0xFF1D4ED8),
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
                      colors: [Color(0xFF1D4ED8), Color(0xFF1E3A8A)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.2),
                                child: const Icon(Icons.directions_bus_rounded,
                                    color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello, ${user?.name.split(' ').first ?? 'Driver'}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Text(today,
                                        style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ──────────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverToBoxAdapter(
                child: tripAsync.when(
                  loading: () => const Center(
                      heightFactor: 5, child: CircularProgressIndicator()),
                  error: (e, _) => _ErrorCard(
                    message: e.toString(),
                    onRetry: () => ref.refresh(driverTripProvider.future),
                  ),
                  data: (trip) => _TripContent(trip: trip),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Trip content ──────────────────────────────────────────────────────────────

class _TripContent extends StatelessWidget {
  const _TripContent({required this.trip});
  final DriverTrip trip;

  Color get _statusColor {
    switch (trip.tripStatus.toLowerCase()) {
      case 'active':
        return const Color(0xFF10B981);
      case 'completed':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  String get _statusLabel {
    switch (trip.tripStatus.toLowerCase()) {
      case 'active':
        return 'Active';
      case 'completed':
        return 'Completed';
      default:
        return 'Not Started';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trip card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's Trip",
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          trip.routeName.isEmpty ? 'No route assigned' : trip.routeName,
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(_statusLabel,
                        style: TextStyle(
                            color: _statusColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 13)),
                  ),
                ],
              ),
              if (trip.vehicleNumber.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.directions_bus_rounded,
                        size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(trip.vehicleNumber,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TripStat(
                      icon: Icons.location_on_rounded,
                      label: 'Stoppages',
                      value: '${trip.stoppageCount}',
                      color: const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TripStat(
                      icon: Icons.people_rounded,
                      label: 'Students',
                      value: '${trip.studentCount}',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Quick actions
        Text('Quick Actions',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          children: [
            _QuickAction(
              icon: Icons.map_rounded,
              label: 'My Route',
              color: const Color(0xFF3B82F6),
              onTap: () => context.go('/driver/route'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.people_rounded,
              label: 'Students',
              color: const Color(0xFF10B981),
              onTap: () => context.go('/driver/students'),
            ),
            const SizedBox(width: 10),
            _QuickAction(
              icon: Icons.fact_check_rounded,
              label: 'Attendance',
              color: const Color(0xFFF59E0B),
              onTap: () => context.go('/driver/attendance'),
            ),
          ],
        ),
      ],
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: cs.onSurfaceVariant)),
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
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
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
