import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/features/driver/domain/driver_model.dart';
import 'package:mobile_app/features/driver/providers/driver_provider.dart';

class RouteScreen extends ConsumerWidget {
  const RouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final routeAsync = ref.watch(driverRouteProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('My Route'),
        centerTitle: false,
        backgroundColor: cs.surface,
        surfaceTintColor: cs.surfaceTint,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.refresh(driverRouteProvider),
          ),
        ],
      ),
      body: routeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorView(
          message: e.toString(),
          onRetry: () => ref.refresh(driverRouteProvider),
        ),
        data: (route) => _RouteView(route: route),
      ),
    );
  }
}

class _RouteView extends StatelessWidget {
  const _RouteView({required this.route});
  final DriverRoute route;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Route info card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                      if (route.vehicleNumber.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(children: [
                          Icon(Icons.directions_bus_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.8)),
                          const SizedBox(width: 6),
                          Text(route.vehicleNumber,
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13)),
                        ]),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          if (route.driverName.isNotEmpty)
                            _InfoChip(
                                icon: Icons.person_rounded,
                                label: route.driverName),
                          if (route.conductorName.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _InfoChip(
                                icon: Icons.support_agent_rounded,
                                label: route.conductorName),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.location_on_rounded,
                        size: 16, color: cs.primary),
                    const SizedBox(width: 6),
                    Text('${route.stoppages.length} Stoppages',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface)),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        if (route.stoppages.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No stoppages found')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _StoppageTile(
                  stoppage: route.stoppages[i],
                  index: i,
                  isLast: i == route.stoppages.length - 1,
                ),
                childCount: route.stoppages.length,
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StoppageTile extends StatelessWidget {
  const _StoppageTile({
    required this.stoppage,
    required this.index,
    required this.isLast,
  });
  final Stoppage stoppage;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        children: [
          // Timeline line + dot
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: cs.primary.withValues(alpha: 0.3)),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(stoppage.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        Text('Stop ${index + 1}',
                            style: TextStyle(
                                fontSize: 11, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  if (stoppage.studentCount > 0)
                    Row(
                      children: [
                        Icon(Icons.people_rounded,
                            size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text('${stoppage.studentCount}',
                            style: TextStyle(
                                fontSize: 12, color: cs.onSurfaceVariant)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 48, color: cs.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
                maxLines: 3),
            const SizedBox(height: 20),
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
