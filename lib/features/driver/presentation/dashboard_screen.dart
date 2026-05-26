import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mobile_app/app_config.dart';
import 'package:mobile_app/features/driver/domain/driver_route_model.dart';
import 'package:mobile_app/features/driver/domain/driver_trip_model.dart';
import 'package:mobile_app/features/driver/providers/driver_providers.dart';

class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final brand = AppConfigScope.of(context).primaryColor;
    final routeAsync = ref.watch(driverRouteProvider);
    final tripsAsync = ref.watch(driverTripsTodayProvider);
    final profileAsync = ref.watch(driverProfileProvider);
    final activeTrip = ref.watch(activeTripProvider);

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Driver'),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverRouteProvider);
          ref.invalidate(driverTripsTodayProvider);
          ref.invalidate(driverProfileProvider);
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _Greeting(profileAsync: profileAsync, brand: brand),
            const SizedBox(height: 16),
            if (activeTrip != null)
              _ActiveTripBanner(trip: activeTrip, brand: brand),
            const SizedBox(height: 16),
            _TripsCard(
              tripsAsync: tripsAsync,
              routeAsync: routeAsync,
              brand: brand,
            ),
            const SizedBox(height: 16),
            _RouteSummary(routeAsync: routeAsync),
          ],
        ),
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.profileAsync, required this.brand});
  final AsyncValue profileAsync;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final greeting = _greetingFor(DateTime.now().hour);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: brand,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          profileAsync.when(
            data: (p) => _Avatar(name: p.name, imageUrl: p.imageUrl),
            loading: () => const CircleAvatar(
                radius: 24, backgroundColor: Colors.white24),
            error: (_, __) => const CircleAvatar(
                radius: 24,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, color: Colors.white)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(greeting,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 13)),
                profileAsync.when(
                  data: (p) => Text(p.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                  loading: () => const SizedBox(
                      height: 22, child: LinearProgressIndicator()),
                  error: (_, __) => Text('Driver',
                      style: TextStyle(
                          color: cs.onPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700)),
                ),
                Text(DateFormat('EEEE, d MMM').format(DateTime.now()),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _greetingFor(int h) {
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.imageUrl});
  final String name;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 26,
      backgroundColor: Colors.white24,
      backgroundImage: (imageUrl != null && imageUrl!.isNotEmpty)
          ? CachedNetworkImageProvider(imageUrl!)
          : null,
      child: (imageUrl == null || imageUrl!.isEmpty)
          ? Text(initial,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold))
          : null,
    );
  }
}

class _ActiveTripBanner extends StatelessWidget {
  const _ActiveTripBanner({required this.trip, required this.brand});
  final DriverTrip trip;
  final Color brand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/driver/trip'),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: brand.withValues(alpha: 0.4), width: 1.4),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: brand.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_bus_rounded,
                    color: brand, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${trip.tripType.label} trip in progress',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '${trip.markedCount} / ${trip.attendance.length} students marked',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: brand),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripsCard extends ConsumerWidget {
  const _TripsCard({
    required this.tripsAsync,
    required this.routeAsync,
    required this.brand,
  });
  final AsyncValue<List<DriverTrip>> tripsAsync;
  final AsyncValue<DriverRoute?> routeAsync;
  final Color brand;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_available_rounded, color: brand, size: 20),
                const SizedBox(width: 8),
                const Text("Today's Trips",
                    style: TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 12),
            tripsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(8),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Text('Failed to load: $e',
                  style: const TextStyle(color: Colors.red)),
              data: (trips) {
                final morning = _find(trips, TripType.morning);
                final evening = _find(trips, TripType.afternoon);
                final route = routeAsync.value;
                return Column(
                  children: [
                    _TripRow(
                      type: TripType.morning,
                      trip: morning,
                      route: route,
                      brand: brand,
                      ref: ref,
                    ),
                    const Divider(height: 24),
                    _TripRow(
                      type: TripType.afternoon,
                      trip: evening,
                      route: route,
                      brand: brand,
                      ref: ref,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static DriverTrip? _find(List<DriverTrip> trips, TripType type) {
    for (final t in trips) {
      if (t.tripType == type) return t;
    }
    return null;
  }
}

class _TripRow extends StatelessWidget {
  const _TripRow({
    required this.type,
    required this.trip,
    required this.route,
    required this.brand,
    required this.ref,
  });
  final TripType type;
  final DriverTrip? trip;
  final DriverRoute? route;
  final Color brand;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasTrip = trip != null;
    final canStart = !hasTrip && route != null;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: brand.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            type == TripType.morning
                ? Icons.wb_sunny_outlined
                : Icons.wb_twilight_rounded,
            color: brand,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 2),
              if (hasTrip)
                _StatusPill(status: trip!.status)
              else
                Text('Not started',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        if (hasTrip && trip!.isActive)
          FilledButton.tonalIcon(
            onPressed: () => context.go('/driver/trip'),
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text('Resume'),
            style: _compactButtonStyle,
          )
        else if (hasTrip && trip!.isCompleted)
          Chip(
              label: const Text('Done',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
              side: BorderSide.none)
        else if (canStart)
          FilledButton.icon(
            onPressed: () => _startTrip(context),
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: const Text('Start'),
            style: _compactButtonStyle,
          )
        else
          OutlinedButton(
            onPressed: null,
            style: _compactButtonStyle,
            child: const Text('No route'),
          ),
      ],
    );
  }

  /// The app theme sets `minimumSize: Size.fromHeight(48)` which Flutter
  /// resolves to `Size(double.infinity, 48)` — infinite minimum width. That
  /// blows up when these buttons sit inside a `Row`. Clamp the minimum here
  /// so trailing actions size to their content.
  static final ButtonStyle _compactButtonStyle = ButtonStyle(
    minimumSize: WidgetStateProperty.all(const Size(0, 40)),
    padding: WidgetStateProperty.all(
      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
  );

  Future<void> _startTrip(BuildContext context) async {
    final routeId = route?.id;
    if (routeId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(startTripControllerProvider)
          .start(routeId: routeId, type: type);
      if (context.mounted) context.go('/driver/trip');
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not start: $e')));
    }
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final cfg = switch (status) {
      TripStatus.scheduled => (
          const Color(0xFF6366F1),
          'Scheduled'
        ),
      TripStatus.inProgress => (
          const Color(0xFFF59E0B),
          'In progress'
        ),
      TripStatus.completed => (
          const Color(0xFF10B981),
          'Completed'
        ),
      TripStatus.cancelled => (
          const Color(0xFFEF4444),
          'Cancelled'
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: cfg.$1.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(cfg.$2,
          style: TextStyle(
              color: cfg.$1,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.3)),
    );
  }
}

class _RouteSummary extends StatelessWidget {
  const _RouteSummary({required this.routeAsync});
  final AsyncValue<DriverRoute?> routeAsync;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: routeAsync.when(
          loading: () => const SizedBox(
              height: 60,
              child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('Failed to load route: $e',
              style: const TextStyle(color: Colors.red)),
          data: (route) {
            if (route == null) {
              return Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: cs.onSurfaceVariant),
                  const SizedBox(width: 12),
                  const Expanded(
                      child: Text(
                          'No route assigned. Contact the school office.')),
                ],
              );
            }
            return Row(
              children: [
                Icon(Icons.alt_route_rounded, color: cs.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(
                        '${route.stoppages.length} stops · ${route.totalStudents} students',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: () => context.go('/driver/route'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
